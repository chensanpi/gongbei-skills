#!/bin/bash
# =============================================================================
# test_gb_helper.sh — gb_helper.sh 框架级冒烟测试
# 用法: bash tests/test_gb_helper.sh
# 说明: 离线可跑，不需要真实凭证与网络。仅验证：
#       配置写入/读取/覆盖、脱敏输出、token 缓存清除、未知命令报错。
#       Token 获取链路（--token）需真实凭证，此处自动跳过。
# =============================================================================

set -e

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
HELPER="$REPO_ROOT/scripts/common/gb_helper.sh"

if [ ! -f "$HELPER" ]; then
  echo "❌ 找不到 $HELPER" >&2
  exit 1
fi

# 使用临时 config，隔离测试与真实配置
TEMP_CONFIG=$(mktemp /tmp/gb_helper_test_config.XXXXXX)
export GONGBEI_CONFIG="$TEMP_CONFIG"

cleanup() { rm -f "$TEMP_CONFIG"; }
trap cleanup EXIT

pass=0
fail=0
skip=0

ok() {
  echo "  ✅ $1"
  pass=$((pass + 1))
}

ng() {
  echo "  ❌ $1"
  echo "     期望: $2"
  echo "     实际: $3"
  fail=$((fail + 1))
}

sk() {
  echo "  ⏭️  $1（跳过: $2）"
  skip=$((skip + 1))
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF -- "$needle"; then
    ok "$desc"
  else
    ng "$desc" "包含: $needle" "$haystack"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
echo "== 1. 配置写入与读取 =="

# 1.1 --set 写入
OUT=$(bash "$HELPER" --set GONGBEI_APP_KEY=test_app_key_123)
assert_contains "1.1 --set 写入配置" "✅ 已设置 GONGBEI_APP_KEY" "$OUT"

# 1.2 --get 读取
OUT=$(bash "$HELPER" --get GONGBEI_APP_KEY)
assert_contains "1.2 --get 读取配置" "GONGBEI_APP_KEY=test_app_key_123" "$OUT"

# 1.3 --set 覆盖已存在的键
bash "$HELPER" --set GONGBEI_APP_KEY=new_key > /dev/null
OUT=$(bash "$HELPER" --get GONGBEI_APP_KEY)
if echo "$OUT" | grep -qF "GONGBEI_APP_KEY=new_key"; then
  ok "1.3 --set 覆盖旧值"
else
  ng "1.3 --set 覆盖旧值" "GONGBEI_APP_KEY=new_key" "$OUT"
fi

# 1.4 配置持久化到文件
if grep -q "^GONGBEI_APP_KEY=new_key$" "$TEMP_CONFIG"; then
  ok "1.4 配置已持久化到文件"
else
  ng "1.4 配置已持久化到文件" "文件中存在 GONGBEI_APP_KEY=new_key" "$(cat "$TEMP_CONFIG")"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo "== 2. 敏感项脱敏 =="

bash "$HELPER" --set GONGBEI_APP_SECRET=super_secret_abc > /dev/null

OUT=$(bash "$HELPER" --get GONGBEI_APP_SECRET)
if echo "$OUT" | grep -qF "super"; then
  ng "2.1 --get 对 Secret 脱敏" "输出不含完整 Secret" "$OUT"
else
  ok "2.1 --get 对 Secret 脱敏"
fi
assert_contains "2.2 --get 脱敏后保留前 4 位" "GONGBEI_APP_SECRET=supe****" "$OUT"

OUT=$(bash "$HELPER" --config)
if echo "$OUT" | grep -qF "super_secret_abc"; then
  ng "2.3 --config 对 Secret 脱敏" "输出不含完整 Secret" "$OUT"
else
  ok "2.3 --config 对 Secret 脱敏"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo "== 3. Token 缓存管理（离线）=="

# 3.1 未配置凭证时 --token 应报错（用全新空配置验证，不依赖主配置内容）
EMPTY_CONFIG=$(mktemp /tmp/gb_helper_test_empty.XXXXXX)
OUT=$(GONGBEI_CONFIG="$EMPTY_CONFIG" bash "$HELPER" --token 2>&1 || true)
rm -f "$EMPTY_CONFIG"
if echo "$OUT" | grep -qF "缺少配置项"; then
  ok "3.1 缺少凭证时 --token 报错提示"
else
  ng "3.1 缺少凭证时 --token 报错提示" "包含: 缺少配置项" "$OUT"
fi

# 3.2 token 缓存清除
bash "$HELPER" --set GONGBEI_APP_TOKEN=fake_token > /dev/null
bash "$HELPER" --set GONGBEI_TOKEN_EXPIRY=9999999999 > /dev/null
OUT=$(bash "$HELPER" --clear-token)
assert_contains "3.2 --clear-token 清除缓存" "✅ Token 缓存已清除" "$OUT"
OUT=$(bash "$HELPER" --token-info)
assert_contains "3.3 清除后 --token-info 显示无缓存" "无缓存" "$OUT"

# ─────────────────────────────────────────────────────────────────────────────
echo "== 4. 帮助与错误处理 =="

OUT=$(bash "$HELPER" --help)
assert_contains "4.1 --help 输出用法" "gb_helper.sh" "$OUT"

OUT=$(bash "$HELPER" --unknown-cmd 2>&1 || true)
if echo "$OUT" | grep -qF "未知命令"; then
  ok "4.2 未知命令报错"
else
  ng "4.2 未知命令报错" "包含: 未知命令" "$OUT"
fi

OUT=$(bash "$HELPER" --set 2>&1 || true)
if echo "$OUT" | grep -qF "格式错误"; then
  ok "4.3 --set 缺参报错"
else
  ng "4.3 --set 缺参报错" "包含: 格式错误" "$OUT"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "────────── 结果汇总 ──────────"
echo "通过: $pass | 失败: $fail | 跳过: $skip"
if [ "$fail" -gt 0 ]; then
  echo "❌ 有测试失败" >&2
  exit 1
fi
echo "✅ 全部通过"
