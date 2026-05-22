#!/bin/bash
# configure.sh — 自动检测 OpenHiTLS 库位置并生成 cjpm.toml
#
# 用法：
#   ./configure.sh                         # 自动检测
#   HITLS_LIB=/custom/path ./configure.sh  # 指定路径
#   ./configure.sh --hitls-lib=/custom/path

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 解析命令行参数 ───────────────────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --hitls-lib=*)
            HITLS_LIB="${arg#*=}"
            ;;
        -h|--help)
            echo "Usage: $0 [--hitls-lib=<path>]"
            echo ""
            echo "Environment variables:"
            echo "  HITLS_LIB   OpenHiTLS library directory"
            echo ""
            echo "Auto-detection order:"
            echo "  1. HITLS_LIB environment variable"
            echo "  2. ~/.local/lib/hitls  (user install)"
            echo "  3. /usr/local/lib      (system install)"
            echo "  4. <project>/../openhitls/build  (build-in-place)"
            exit 0
            ;;
    esac
done

# ── 按优先级自动检测 HiTLS 库路径 ────────────────────────────────────────────
HITLS_PATH=""
BOUNDSCHECK_PATH=""

detect_hitls() {
    local path="$1"
    # 检查是否包含 hitls_crypto 的静态库或动态库
    if [ -d "$path" ] && \
       ( [ -f "$path/libhitls_crypto.a" ] || [ -f "$path/libhitls_crypto.so" ] ); then
        return 0
    fi
    return 1
}

if [ -n "$HITLS_LIB" ]; then
    # 1. 用户显式指定
    HITLS_PATH="$HITLS_LIB"
elif detect_hitls "$HOME/.local/lib/hitls"; then
    # 2. 用户本地安装（推荐安装位置）
    HITLS_PATH="$HOME/.local/lib/hitls"
elif detect_hitls "/usr/local/lib"; then
    # 3. 系统安装
    HITLS_PATH="/usr/local/lib"
elif detect_hitls "${SCRIPT_DIR}/../openhitls/build"; then
    # 4. 源码同级目录直接编译
    HITLS_PATH="$(cd "${SCRIPT_DIR}/../openhitls/build" && pwd)"
    SECURE_C="${SCRIPT_DIR}/../openhitls/platform/Secure_C/lib"
    if [ -d "$SECURE_C" ]; then
        BOUNDSCHECK_PATH="$(cd "$SECURE_C" && pwd)"
    fi
fi

# ── 未找到时提示安装 ──────────────────────────────────────────────────────────
if [ -z "$HITLS_PATH" ]; then
    echo "错误: 未找到 OpenHiTLS 库！"
    echo ""
    echo "请先安装 OpenHiTLS，然后重新运行此脚本："
    echo ""
    echo "  git clone https://gitcode.com/openHiTLS/openhitls.git"
    echo "  cd openhitls && mkdir -p build && cd build"
    echo "  python3 ../configure.py --enable hitls_bsl hitls_crypto \\"
    echo "      --lib_type static --bits=64 --system=linux"
    echo "  cmake .. -DCMAKE_INSTALL_PREFIX=~/.local"
    echo "  make -j && make install"
    echo ""
    echo "安装完成后，库文件应位于 ~/.local/lib/hitls/"
    echo "也可通过环境变量指定自定义路径："
    echo "  HITLS_LIB=/your/path ./configure.sh"
    exit 1
fi

# boundscheck 未单独检测到时，与 hitls 库同目录
BOUNDSCHECK_PATH="${BOUNDSCHECK_PATH:-$HITLS_PATH}"

# ── 生成 cjpm.toml ────────────────────────────────────────────────────────────
TEMPLATE="${SCRIPT_DIR}/cjpm.toml.template"
OUTPUT="${SCRIPT_DIR}/cjpm.toml"

if [ ! -f "${TEMPLATE}" ]; then
    echo "错误: 模板文件不存在: ${TEMPLATE}"
    exit 1
fi

sed -e "s|@HITLS_LIB@|${HITLS_PATH}|g" \
    -e "s|@BOUNDSCHECK_LIB@|${BOUNDSCHECK_PATH}|g" \
    "${TEMPLATE}" > "${OUTPUT}"

echo "已生成 cjpm.toml"
echo "  HITLS_LIB      = ${HITLS_PATH}"
echo "  BOUNDSCHECK    = ${BOUNDSCHECK_PATH}"
echo ""
echo "下一步运行: cjpm build"
