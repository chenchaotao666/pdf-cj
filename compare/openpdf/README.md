# OpenPDF Java 对照示例

基于 OpenPDF 2.0.3，对应 `compare/COMPARE_LIST.md` 中的 23 个功能模块，每个模块都是独立可运行的 Java 类。

## 运行方式

```bash
cd compare/openpdf

# 构建 Fat JAR
mvn package -q

# 运行全部 23 个模块
java -cp target/pdf-compare-1.0-SNAPSHOT-jar-with-dependencies.jar RunAllSections

# 运行单个模块
java -cp target/pdf-compare-1.0-SNAPSHOT-jar-with-dependencies.jar S07_Table
```

输出目录：`compare/openpdf/output/`

---

## 文件列表

| 类名 | 对应模块 | 输出 PDF |
|------|---------|---------|
| `S01_DocumentPage` | 文档与页面控制 | `java_s01_document_page.pdf` |
| `S02_FontText` | 字体与文本 | `java_s02_font_text.pdf` |
| `S03_Chunk` | Chunk 文本块 | `java_s03_chunk.pdf` |
| `S04_Phrase` | Phrase 短语 | `java_s04_phrase.pdf` |
| `S05_Paragraph` | Paragraph 段落 | `java_s05_paragraph.pdf` |
| `S06_Anchor` | Anchor 超链接 | `java_s06_anchor.pdf` |
| `S07_Table` | PdfPTable / PdfPCell 表格 | `java_s07_table.pdf` |
| `S08_Image` | Image 图片 | `java_s08_image.pdf` |
| `S09_Drawing` | PdfContentByte 底层绘图 | `java_s09_drawing.pdf` |
| `S10_PageEvent` | PageEvent 页面事件 | `java_s10_pageevent.pdf` |
| `S11_Bookmark` | Bookmark / Outline 书签 | `java_s11_bookmark.pdf` |
| `S12_Annotation` | Annotation 注释 | `java_s12_annotation.pdf` |
| `S13_FormField` | AcroForm / FormField 表单 | `java_s13_formfield.pdf` |
| `S14_Transparency` | 透明度与混合模式 | `java_s14_transparency.pdf` |
| `S15_Shading` | Shading 渐变 | `java_s15_shading.pdf` |
| `S16_Barcode` | Barcode 条形码 | `java_s16_barcode.pdf` |
| `S17_ReaderStamper` | PdfReader / PdfStamper 读取修改 | `java_s17_reader_stamper.pdf`<br>`java_s17_form_filled.pdf` |
| `S18_PdfCopy` | PdfCopy PDF 合并复制 | `java_s18_copy_merged.pdf`<br>`java_s18_selected_pages.pdf`<br>`java_s18_smart_copy.pdf`<br>`java_s18_individual_pages.pdf` |
| `S19_TextExtract` | TextExtractor 文本提取 | `java_s19_text_extract.pdf` |
| `S20_Security` | Security 加密与权限 | `java_s20_encrypted_aes128.pdf`<br>`java_s20_encrypted_aes256.pdf`<br>`java_s20_encrypted_std128.pdf` |
| `S21_ColumnText` | ColumnText 多列排版 | `java_s21_column_text.pdf` |
| `S22_Chapter` | Chapter / Section 章节 | `java_s22_chapter.pdf` |
| `S23_Metadata` | 元数据与版本 | `java_s23_metadata.pdf` |
| `RunAllSections` | 批量运行全部 23 个模块 | 所有上述 PDF |

---

## OpenPDF 2.x 注意事项

| 问题 | 处理方式 |
|------|---------|
| `setCMYKColorFill/Stroke` 参数类型 | 2.x 改为 `int`（0–255），1.x 为 `float`（0.0–1.0） |
| `PdfTextExtractor` 不可用 | S19 改用 `reader.getPageContent()` 获取原始内容流 |
| `ENCRYPTION_AES_256` 不可用 | S20 自动回退到 AES-128 |
| `PdfCopy.addDocument()` 不存在 | S18 改用逐页 `getImportedPage()` + `addPage()` |
| TTC 字体路径 | 需加 `,0` 后缀指定字体槽位，如 `NotoSansCJK-Regular.ttc,0` |
| `Chunk.SPACETABBING` 不存在 | 用 `"\t"` 替代 |
| `PdfOutline.setStyle(bool,bool)` | 2.x 改为 `setStyle(int)`：0=正常，1=斜体，2=粗体，3=粗斜体 |
| 匿名内部类 | Java 支持匿名内部类实现 `PdfPageEventHelper`；Cangjie 必须定义命名类 |

---

## 依赖

```xml
<dependency>
    <groupId>com.github.librepdf</groupId>
    <artifactId>openpdf</artifactId>
    <version>2.0.3</version>
</dependency>
<!-- 加密功能需要 BouncyCastle -->
<dependency>
    <groupId>org.bouncycastle</groupId>
    <artifactId>bcprov-jdk18on</artifactId>
    <version>1.78.1</version>
</dependency>
```
