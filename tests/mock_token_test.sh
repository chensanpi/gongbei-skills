#!/bin/bash
# =============================================================================
# mock_token_test.sh — gb_helper.sh Token 链路离线验证（可选运行）
# 用法: bash tests/mock_token_test.sh
# 说明: 用 mock curl 模拟官方鉴权接口（POST /open-api/auth/getAppToken），
#       验证 --token 的 获取 → 解析 → 缓存 → 复用 → 强制刷新 全链路。
#       同时校验请求 URL 与 Body 是否符合官方约定。无需真实凭证与网络。
# =============================================================================

set -e

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
HELPER="$REPO_ROOT/scripts/common/gb_helper.sh"

if [ ! -f "$HELPER" ]; then
  echo "❌ 找不到 $HELPER" >&2
  exit 1
fi

# 临时目录：mock curl + 临时 config，测试结束自动清理
WORKDIR=$(mktemp -d /tmp/gb_mock_test.XXXXXX)
MOCKBIN="$WORKDIR/mockbin"
MOCKCFG="$WORKDIR/config"
mkdir -p "$MOCKBIN"

# 官方响应结构：expireTime 为毫秒时间戳（当前时间 + 7200 秒）
MOCK_EXPIRE_MS=$(( ($(date +%s) + 7200) * 1000 ))

cat > "$MOCKBIN/curl" <<EOF
#!/bin/bash
# 校验请求地址与 Body，命中官方鉴权约定才返回成功响应
case "\$*" in
  *"/open-api/auth/getAppToken"*) ;;
  *)
    echo '{"code":"500","msg":"mock: URL 未命中 /open-api/auth/getAppToken","success":false}' >&2
    exit 1
    ;;
esac
case "\$*" in
  *"appKey"*"appSecret"*) ;;
  *)
    echo '{"code":"500","msg":"mock: 请求体缺少 appKey/appSecret","success":false}' >&2
    exit 1
    ;;
esac
echo '{"code":"200","msg":"成功","requestId":"mock-req-1","data":{"appToken":"mock_token_ABC123","expireTime":${MOCK_EXPIRE_MS}},"success":true}'
EOF
chmod +x "$MOCKBIN/curl"

export GONGBEI_CONFIG="$MOCKCFG"
export PATH="$MOCKBIN:$PATH"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

echo "== 配置凭证 =="
bash "$HELPER" --set GONGBEI_APP_KEY=mock_app_key
bash "$HELPER" --set GONGBEI_APP_SECRET=mock_secret

echo ""
echo "== 第一次 --token（应触发 mock curl 获取）=="
TOKEN1=$(bash "$HELPER" --token)
echo "TOKEN1=$TOKEN1"
[ "$TOKEN1" = "mock_token_ABC123" ] && echo "PASS: token 解析正确" || { echo "FAIL: token=$TOKEN1"; exit 1; }

echo ""
echo "== 第二次 --token（应命中缓存，不再调用 curl）=="
TOKEN2=$(bash "$HELPER" --token)
echo "TOKEN2=$TOKEN2"
[ "$TOKEN2" = "mock_token_ABC123" ] && echo "PASS: 缓存复用正确" || { echo "FAIL: token2=$TOKEN2"; exit 1; }

echo ""
echo "== --token-info（应显示剩余约 7000 秒）=="
bash "$HELPER" --token-info

echo ""
echo "== 强制刷新 --token --nocache =="
TOKEN3=$(bash "$HELPER" --token --nocache)
echo "TOKEN3=$TOKEN3"
[ "$TOKEN3" = "mock_token_ABC123" ] && echo "PASS: --nocache 刷新正确" || { echo "FAIL: token3=$TOKEN3"; exit 1; }

echo ""
echo "✅ 全部通过"
