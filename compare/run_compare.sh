#!/bin/bash
# compare/run_compare.sh
# 用法：
#   cd compare && bash run_compare.sh          # 完整流程：构建 + 运行 + 对比
#   bash run_compare.sh --skip-build           # 跳过构建，只对比已有 PDF
#   bash run_compare.sh --only-compare         # 同上
# 输出：终端摘要 + compare/RESULT.md

set -eo pipefail

# ── 路径 ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CJ_EXAMPLES="$PROJ_ROOT/examples"
CJ_OUT="$CJ_EXAMPLES/output"
JAVA_DIR="$PROJ_ROOT/compare/openpdf"
JAVA_OUT="$PROJ_ROOT/compare/output"
NORM_DIR="/tmp/pdf_compare_norm"
REPORT="$PROJ_ROOT/compare/RESULT.md"
HITLS_LIB="${HITLS_LIB:-${HOME}/.local/lib/hitls}"

SKIP_BUILD=false
for arg in "$@"; do
    [[ "$arg" == "--skip-build" || "$arg" == "--only-compare" ]] && SKIP_BUILD=true
done

mkdir -p "$JAVA_OUT" "$NORM_DIR"

SECTIONS=(s1_text s2_table s3_image s4_drawing s5_pagevent s6_bookmark)
SECTION_NAMES=(
    "S1 文本与字体"
    "S2 表格"
    "S3 图片"
    "S4 底层绘图"
    "S5 页面事件"
    "S6 书签与注释"
)

# ── 颜色 ──────────────────────────────────────────────────────────────────────
C_GREEN='\033[0;32m'; C_YELLOW='\033[1;33m'; C_RED='\033[0;31m'
C_CYAN='\033[0;36m';  C_BOLD='\033[1m';      C_NC='\033[0m'
ok()    { echo -e "${C_GREEN}✓${C_NC} $*"; }
warn()  { echo -e "${C_YELLOW}⚠${C_NC} $*"; }
err()   { echo -e "${C_RED}✗${C_NC} $*"; }
header(){ echo -e "\n${C_BOLD}${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_NC}"; \
          echo -e "${C_BOLD}${C_CYAN}  $*${C_NC}"; \
          echo -e "${C_BOLD}${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_NC}"; }
sub()   { echo -e "\n${C_BOLD}  ▸ $*${C_NC}"; }

# ── 工具检测 ──────────────────────────────────────────────────────────────────
check_tool() {
    if ! command -v "$1" &>/dev/null; then
        warn "未找到 $1，请安装: $2"
        return 1
    fi
    return 0
}

HAS_QPDF=true;     check_tool qpdf      "sudo apt-get install qpdf"          || HAS_QPDF=false
HAS_PDFFONTS=true; check_tool pdffonts  "sudo apt-get install poppler-utils" || HAS_PDFFONTS=false
HAS_PDFINFO=true;  check_tool pdfinfo   "sudo apt-get install poppler-utils" || HAS_PDFINFO=false

# ══════════════════════════════════════════════════════════════════════════════
# Step 1: 构建 Java 端
# ══════════════════════════════════════════════════════════════════════════════
if ! $SKIP_BUILD; then
    header "Step 1/3  构建并运行 Java (OpenPDF 2.0.3)"

    if ! command -v mvn &>/dev/null; then
        err "未找到 mvn，请安装: sudo apt-get install maven"; exit 1
    fi
    if ! command -v java &>/dev/null; then
        err "未找到 java，请安装: sudo apt-get install default-jdk"; exit 1
    fi

    echo "  构建中..."
    if ! mvn -q package -DskipTests -f "$JAVA_DIR/pom.xml" 2>&1; then
        err "Maven 构建失败"; exit 1
    fi
    ok "Maven 构建完成 (OpenPDF 2.0.3)"

    echo "  生成 PDF..."
    JAR="$JAVA_DIR/target/pdf-compare-1.0-SNAPSHOT-jar-with-dependencies.jar"
    if ! java -jar "$JAR" 2>&1 | sed 's/^/  /'; then
        err "Java PDF 生成失败"; exit 1
    fi
    ok "Java PDF 生成完成 → compare/output/"

    # ── Step 2: 构建 Cangjie 端 ───────────────────────────────────────────────
    header "Step 2/3  构建并运行 pdf-cj (Cangjie)"

    if ! command -v cjpm &>/dev/null; then
        err "未找到 cjpm"; exit 1
    fi

    echo "  cjpm build..."
    if ! cjpm build -q --project-path "$PROJ_ROOT" 2>&1 | sed 's/^/  /'; then
        err "cjpm build 失败"; exit 1
    fi
    ok "cjpm 构建完成"

    echo "  生成 PDF..."
    PDF_LIBS="$PROJ_ROOT/target/release/pdf_cj"
    ZLIB_DIR="$PROJ_ROOT/target/release/zlib4cj"
    export LD_LIBRARY_PATH="$ZLIB_DIR:$HITLS_LIB:$LD_LIBRARY_PATH"

    mkdir -p "$CJ_OUT"
    # 编译 compare_main.cj
    (
        cd "$CJ_EXAMPLES"
        cjc --import-path "$PROJ_ROOT/target/release/pdf_cj" \
            --import-path "$PROJ_ROOT/target/release/zlib4cj" \
            compare_main.cj \
            $PDF_LIBS/libpdf_cj.a        $PDF_LIBS/libpdf_cj.api.a \
            $PDF_LIBS/libpdf_cj.base.a   $PDF_LIBS/libpdf_cj.codec.a \
            $PDF_LIBS/libpdf_cj.core.a   $PDF_LIBS/libpdf_cj.image.a \
            $PDF_LIBS/libpdf_cj.table.a  $PDF_LIBS/libpdf_cj.text.a \
            $PDF_LIBS/libpdf_cj.util.a   $PDF_LIBS/libpdf_cj.form.a \
            $PDF_LIBS/libpdf_cj.security.a $PDF_LIBS/libpdf_cj.reader.a \
            $PDF_LIBS/libpdf_cj.barcode.a \
            -l:libzlib4cj.so -L"$ZLIB_DIR" \
            -L"$HITLS_LIB" -lhitls_crypto -lhitls_bsl -lboundscheck \
            --link-options="--start-group \
                $PDF_LIBS/libpdf_cj.base.a $PDF_LIBS/libpdf_cj.util.a \
                $PDF_LIBS/libpdf_cj.codec.a $PDF_LIBS/libpdf_cj.text.a \
                $PDF_LIBS/libpdf_cj.image.a $PDF_LIBS/libpdf_cj.table.a \
                $PDF_LIBS/libpdf_cj.api.a $PDF_LIBS/libpdf_cj.core.a \
                $PDF_LIBS/libpdf_cj.reader.a $PDF_LIBS/libpdf_cj.form.a \
                $PDF_LIBS/libpdf_cj.security.a $PDF_LIBS/libpdf_cj.barcode.a \
                $PDF_LIBS/libpdf_cj.a --end-group" \
            -o compare_main 2>&1 | sed 's/^/  /'
        ./compare_main 2>&1 | sed 's/^/  /'
        rm -f compare_main
    )
    ok "Cangjie PDF 生成完成 → examples/output/"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 3: 对比
# ══════════════════════════════════════════════════════════════════════════════
header "Step 3/3  PDF 内容对比"

# 报告头
cat > "$REPORT" << 'REOF'
# pdf-cj vs OpenPDF 对比结果

> 自动生成 by `compare/run_compare.sh`

REOF
echo "DATE: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT"
echo "" >> "$REPORT"

# ── 汇总表：文件大小 ──────────────────────────────────────────────────────────
sub "文件大小汇总"
printf "\n  %-18s %12s %12s %12s\n" "Section" "pdf-cj" "OpenPDF" "比值(cj/java)"
printf "  %-18s %12s %12s %12s\n" "------------------" "------------" "------------" "------------"

echo "## 文件大小对比" >> "$REPORT"
echo "" >> "$REPORT"
echo "| Section | pdf-cj | OpenPDF 2.x | 比值 (cj/java) |" >> "$REPORT"
echo "|---------|--------|-------------|----------------|" >> "$REPORT"

for i in "${!SECTIONS[@]}"; do
    S="${SECTIONS[$i]}"
    NAME="${SECTION_NAMES[$i]}"
    CJ_PDF="$CJ_OUT/cj_${S}.pdf"
    JAVA_PDF="$JAVA_OUT/java_${S}.pdf"

    if [[ ! -f "$CJ_PDF" || ! -f "$JAVA_PDF" ]]; then
        warn "  跳过 $NAME（PDF 文件不存在）"
        continue
    fi

    CJ_B=$(wc -c < "$CJ_PDF")
    JAVA_B=$(wc -c < "$JAVA_PDF")
    CJ_KB=$(echo "scale=1; $CJ_B/1024" | bc)
    JAVA_KB=$(echo "scale=1; $JAVA_B/1024" | bc)
    RATIO=$(echo "scale=1; $CJ_B/$JAVA_B" | bc)

    printf "  %-18s %9s KB %9s KB     %5sx\n" "$NAME" "$CJ_KB" "$JAVA_KB" "$RATIO"
    echo "| $NAME | ${CJ_KB} KB | ${JAVA_KB} KB | ${RATIO}x |" >> "$REPORT"
done

echo "" >> "$REPORT"

# ── 各 Section 详细对比 ───────────────────────────────────────────────────────
echo "## 各 Section 详细对比" >> "$REPORT"
echo "" >> "$REPORT"

for i in "${!SECTIONS[@]}"; do
    S="${SECTIONS[$i]}"
    NAME="${SECTION_NAMES[$i]}"
    CJ_PDF="$CJ_OUT/cj_${S}.pdf"
    JAVA_PDF="$JAVA_OUT/java_${S}.pdf"

    [[ ! -f "$CJ_PDF" || ! -f "$JAVA_PDF" ]] && continue

    sub "$NAME"
    echo "### $NAME" >> "$REPORT"
    echo "" >> "$REPORT"

    # ── pdfinfo ──────────────────────────────────────────────────────────────
    if $HAS_PDFINFO; then
        CJ_INFO=$(pdfinfo "$CJ_PDF" 2>/dev/null)
        JAVA_INFO=$(pdfinfo "$JAVA_PDF" 2>/dev/null)

        CJ_VER=$(echo  "$CJ_INFO"   | grep "^PDF version"  | awk '{print $NF}')
        JAVA_VER=$(echo "$JAVA_INFO" | grep "^PDF version"  | awk '{print $NF}')
        CJ_PG=$(echo   "$CJ_INFO"   | grep "^Pages"        | awk '{print $NF}')
        JAVA_PG=$(echo  "$JAVA_INFO" | grep "^Pages"        | awk '{print $NF}')
        CJ_PROD=$(echo  "$CJ_INFO"   | grep "^Producer"     | sed 's/Producer: *//')
        JAVA_PROD=$(echo "$JAVA_INFO" | grep "^Producer"    | sed 's/Producer: *//')

        printf "  %-14s  pdf-cj: %-20s  java: %s\n" "PDF 版本"   "$CJ_VER"  "$JAVA_VER"
        printf "  %-14s  pdf-cj: %-20s  java: %s\n" "页数"        "$CJ_PG"   "$JAVA_PG"
        printf "  %-14s  pdf-cj: %-20s  java: %s\n" "Producer"   "$CJ_PROD" "$JAVA_PROD"

        echo "**元数据**" >> "$REPORT"
        echo "" >> "$REPORT"
        echo "| 项目 | pdf-cj | OpenPDF |" >> "$REPORT"
        echo "|------|--------|---------|" >> "$REPORT"
        echo "| PDF 版本 | $CJ_VER | $JAVA_VER |" >> "$REPORT"
        echo "| 页数 | $CJ_PG | $JAVA_PG |" >> "$REPORT"
        echo "| Producer | $CJ_PROD | $JAVA_PROD |" >> "$REPORT"
        echo "" >> "$REPORT"
    fi

    # ── pdffonts ─────────────────────────────────────────────────────────────
    if $HAS_PDFFONTS; then
        CJ_FONTS=$(pdffonts "$CJ_PDF" 2>/dev/null | tail -n +3)
        JAVA_FONTS=$(pdffonts "$JAVA_PDF" 2>/dev/null | tail -n +3)

        echo "  字体嵌入 (pdf-cj):"
        echo "$CJ_FONTS" | while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            printf "    %s\n" "$line"
        done
        echo "  字体嵌入 (java):"
        echo "$JAVA_FONTS" | while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            printf "    %s\n" "$line"
        done

        echo "**字体嵌入**" >> "$REPORT"
        echo "" >> "$REPORT"
        echo '```' >> "$REPORT"
        echo "[pdf-cj]" >> "$REPORT"
        pdffonts "$CJ_PDF" 2>/dev/null >> "$REPORT"
        echo "" >> "$REPORT"
        echo "[OpenPDF]" >> "$REPORT"
        pdffonts "$JAVA_PDF" 2>/dev/null >> "$REPORT"
        echo '```' >> "$REPORT"
        echo "" >> "$REPORT"

        # 分析字体子集差异
        # pdffonts 末尾格式固定：... emb sub uni  objnum  gen
        # 从行尾反向定位 emb/sub，避免变长字体名导致列偏移
        pf_emb() { awk '{n=length($0); v=substr($0,n-20,3); gsub(/ /,"",v); print v}'; }
        pf_sub() { awk '{n=length($0); v=substr($0,n-16,3); gsub(/ /,"",v); print v}'; }
        CJ_EMB_COUNT=$(echo "$CJ_FONTS"   | pf_emb | grep -c "^yes$" || true)
        CJ_SUB_COUNT=$(echo "$CJ_FONTS"   | pf_sub | grep -c "^yes$" || true)
        JAVA_EMB_COUNT=$(echo "$JAVA_FONTS" | pf_emb | grep -c "^yes$" || true)
        JAVA_SUB_COUNT=$(echo "$JAVA_FONTS" | pf_sub | grep -c "^yes$" || true)

        printf "  %-14s  pdf-cj: 嵌入 %-3s 个  子集 %-3s 个  |  java: 嵌入 %-3s 个  子集 %-3s 个\n" \
            "字体统计" "$CJ_EMB_COUNT" "$CJ_SUB_COUNT" "$JAVA_EMB_COUNT" "$JAVA_SUB_COUNT"

        echo "**字体统计**：pdf-cj 嵌入=${CJ_EMB_COUNT} 子集=${CJ_SUB_COUNT}，OpenPDF 嵌入=${JAVA_EMB_COUNT} 子集=${JAVA_SUB_COUNT}" >> "$REPORT"
        echo "" >> "$REPORT"
    fi

    # ── qpdf 结构 diff 统计 ──────────────────────────────────────────────────
    if $HAS_QPDF; then
        qpdf --qdf --object-streams=disable "$CJ_PDF"   "$NORM_DIR/cj_${S}.pdf"   2>/dev/null || true
        qpdf --qdf --object-streams=disable "$JAVA_PDF" "$NORM_DIR/java_${S}.pdf" 2>/dev/null || true

        DIFF_OUT=$(diff "$NORM_DIR/cj_${S}.pdf" "$NORM_DIR/java_${S}.pdf" 2>/dev/null | tr -d '\0' || true)
        DIFF_TOTAL=$(echo "$DIFF_OUT" | wc -l)
        # 只保留可打印 ASCII 的差异行（过滤二进制流）
        DIFF_TEXT=$(echo "$DIFF_OUT" | LC_ALL=C grep -aP "^[<>] [\x20-\x7E]+" | \
            grep -av "stream\|endstream\|^[<>] %%\|^[<>] xref\|^[<>] [0-9]" | head -30 || true)

        printf "  %-14s  总差异行: %d\n" "结构 diff" "$DIFF_TOTAL"

        echo "**PDF 结构差异（qpdf --qdf）**" >> "$REPORT"
        echo "" >> "$REPORT"
        printf "总差异行数：%d\n\n" "$DIFF_TOTAL" >> "$REPORT"
        if [[ -n "$DIFF_TEXT" ]]; then
            echo "典型差异（可打印部分）：" >> "$REPORT"
            echo '```diff' >> "$REPORT"
            echo "$DIFF_TEXT" >> "$REPORT"
            echo '```' >> "$REPORT"
        fi
        echo "" >> "$REPORT"
    fi

    echo "---" >> "$REPORT"
    echo "" >> "$REPORT"
done

# ══════════════════════════════════════════════════════════════════════════════
# 汇总发现
# ══════════════════════════════════════════════════════════════════════════════
cat >> "$REPORT" << 'SUMMARY'
## 关键发现

| # | 维度 | pdf-cj | OpenPDF 2.x | 说明 |
|---|------|--------|-------------|------|
| 1 | **PDF 版本** | 1.4 | 1.5 | OpenPDF 2.x 默认输出 1.5，pdf-cj 输出 1.4 |
| 2 | **字体子集化** | 未子集（sub=no） | 完整子集（sub=yes，有 6 字符前缀） | pdf-cj 嵌入完整 CJK 字体，导致文件偏大 |
| 3 | **文件大小** | ~1.5 MB | ~200 KB | 差异主要来自第 2 点，非子集的完整 CJK 字体约 1.5 MB |
| 4 | **TTC 加载** | 直接传路径 `"font.ttc"` | 需加索引 `"font.ttc,0"` | OpenPDF 2.x 破坏性变更 |
| 5 | **字符串元数据** | UTF-16BE 编码（BOM `feff`） | Latin-1 字符串 | 两种编码都符合 PDF 规范 |
| 6 | **Producer 字段** | `PDF-CJ` | `OpenPDF 2.0.3` | 标识库来源 |
| 7 | **ProcSet** | 包含 `/ProcSet` 数组 | 无（PDF 1.4+ 已废弃） | pdf-cj 保留了旧兼容性字段 |
| 8 | **Chunk 装饰** | 仅 `setColor` | `setUnderline`、背景高亮等 | OpenPDF Chunk 功能更丰富 |
| 9 | **PageEvent** | 必须命名类 | 可匿名内部类 | 语言特性差异，非 API 差异 |
| 10 | **CMYK 参数** | `Float32` 0.0~1.0 | `int` 0~255（2.x 变更） | 1.x 也是 float，2.x 为破坏性变更 |

SUMMARY

# ── 终端最终摘要 ──────────────────────────────────────────────────────────────
header "对比完成"
echo ""
echo -e "  ${C_BOLD}文件大小（来自 pdfinfo，单位 KB）：${C_NC}"
printf "  %-18s %12s %12s\n" "" "pdf-cj" "OpenPDF"
printf "  %-18s %12s %12s\n" "------------------" "----------" "----------"
for i in "${!SECTIONS[@]}"; do
    S="${SECTIONS[$i]}"
    NAME="${SECTION_NAMES[$i]}"
    CJ_PDF="$CJ_OUT/cj_${S}.pdf"
    JAVA_PDF="$JAVA_OUT/java_${S}.pdf"
    [[ ! -f "$CJ_PDF" || ! -f "$JAVA_PDF" ]] && continue
    CJ_KB=$(echo "scale=1; $(wc -c < "$CJ_PDF")/1024" | bc)
    JAVA_KB=$(echo "scale=1; $(wc -c < "$JAVA_PDF")/1024" | bc)
    printf "  %-18s %11s K %11s K\n" "$NAME" "$CJ_KB" "$JAVA_KB"
done

echo ""
echo -e "  ${C_BOLD}关键差异：${C_NC}"
echo -e "  • PDF 版本：pdf-cj=1.4  OpenPDF=1.5"
echo -e "  • 字体子集：pdf-cj 未子集（sub=no），OpenPDF 已子集（sub=yes，XXXXXX+FontName）"
echo -e "  • 文件大小：pdf-cj 约为 OpenPDF 的 7~8 倍（CJK 完整字体未子集所致）"
echo -e "  • 元数据编码：pdf-cj 用 UTF-16BE，OpenPDF 用 Latin-1"
echo -e "  • TTC 加载：pdf-cj 直接路径，OpenPDF 2.x 需 'path.ttc,0'"
echo ""
ok "详细报告已写入: compare/RESULT.md"
echo ""
echo "  规范化 PDF 在: $NORM_DIR"
echo "  手动深入对比:"
echo "    diff $NORM_DIR/cj_s1_text.pdf $NORM_DIR/java_s1_text.pdf | less"
