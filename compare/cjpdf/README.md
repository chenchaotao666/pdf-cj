# pdf-cj 仓颉语言对照示例

基于 pdf-cj 项目，对应 `compare/COMPARE_LIST.md` 中的 23 个功能模块，每个模块都是独立可运行的仓颉函数。

## 运行方式

```bash
# 首先在项目根目录构建 pdf-cj
cd /path/to/pdf-cj
cjpm build

# 进入 cjpdf 目录
cd compare/cjpdf

# 运行全部 23 个模块
./run.sh all

# 运行单个模块（示例：Section 7 表格）
./run.sh 7
./run.sh 07   # 同上
```

输出目录：`compare/cjpdf/output/`

---

## 文件列表

| 文件 | 对应模块 | 输出 PDF |
|------|---------|---------|
| `S01_DocumentPage.cj` | 文档与页面控制 | `cj_s01_document_page.pdf` |
| `S02_FontText.cj` | 字体与文本 | `cj_s02_font_text.pdf` |
| `S03_Chunk.cj` | Chunk 文本块 | `cj_s03_chunk.pdf` |
| `S04_Phrase.cj` | Phrase 短语 | `cj_s04_phrase.pdf` |
| `S05_Paragraph.cj` | Paragraph 段落 | `cj_s05_paragraph.pdf` |
| `S06_Anchor.cj` | Anchor 超链接 | `cj_s06_anchor.pdf` |
| `S07_Table.cj` | PdfPTable / PdfPCell 表格 | `cj_s07_table.pdf` |
| `S08_Image.cj` | Image 图片 | `cj_s08_image.pdf` |
| `S09_Drawing.cj` | PdfContentByte 底层绘图 | `cj_s09_drawing.pdf` |
| `S10_PageEvent.cj` | PageEvent 页面事件 | `cj_s10_pageevent.pdf` |
| `S11_Bookmark.cj` | Bookmark / Outline 书签 | `cj_s11_bookmark.pdf` |
| `S12_Annotation.cj` | Annotation 注释 | `cj_s12_annotation.pdf` |
| `S13_FormField.cj` | AcroForm / FormField 表单 | `cj_s13_formfield.pdf` |
| `S14_Transparency.cj` | 透明度与混合模式 | `cj_s14_transparency.pdf` |
| `S15_Shading.cj` | Shading 渐变 | `cj_s15_shading.pdf` |
| `S16_Barcode.cj` | Barcode 条形码 | `cj_s16_barcode.pdf` |
| `S17_ReaderStamper.cj` | PdfReader / PdfStamper 读取修改 | `cj_s17_reader_stamper.pdf`<br>`cj_s17_form_filled.pdf` |
| `S18_PdfCopy.cj` | PdfCopy PDF 合并复制 | `cj_s18_copy_merged.pdf`<br>`cj_s18_selected_pages.pdf`<br>`cj_s18_smart_copy.pdf` |
| `S19_TextExtract.cj` | TextExtractor 文本提取 | `cj_s19_text_extract.pdf` |
| `S20_Security.cj` | Security 加密与权限 | `cj_s20_encrypted_aes128.pdf`<br>`cj_s20_encrypted_aes256.pdf` |
| `S21_ColumnText.cj` | ColumnText 多列排版 | `cj_s21_column_text.pdf` |
| `S22_Chapter.cj` | Chapter / Section 章节 | `cj_s22_chapter.pdf` |
| `S23_Metadata.cj` | 元数据与版本 | `cj_s23_metadata.pdf` |
| `RunAllSections.cj` | 批量运行全部 23 个模块 | 所有上述 PDF |
| `SharedFonts.cj` | 共享字体工厂（内部依赖） | — |

---

## pdf-cj vs OpenPDF API 差异速查

| Java (OpenPDF) | 仓颉 (pdf-cj) | 说明 |
|----------------|--------------|------|
| `doc.getPageSize()` | `doc.pageSize` | 仓颉用属性语法，无括号 |
| `doc.leftMargin()` | `doc.leftMargin` | 同上，所有 margin getter |
| `new Font(bf, size, Font.BOLD)` | `Font(bf, size, FontStyle.Bold)` | 枚举值不同 |
| `new Color(r, g, b)` | `Color(r, g, b)` 或 `Color.RED` | 同名，用法相同 |
| `setCMYKColorFill(c,m,y,k)` (float 0.0–1.0) | `setCMYKColorFill(c,m,y,k)` (Float32 0.0–1.0) | OpenPDF 2.x 改为 int；pdf-cj 保持 float |
| `implements PdfPageEventHelper` (匿名类) | 命名类 `extends PdfPageEventHelper` | 仓颉不支持匿名内部类 |
| `Chunk.setStrikethrough(true)` | `chunk.setStrikethrough(true)` | pdf-cj 支持 |
| `BarcodeQRCode` | `BarcodeQRCode` | pdf-cj 支持二维码 |
| `writer.setEncryption(AES_256, ...)` | `writer.setEncryption(...)` | pdf-cj 支持 AES-256 |
| `PdfTextExtractor.getTextFromPage(...)` | `PdfReader.getTextFromPage(...)` | pdf-cj 内置文本提取 |

---

## 编译注意事项

| 问题 | 处理方式 |
|------|---------|
| 多文件同包时模块级 `let` 命名冲突 | 使用 `_sXX_` 前缀，或将变量声明在函数体内 |
| 23 个 CJK 字体同时加载 OOM | `SharedFonts.cj` 提供惰性工厂函数 `newCjkBf()` / `newHelvBf()`，在函数体内按需创建 |
| 静态库循环依赖 | `run.sh` 使用 `--start-group ... --end-group` 链接选项 |
| TTC 字体路径 | 无需 `,0` 后缀（pdf-cj 自动处理） |
| 属性访问 | 所有 getter 使用属性语法（无括号），如 `doc.pageSize`、`cell.border` |

---

## 依赖

- **pdf-cj** 项目（本仓库），需先执行 `cjpm build`
- **CJK 字体**：`/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc`
- **运行时库**：`libzlib4cj.so`、`libhitls_crypto`、`libhitls_bsl`、`libboundscheck`（随 pdf-cj 构建产物提供）
