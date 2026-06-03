# pdf-cj API 使用指南

> 本文档全面介绍 **pdf-cj**（仓颉语言 PDF 库，对标 Java OpenPDF）的公开 API 与用法。
> 每节都给出可直接参考的仓颉代码片段。完整可运行示例见 [`examples/src/`](../examples/src)（S01–S23）。

---

## 目录

1. [安装与项目配置](#1-安装与项目配置)
2. [快速开始](#2-快速开始)
3. [核心概念](#3-核心概念)
4. [文档与页面](#4-文档与页面)
5. [字体](#5-字体)
6. [颜色](#6-颜色)
7. [文本元素：Chunk / Phrase / Paragraph / Anchor](#7-文本元素)
8. [章节与书签](#8-章节与书签)
9. [表格](#9-表格)
10. [图片](#10-图片)
11. [底层绘图 PdfContentByte](#11-底层绘图-pdfcontentbyte)
12. [多列排版 ColumnText](#12-多列排版-columntext)
13. [页眉页脚与页面事件](#13-页眉页脚与页面事件)
14. [透明度与混合模式](#14-透明度与混合模式)
15. [渐变 Shading](#15-渐变-shading)
16. [注释 Annotation](#16-注释-annotation)
17. [表单 AcroForm](#17-表单-acroform)
18. [条形码](#18-条形码)
19. [加密与权限](#19-加密与权限)
20. [读取与修改 PdfReader / PdfStamper](#20-读取与修改-pdfreader--pdfstamper)
21. [合并复制 PdfCopy](#21-合并复制-pdfcopy)
22. [文本提取 TextExtractor](#22-文本提取-textextractor)
23. [附录：常量与枚举速查](#23-附录常量与枚举速查)

---

## 1. 安装与项目配置

pdf-cj 是一个 cjpm 库（`output-type = "static"`），依赖 `zlib4cj`（压缩）与 **OpenHiTLS**（加密 FFI）。

在你的项目 `cjpm.toml` 中以路径或 git 方式引用，并配置 HiTLS 的 FFI 路径：

```toml
[package]
name = "my_app"
cjc-version = "1.0.4"
output-type = "executable"

[dependencies]
pdf_cj = { path = "../pdf-cj" }   # 或 git = "..."

# OpenHiTLS FFI（cjpm 不支持 ~，必须绝对路径）
[ffi.c]
hitls_crypto = { path = "/home/you/.local/lib/hitls" }
hitls_bsl    = { path = "/home/you/.local/lib/hitls" }
boundscheck  = { path = "/home/you/.local/lib/hitls" }
```

> 示例工程 `examples/` 提供了 `build.sh`，可自动检测 HiTLS 路径并生成 `cjpm.toml`，可作为参考。

导入方式：顶层包 `pdf_cj` 重新导出了全部常用类型，也可直接 import 子包：

```cangjie
import pdf_cj.api.{Document, Paragraph, Chunk, Phrase}
import pdf_cj.core.PdfWriter
import pdf_cj.text.{Font, BaseFont, FontStyle, Color, Alignment}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}
```

---

## 2. 快速开始

最小可运行示例——创建一个 A4 文档、写入一段文字、保存：

```cangjie
import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.text.{Font, BaseFont}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

main(): Int64 {
    // 1. 创建文档（A4，四边留白 72pt）
    let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)

    // 2. 绑定输出（File 实现了 OutputStream 接口）
    let file = File(Path("hello.pdf"), OpenMode.Write)
    let writer = PdfWriter.getInstance(doc, file)

    // 3. 打开文档后才能写入
    doc.open()

    // 4. 写入内容
    let helv = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
    doc.add(Paragraph("Hello, pdf-cj!", Font(helv, 18.0)))

    // 5. 关闭文档（写出 xref、trailer 等）
    doc.close()
    0
}
```

---

## 3. 核心概念

| 概念 | 说明 |
|------|------|
| **坐标系** | PDF 原点在**左下角**，X 向右、Y 向上，单位为**点（pt）**，1pt = 1/72 inch。 |
| **生命周期** | `Document` 必须 `open()` 后才能 `add()`，结束时 `close()` 写出文件。 |
| **高层 vs 底层** | 高层用 `doc.add(element)` 流式排版；底层用 `writer.getDirectContent()` 拿到 `PdfContentByte` 自由绘制。 |
| **属性语法** | getter 用属性语法（无括号），如 `doc.pageSize`、`doc.leftMargin`、`writer.pageNumber`。 |
| **单位类型** | 尺寸/坐标参数统一为 `Float32`；字面量需写成 `72.0` 而非 `72`。 |
| **TTC 字体** | 传字体路径无需 `,0` 索引后缀，pdf-cj 自动处理。 |

---

## 4. 文档与页面

### 创建文档

```cangjie
let doc = Document()                                  // 默认 A4
let doc = Document(PageSize.LETTER)                   // 指定页面大小
let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0) // 左右上下留白
```

### 页面大小与方向

```cangjie
import pdf_cj.util.{PageSize, Rectangle}

PageSize.A4        // A0–A10, B0–B5, LETTER, LEGAL, TABLOID 等
Rectangle(595.0, 842.0)             // 自定义宽高
PageSize.A4.rotate()                // 横向（landscape）
doc.setPageSize(PageSize.A4.rotate())
```

### 元数据

```cangjie
doc.addTitle("报告标题")
doc.addAuthor("作者")
doc.addSubject("主题")
doc.addKeywords("pdf, cangjie")
doc.addCreator("my_app")
doc.addCreationDate()
```

### 分页与页面信息

```cangjie
doc.newPage()                        // 强制新页
doc.setMargins(50.0, 50.0, 50.0, 50.0)
doc.resetPageCount()                 // 重置页码计数

let w = doc.pageSize.width           // 当前页宽
let ml = doc.leftMargin              // 各边留白：leftMargin/rightMargin/topMargin/bottomMargin
let pageNo = writer.pageNumber       // 当前页码（来自 writer）
```

---

## 5. 字体

### 标准 14 字体（无需嵌入）

```cangjie
import pdf_cj.text.BaseFont

let helv = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
// 可用常量：HELVETICA / HELVETICA_BOLD / TIMES_ROMAN / COURIER / SYMBOL / ZAPFDINGBATS ...
```

### TrueType / OpenType 嵌入字体（含中文）

```cangjie
// IDENTITY_H = Unicode 横排；EMBEDDED = 嵌入并自动子集化
let cjk = BaseFont.createFont(
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
    BaseFont.IDENTITY_H,
    BaseFont.EMBEDDED
)
```

> pdf-cj 会自动对嵌入字体做**子集化**（仅嵌入用到的字形），并按字体路径缓存，
> 同一字体在一次进程内只加载一次，避免大字体反复加载导致内存膨胀。

### Font：字号 + 样式 + 颜色

```cangjie
import pdf_cj.text.{Font, FontStyle, Color}

Font(helv, 12.0)                                  // 字体 + 字号
Font(helv, 14.0, FontStyle.Bold)                  // 加粗
Font(helv, 12.0, FontStyle.Italic, Color.RED)     // 斜体 + 颜色

// FontStyle: Normal / Bold / Italic / BoldItalic / Underline / Strikethrough
```

字符串宽度测量：

```cangjie
let w = helv.getWidthPoint("text", 12.0)   // 指定字号下的宽度（pt）
```

---

## 6. 颜色

```cangjie
import pdf_cj.text.{Color, CMYKColor, GrayColor}

// RGB（0–255）
Color(255, 0, 0)
Color(255, 0, 0, 128)            // 带 alpha
Color.RED                        // 预设：BLACK/WHITE/RED/GREEN/BLUE/CYAN/MAGENTA/YELLOW/ORANGE/GRAY...
Color.fromHex(0x3366CC)          // 16 进制

// CMYK（0.0–1.0）
CMYKColor(0.0, 1.0, 1.0, 0.0)    // = 红；预设 CMYKColor.RED 等

// 灰度（0.0=黑，1.0=白）
GrayColor(0.5)
```

---

## 7. 文本元素

文本三层结构：**Chunk**（同样式文本片段）⊂ **Phrase**（行内片段集合 + 行距）⊂ **Paragraph**（段落 + 对齐/缩进/间距）。

### Chunk

```cangjie
import pdf_cj.api.Chunk

let c = Chunk("文本", Font(helv, 12.0))
c.setColor(Color.BLUE)
c.setUnderline()                     // 下划线
c.setStrikethrough()                 // 删除线
c.setBackground(Color.YELLOW)        // 背景色
c.setAnchorURL("https://example.com")  // 外部链接
c.setLocalGoto("dest1")              // 跳转到本地命名目标
c.setLocalDestination("dest1")       // 定义本地命名目标
```

### Phrase

```cangjie
import pdf_cj.api.Phrase

let p = Phrase("行内文本", Font(helv, 12.0))
p.setLeading(16.0)                   // 行距
p.add(Chunk(" 追加片段", Font(helv, 12.0, FontStyle.Bold)))
```

### Paragraph

```cangjie
import pdf_cj.api.Paragraph
import pdf_cj.text.Alignment

let para = Paragraph("段落正文……", Font(helv, 12.0))
para.setAlignment(Alignment.Justified)   // Left / Center / Right / Justified
para.setFirstLineIndent(24.0)            // 首行缩进
para.setIndentationLeft(20.0)            // 左缩进
para.setIndentationRight(20.0)           // 右缩进
para.setSpacingBefore(6.0)               // 段前距
para.setSpacingAfter(10.0)               // 段后距
para.setLeading(20.0)                    // 固定行距
para.setMultipliedLeading(1.5)           // 倍数行距
doc.add(para)
```

### Anchor（超链接 / 锚点）

```cangjie
import pdf_cj.api.Anchor

let link = Anchor("点击访问", Font(helv, 12.0, FontStyle.Normal, Color.BLUE))
link.setReference("https://example.com")   // 外部链接
// 或作为命名锚点：link.setName("section1")
doc.add(link)
```

---

## 8. 章节与书签

### Chapter / Section（自动生成书签）

```cangjie
import pdf_cj.api.{Chapter, Paragraph}

let chapter = Chapter(Paragraph("第一章 概述", Font(cjk, 18.0, FontStyle.Bold)), 1)
chapter.add(Paragraph("章节正文……", Font(cjk, 12.0)))

let section = chapter.addSection(Paragraph("1.1 小节", Font(cjk, 14.0, FontStyle.Bold)))
section.add(Paragraph("小节正文……", Font(cjk, 12.0)))

doc.add(chapter)   // Chapter/Section 会自动产生 PDF 书签（大纲）
```

### 手动书签 PdfOutline / PdfDestination

```cangjie
import pdf_cj.form.{PdfDestination, PdfOutline}

// 取当前页引用作为跳转目标
let page1Ref = writer.getCurrentPageReference()

// 顶层大纲项（直接挂到根）
let ch1 = writer.addOutline("第一章 概述", PdfDestination(page1Ref))

// 子项：构造 PdfOutline 后 addChild
let sec = PdfOutline("1.1 起步", PdfDestination(page1Ref))
sec.setBold(true)
sec.setColor(0.2, 0.2, 0.8)
ch1.addChild(sec)
```

> 简单场景推荐直接使用 `Chapter`/`Section` 自动书签；`PdfOutlineTree`/`PdfOutlineBuilder`
> 提供更细粒度的树形大纲控制（加粗/斜体/颜色/展开状态）。

---

## 9. 表格

```cangjie
import pdf_cj.table.{PdfPTable, PdfPCell}
import pdf_cj.text.{Alignment, VerticalAlignment, Border}

// 3 列，列宽比例 1:2:2
let table = PdfPTable([1.0, 2.0, 2.0])
table.setWidthPercentage(100.0)        // 占满可用宽度
table.setHeaderRows(1)                  // 首行为表头（跨页重复）

// 表头单元格
let h = PdfPCell(Phrase("名称", Font(cjk, 12.0, FontStyle.Bold)))
h.setBackgroundColor(Color(60, 60, 150))
h.setHorizontalAlignment(Alignment.Center)
h.setVerticalAlignment(VerticalAlignment.Middle)
h.setPadding(6.0)
table.addCell(h)

// 普通单元格（也可直接 addCell(text) / addCell(phrase)）
table.addCell("内容")

// 跨行列
let span = PdfPCell(Phrase("合并单元格"))
span.setColspan(2)                      // 跨 2 列
span.setRowspan(2)                      // 跨 2 行
table.addCell(span)

// 边框控制
let cell = PdfPCell(Phrase("无边框"))
cell.setBorder(Border.NO_BORDER)        // NO_BORDER / TOP / BOTTOM / LEFT / RIGHT / BOX
cell.setBorderColor(Color.GRAY)
cell.setBorderWidth(0.5)

doc.add(table)
```

---

## 10. 图片

```cangjie
import pdf_cj.image.Image
import pdf_cj.text.Alignment

let img = Image.getInstance("images/photo.jpg")   // 支持 JPEG/PNG/GIF/BMP/JPEG2000
// 也可从字节数组：Image.getInstance(byteArray)

img.scalePercent(30.0)                  // 等比缩放到 30%
img.scalePercent(50.0, 30.0)            // X/Y 不同比例
img.scaleAbsolute(200.0, 120.0)         // 绝对宽高
img.scaleToFit(200.0, 120.0)            // 等比缩放至适配框内

img.setAlignment(Alignment.Center)      // 流式布局对齐
img.setRotation(15.0)                   // 旋转角度（度）
img.setSpacingBefore(4.0)
img.setSpacingAfter(10.0)
doc.add(img)

// 绝对定位（不参与流式排版）
img.setAbsolutePosition(100.0, 600.0)
doc.add(img)

// 只读尺寸
let w = img.plainWidth                  // 原始宽
let sw = img.scaledWidth                // 缩放后宽
```

---

## 11. 底层绘图 PdfContentByte

通过 `writer.getDirectContent()` 获取画布，在当前页自由绘制矢量图形与文字。

```cangjie
import pdf_cj.core.{PdfWriter, PdfContentByte}

let cb = writer.getDirectContent()

// ---- 路径与填充/描边 ----
cb.saveState()                          // 保存图形状态
cb.setLineWidth(2.0)
cb.setColorStroke(Color.RED)
cb.setColorFill(Color(200, 200, 255))
cb.moveTo(50.0, 700.0)
cb.lineTo(300.0, 700.0)
cb.curveTo(320.0, 720.0, 360.0, 680.0, 400.0, 700.0)  // 三次贝塞尔
cb.stroke()                             // 描边（或 fill / fillStroke / eoFill）
cb.restoreState()                       // 恢复图形状态

// ---- 基本图形 ----
cb.rectangle(50.0, 600.0, 200.0, 80.0)  // x, y, w, h
cb.roundRectangle(50.0, 500.0, 200.0, 60.0, 8.0)
cb.ellipse(50.0, 400.0, 250.0, 460.0)
cb.arc(50.0, 300.0, 250.0, 360.0, 0.0, 180.0)
cb.fill()

// ---- 线型 ----
cb.setLineCap(PdfContentByte.LINE_CAP_ROUND)        // BUTT / ROUND / PROJECTING_SQUARE
cb.setLineJoin(PdfContentByte.LINE_JOIN_MITER)      // MITER / ROUND / BEVEL
cb.setLineDash(3.0, 2.0, 0.0)                       // 虚线 on/off/phase

// ---- 文本 ----
cb.beginText()
cb.setFontAndSize(helv, writer.addFont(helv), 16.0) // 先 addFont 取资源名
cb.setColorFill(Color.BLACK)
cb.setTextMatrix(50.0, 800.0)                       // 定位
cb.showText("直接绘制的文本")
cb.showTextAligned(PdfContentByte.ALIGN_RIGHT, "右对齐", 558.0, 800.0, 0.0)
cb.endText()

// ---- 颜色空间 ----
cb.setCMYKColorFill(0.0, 1.0, 1.0, 0.0)             // CMYK 0.0–1.0
cb.setGrayFill(0.5)

// ---- 变换与裁剪 ----
cb.concatCTM(1.0, 0.0, 0.0, 1.0, 100.0, 0.0)        // 仿射变换
cb.rectangle(0.0, 0.0, 100.0, 100.0); cb.clip(); cb.newPath()
```

> `writer.addFont(baseFont)` 返回该字体在资源字典中的名字，供 `setFontAndSize` 使用。

---

## 12. 多列排版 ColumnText

```cangjie
import pdf_cj.core.ColumnText
import pdf_cj.api.Phrase

let ct = ColumnText(writer.getDirectContent())
ct.setSimpleColumn(72.0, 72.0, 290.0, 770.0)   // 第一栏：llx, lly, urx, ury
ct.setAlignment(Alignment.Justified)
ct.setLeading(14.0)
ct.addText(Phrase("一大段需要分栏排版的文本……", Font(cjk, 11.0)))

let status = ct.go()                            // 排入；返回是否还有剩余
if (status == ColumnText.NO_MORE_COLUMN) {
    // 本栏已满，可设置下一栏继续
    ct.setSimpleColumn(305.0, 72.0, 523.0, 770.0)
    ct.go()
}
```

---

## 13. 页眉页脚与页面事件

### HeaderFooter（简单页眉/页脚）

```cangjie
import pdf_cj.api.{HeaderFooter, Phrase}

let footer = HeaderFooter(Phrase("第 ", Font(helv, 9.0)), true)  // true = 带页码
footer.setAlignment(Alignment.Center)
doc.setFooter(footer)
```

### PdfPageEventHelper（精细控制每页绘制）

仓颉不支持匿名内部类，需定义命名类继承 `PdfPageEventHelper`：

```cangjie
import pdf_cj.core.{PdfWriter, PdfPageEventHelper}

class MyPageEvent <: PdfPageEventHelper {
    public override func onEndPage(w: PdfWriter, d: Document): Unit {
        let cb = w.getDirectContent()
        let helv = newHelvBf()
        cb.beginText()
        cb.setFontAndSize(helv, w.addFont(helv), 9.0)
        cb.setTextMatrix(40.0, 815.0)
        cb.showText("页眉文字")
        cb.showTextAligned(PdfContentByte.ALIGN_RIGHT, "第 ${w.pageNumber} 页", 558.0, 815.0, 0.0)
        cb.endText()
    }
    // 还可覆写：onOpenDocument / onCloseDocument / onStartPage / onChapter / onSection ...
}

// 注册（必须在 doc.open() 之前）
writer.setPageEvent(MyPageEvent())
```

---

## 14. 透明度与混合模式

```cangjie
import pdf_cj.core.{PdfGState, BlendMode}

let gs = PdfGState()
gs.setFillAlpha(0.5)                 // 填充不透明度 0.0–1.0
gs.setStrokeAlpha(0.8)               // 描边不透明度
gs.setBlendMode(BlendMode.MULTIPLY)  // NORMAL/MULTIPLY/SCREEN/OVERLAY/DARKEN/LIGHTEN...

let gsName = writer.addGState(gs)    // 注册为扩展图形状态资源
cb.setExtGState(gsName)              // 应用
cb.setColorFill(Color.RED)
cb.rectangle(100.0, 600.0, 200.0, 100.0)
cb.fill()
```

---

## 15. 渐变 Shading

```cangjie
import pdf_cj.core.{PdfAxialShading, PdfRadialShading, PdfShadingPattern}

// 线性（轴向）渐变：起点色 → 终点色
let axial = PdfAxialShading(72.0, 680.0, Color.RED, 450.0, 680.0, Color.BLUE)
let patName = writer.addShadingPattern(PdfShadingPattern(axial))
cb.setColorFillPattern(patName)      // 用渐变作为填充
cb.rectangle(72.0, 660.0, 378.0, 40.0)
cb.fill()

// 径向渐变：内圆(cx,cy,r,色) → 外圆(cx,cy,r,色)
let radial = PdfRadialShading(250.0, 400.0, 0.0, Color.YELLOW,
                              250.0, 400.0, 80.0, Color.RED)
let radName = writer.addShadingPattern(PdfShadingPattern(radial))
cb.setColorFillPattern(radName)
cb.ellipse(170.0, 320.0, 330.0, 480.0)
cb.fill()
```

---

## 16. 注释 Annotation

通过 `PdfAnnotation` 的工厂方法创建，再 `writer.addAnnotation(...)`。

```cangjie
import pdf_cj.form.PdfAnnotation
import pdf_cj.util.Rectangle

// 文本注释（便签）
let note = PdfAnnotation.createText(100.0, 700.0, "这是一条批注")
writer.addAnnotation(note)

// 高亮 / 下划线 / 删除线（需 quadPoints）
let hl = PdfAnnotation.createHighlight(Rectangle(100.0, 650.0, 300.0, 665.0),
                                       [100.0, 665.0, 300.0, 665.0, 100.0, 650.0, 300.0, 650.0])
writer.addAnnotation(hl)

// 方框 / 圆形 / 自由文本 / 图章
let sq = PdfAnnotation.createSquare(Rectangle(100.0, 600.0, 200.0, 640.0))
let ft = PdfAnnotation.createFreeText(Rectangle(100.0, 550.0, 300.0, 580.0), "自由文本", "/Helv 12 Tf 0 g")
writer.addAnnotation(sq)
writer.addAnnotation(ft)
```

---

## 17. 表单 AcroForm

### 创建表单字段

```cangjie
import pdf_cj.form.PdfFormFieldFactory

let tf = PdfFormFieldFactory.createTextField("name", 200.0, 700.0, 200.0, 20.0)
tf.setValue("默认值")
writer.addFormField(tf)

let cb_ = PdfFormFieldFactory.createCheckBox("agree", 200.0, 660.0, 16.0)
writer.addFormField(cb_)

let combo = PdfFormFieldFactory.createComboBox("city", 200.0, 620.0, 150.0, 20.0)
let radio = PdfFormFieldFactory.createRadioButtonGroup("gender")
let list  = PdfFormFieldFactory.createListBox("lang", 200.0, 560.0, 150.0, 60.0)
let btn   = PdfFormFieldFactory.createPushButton("submit", 200.0, 520.0, 80.0, 24.0, "提交")
```

### 读取/填写已有表单（配合 PdfStamper，见 §20）

```cangjie
let acro = stamper.getAcroFields()
acro.setField("name", "张三")
let value = acro.getField("name")
let names = acro.getFieldNames()
```

---

## 18. 条形码

```cangjie
import pdf_cj.barcode.{Barcode128, BarcodeEAN, Barcode39, BarcodeQRCode, BarcodePDF417, BarcodeDatamatrix}
import pdf_cj.text.Color

// Code 128
let c128 = Barcode128("pdf-cj-0.1.0")
c128.barHeight = 40.0
c128.moduleWidth = 0.8
let img128 = c128.createFlowImage(Color(0, 0, 0))   // 返回 Image，可 doc.add
doc.add(img128)

// EAN-13 / EAN-8
let ean = BarcodeEAN("9781234567897")               // 12 位（自动校验位）
ean.barHeight = 60.0
doc.add(ean.createFlowImage(Color(0, 0, 0)))
let ean8 = BarcodeEAN("12345670"); ean8.isEAN8 = true

// Code 39（大写字母/数字）
let c39 = Barcode39("PDF-CJ")
doc.add(c39.createFlowImage(Color(0, 0, 0)))

// PDF417（二维堆叠码）
let pdf417 = BarcodePDF417("pdf-cj 0.1.0 demo")
doc.add(pdf417.createFlowImage(Color(0, 0, 0), 300.0, 80.0))  // 目标宽高

// QR 码（绘制到画布）
let qr = BarcodeQRCode("https://example.com")
let qrImg = qr.createImage(cb, Color(0, 0, 0), Color(255, 255, 255))

// DataMatrix
let dm = BarcodeDatamatrix()
dm.generate("pdf-cj 0.1.0")
let dmImg = dm.createImage()
dmImg.scaleAbsolute(100.0, 100.0)
doc.add(dmImg)
```

---

## 19. 加密与权限

```cangjie
import pdf_cj.security.{PdfEncryption, PdfEncryptionConfig, PdfPermissions, EncryptionAlgorithm}

let config = PdfEncryptionConfig()
config.setUserPassword("user123")        // 打开口令（可空）
config.setOwnerPassword("owner456")      // 权限口令
config.setAlgorithm(EncryptionAlgorithm.AES_256)   // RC4_128 / AES_128 / AES_256
config.setPermissions(
    PdfPermissions.ALLOW_PRINTING | PdfPermissions.ALLOW_COPY)

let enc = PdfEncryption(config)
writer.setEncryption(enc)                // 必须在 doc.open() 之前
```

权限位常量：`ALLOW_PRINTING / ALLOW_COPY / ALLOW_MODIFY_CONTENTS / ALLOW_MODIFY_ANNOTATIONS / ALLOW_FILL_IN / ALLOW_SCREEN_READERS / ALLOW_ASSEMBLY / ALLOW_DEGRADED_PRINTING`（可用 `|` 组合）。

便捷工厂：

```cangjie
let enc = PdfEncryption.createAES128Encryption("user", "owner")
let enc2 = PdfEncryption.createStandardEncryption("user", "owner",
              PdfEncryption.createFullPermissions())
```

---

## 20. 读取与修改 PdfReader / PdfStamper

```cangjie
import pdf_cj.reader.{PdfReader, PdfStamper}
import pdf_cj.base.PdfFileOutputStream

// 读取
let reader = PdfReader("input.pdf")
let n = reader.getNumberOfPages()
let size = reader.getPageSize(1)
let info = reader.getInfo()              // 元数据 HashMap

// 盖章/批注修改（在已有 PDF 上叠加内容）
let stamper = PdfStamper(reader, PdfFileOutputStream("output.pdf"))
let over = stamper.getOverContent(1)     // 第 1 页的“上层”画布
over.beginText()
over.setFontAndSize(helv, "F1", 24.0)
over.setColorFill(Color.RED)
over.setTextMatrix(200.0, 400.0)
over.showText("WATERMARK")
over.endText()

// 填写表单
let acro = stamper.getAcroFields()
acro.setField("name", "李四")

stamper.close()
reader.close()
```

---

## 21. 合并复制 PdfCopy

```cangjie
import pdf_cj.reader.{PdfReader, PdfCopy, PdfSmartCopy}
import pdf_cj.base.PdfFileOutputStream

let doc = Document()
let copy = PdfCopy(doc, PdfFileOutputStream("merged.pdf"))
doc.open()

// 逐页导入
let a = PdfReader("a.pdf")
for (p in 1..=a.getNumberOfPages()) {
    copy.addPage(copy.getImportedPage(a, Int32(p)))
}
// 或整本导入：copy.addDocument(reader)
// 或按范围选择：copy.selectPages(reader, "1-3,5")

doc.close()
```

> `PdfSmartCopy` 用法相同，但会对重复资源（如相同字体/图片）去重，输出更小。

---

## 22. 文本提取 TextExtractor

```cangjie
import pdf_cj.reader.{PdfReader, TextExtractor}

let reader = PdfReader("doc.pdf")
let page1 = TextExtractor.extractPage(reader, 1i32)   // 提取指定页
let all = TextExtractor.extractAll(reader)            // 提取全文
reader.close()
println(all)
```

---

## 23. 附录：常量与枚举速查

### Alignment（水平对齐）
`Left` (0) · `Center` (1) · `Right` (2) · `Justified` (3)

### VerticalAlignment（垂直对齐）
`Top` (4) · `Middle` (5) · `Bottom` (6) · `Baseline` (7)

### FontStyle
`Normal` (0) · `Bold` (1) · `Italic` (2) · `BoldItalic` (3) · `Underline` (4) · `Strikethrough` (8)

### Border（单元格/页眉边框，可用 `+` 组合）
`NO_BORDER` (0) · `TOP` (1) · `BOTTOM` (2) · `LEFT` (4) · `RIGHT` (8) · `BOX` (15)

### PdfContentByte 常量
- 线帽：`LINE_CAP_BUTT` / `LINE_CAP_ROUND` / `LINE_CAP_PROJECTING_SQUARE`
- 连接：`LINE_JOIN_MITER` / `LINE_JOIN_ROUND` / `LINE_JOIN_BEVEL`
- 对齐：`ALIGN_LEFT` / `ALIGN_CENTER` / `ALIGN_RIGHT`
- 文本渲染模式：`TEXT_RENDER_MODE_FILL` / `_STROKE` / `_FILL_STROKE` / `_INVISIBLE` / `_FILL_CLIP` ...

### EncryptionAlgorithm
`RC4_128` · `AES_128` · `AES_256`

### BaseFont 编码 / 嵌入常量
- 编码：`WINANSI`（=`CP1252`）· `MACROMAN` · `IDENTITY_H` · `IDENTITY_V`
- 嵌入：`EMBEDDED` (true) · `NOT_EMBEDDED` (false)

### PageSize（部分）
`A0`–`A10` · `B0`–`B5` · `LETTER` · `LEGAL` · `TABLOID`；`.rotate()` 转横向。

---

## 与 OpenPDF (Java) 的主要差异

| Java (OpenPDF) | 仓颉 (pdf-cj) |
|----------------|---------------|
| `new Document(...)` | `Document(...)`（无 `new`） |
| `new FileOutputStream("f.pdf")` | `File(Path("f.pdf"), OpenMode.Write)` |
| `Element.ALIGN_CENTER`（int） | `Alignment.Center`（枚举） |
| `Font.BOLD`（int） | `FontStyle.Bold`（枚举） |
| `doc.getPageSize()` / `doc.leftMargin()` | `doc.pageSize` / `doc.leftMargin`（属性，无括号） |
| 尺寸用 `float`/`int` | 统一 `Float32`（字面量写 `72.0`） |
| 匿名内部类实现 PageEvent | 命名类 `<: PdfPageEventHelper` |
| TTC 路径需 `font.ttc,0` | 直接传路径，无需索引后缀 |

---

> 更多端到端可运行示例（含中英文混排、复杂表格、页面事件、加密、合并等 23 个场景），
> 请参阅 [`examples/src/S01`–`S23`](../examples/src)，运行方式见 [`examples/README.md`](../examples/README.md)。
