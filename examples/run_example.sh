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
# 设置 zlib4cj 动态库路径
export LD_LIBRARY_PATH="../target/release/zlib4cj:$LD_LIBRARY_PATH"

# 链接所有必要的库文件（包括 zlib4cj）
cjc --import-path ../target/release/pdf_cj \
    --import-path ../target/release/zlib4cj \
    "$EXAMPLE_FILE" \
    ../target/release/pdf_cj/libpdf_cj.a \
    ../target/release/pdf_cj/libpdf_cj.api.a \
    ../target/release/pdf_cj/libpdf_cj.base.a \
    ../target/release/pdf_cj/libpdf_cj.codec.a \
    ../target/release/pdf_cj/libpdf_cj.core.a \
    ../target/release/pdf_cj/libpdf_cj.image.a \
    ../target/release/pdf_cj/libpdf_cj.table.a \
    ../target/release/pdf_cj/libpdf_cj.text.a \
    ../target/release/pdf_cj/libpdf_cj.util.a \
    ../target/release/pdf_cj/libpdf_cj.form.a \
    ../target/release/pdf_cj/libpdf_cj.security.a \
    ../target/release/pdf_cj/libpdf_cj.reader.a \
    -l:libzlib4cj.so \
    -L../target/release/zlib4cj \
    -o "$EXAMPLE_NAME"

if [ $? -eq 0 ]; then
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
