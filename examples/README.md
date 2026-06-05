# pdf-cj 仓颉语言示例

基于 pdf-cj 项目的 23 个功能模块示例（`src/S01`–`src/S23`），与 `openpdf-examples/`
下的 OpenPDF Java 示例一一对应。本目录是一个独立的 cjpm 可执行项目，通过
`pdf_cj = { path = ".." }` 依赖上层库。

## 运行方式

```bash
# 1. 首次：生成 cjpm.toml（自动检测 HiTLS 路径）并构建
cd examples
./build.sh
# 或指定 HiTLS 路径： HITLS_LIB=/your/path ./build.sh

# 2. 运行
cjpm run                       # 运行全部 23 个模块（默认）
cjpm run --run-args "all"      # 运行全部
cjpm run --run-args "7"        # 只运行 S07
cjpm run --run-args "07"       # 同上
```

> 若已有正确的 `cjpm.toml`（含 HiTLS 路径），也可直接 `cjpm build` / `cjpm run`，无需 `build.sh`。

输出目录：`examples/output/`　图片资源：`examples/images/`

### CJK 字体解析

示例需要一个中文字体文件。`src/SharedFonts.cj` 的 `resolveCjkFont()` 按以下优先级查找：

1. **环境变量 `PDFCJ_CJK_FONT`**（部署时显式指定）：
   ```bash
   PDFCJ_CJK_FONT=/path/to/NotoSansCJK-Regular.ttc cjpm run
   ```
2. **随仓库打包的字体** `examples/fonts/NotoSansCJK-Regular.ttc`（开箱即用，保证可移植）；
3. **常见系统路径**（Linux Noto/文泉驿、macOS PingFang、Windows 微软雅黑/宋体）。

全部找不到时会抛出明确错误并提示如何配置。

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
| `S24_FontRegistry.cj` | FontFactory.registerDirectories 按名加载 | `cj_s24_font_registry.pdf` |
| `S25_CJKCMap.cj` | 预置 CMap 命名 CJK 字体（不嵌入） | `cj_s25_cjk_cmap.pdf` |
| `main.cj` | 入口调度器（all / 编号） | 所有上述 PDF |
| `SharedFonts.cj` | 共享字体工厂（内部依赖） | — |

> 以上 `.cj` 源文件均位于 `src/` 目录下。

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

## 依赖

- **pdf-cj** 项目（本仓库上层目录），通过 `pdf_cj = { path = ".." }` 引用
- **CJK 字体**：`/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc`
- **OpenHiTLS**：`build.sh` 自动检测（`~/.local/lib/hitls` 等），或用 `HITLS_LIB` 指定
