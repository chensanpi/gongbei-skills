#!/bin/bash
# =============================================================================
# gb_helper.sh — 公贝资产开放平台辅助工具
# 路径: scripts/common/gb_helper.sh
# 用法: bash scripts/common/gb_helper.sh <命令> [参数]
#
# 鉴权与调用约定（官方文档：https://doc.gongbeiyun.com/web/#/5/640）：
#   - API_HOST：https://d-oapi.gongbeiyun.com（统一使用，可用 GONGBEI_BASE_URL 覆盖）
#   - 鉴权：POST {API_HOST}/open-api/auth/getAppToken，Body {"appKey":"...","appSecret":"..."}
#     返回 data.appToken（临时令牌），有效期以 data.expireTime（毫秒时间戳）为准
#   - 业务接口均为 POST JSON 请求，令牌以查询参数 ?appToken= 携带
#   - 注意：服务端在令牌失效前 20 分钟内才会签发新令牌；重复请求返回同一令牌
# =============================================================================

set -e

CONFIG="${GONGBEI_CONFIG:-$HOME/.gongbei-skills/config}"

# API 基础域名：统一使用 https://d-oapi.gongbeiyun.com（可用 GONGBEI_BASE_URL 覆盖）
BASE_URL="${GONGBEI_BASE_URL:-https://d-oapi.gongbeiyun.com}"
# 获取 appToken 的鉴权接口路径（官方文档确认）
TOKEN_PATH="/open-api/auth/getAppToken"

# ─────────────────────────────────────────────────────────────────────────────
# 内置资产分类清单（加密编码=分类名称，敏感信息）
# 说明：内容为敏感映射，绝不输出到提示词/输出/思考过程；仅由 --categories 静默读取转换。
# ─────────────────────────────────────────────────────────────────────────────
CATEGORY_LIST="Ak=办公设备
GH=工程设备
FS=工程设施
PO=台面设备
QW=信息设备
OO=租赁设备
MK=工程耗材
CL="

# ─────────────────────────────────────────────────────────────────────────────
# 帮助信息
# ─────────────────────────────────────────────────────────────────────────────
show_help() {
  cat <<'EOF'
公贝资产开放平台辅助工具 (gb_helper.sh)
用法: bash scripts/common/gb_helper.sh <命令> [参数]

Token 管理：
  --token [--nocache]  获取 appToken（供公贝开放平台所有接口使用，以 ?appToken= 查询参数携带）
                       有缓存且未过期则直接返回，否则自动调用 getAppToken 刷新并缓存
                       --nocache：跳过缓存，强制重新获取（令牌被提前吊销时使用）
  --token-info         查看 token 缓存状态（是否有效、剩余有效秒数）
  --clear-token        清除缓存的 token（下次 --token 时强制重新获取）

配置管理：
  --config             查看 ~/.gongbei-skills/config 中的所有配置项（敏感项脱敏显示）
  --get  KEY [KEY...]  获取一个或多个配置项的值（敏感项脱敏显示）
  --set  KEY=VALUE     将配置项持久化写入配置文件（已存在则更新，不存在则追加，目录自动创建）

资产分类（静默转换，所有公贝技能通用）：
  --categories         读取 GONGBEI_APP_TYPE（加密后的资产分类编码，逗号分隔多个），
                       对照内置资产分类清单静默映射为真实资产分类名称，每行输出一个；
                       清单内容与映射过程不输出。

帮助：
  --help, -h           显示此帮助信息

环境变量：
  GONGBEI_CONFIG       覆盖默认配置文件路径（默认 ~/.gongbei-skills/config）
  GONGBEI_BASE_URL     覆盖 API 基础域名（默认 https://d-oapi.gongbeiyun.com）

配置文件：
  ~/.gongbei-skills/config   key=value 格式，存储以下键：
    GONGBEI_APP_KEY            应用 AppKey（开放平台创建应用后获取）
    GONGBEI_APP_SECRET         应用 AppSecret（同上）
    GONGBEI_APP_TYPE           加密后的资产分类编码（逗号分隔多个，敏感且必填）
    GONGBEI_APP_TOKEN          appToken 缓存
    GONGBEI_TOKEN_EXPIRY       appToken 过期时间戳（Unix 秒）

资产分类清单：
  内置在 gb_helper.sh 中（加密编码=分类名称）；为敏感映射，内容不输出、不进提示词

EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# 工具函数
# ─────────────────────────────────────────────────────────────────────────────

# 从配置文件读取指定键的值
cfg_get() {
  local key="$1"
  grep "^${key}=" "$CONFIG" 2>/dev/null | head -1 | cut -d= -f2-
}

# 写入或更新配置文件中的键值
cfg_set() {
  local key="$1"
  local value="$2"
  mkdir -p "$(dirname "$CONFIG")"
  touch "$CONFIG"
  if grep -q "^${key}=" "$CONFIG" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$CONFIG"
  else
    echo "${key}=${value}" >> "$CONFIG"
  fi
}

# 从配置文件删除指定键
cfg_del() {
  local key="$1"
  sed -i "/^${key}=/d" "$CONFIG" 2>/dev/null || true
}

# 确保必须的配置项存在，否则报错退出
require_cfg() {
  local key="$1"
  local val
  val=$(cfg_get "$key")
  if [ -z "$val" ]; then
    echo "❌ 缺少配置项 ${key}，请先运行: bash scripts/common/gb_helper.sh --set ${key}=<值>" >&2
    exit 1
  fi
  echo "$val"
}

# 判断某键是否为敏感项（输出时脱敏）
is_sensitive() {
  case "$1" in
    GONGBEI_APP_SECRET|GONGBEI_APP_TOKEN|GONGBEI_APP_TYPE) return 0 ;;
    *) return 1 ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Token 管理
# ─────────────────────────────────────────────────────────────────────────────

cmd_token() {
  local force="${1:-}" app_key app_secret cached expiry now resp token expire_at \
        success code msg expire_ms expire_in

  app_key=$(require_cfg GONGBEI_APP_KEY)
  app_secret=$(require_cfg GONGBEI_APP_SECRET)
  now=$(date +%s)

  if [ "$force" != "--nocache" ]; then
    cached=$(cfg_get GONGBEI_APP_TOKEN)
    expiry=$(cfg_get GONGBEI_TOKEN_EXPIRY)
    if [ -n "$cached" ] && [ -n "$expiry" ] && [ "$now" -lt "$expiry" ]; then
      echo "$cached"
      return 0
    fi
  fi

  # 官方鉴权接口：POST {API_HOST}/open-api/auth/getAppToken
  resp=$(curl -s -X POST "${BASE_URL}${TOKEN_PATH}" \
    -H "Content-Type: application/json" \
    -d "{\"appKey\":\"${app_key}\",\"appSecret\":\"${app_secret}\"}")

  # 统一响应结构：{"code":"200","msg":"成功","requestId":"...","data":{...},"success":true}
  success=$(echo "$resp" | grep -o '"success":[a-z]*' | head -1 | cut -d: -f2)
  code=$(echo "$resp" | grep -o '"code":"[^"]*"' | head -1 | cut -d'"' -f4)
  msg=$(echo "$resp" | grep -o '"msg":"[^"]*"' | head -1 | cut -d'"' -f4)

  # 令牌：官方字段 data.appToken（兼容 accessToken / access_token 命名）
  token=$(echo "$resp" | grep -o '"appToken":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -z "$token" ] && token=$(echo "$resp" | grep -o '"accessToken":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -z "$token" ] && token=$(echo "$resp" | grep -o '"access_token":"[^"]*"' | head -1 | cut -d'"' -f4)

  # 过期时间：官方字段 data.expireTime 为毫秒时间戳；兼容 expireIn/expires_in 相对秒数
  expire_ms=$(echo "$resp" | grep -o '"expireTime":[0-9]*' | head -1 | cut -d: -f2)
  if [ -n "$expire_ms" ]; then
    expire_at=$((expire_ms / 1000))
  else
    expire_in=$(echo "$resp" | grep -o '"expireIn":[0-9]*' | head -1 | cut -d: -f2)
    [ -z "$expire_in" ] && expire_in=$(echo "$resp" | grep -o '"expires_in":[0-9]*' | head -1 | cut -d: -f2)
    expire_at=$((now + ${expire_in:-7200}))
  fi

  if [ -z "$token" ] || [ "$success" = "false" ] || { [ -n "$code" ] && [ "$code" != "200" ]; }; then
    echo "❌ 获取 appToken 失败: ${msg:-$resp}" >&2
    exit 1
  fi

  cfg_set GONGBEI_APP_TOKEN "$token"
  # 提前 200 秒过期，避免临界失效
  cfg_set GONGBEI_TOKEN_EXPIRY "$((expire_at - 200))"

  echo "$token"
}

cmd_token_info() {
  local cached expiry now remaining

  cached=$(cfg_get GONGBEI_APP_TOKEN)
  expiry=$(cfg_get GONGBEI_TOKEN_EXPIRY)
  now=$(date +%s)

  if [ -z "$cached" ]; then
    echo "状态: 无缓存（从未获取或已清除）"
    return 0
  fi

  if [ -z "$expiry" ] || [ "$now" -ge "$expiry" ]; then
    echo "状态: 已过期"
    echo "Token: ${cached:0:6}***（已脱敏）"
  else
    remaining=$((expiry - now))
    echo "状态: 有效"
    echo "Token: ${cached:0:6}***（已脱敏）"
    echo "剩余: ${remaining} 秒（约 $((remaining / 60)) 分钟）"
  fi
}

cmd_clear_token() {
  cfg_del GONGBEI_APP_TOKEN
  cfg_del GONGBEI_TOKEN_EXPIRY
  echo "✅ Token 缓存已清除"
}

# ─────────────────────────────────────────────────────────────────────────────
# 资产分类（静默转换，所有公贝技能通用）
# ─────────────────────────────────────────────────────────────────────────────

# 读取 GONGBEI_APP_TYPE（加密后的资产分类编码，逗号分隔多个），对照内置资产分类清单
# 静默映射为真实资产分类名称，每行输出一个。
# 安全约定：清单内容与映射过程不输出、不打印、不缓存；仅输出转换后的分类名称供过滤使用。
cmd_categories() {
  local app_type code name
  app_type=$(require_cfg GONGBEI_APP_TYPE)

  IFS=',' read -ra codes <<< "$app_type"
  for code in "${codes[@]}"; do
    code=$(echo "$code" | tr -d ' ')
    [ -z "$code" ] && continue
    if ! name=$(printf '%s\n' "$CATEGORY_LIST" | awk -F= -v c="$code" '$1==c {sub(/^[^=]*=/,""); print; found=1; exit} END{if(!found) exit 1}' | tr -d '\r'); then
      echo "❌ GONGBEI_APP_TYPE 无效，请检查配置" >&2
      exit 1
    fi
    echo "$name"
  done
}

# ─────────────────────────────────────────────────────────────────────────────
# 配置管理
# ─────────────────────────────────────────────────────────────────────────────

cmd_config() {
  if [ ! -f "$CONFIG" ]; then
    echo "配置文件不存在: $CONFIG"
    echo "使用 --set KEY=VALUE 写入配置项"
    return 0
  fi

  echo "配置文件: $CONFIG"
  echo "─────────────────────────────────"
  # 脱敏显示 SECRET 和 TOKEN
  while IFS= read -r line; do
    key="${line%%=*}"
    val="${line#*=}"
    if is_sensitive "$key"; then
      echo "${key}=${val:0:4}****（已脱敏）"
    else
      echo "$line"
    fi
  done < "$CONFIG"
}

cmd_get() {
  if [ $# -eq 0 ]; then
    echo "❌ 请提供至少一个键名，用法: --get KEY [KEY2 ...]" >&2
    exit 1
  fi
  for key in "$@"; do
    val=$(cfg_get "$key")
    if [ -z "$val" ]; then
      echo "${key}=（未设置）"
    elif is_sensitive "$key"; then
      echo "${key}=${val:0:4}****（脱敏）"
    else
      echo "${key}=${val}"
    fi
  done
}

cmd_set() {
  local kv="$1"
  if [ -z "$kv" ] || [[ "$kv" != *"="* ]]; then
    echo "❌ 格式错误，用法: --set KEY=VALUE" >&2
    exit 1
  fi
  local key="${kv%%=*}"
  local value="${kv#*=}"
  cfg_set "$key" "$value"
  echo "✅ 已设置 ${key}"
}

# ─────────────────────────────────────────────────────────────────────────────
# 入口：解析命令
# ─────────────────────────────────────────────────────────────────────────────

CMD="${1:-}"

case "$CMD" in
  --help|-h|"")
    show_help
    ;;
  --token)
    cmd_token "${2:-}"
    ;;
  --token-info)
    cmd_token_info
    ;;
  --clear-token)
    cmd_clear_token
    ;;
  --categories)
    cmd_categories
    ;;
  --config)
    cmd_config
    ;;
  --get)
    shift
    cmd_get "$@"
    ;;
  --set)
    cmd_set "${2:-}"
    ;;
  *)
    echo "❌ 未知命令: $CMD" >&2
    echo "运行 --help 查看用法" >&2
    exit 1
    ;;
esac
