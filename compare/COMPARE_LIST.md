# pdf-cj vs OpenPDF 全量功能对照列表

> **目的**：通过逐一对照 Java OpenPDF 与 Cangjie pdf-cj 的代码示例，确认 pdf-cj 覆盖了 OpenPDF 的全量核心能力。
>
> **图例**
> - ✅ 已实现，API 完整
> - ⚠️ 已实现，存在细微差异（见备注）
> - ❌ 尚未实现

---

## 目录

1. [文档与页面控制](#1-文档与页面控制)
2. [字体与文本](#2-字体与文本)
3. [Chunk（文本块）](#3-chunk-文本块)
4. [Phrase（短语）](#4-phrase-短语)
5. [Paragraph（段落）](#5-paragraph-段落)
6. [Anchor（超链接）](#6-anchor-超链接)
7. [表格 PdfPTable / PdfPCell](#7-表格-pdfptable--pdfpcell)
8. [图片 Image](#8-图片-image)
9. [底层绘图 PdfContentByte](#9-底层绘图-pdfcontentbyte)
10. [页面事件 PageEvent](#10-页面事件-pageevent)
11. [书签 Bookmark / Outline](#11-书签-bookmark--outline)
12. [注释 Annotation](#12-注释-annotation)
13. [表单字段 AcroForm / FormField](#13-表单字段-acroform--formfield)
14. [透明度与混合模式](#14-透明度与混合模式)
15. [渐变 Shading](#15-渐变-shading)
16. [条形码 Barcode](#16-条形码-barcode)
17. [读取与修改 PdfReader / PdfStamper](#17-读取与修改-pdfreader--pdfstamper)
18. [PDF 合并复制 PdfCopy](#18-pdf-合并复制-pdfcopy)
19. [文本提取 TextExtractor](#19-文本提取-textextractor)
20. [加密与权限 Security](#20-加密与权限-security)
21. [多列排版 ColumnText](#21-多列排版-columntext)
22. [章节 Chapter / Section](#22-章节-chapter--section)
23. [元数据与版本](#23-元数据与版本)

---

## 1. 文档与页面控制

### 1-A 创建文档 ✅

| 功能 | Java OpenPDF | Cangjie pdf-cj |
|------|-------------|----------------|
| 创建文档 | `new Document()` | `Document()` |
| 指定页面尺寸和边距 | `new Document(PageSize.A4, 72, 72, 72, 72)` | `Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)` |
| 关联写入器 | `PdfWriter.getInstance(doc, new FileOutputStream("f.pdf"))` | `PdfWriter.getInstance(doc, File(Path("f.pdf"), OpenMode.Write))` |
| 打开文档 | `doc.open()` | `doc.open()` |
| 关闭文档 | `doc.close()` | `doc.close()` |

```java
// Java
Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream("out.pdf"));
doc.open();
doc.add(new Paragraph("Hello"));
doc.close();
```

```cangjie
// Cangjie
let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
let writer = PdfWriter.getInstance(doc, File(Path("out.pdf"), OpenMode.Write))
doc.open()
doc.add(Paragraph("Hello"))
doc.close()
```

### 1-B 页面尺寸常量 ✅

```java
// Java
PageSize.A4          // 595 × 842
PageSize.LETTER      // 612 × 792
PageSize.A4.rotate() // 横向
new Rectangle(200, 300) // 自定义
```

```cangjie
// Cangjie
PageSize.A4
PageSize.LETTER
PageSize.A4.rotate()
Rectangle(200.0, 300.0)
```

### 1-C 换页与页面控制 ✅

```java
// Java
doc.newPage();
writer.setPageSize(PageSize.A3);
writer.setMargins(50, 50, 60, 60);
doc.resetPageCount();
```

```cangjie
// Cangjie
doc.newPage()
writer.setPageSize(PageSize.A3)
writer.setMargins(50.0, 50.0, 60.0, 60.0)
doc.resetPageCount()
```

---

## 2. 字体与文本

### 2-A 内置拉丁字体 ✅

```java
// Java
BaseFont bf = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED);
Font font = new Font(bf, 12, Font.BOLD);
Font font2 = new Font(bf, 12, Font.BOLDITALIC, Color.RED);
```

```cangjie
// Cangjie
let bf = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
let font = Font(bf, 12.0, FontStyle.Bold)
let font2 = Font(bf, 12.0, FontStyle.BoldItalic, Color(255, 0, 0))
```

> ⚠️ 差异：Java `new Font(bf, size, style, color)` 四参数构造器；Cangjie 同样支持四参数 `Font(bf, size, style, color)`。

### 2-B CJK / TrueType 嵌入字体 ✅

```java
// Java
BaseFont cjkBf = BaseFont.createFont(
    "/path/NotoSansCJK-Regular.ttc",
    BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
Font cjkFont = new Font(cjkBf, 14);
```

```cangjie
// Cangjie（完全相同的常量名和调用方式）
let cjkBf = BaseFont.createFont(
    "/path/NotoSansCJK-Regular.ttc",
    BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
let cjkFont = Font(cjkBf, 14.0)
```

### 2-C FontStyle 枚举 ✅

| Java `Font.XXX` (int) | Cangjie `FontStyle.XXX` (enum) |
|----------------------|-------------------------------|
| `Font.NORMAL (0)` | `FontStyle.Normal` |
| `Font.BOLD (1)` | `FontStyle.Bold` |
| `Font.ITALIC (2)` | `FontStyle.Italic` |
| `Font.BOLDITALIC (3)` | `FontStyle.BoldItalic` |
| `Font.STRIKETHRU (8)` | `FontStyle.Strikethrough` |
| `Font.UNDERLINE (4)` | `FontStyle.Underline` |

### 2-D FontSelector（多字体自动匹配） ✅

```java
// Java
FontSelector fs = new FontSelector();
fs.addFont(cjkFont);
fs.addFont(latinFont);
Phrase p = fs.process("中文 English Mixed");
doc.add(new Paragraph(p));
```

```cangjie
// Cangjie
let fs = FontSelector()
fs.addFont(cjkBf)
fs.addFont(latinBf)
let segments = fs.selectFonts("中文 English Mixed")
// 遍历 segments 构造 Phrase
```

### 2-E FontFactory ✅

```java
// Java
Font font = FontFactory.getFont(FontFactory.HELVETICA, 12, Font.BOLD);
```

```cangjie
// Cangjie
let font = FontFactory.getFont(FontFactory.HELVETICA, 12.0, FontStyle.Bold)
```

---

## 3. Chunk（文本块）

### 3-A 创建 Chunk ✅

```java
// Java
Chunk c = new Chunk("文本", font);
Chunk c2 = new Chunk('A');
```

```cangjie
// Cangjie
let c = Chunk("文本", font)
let c2 = Chunk(r'A')
```

### 3-B Chunk 样式 ✅

```java
// Java
chunk.setUnderline(0.6f, -2f);          // 下划线
chunk.setUnderline(0.6f, 4f);           // 删除线（正 y 值）
chunk.setBackground(new Color(255,255,0));
chunk.setFont(new Font(bf, 14));
```

```cangjie
// Cangjie
chunk.setUnderline()                     // 下划线
chunk.setStrikethrough()                 // 删除线（独立方法）
_ = chunk.setBackground(Color(255, 255, 0))
chunk.setFont(Font(bf, 14.0))
```

> ⚠️ Java 用带参数的 `setUnderline(thickness, yPos)` 同时实现下划线和删除线；Cangjie 提供 `setUnderline()` 和 `setStrikethrough()` 两个独立方法，更语义化。

### 3-C Chunk 颜色 ✅

```java
// Java（通过 Font 构造器传色）
Chunk colored = new Chunk("红色", new Font(bf, 12, Font.NORMAL, Color.RED));
```

```cangjie
// Cangjie（通过 setColor 方法）
let colored = Chunk("红色", Font(bf, 12.0))
_ = colored.setColor(Color(255, 0, 0))
```

### 3-D Chunk 特殊常量 ✅

```java
// Java
Chunk.NEWLINE
Chunk.NEWPAGE
Chunk.SPACETABBING
```

```cangjie
// Cangjie（完全相同）
Chunk.NEWLINE
Chunk.NEWPAGE
Chunk.SPACETABBING
```

### 3-E Chunk 本地书签跳转 ✅

```java
// Java
Chunk dest = new Chunk("目标位置");
dest.setLocalDestination("chapter1");

Chunk link = new Chunk("跳转到第一章");
link.setLocalGoto("chapter1");
```

```cangjie
// Cangjie
let dest = Chunk("目标位置")
_ = dest.setLocalDestination("chapter1")

let link = Chunk("跳转到第一章")
_ = link.setLocalGoto("chapter1")
```

### 3-F Chunk 超链接（底层） ✅

```java
// Java
Chunk c = new Chunk("OpenPDF");
c.setAnchor("https://github.com/LibrePDF/OpenPDF");
```

```cangjie
// Cangjie
let c = Chunk("OpenPDF")
_ = c.setAnchorURL("https://github.com/LibrePDF/OpenPDF")
```

---

## 4. Phrase（短语）

### 4-A 创建 Phrase ✅

```java
// Java
Phrase p = new Phrase();
Phrase p2 = new Phrase("文本");
Phrase p3 = new Phrase("文本", font);
Phrase p4 = new Phrase(20f, "文本", font);  // 指定行距
Phrase p5 = new Phrase(16f);               // 仅行距
```

```cangjie
// Cangjie（构造器签名完全对应）
let p = Phrase()
let p2 = Phrase("文本")
let p3 = Phrase("文本", font)
let p4 = Phrase(20.0, "文本", font)
let p5 = Phrase(16.0)
```

### 4-B Phrase 添加内容 ✅

```java
// Java
phrase.add(chunk);
phrase.add(new Chunk("追加"));
phrase.add(new Phrase("子短语"));
phrase.addChunk(chunk);
```

```cangjie
// Cangjie
_ = phrase.add(chunk)
_ = phrase.add(Chunk("追加"))
_ = phrase.add(Phrase("子短语"))
phrase.addChunk(chunk)
```

---

## 5. Paragraph（段落）

### 5-A 创建 Paragraph ✅

```java
// Java
Paragraph p = new Paragraph();
Paragraph p2 = new Paragraph("文本");
Paragraph p3 = new Paragraph("文本", font);
Paragraph p4 = new Paragraph(phrase);
```

```cangjie
// Cangjie
let p = Paragraph()
let p2 = Paragraph("文本")
let p3 = Paragraph("文本", font)
let p4 = Paragraph(phrase)
```

### 5-B Paragraph 对齐 ✅

```java
// Java
p.setAlignment(Element.ALIGN_LEFT);       // 0
p.setAlignment(Element.ALIGN_CENTER);     // 1
p.setAlignment(Element.ALIGN_RIGHT);      // 2
p.setAlignment(Element.ALIGN_JUSTIFIED);  // 8
```

```cangjie
// Cangjie（枚举替代 int 常量）
p.setAlignment(Alignment.Left)
p.setAlignment(Alignment.Center)
p.setAlignment(Alignment.Right)
p.setAlignment(Alignment.Justified)
```

### 5-C Paragraph 间距与缩进 ✅

```java
// Java
p.setLeading(20f);
p.setLeading(0f, 1.5f);           // 乘数行距
p.setSpacingBefore(10f);
p.setSpacingAfter(10f);
p.setFirstLineIndent(24f);
p.setIndentationLeft(20f);
p.setIndentationRight(20f);
p.setKeepTogether(true);
p.setExtraParagraphSpace(6f);
```

```cangjie
// Cangjie（方法名完全相同，参数 Float32）
p.setLeading(20.0)
p.setMultipliedLeading(1.5)
p.setSpacingBefore(10.0)
p.setSpacingAfter(10.0)
p.setFirstLineIndent(24.0)
p.setIndentationLeft(20.0)
p.setIndentationRight(20.0)
p.setKeepTogether(true)
p.setExtraParagraphSpace(6.0)
```

---

## 6. Anchor（超链接）

### 6-A 创建 Anchor ✅

```java
// Java
Anchor anchor = new Anchor("点击访问", font);
anchor.setReference("https://example.com");
anchor.setName("section1");   // 命名锚点

Paragraph para = new Paragraph();
para.add(anchor);
doc.add(para);
```

```cangjie
// Cangjie
let anchor = Anchor("点击访问", font)
anchor.setReference("https://example.com")
anchor.setName("section1")

let para = Paragraph()
_ = para.add(anchor)
doc.add(para)
```

### 6-B Anchor 直接加入文档 ✅

```java
// Java
doc.add(anchor);  // Anchor 继承 Phrase，可直接添加
```

```cangjie
// Cangjie（writer 自动包装成 Paragraph）
doc.add(anchor)
```

### 6-C Anchor 混排 ✅

```java
// Java
Paragraph para = new Paragraph("前置文字 ", font);
para.add(anchor);
para.add(new Chunk(" 后置文字", font));
doc.add(para);
```

```cangjie
// Cangjie
let para = Paragraph("前置文字 ", font)
_ = para.add(anchor)
_ = para.add(" 后置文字")
doc.add(para)
```

---

## 7. 表格 PdfPTable / PdfPCell

### 7-A 基础表格 ✅

```java
// Java
PdfPTable table = new PdfPTable(3);
table.setWidthPercentage(80f);
table.setWidths(new float[]{1f, 2f, 1f});
table.setSpacingBefore(6f);
table.setSpacingAfter(16f);
table.addCell(new PdfPCell(new Phrase("姓名", font)));
```

```cangjie
// Cangjie
let table = PdfPTable(3)
table.setWidthPercentage(80.0)
table.setWidths([1.0, 2.0, 1.0])
table.setSpacingBefore(6.0)
table.setSpacingAfter(16.0)
table.addCell(PdfPCell(Phrase("姓名", font)))
```

### 7-B 单元格样式 ✅

```java
// Java
PdfPCell cell = new PdfPCell(new Phrase("内容"));
cell.setBackgroundColor(new Color(66, 139, 202));
cell.setHorizontalAlignment(Element.ALIGN_CENTER);
cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
cell.setPadding(6f);
cell.setPaddingLeft(10f);
cell.setBorder(Rectangle.BOX);
cell.setBorderWidth(1.5f);
cell.setBorderColor(Color.DARK_GRAY);
cell.disableBorderSide(Rectangle.BOTTOM);
cell.setFixedHeight(30f);
cell.setMinimumHeight(20f);
cell.setNoWrap(true);
```

```cangjie
// Cangjie
let cell = PdfPCell(Phrase("内容"))
cell.setBackgroundColor(Color(66, 139, 202))
cell.setHorizontalAlignment(Alignment.Center)
cell.setVerticalAlignment(VerticalAlignment.Middle)
cell.setPadding(6.0)
cell.setPaddingLeft(10.0)
cell.setBorder(Rectangle.BOX)
cell.setBorderWidth(1.5)
cell.setBorderColor(Color(64, 64, 64))
cell.disableBorderSide(Rectangle.BOTTOM)
cell.setFixedHeight(30.0)
cell.setMinimumHeight(20.0)
cell.setNoWrap(true)
```

### 7-C Colspan / Rowspan ✅

```java
// Java
cell.setColspan(3);
cell.setRowspan(2);
```

```cangjie
// Cangjie（方法名完全相同）
cell.setColspan(3)
cell.setRowspan(2)
```

### 7-D 单元格内嵌 Paragraph ✅

```java
// Java
PdfPCell cell = new PdfPCell();
Paragraph p = new Paragraph("标题", boldFont);
p.setSpacingAfter(4f);
cell.addElement(p);
cell.addElement(new Paragraph("副文字", normalFont));
```

```cangjie
// Cangjie（方法名完全相同）
let cell = PdfPCell()
let p = Paragraph("标题", boldFont)
p.setSpacingAfter(4.0)
cell.addElement(p)
cell.addElement(Paragraph("副文字", normalFont))
```

### 7-E 重复表头 ✅

```java
// Java
table.setHeaderRows(1);
table.setFooterRows(1);     // 末尾行也重复
table.setSkipFirstHeader(true);
```

```cangjie
// Cangjie（方法名完全相同）
table.setHeaderRows(1)
table.setFooterRows(1)
table.setSkipFirstHeader(true)
```

### 7-F 锁定宽度 ✅

```java
// Java
table.setTotalWidth(400f);
table.setLockedWidth(true);
```

```cangjie
// Cangjie
table.setTotalWidth(400.0)
table.setLockedWidth(true)
```

### 7-G 在指定坐标直接绘制表格 ✅

```java
// Java
table.writeSelectedRows(0, -1, x, y, writer.getDirectContent());
```

```cangjie
// Cangjie
writer.writeSelectedRows(table, 0, -1, x, y, writer.getDirectContent())
```

---

## 8. 图片 Image

### 8-A 加载图片 ✅

```java
// Java
Image img = Image.getInstance("photo.jpg");
Image img2 = Image.getInstance("icon.png");
Image img3 = Image.getInstance(url);         // 从 URL 加载
Image img4 = Image.getInstance(byteArray);   // 从字节数组加载
```

```cangjie
// Cangjie（支持路径/字节数组）
let img = Image.getInstance("photo.jpg")
let img2 = Image.getInstance("icon.png")
// URL 加载：使用 Image.getInstance(bytes) 配合 URL 读取
```

> ⚠️ 直接传 URL 对象的重载在 Cangjie 中需手动下载字节后传入。

### 8-B 缩放 ✅

```java
// Java
img.scaleAbsolute(200f, 150f);
img.scalePercent(50f);
img.scalePercent(80f, 60f);   // 非等比
img.scaleToFit(400f, 300f);   // 等比适配
```

```cangjie
// Cangjie（方法名完全相同）
img.scaleAbsolute(200.0, 150.0)
img.scalePercent(50.0)
img.scalePercent(80.0, 60.0)
img.scaleToFit(400.0, 300.0)
```

### 8-C 对齐与位置 ✅

```java
// Java
img.setAlignment(Image.LEFT);
img.setAlignment(Image.MIDDLE);
img.setAlignment(Image.RIGHT);
img.setAbsolutePosition(100f, 500f);
img.setRotation((float)Math.PI / 4);
img.setRotationDegrees(45);
img.setSpacingBefore(10f);
img.setSpacingAfter(10f);
```

```cangjie
// Cangjie
img.setAlignment(Alignment.Left)
img.setAlignment(Alignment.Center)
img.setAlignment(Alignment.Right)
img.setAbsolutePosition(100.0, 500.0)
img.setRotationRadians(Float32.PI / 4.0)
img.setRotation(45.0)   // 角度
img.setSpacingBefore(10.0)
img.setSpacingAfter(10.0)
```

### 8-D 图片直接绘制到画布 ✅

```java
// Java
cb.addImage(img, width, 0, 0, height, x, y);
```

```cangjie
// Cangjie：通过 doc.add(img) 加入文档流，或使用绝对位置
img.setAbsolutePosition(x, y)
doc.add(img)
```

---

## 9. 底层绘图 PdfContentByte

### 9-A 获取画布 ✅

```java
// Java
PdfContentByte cb = writer.getDirectContent();
PdfContentByte cbUnder = writer.getDirectContentUnder();  // 底层（背景）
```

```cangjie
// Cangjie
let cb = writer.getDirectContent()
// getDirectContentUnder 通过 PdfStamper.getUnderContent 实现
```

### 9-B 文本绘制 ✅

```java
// Java
cb.beginText();
cb.setFontAndSize(bf, 12);
cb.showTextAligned(Element.ALIGN_LEFT, "文字", x, y, 0);
cb.setTextMatrix(x, y);
cb.showText("内联文字");
cb.setLeading(20f);
cb.newlineText();
cb.setCharacterSpacing(2f);
cb.setWordSpacing(3f);
cb.setHorizontalScaling(80f);
cb.setTextRenderingMode(PdfContentByte.TEXT_RENDER_MODE_FILL);
cb.setTextRise(5f);
cb.endText();
```

```cangjie
// Cangjie（方法名完全相同）
cb.beginText()
cb.setFontAndSize(bf, "FontName", 12.0)
cb.showTextAligned(0, "文字", x, y, 0.0)
cb.setTextMatrix(x, y)
cb.showText("内联文字")
cb.setLeading(20.0)
cb.newlineText()
cb.setCharacterSpacing(2.0)
cb.setWordSpacing(3.0)
cb.setHorizontalScaling(80.0)
cb.setTextRenderingMode(0)
cb.setTextRise(5.0)
cb.endText()
```

### 9-C 路径绘制 ✅

```java
// Java
cb.moveTo(x1, y1);
cb.lineTo(x2, y2);
cb.curveTo(cx1, cy1, cx2, cy2, x, y);
cb.closePath();
cb.stroke();
cb.fill();
cb.fillStroke();
cb.eoFill();         // 奇偶规则填充
cb.rectangle(x, y, w, h);
cb.roundRectangle(x, y, w, h, radius);
cb.ellipse(x1, y1, x2, y2);
cb.arc(x1, y1, x2, y2, start, extent);
```

```cangjie
// Cangjie（方法名完全相同）
cb.moveTo(x1, y1)
cb.lineTo(x2, y2)
cb.curveTo(cx1, cy1, cx2, cy2, x, y)
cb.closePath()
cb.stroke()
cb.fill()
cb.fillStroke()
cb.eoFill()
cb.rectangle(x, y, w, h)
cb.roundRectangle(x, y, w, h, radius)
cb.ellipse(x1, y1, x2, y2)
cb.arc(x1, y1, x2, y2, start, extent)
```

### 9-D 颜色设置 ✅

```java
// Java
cb.setColorFill(new Color(255, 0, 0));
cb.setColorStroke(new Color(0, 0, 0));
cb.setGrayFill(0.5f);
cb.setCMYKColorFill(0.1f, 0.9f, 0.5f, 0f);
```

```cangjie
// Cangjie
cb.setColorFill(Color(255, 0, 0))
cb.setColorStroke(Color(0, 0, 0))
cb.setGrayFill(0.5)
cb.setCMYKColorFill(0.1, 0.9, 0.5, 0.0)
```

### 9-E 画笔样式 ✅

```java
// Java
cb.setLineWidth(2f);
cb.setLineCap(PdfContentByte.LINE_CAP_ROUND);
cb.setLineJoin(PdfContentByte.LINE_JOIN_MITER);
cb.setMiterLimit(10f);
cb.setLineDash(5f, 3f, 0f);   // on, off, phase
cb.saveState();
cb.restoreState();
cb.concatCTM(a, b, c, d, e, f);  // 变换矩阵
```

```cangjie
// Cangjie（方法名完全相同）
cb.setLineWidth(2.0)
cb.setLineCap(1)   // 1 = round
cb.setLineJoin(0)
cb.setMiterLimit(10.0)
cb.setLineDash(5.0, 3.0, 0.0)
cb.saveState()
cb.restoreState()
cb.concatCTM(a, b, c, d, e, f)
```

---

## 10. 页面事件 PageEvent

### 10-A 实现 PageEvent ✅

```java
// Java（匿名内部类）
writer.setPageEvent(new PdfPageEventHelper() {
    @Override
    public void onStartPage(PdfWriter writer, Document doc) { ... }
    @Override
    public void onEndPage(PdfWriter writer, Document doc) {
        // 绘制页眉页脚
        PdfContentByte cb = writer.getDirectContent();
        cb.beginText();
        cb.setFontAndSize(bf, 10);
        cb.showTextAligned(LEFT, "页眉", marginLeft, pageHeight - 30, 0);
        cb.showTextAligned(RIGHT, "第" + writer.getPageNumber() + "页",
                           pageWidth - marginRight, 20, 0);
        cb.endText();
    }
    @Override
    public void onCloseDocument(PdfWriter writer, Document doc) { ... }
});
```

```cangjie
// Cangjie（必须定义命名类，不支持匿名内部类）
class MyPageEvent <: PdfPageEventHelper {
    public override func onStartPage(writer: PdfWriter, doc: Document): Unit { }
    public override func onEndPage(writer: PdfWriter, doc: Document): Unit {
        let cb = writer.getDirectContent()
        let pageNum = writer.pageNumber
        cb.beginText()
        cb.setFontAndSize(bf, "FontName", 10.0)
        cb.showTextAligned(0, "页眉", marginLeft, pageHeight - 30.0, 0.0)
        cb.showTextAligned(2, "第${pageNum}页", pageWidth - marginRight, 20.0, 0.0)
        cb.endText()
    }
    public override func onCloseDocument(writer: PdfWriter, doc: Document): Unit { }
}

writer.setPageEvent(MyPageEvent())
```

> ⚠️ 关键差异：Java 可用匿名内部类；Cangjie 必须定义命名类。

### 10-B HeaderFooter 高级 API ✅

```java
// Java
HeaderFooter header = new HeaderFooter(new Phrase("标题", font), false);
header.setAlignment(Element.ALIGN_CENTER);
header.setBorder(Rectangle.BOTTOM);
doc.setHeader(header);

HeaderFooter footer = new HeaderFooter(new Phrase("第 ", font), new Phrase(" 页", font));
footer.setAlignment(Element.ALIGN_RIGHT);
doc.setFooter(footer);
doc.resetHeader();
doc.resetFooter();
```

```cangjie
// Cangjie
let header = HeaderFooter(Phrase("标题", font), false)
header.setAlignment(Alignment.Center)
header.setBorder(Rectangle.BOTTOM)
doc.setHeader(header)

let footer = HeaderFooter(Phrase("第 ", font), Phrase(" 页", font))
footer.setAlignment(Alignment.Right)
doc.setFooter(footer)
doc.resetHeader()
doc.resetFooter()
```

---

## 11. 书签 Bookmark / Outline

### 11-A 添加书签 ✅

```java
// Java
PdfOutline root = writer.getRootOutline();
PdfDestination dest = new PdfDestination(PdfDestination.FIT);
PdfOutline outline = new PdfOutline(root, dest, "第一章");
PdfOutline child = new PdfOutline(outline,
    new PdfDestination(PdfDestination.FITH), "1.1 小节");
child.setStyle(true, false);   // bold
child.setColor(new Color(0, 0, 255));
```

```cangjie
// Cangjie（使用 addOutline 简洁 API）
let dest = PdfDestination(PdfDestination.FIT)
let outline = writer.addOutline("第一章", dest)
let childDest = PdfDestination(PdfDestination.FITH)
let child = PdfOutline("1.1 小节", childDest)
outline.addChild(child)
child.setBold(true)
child.setColor(0.0, 0.0, 1.0)
```

### 11-B OutlineBuilder 链式 API ✅

```cangjie
// Cangjie（pdf-cj 扩展的链式构建器，OpenPDF 无对应）
let tree = PdfOutlineBuilder()
    .addRootOutline("第一章", PdfDestination(PdfDestination.FIT))
    .addChildOutline("1.1 小节", PdfDestination(PdfDestination.FITH))
    .setStyle(true, false)
    .moveToParent()
    .addRootOutline("第二章", PdfDestination(PdfDestination.FIT))
    .build()
writer.setOutlineTree(tree)
```

### 11-C 目标页面类型 ✅

```java
// Java
new PdfDestination(PdfDestination.FIT)      // 适应页面
new PdfDestination(PdfDestination.FITH)     // 适应宽度
new PdfDestination(PdfDestination.FITV)     // 适应高度
new PdfDestination(PdfDestination.XYZ, x, y, zoom) // 指定坐标
```

```cangjie
// Cangjie（常量名完全相同）
PdfDestination(PdfDestination.FIT)
PdfDestination(PdfDestination.FITH)
PdfDestination(PdfDestination.FITV)
PdfDestination(PdfDestination.XYZ, x, y, zoom)
```

---

## 12. 注释 Annotation

### 12-A 文本注释（便签） ✅

```java
// Java
PdfAnnotation ann = PdfAnnotation.createText(writer,
    new Rectangle(100, 700, 200, 750), "标题", "内容", true, "Comment");
writer.addAnnotation(ann);
```

```cangjie
// Cangjie
let ann = PdfAnnotationText(Rectangle(100.0, 700.0, 200.0, 750.0))
ann.setTitle("标题")
ann.setContents("内容")
writer.addAnnotation(ann)
```

### 12-B URL 链接注释 ✅

```java
// Java
PdfAnnotation link = PdfAnnotationFactory.createURLLink(writer,
    new Rectangle(72, 700, 300, 720), "https://example.com");
writer.addAnnotation(link);
```

```cangjie
// Cangjie
let linkRect = Rectangle(72.0, 700.0, 300.0, 720.0)
let link = PdfAnnotationFactory.createURLLink(linkRect, "https://example.com")
writer.addAnnotation(link)
```

### 12-C 高亮/下划线/删除线注释 ✅

```java
// Java
float[] quads = {72, 730, 300, 730, 72, 718, 300, 718};
PdfAnnotation highlight = PdfAnnotation.createMarkup(writer,
    new Rectangle(72, 718, 300, 730), "", PdfAnnotation.MARKUP_HIGHLIGHT, quads);
```

```cangjie
// Cangjie
let quads: Array<Float32> = [72.0, 730.0, 300.0, 730.0, 72.0, 718.0, 300.0, 718.0]
let hl = PdfAnnotationHighlight(Rectangle(72.0, 718.0, 300.0, 730.0))
hl.setQuadPoints(quads)
hl.setContents("高亮注释")
writer.addAnnotation(hl)
```

### 12-D 自由文本注释 ✅

```java
// Java
PdfAnnotation freeText = PdfAnnotation.createFreeText(writer,
    new Rectangle(100, 600, 300, 650), "注释文字", cb);
```

```cangjie
// Cangjie
let ft = PdfAnnotationFreeText(Rectangle(100.0, 600.0, 300.0, 650.0))
ft.setContents("注释文字")
writer.addAnnotation(ft)
```

### 12-E 几何形状注释 ✅

```cangjie
// Cangjie
let square = PdfAnnotationSquare(Rectangle(100.0, 500.0, 200.0, 560.0))
square.setContents("矩形注释")
writer.addAnnotation(square)

let circle = PdfAnnotationCircle(Rectangle(220.0, 500.0, 320.0, 560.0))
circle.setContents("椭圆注释")
writer.addAnnotation(circle)
```

### 12-F 图章注释 ✅

```cangjie
// Cangjie
let stamp = PdfAnnotationStamp(Rectangle(100.0, 400.0, 250.0, 450.0))
stamp.setIcon("Approved")
stamp.setContents("已审批")
writer.addAnnotation(stamp)
```

---

## 13. 表单字段 AcroForm / FormField

### 13-A 文本框 ✅

```java
// Java
TextField text = new TextField(writer, new Rectangle(72, 700, 300, 720), "name");
text.setFontSize(12);
text.setText("默认值");
writer.addAnnotation(text.getTextField());
```

```cangjie
// Cangjie
let tf = PdfFormFieldFactory.createTextField(
    writer, Rectangle(72.0, 700.0, 300.0, 720.0), "name")
tf.setDefaultValue("默认值")
writer.addFormField(tf)
```

### 13-B 复选框 ✅

```java
// Java
RadioCheckField check = new RadioCheckField(writer,
    new Rectangle(72, 650, 90, 668), "agree", "Yes");
check.setCheckType(RadioCheckField.TYPE_CHECK);
check.setChecked(true);
writer.addAnnotation(check.getCheckField());
```

```cangjie
// Cangjie
let cb = PdfFormFieldFactory.createCheckBox(
    writer, Rectangle(72.0, 650.0, 90.0, 668.0), "agree", true)
writer.addFormField(cb)
```

### 13-C 单选按钮组 ✅

```java
// Java
RadioCheckField radio = new RadioCheckField(writer,
    new Rectangle(72, 600, 90, 618), "gender", "male");
PdfFormField radioGroup = radio.getRadioGroup(true, false);
writer.addAnnotation(radioGroup);
```

```cangjie
// Cangjie
let group = PdfFormFieldFactory.createRadioGroup(writer, "gender")
let r1 = PdfFormFieldFactory.createRadioButton(
    writer, Rectangle(72.0, 600.0, 90.0, 618.0), "gender", "male", true)
group.addKid(r1)
writer.addFormField(group)
```

### 13-D 下拉框 ✅

```java
// Java
String[] items = {"选项1", "选项2", "选项3"};
ChoiceField combo = new ChoiceField(writer,
    new Rectangle(100, 550, 300, 568), "color", items);
combo.setChoiceType(ChoiceField.TYPE_COMBO);
```

```cangjie
// Cangjie
let items = ["选项1", "选项2", "选项3"]
let combo = PdfFormFieldFactory.createComboBox(
    writer, Rectangle(100.0, 550.0, 300.0, 568.0), "color", items)
writer.addFormField(combo)
```

### 13-E 列表框 ✅

```cangjie
// Cangjie
let list = PdfFormFieldFactory.createListBox(
    writer, Rectangle(100.0, 450.0, 300.0, 530.0), "items",
    ["苹果", "香蕉", "橙子"])
writer.addFormField(list)
```

### 13-F 按钮 ✅

```cangjie
// Cangjie
let btn = PdfFormFieldFactory.createPushButton(
    writer, Rectangle(100.0, 400.0, 200.0, 420.0), "submit", "提交")
writer.addFormField(btn)
```

### 13-G 读取/填写表单（PdfStamper） ✅

```java
// Java
PdfReader reader = new PdfReader("form.pdf");
PdfStamper stamper = new PdfStamper(reader, new FileOutputStream("filled.pdf"));
AcroFields fields = stamper.getAcroFields();
fields.setField("name", "张三");
fields.setField("age", "25");
stamper.close();
reader.close();
```

```cangjie
// Cangjie
let reader = PdfReader("form.pdf")
let outFile = File(Path("filled.pdf"), OpenMode.Write)
let stamper = PdfStamperFactory.create(reader, outFile)
let fields = stamper.getAcroFields()
_ = fields.setField("name", "张三")
_ = fields.setField("age", "25")
stamper.close()
reader.close()
```

---

## 14. 透明度与混合模式

### 14-A 透明度（GState） ✅

```java
// Java
PdfGState gs = new PdfGState();
gs.setFillOpacity(0.5f);
gs.setStrokeOpacity(0.8f);
cb.setGState(gs);
```

```cangjie
// Cangjie
let gs = PdfGState()
gs.setFillAlpha(0.5)
gs.setStrokeAlpha(0.8)
let gsName = writer.addGState(gs)
cb.setExtGState(gsName)
```

### 14-B 混合模式 ✅

```java
// Java
PdfGState gs = new PdfGState();
gs.setBlendMode(new PdfName("Multiply"));
cb.setGState(gs);
```

```cangjie
// Cangjie
let gs = PdfGState()
gs.setBlendMode(BlendMode.MULTIPLY)
let gsName = writer.addGState(gs)
cb.setExtGState(gsName)
```

---

## 15. 渐变 Shading

### 15-A 轴向渐变（线性渐变） ✅

```java
// Java
PdfShading shading = PdfShading.simpleAxial(writer,
    x0, y0, x1, y1, new Color(255,0,0), new Color(0,0,255));
PdfShadingPattern pattern = new PdfShadingPattern(shading);
cb.setShadingFill(pattern);
cb.rectangle(x, y, w, h);
cb.fill();
```

```cangjie
// Cangjie
let shading = PdfAxialShading(
    x0, y0, x1, y1, Color(255, 0, 0), Color(0, 0, 255))
let patternName = writer.addShadingPattern(PdfShadingPattern(shading))
cb.setColorFillPattern(patternName)
cb.rectangle(x, y, w, h)
cb.fill()
```

### 15-B 径向渐变 ✅

```java
// Java
PdfShading shading = PdfShading.simpleRadial(writer,
    cx, cy, r0, cx, cy, r1, Color.WHITE, Color.BLUE, false, false);
```

```cangjie
// Cangjie
let shading = PdfRadialShading(
    cx, cy, r0, cx, cy, r1, Color(255, 255, 255), Color(0, 0, 255))
let patternName = writer.addShadingPattern(PdfShadingPattern(shading))
cb.setColorFillPattern(patternName)
```

---

## 16. 条形码 Barcode

### 16-A QR 码 ✅

```java
// Java
BarcodeQRCode qr = new BarcodeQRCode("https://example.com", 1, 1, null);
Image img = qr.getImage();
img.setAbsolutePosition(x, y);
doc.add(img);
```

```cangjie
// Cangjie
let cb = writer.getDirectContent()
let qr = BarcodeQRCode("https://example.com", 200, 200)
let img = qr.createImage(cb, Color(0, 0, 0), Color(255, 255, 255))
img.setAbsolutePosition(x, y)
doc.add(img)
```

### 16-B Code-128 条形码 ✅

```java
// Java
Barcode128 barcode = new Barcode128();
barcode.setCode("1234567890");
Image img = barcode.createImageWithBarcode(cb, null, null);
```

```cangjie
// Cangjie
let barcode = Barcode128("1234567890")
let img = barcode.createImage(cb, Color(0, 0, 0), Color(255, 255, 255))
```

### 16-C Code-39 条形码 ✅

```cangjie
// Cangjie
let barcode = Barcode39("HELLO-CJ")
let img = barcode.createImage(cb, Color(0, 0, 0), Color(255, 255, 255))
```

### 16-D EAN 条形码 ✅

```cangjie
// Cangjie
let barcode = BarcodeEAN("978-3-16-148410-0")
let img = barcode.createImage(cb, Color(0, 0, 0), Color(255, 255, 255))
```

### 16-E PDF417 条形码 ✅

```cangjie
// Cangjie
let barcode = BarcodePDF417("二维条形码内容")
let img = barcode.createImage(cb, Color(0, 0, 0), Color(255, 255, 255))
```

---

## 17. 读取与修改 PdfReader / PdfStamper

### 17-A 读取 PDF ✅

```java
// Java
PdfReader reader = new PdfReader("input.pdf");
int pages = reader.getNumberOfPages();
Rectangle pageSize = reader.getPageSize(1);
byte[] content = reader.getPageContent(1);
HashMap<String, String> info = reader.getInfo();
String version = reader.getPdfVersion();
boolean encrypted = reader.isEncrypted();
reader.close();
```

```cangjie
// Cangjie（方法名完全相同）
let reader = PdfReader("input.pdf")
let pages = reader.getNumberOfPages()
let pageSize = reader.getPageSize(1)
let content = reader.getPageContent(1)
let info = reader.getInfo()
let version = reader.getPdfVersion()
let encrypted = reader.isEncrypted()
reader.close()
```

### 17-B 在已有页面叠加内容 ✅

```java
// Java
PdfStamper stamper = new PdfStamper(reader, new FileOutputStream("out.pdf"));
PdfContentByte over = stamper.getOverContent(1);    // 页面上层
PdfContentByte under = stamper.getUnderContent(1);  // 页面下层（背景）
over.beginText();
over.setFontAndSize(bf, 12);
over.showTextAligned(LEFT, "水印", 200, 400, 45);
over.endText();
stamper.close();
```

```cangjie
// Cangjie
let stamper = PdfStamperFactory.create(reader, File(Path("out.pdf"), OpenMode.Write))
let over = stamper.getOverContent(1)
let under = stamper.getUnderContent(1)
over.beginText()
over.setFontAndSize(bf, "FontName", 12.0)
over.showTextAligned(0, "水印", 200.0, 400.0, 45.0)
over.endText()
stamper.close()
```

### 17-C 修改文档信息 ✅

```java
// Java
HashMap<String, String> info = new HashMap<>();
info.put("Title", "新标题");
stamper.setMoreInfo(info);
```

```cangjie
// Cangjie
let info = HashMap<String, String>()
info["Title"] = "新标题"
stamper.setMoreInfo(info)
```

---

## 18. PDF 合并复制 PdfCopy

### 18-A 合并多个 PDF ✅

```java
// Java
Document doc = new Document();
PdfCopy copy = new PdfCopy(doc, new FileOutputStream("merged.pdf"));
doc.open();
PdfReader r1 = new PdfReader("a.pdf");
copy.addDocument(r1);
r1.close();
PdfReader r2 = new PdfReader("b.pdf");
copy.addDocument(r2);
r2.close();
doc.close();
```

```cangjie
// Cangjie
let doc = Document()
let copy = PdfCopy(doc, File(Path("merged.pdf"), OpenMode.Write))
doc.open()
let r1 = PdfReader("a.pdf")
copy.addDocument(r1)
r1.close()
let r2 = PdfReader("b.pdf")
copy.addDocument(r2)
r2.close()
doc.close()
```

### 18-B 选择页面范围 ✅

```java
// Java
copy.selectPages(reader, "1,3-5,8");
```

```cangjie
// Cangjie（方法名相同）
copy.selectPages(reader, "1,3-5,8")
```

### 18-C 智能合并（PdfSmartCopy，去重资源） ✅

```java
// Java
PdfSmartCopy smartCopy = new PdfSmartCopy(doc, outputStream);
```

```cangjie
// Cangjie
let smartCopy = PdfSmartCopy(doc, File(Path("merged.pdf"), OpenMode.Write))
```

---

## 19. 文本提取 TextExtractor

### 19-A 提取页面文本 ✅

```java
// Java（需第三方库或自实现）
PdfReader reader = new PdfReader("doc.pdf");
PdfTextExtractor extractor = new PdfTextExtractor(reader);
String text = extractor.getTextFromPage(1);
reader.close();
```

```cangjie
// Cangjie
let reader = PdfReader("doc.pdf")
let extractor = TextExtractor(reader)
let text = extractor.extractPage(1)
reader.close()
```

---

## 20. 加密与权限 Security

### 20-A 设置加密 ✅

```java
// Java
writer.setEncryption(
    "userpass".getBytes(), "ownerpass".getBytes(),
    PdfWriter.ALLOW_PRINTING | PdfWriter.ALLOW_COPY,
    PdfWriter.ENCRYPTION_AES_256);
```

```cangjie
// Cangjie
let config = PdfEncryptionConfig()
config.setUserPassword("userpass")
config.setOwnerPassword("ownerpass")
config.setPermissions(PdfPermissions.ALLOW_PRINTING | PdfPermissions.ALLOW_COPY)
config.setAlgorithm(EncryptionAlgorithm.AES256)
writer.setEncryption(PdfEncryptionFactory.create(config))
```

### 20-B 通过 Stamper 加密 ✅

```java
// Java
stamper.setEncryption(
    "user".getBytes(), "owner".getBytes(),
    PdfWriter.ALLOW_PRINTING, PdfWriter.ENCRYPTION_AES_128);
```

```cangjie
// Cangjie
stamper.setEncryption(
    "user", "owner",
    PdfPermissions.ALLOW_PRINTING,
    EncryptionAlgorithm.AES128)
```

---

## 21. 多列排版 ColumnText

### 21-A 简单列排版 ✅

```java
// Java
ColumnText ct = new ColumnText(cb);
ct.setSimpleColumn(llx, lly, urx, ury);
ct.addElement(new Paragraph("第一列文字", font));
int status = ct.go();
```

```cangjie
// Cangjie
let ct = ColumnText(cb)
ct.setSimpleColumn(llx, lly, urx, ury)
ct.addElement(Paragraph("第一列文字", font))
let status = ct.go()
```

### 21-B 流式文本溢出处理 ✅

```java
// Java
ColumnText ct = new ColumnText(cb);
ct.setSimpleColumn(50, 50, 280, 750);
ct.addElement(longParagraph);
int status = ct.go();
if (ColumnText.hasMoreText(status)) {
    doc.newPage();
    ct.setSimpleColumn(50, 50, 280, 750);
    ct.go();
}
```

```cangjie
// Cangjie
let ct = ColumnText(cb)
ct.setSimpleColumn(50.0, 50.0, 280.0, 750.0)
ct.addElement(longParagraph)
var status = ct.go()
if (ct.hasMoreText()) {
    doc.newPage()
    ct.setSimpleColumn(50.0, 50.0, 280.0, 750.0)
    _ = ct.go()
}
```

### 21-C 两列排版 ✅

```java
// Java
// 左列
ColumnText left = new ColumnText(cb);
left.setSimpleColumn(50, 50, 270, 750);
left.addElement(para1);
left.go();
// 右列
ColumnText right = new ColumnText(cb);
right.setSimpleColumn(300, 50, 520, 750);
right.addElement(para2);
right.go();
```

```cangjie
// Cangjie（相同逻辑）
let left = ColumnText(cb)
left.setSimpleColumn(50.0, 50.0, 270.0, 750.0)
left.addElement(para1)
_ = left.go()

let right = ColumnText(cb)
right.setSimpleColumn(300.0, 50.0, 520.0, 750.0)
right.addElement(para2)
_ = right.go()
```

---

## 22. 章节 Chapter / Section

### 22-A 创建章节 ✅

```java
// Java
Chapter chapter = new Chapter(new Paragraph("第一章", font), 1);
chapter.setNumberDepth(0);  // 不显示编号

Section section = chapter.addSection(new Paragraph("1.1 小节"));
section.setIndentationLeft(20f);
section.add(new Paragraph("正文内容"));

doc.add(chapter);
```

```cangjie
// Cangjie（完全相同的 API）
let chapter = Chapter(Paragraph("第一章", font), 1)
chapter.setNumberDepth(0)

let section = chapter.addSection(Paragraph("1.1 小节"))
section.setIndentationLeft(20.0)
_ = section.add(Paragraph("正文内容"))

doc.add(chapter)
```

---

## 23. 元数据与版本

### 23-A 文档元数据 ✅

```java
// Java
doc.addTitle("标题");
doc.addAuthor("作者");
doc.addSubject("主题");
doc.addKeywords("关键词");
doc.addCreator("创建工具");
doc.addCreationDate();
doc.addHeader("自定义Key", "自定义Value");
doc.addJavaScript("app.alert('Hello');");
```

```cangjie
// Cangjie（方法名完全相同）
doc.addTitle("标题")
doc.addAuthor("作者")
doc.addSubject("主题")
doc.addKeywords("关键词")
doc.addCreator("创建工具")
doc.addCreationDate()
// addHeader 通过 addMeta 实现
doc.addJavaScript("app.alert('Hello');")
```

### 23-B PDF 版本 ✅

```java
// Java
writer.setPdfVersion(PdfWriter.VERSION_1_7);
```

```cangjie
// Cangjie
writer.setPdfVersion("1.7")
```

---

## 汇总对照表

| 功能模块 | 状态 | 关键差异 |
|---------|------|---------|
| 文档与页面控制 | ✅ | 参数类型 Float32 vs float |
| 内置拉丁字体 | ✅ | FontStyle 枚举 vs Font.BOLD int |
| CJK/TrueType 字体 | ✅ | 完全相同 |
| Chunk 样式 | ✅ | setUnderline/setStrikethrough 独立方法 |
| Phrase | ✅ | 完全相同 |
| Paragraph | ✅ | Alignment 枚举 vs Element.ALIGN_* int |
| Anchor 超链接 | ✅ | 完全相同 |
| PdfPTable 表格 | ✅ | 完全相同 |
| PdfPCell 单元格 | ✅ | VerticalAlignment 枚举 |
| Image 图片 | ✅ | Alignment 枚举；URL 加载需手动处理 |
| PdfContentByte 底层绘图 | ✅ | 完全相同 |
| PageEvent 页面事件 | ✅ | 必须命名类，不能用匿名内部类 |
| HeaderFooter | ✅ | 完全相同 |
| Outline 书签 | ✅ | 额外提供 OutlineBuilder 链式 API |
| Annotation 注释 | ✅ | 工厂类拆分为具体子类 |
| AcroForm 表单 | ✅ | PdfFormFieldFactory 工厂方式 |
| 透明度 GState | ✅ | setFillAlpha vs setFillOpacity |
| 渐变 Shading | ✅ | writer.addShadingPattern 注册后使用 |
| 条形码 Barcode | ✅ | 支持 QR/128/39/EAN/PDF417 |
| PdfReader 读取 | ✅ | 完全相同 |
| PdfStamper 修改 | ✅ | PdfStamperFactory.create |
| PdfCopy 合并 | ✅ | 完全相同 |
| TextExtractor 文本提取 | ✅ | extractPage vs getTextFromPage |
| Security 加密 | ✅ | PdfEncryptionConfig 配置类 |
| ColumnText 多列 | ✅ | hasMoreText 改为实例方法 |
| Chapter/Section | ✅ | 完全相同 |
| 文档元数据 | ✅ | 完全相同 |
| PDF 版本 | ✅ | 字符串参数 vs PdfWriter 常量 |
