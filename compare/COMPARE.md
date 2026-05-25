# pdf-cj vs OpenPDF 对比使用文档

## 目录结构

```
pdf-cj/
├── compare/
│   ├── COMPARE.md                          ← 本文档
│   ├── openpdf/
│   │   ├── pom.xml                         ← OpenPDF Maven 项目
│   │   └── src/main/java/PdfCompare.java   ← Java 端，6 个场景
│   └── output/                             ← Java 生成的 PDF（运行后生成）
│
└── examples/
    ├── compare_main.cj                     ← Cangjie 端，与 Java 等价的 6 个场景
    ├── run_example.sh                      ← Cangjie 示例运行脚本
    └── output/                             ← Cangjie 生成的 PDF（运行后生成）
```

---

## 依赖软件

### 1. Cangjie 端（必须）

| 软件 | 版本要求 | 说明 |
|------|---------|------|
| `cjc` / `cjpm` | ≥ 1.0.3 | 仓颉编译器和包管理器 |
| `NotoSansCJK-Regular.ttc` | 任意版本 | CJK 字体文件，硬编码路径 `/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc` |
| HiTLS 动态库 | 配套版本 | 加密模块，路径 `~/.local/lib/hitls/`（可通过 `HITLS_LIB` 环境变量覆盖） |

安装字体（Ubuntu/Debian）：

```bash
sudo apt-get install fonts-noto-cjk
```

### 2. Java 端（必须）

| 软件 | 版本要求 | 说明 |
|------|---------|------|
| JDK | ≥ 11 | 编译和运行 Java |
| Maven | ≥ 3.6 | 构建工具，自动下载 OpenPDF 依赖 |
| 网络 | 首次构建需要 | Maven 从中央仓库下载 OpenPDF 2.0.3 |

安装（Ubuntu/Debian）：

```bash
sudo apt-get install default-jdk maven
```

### 3. PDF 对比工具（可选，用于内容层对比）

| 软件 | 用途 | 安装命令 |
|------|------|---------|
| `qpdf` | 规范化 PDF 结构，用于 diff | `sudo apt-get install qpdf` |
| `pdffonts` | 查看字体嵌入情况 | `sudo apt-get install poppler-utils` |
| `pdfinfo` | 查看 PDF 元数据、页数、版本 | 同上（poppler-utils 包含） |
| `pdftotext` | 提取文本内容 | 同上 |

一次性安装全部：

```bash
sudo apt-get install qpdf poppler-utils
```

---

## 运行步骤

### Step 1：构建 pdf-cj 库

在项目根目录执行：

```bash
cd /path/to/pdf-cj
cjpm build
```

成功输出：`cjpm build success`

---

### Step 2：运行 Cangjie 端，生成 cj_s*.pdf

```bash
cd examples
./run_example.sh compare_main
```

生成文件（位于 `examples/output/`）：

```
cj_s1_text.pdf      S1 文本与字体
cj_s2_table.pdf     S2 表格（colspan / rowspan / headerRows）
cj_s3_image.pdf     S3 图片嵌入与缩放
cj_s4_drawing.pdf   S4 底层绘图（PdfContentByte）
cj_s5_pagevent.pdf  S5 页面事件（页眉 / 页脚 / 页码）
cj_s6_bookmark.pdf  S6 书签与超链接注释
```

---

### Step 3：构建并运行 Java 端，生成 java_s*.pdf

```bash
cd compare/openpdf

# 首次：下载依赖并打包（需要网络，约 30-60 秒）
mvn package

# 之后：直接运行
java -jar target/pdf-compare-1.0-SNAPSHOT-jar-with-dependencies.jar
```

生成文件（位于 `compare/output/`）：

```
java_s1_text.pdf
java_s2_table.pdf
java_s3_image.pdf
java_s4_drawing.pdf
java_s5_pagevent.pdf
java_s6_bookmark.pdf
```

> **注意**：Java 端读取图片的路径相对于 `compare/openpdf/` 目录，
> 实际解析为 `../../examples/images/`，需要确保从 `compare/openpdf/` 目录运行。

---

### Step 4：对比 PDF 内容

#### 4-A 字体嵌入对比（最常用）

```bash
# 对比 S1 文本文件的字体嵌入情况
pdffonts examples/output/cj_s1_text.pdf
pdffonts compare/output/java_s1_text.pdf
```

输出示例（关注 `emb` 列和字体名前缀）：

```
name                   type              emb sub uni
ABCDEF+NotoSansCJK...  CIDFontType2      yes yes yes  ← 子集嵌入，有 6 字符前缀
Helvetica              Type1             no  no  no   ← 内置字体，不嵌入
```

#### 4-B 文件元数据对比

```bash
pdfinfo examples/output/cj_s1_text.pdf
pdfinfo compare/output/java_s1_text.pdf
```

关注：`PDF version`、`Pages`、`Producer`、`Creator`

#### 4-C 结构层 diff（最深入）

```bash
NORM=/tmp/pdf_norm
mkdir -p $NORM

# 规范化（解压 stream，展开 xref，使 PDF 可读）
qpdf --qdf --object-streams=disable examples/output/cj_s1_text.pdf   $NORM/cj_s1.pdf
qpdf --qdf --object-streams=disable compare/output/java_s1_text.pdf  $NORM/java_s1.pdf

# 查看差异
diff $NORM/cj_s1.pdf $NORM/java_s1.pdf | head -80
```

#### 4-D 文件大小对比

```bash
# 对比所有 section 的文件大小
for s in s1_text s2_table s3_image s4_drawing s5_pagevent s6_bookmark; do
    cj_size=$(wc -c < examples/output/cj_${s}.pdf)
    java_size=$(wc -c < compare/output/java_${s}.pdf)
    printf "%-15s  cj: %8d B   java: %8d B\n" "$s" "$cj_size" "$java_size"
done
```

---

## 主要 API 差异对照表

| # | pdf-cj（Cangjie） | OpenPDF（Java） |
|---|-------------------|----------------|
| 1 | `Document(...)` | `new Document(...)` |
| 2 | `File(Path("f.pdf"), OpenMode.Write)` | `new FileOutputStream("f.pdf")` |
| 3 | `Alignment.Center`（枚举） | `Element.ALIGN_CENTER`（int 1） |
| 4 | `FontStyle.Bold`（枚举） | `Font.BOLD`（int 1） |
| 5 | `Color(r, g, b)` `pdf_cj.text` | `new Color(r,g,b)` `java.awt` |
| 6 | 所有尺寸/坐标用 `Float32` | 用 `float` / `int` |
| 7 | `Font(bf, 12.0, FontStyle.Bold)` | `new Font(bf, 12, Font.BOLD, color)`（支持内联颜色） |
| 8 | `Chunk` 仅有 `setColor`，无下划线/删除线 | `Chunk.setUnderline(thickness, yPos)` |
| 9 | 空行用 `Paragraph("")` | `Chunk.NEWLINE` |
| 10 | 必须定义命名类 `<: PdfPageEventHelper` | 匿名内部类 `new PdfPageEventHelper() { ... }` |
| 11 | 全部 unchecked exception | checked `DocumentException` |
| 12 | `img.setAlignment(Alignment.Center)` | `img.setAlignment(Image.MIDDLE)` |
| 13 | `Image` 无 `setSpacingBefore/After`，用 `Paragraph("")` 间隔 | `img.setSpacingBefore/After(float)` |
| 14 | `writer.addOutline(title, dest)` + `outline.addChild(...)` | `new PdfOutline(parent, dest, title)` |
| 15 | `table.setWidths([1.0, 2.0, 1.0])` | `table.setWidths(new float[]{1f, 2f, 1f})` |
| 16 | `setCMYKColorFill(Float32, ...)` 0.0~1.0 | OpenPDF 2.x 改为 `setCMYKColorFill(int, ...)` 0~255 |
| 17 | `Chunk` 无删除线方法 | OpenPDF 2.x 也移除了 `setStrikethrough` |
| 18 | 数组字面量推断 `Float64`，需显式 `Float32(x)` | Java int/float 隐式转换，无需显式 |
| 19 | TTC 字体直接传路径：`"font.ttc"` | OpenPDF 2.x 必须加索引：`"font.ttc,0"` |

---

## 常见问题

**Q: Java 运行时找不到图片**

```
Exception in thread "main" java.io.IOException: ... images/river.jpg
```

确保从 `compare/openpdf/` 目录运行，图片路径硬编码为 `../../examples/images/`：

```bash
cd compare/openpdf
java -jar target/pdf-compare-*-jar-with-dependencies.jar
```

**Q: Cangjie 运行时 `Cannot open font file`**

字体未安装：

```bash
sudo apt-get install fonts-noto-cjk
ls /usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc
```

**Q: Cangjie 运行时 `error while loading shared libraries: libhitls_crypto.so`**

HiTLS 库路径未设置：

```bash
export HITLS_LIB=~/.local/lib/hitls   # 或实际安装路径
cd examples && ./run_example.sh compare_main
```

**Q: Maven 构建失败 `Could not resolve artifact`**

网络问题，配置国内镜像：

```bash
# ~/.m2/settings.xml 中加入阿里云镜像
```

或手动指定：

```bash
mvn package -Dmaven.repo.local=/tmp/m2repo
```
