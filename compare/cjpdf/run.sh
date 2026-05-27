#!/bin/bash
# compare/cjpdf/run.sh
# 用法:
#   ./run.sh           # 编译运行所有 section
#   ./run.sh all       # 同上
#   ./run.sh 1         # 只运行 S01
#   ./run.sh 01        # 同上
#
# 依赖: 需要先 cjpm build 项目 (在 pdf-cj 根目录执行)

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PDF_LIBS="$PROJ_ROOT/target/release/pdf_cj"
ZLIB_DIR="$PROJ_ROOT/target/release/zlib4cj"
HITLS_LIB="${HITLS_LIB:-${HOME}/.local/lib/hitls}"

ulimit -v unlimited 2>/dev/null || true
ulimit -s unlimited 2>/dev/null || true

export LD_LIBRARY_PATH="$ZLIB_DIR:$HITLS_LIB:$LD_LIBRARY_PATH"

mkdir -p "$SCRIPT_DIR/output"
cd "$SCRIPT_DIR"

# All source files in order
ALL_SRCS=(
    SharedFonts.cj
    S01_DocumentPage.cj
    S02_FontText.cj
    S03_Chunk.cj
    S04_Phrase.cj
    S05_Paragraph.cj
    S06_Anchor.cj
    S07_Table.cj
    S08_Image.cj
    S09_Drawing.cj
    S10_PageEvent.cj
    S11_Bookmark.cj
    S12_Annotation.cj
    S13_FormField.cj
    S14_Transparency.cj
    S15_Shading.cj
    S16_Barcode.cj
    S17_ReaderStamper.cj
    S18_PdfCopy.cj
    S19_TextExtract.cj
    S20_Security.cj
    S21_ColumnText.cj
    S22_Chapter.cj
    S23_Metadata.cj
)

# Section number → function name mapping
declare -A SECTION_FUNC=(
    ["1"]="s01_documentPage"   ["2"]="s02_fontText"
    ["3"]="s03_chunk"          ["4"]="s04_phrase"
    ["5"]="s05_paragraph"      ["6"]="s06_anchor"
    ["7"]="s07_table"          ["8"]="s08_image"
    ["9"]="s09_drawing"        ["10"]="s10_pageEvent"
    ["11"]="s11_bookmark"      ["12"]="s12_annotation"
    ["13"]="s13_formField"     ["14"]="s14_transparency"
    ["15"]="s15_shading"       ["16"]="s16_barcode"
    ["17"]="s17_readerStamper" ["18"]="s18_pdfCopy"
    ["19"]="s19_textExtract"   ["20"]="s20_security"
    ["21"]="s21_columnText"    ["22"]="s22_chapter"
    ["23"]="s23_metadata"
)

compile_cmd() {
    local srcs=("$@")
    cjc \
        --import-path "$PDF_LIBS" \
        --import-path "$ZLIB_DIR" \
        "${srcs[@]}" \
        "$PDF_LIBS/libpdf_cj.a" \
        "$PDF_LIBS/libpdf_cj.api.a" \
        "$PDF_LIBS/libpdf_cj.base.a" \
        "$PDF_LIBS/libpdf_cj.codec.a" \
        "$PDF_LIBS/libpdf_cj.core.a" \
        "$PDF_LIBS/libpdf_cj.image.a" \
        "$PDF_LIBS/libpdf_cj.table.a" \
        "$PDF_LIBS/libpdf_cj.text.a" \
        "$PDF_LIBS/libpdf_cj.util.a" \
        "$PDF_LIBS/libpdf_cj.form.a" \
        "$PDF_LIBS/libpdf_cj.security.a" \
        "$PDF_LIBS/libpdf_cj.reader.a" \
        "$PDF_LIBS/libpdf_cj.barcode.a" \
        -l:libzlib4cj.so \
        -L"$ZLIB_DIR" \
        -L"$HITLS_LIB" \
        -lhitls_crypto -lhitls_bsl -lboundscheck \
        --link-options="--start-group \
            $PDF_LIBS/libpdf_cj.base.a \
            $PDF_LIBS/libpdf_cj.util.a \
            $PDF_LIBS/libpdf_cj.codec.a \
            $PDF_LIBS/libpdf_cj.text.a \
            $PDF_LIBS/libpdf_cj.image.a \
            $PDF_LIBS/libpdf_cj.table.a \
            $PDF_LIBS/libpdf_cj.api.a \
            $PDF_LIBS/libpdf_cj.core.a \
            $PDF_LIBS/libpdf_cj.reader.a \
            $PDF_LIBS/libpdf_cj.form.a \
            $PDF_LIBS/libpdf_cj.security.a \
            $PDF_LIBS/libpdf_cj.barcode.a \
            $PDF_LIBS/libpdf_cj.a --end-group"
}

run_all() {
    echo "编译全部 23 个 Section..."
    compile_cmd "${ALL_SRCS[@]}" RunAllSections.cj -o RunAllSections
    echo "运行..."
    ./RunAllSections
    rm -f RunAllSections
}

run_single() {
    local num=$1
    # Remove leading zero
    num="${num#0}"
    local func="${SECTION_FUNC[$num]}"
    if [ -z "$func" ]; then
        echo "未知 Section: $num (有效范围 1-23)"
        exit 1
    fi
    local srcfile=$(ls S$(printf '%02d' $num)_*.cj 2>/dev/null | head -1)
    if [ -z "$srcfile" ]; then
        echo "找不到 Section $num 的源文件"
        exit 1
    fi
    echo "编译 $srcfile..."
    # Create temp main wrapper
    local tmpfile=$(mktemp /tmp/cjpdf_main_XXXXXX.cj)
    echo "package pdf_cj_examples" > "$tmpfile"
    echo "main(): Int64 { ${func}(); 0 }" >> "$tmpfile"
    compile_cmd SharedFonts.cj "$srcfile" "$tmpfile" -o /tmp/cjpdf_runner_$$
    rm -f "$tmpfile"
    echo "运行 $srcfile..."
    /tmp/cjpdf_runner_$$
    rm -f /tmp/cjpdf_runner_$$
}

case "${1:-all}" in
    all|"") run_all ;;
    [0-9]*) run_single "${1#0}" ;;
    *) echo "用法: $0 [all|1-23]"; exit 1 ;;
esac
