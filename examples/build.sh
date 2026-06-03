#!/bin/bash
# build.sh — 自动检测 HiTLS 库位置并生成 cjpm.toml，然后构建示例
#
# 用法：
#   ./build.sh                         # 检测 + 构建
#   HITLS_LIB=/custom/path ./build.sh  # 指定 HiTLS 路径
#
# 检测优先级：
#   1. HITLS_LIB 环境变量
#   2. ~/.local/lib/hitls （用户本地安装）
#   3. /usr/local/lib     （系统安装）
#   4. ../../openhitls/build （源码同级编译）

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_hitls() {
    local p="$1"
    [ -d "$p" ] && { [ -f "$p/libhitls_crypto.a" ] || [ -f "$p/libhitls_crypto.so" ]; }
}

HITLS_PATH=""
BOUNDSCHECK_PATH=""

if [ -n "$HITLS_LIB" ]; then
    HITLS_PATH="$HITLS_LIB"
elif detect_hitls "$HOME/.local/lib/hitls"; then
    HITLS_PATH="$HOME/.local/lib/hitls"
elif detect_hitls "/usr/local/lib"; then
    HITLS_PATH="/usr/local/lib"
elif detect_hitls "${SCRIPT_DIR}/../../openhitls/build"; then
    HITLS_PATH="$(cd "${SCRIPT_DIR}/../../openhitls/build" && pwd)"
    SECURE_C="${SCRIPT_DIR}/../../openhitls/platform/Secure_C/lib"
    [ -d "$SECURE_C" ] && BOUNDSCHECK_PATH="$(cd "$SECURE_C" && pwd)"
fi

if [ -z "$HITLS_PATH" ]; then
    echo "错误: 未找到 OpenHiTLS 库！"
    echo "请安装到 ~/.local/lib/hitls 或通过环境变量指定："
    echo "  HITLS_LIB=/your/path ./build.sh"
    exit 1
fi
BOUNDSCHECK_PATH="${BOUNDSCHECK_PATH:-$HITLS_PATH}"

echo "使用 HiTLS 库路径: $HITLS_PATH"

# 生成 cjpm.toml
cat > "${SCRIPT_DIR}/cjpm.toml" << EOF
[package]
name = "pdf_cj_examples"
version = "0.1.0"
description = "Examples for pdf-cj (S01-S23, OpenPDF 对照)"
cjc-version = "1.0.4"
output-type = "executable"
c-arguments = ["-Woff", "unused"]

[dependencies]
pdf_cj = { path = ".." }

# openHiTLS FFI 配置 (由 build.sh 自动生成)
[ffi.c]
hitls_crypto = { path = "${HITLS_PATH}" }
hitls_bsl = { path = "${HITLS_PATH}" }
boundscheck = { path = "${BOUNDSCHECK_PATH}" }
EOF

echo "已生成 cjpm.toml"
cjpm build "$@"
