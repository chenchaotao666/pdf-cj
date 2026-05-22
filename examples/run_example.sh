#!/bin/bash

# PDF-CJ 示例运行脚本
# 使用方法: ./run_example.sh <example_name>
# 例如: ./run_example.sh hello_world

# 设置无限虚拟内存以支持大字体文件加载
ulimit -v unlimited 2>/dev/null || true
ulimit -s unlimited 2>/dev/null || true

if [ -z "$1" ]; then
    echo "使用方法: $0 <example_name>"
    echo ""
    echo "可用示例:"
    echo "  hello_world          - 入门示例"
    echo "  example_table        - 表格示例"
    echo "  example_comprehensive - 综合示例"
    exit 1
fi

EXAMPLE_NAME=$1
EXAMPLE_FILE="${EXAMPLE_NAME}.cj"

if [ ! -f "$EXAMPLE_FILE" ]; then
    echo "错误: 找不到示例文件 $EXAMPLE_FILE"
    exit 1
fi

echo "编译示例: $EXAMPLE_NAME"
# 动态库搜索路径（可通过环境变量覆盖，默认 ~/.local/lib/hitls）
HITLS_LIB="${HITLS_LIB:-${HOME}/.local/lib/hitls}"
export LD_LIBRARY_PATH="../target/release/zlib4cj:${HITLS_LIB}:$LD_LIBRARY_PATH"

# 链接所有必要的库文件（包括 zlib4cj）
# pdf_cj 各子包之间存在反射元数据 (.ti) 的循环引用 (例如 text.a 依赖 base.a)。
# 由于 ld 默认单遍扫描静态库，先列的 .a 在被后续 .a 引用时会找不到符号。
# 这里通过 --link-options 在 ld 命令尾部追加一遍带 --start-group 的所有库，
# 让 ld 反复迭代解析直到所有符号解决。
PDF_LIBS_DIR="../target/release/pdf_cj"
cjc --import-path ../target/release/pdf_cj \
    --import-path ../target/release/zlib4cj \
    "$EXAMPLE_FILE" \
    ${PDF_LIBS_DIR}/libpdf_cj.a \
    ${PDF_LIBS_DIR}/libpdf_cj.api.a \
    ${PDF_LIBS_DIR}/libpdf_cj.base.a \
    ${PDF_LIBS_DIR}/libpdf_cj.codec.a \
    ${PDF_LIBS_DIR}/libpdf_cj.core.a \
    ${PDF_LIBS_DIR}/libpdf_cj.image.a \
    ${PDF_LIBS_DIR}/libpdf_cj.table.a \
    ${PDF_LIBS_DIR}/libpdf_cj.text.a \
    ${PDF_LIBS_DIR}/libpdf_cj.util.a \
    ${PDF_LIBS_DIR}/libpdf_cj.form.a \
    ${PDF_LIBS_DIR}/libpdf_cj.security.a \
    ${PDF_LIBS_DIR}/libpdf_cj.reader.a \
    ${PDF_LIBS_DIR}/libpdf_cj.barcode.a \
    -l:libzlib4cj.so \
    -L../target/release/zlib4cj \
    -L${HITLS_LIB} \
    -lhitls_crypto -lhitls_bsl -lboundscheck \
    --link-options="--start-group ${PDF_LIBS_DIR}/libpdf_cj.base.a ${PDF_LIBS_DIR}/libpdf_cj.util.a ${PDF_LIBS_DIR}/libpdf_cj.codec.a ${PDF_LIBS_DIR}/libpdf_cj.text.a ${PDF_LIBS_DIR}/libpdf_cj.image.a ${PDF_LIBS_DIR}/libpdf_cj.table.a ${PDF_LIBS_DIR}/libpdf_cj.api.a ${PDF_LIBS_DIR}/libpdf_cj.core.a ${PDF_LIBS_DIR}/libpdf_cj.reader.a ${PDF_LIBS_DIR}/libpdf_cj.form.a ${PDF_LIBS_DIR}/libpdf_cj.security.a ${PDF_LIBS_DIR}/libpdf_cj.barcode.a ${PDF_LIBS_DIR}/libpdf_cj.a --end-group" \
    -o "$EXAMPLE_NAME"

if [ $? -eq 0 ]; then
    # 确保示例输出目录存在（示例会向 output/ 写 PDF 文件）
    mkdir -p output
    echo "运行示例: $EXAMPLE_NAME"
    echo "----------------------------------------"
    ./"$EXAMPLE_NAME"
    EXIT_CODE=$?
    echo "----------------------------------------"

    if [ $EXIT_CODE -eq 0 ]; then
        echo "✓ 示例运行成功"
        # 清理可执行文件
        rm -f "$EXAMPLE_NAME"
    else
        echo "✗ 示例运行失败 (退出码: $EXIT_CODE)"
    fi
else
    echo "✗ 编译失败"
    exit 1
fi
