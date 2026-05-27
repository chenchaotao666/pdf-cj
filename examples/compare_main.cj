/**
 * compare_main.cj  —  pdf-cj API 演示
 *
 * 与 compare/openpdf/src/main/java/PdfCompare.java 生成完全相同内容的测试文档，
 * 便于逐行对比两套 API 的差异。
 *
 * ════ 主要 API 差异一览 ════════════════════════════════════════════════════
 *  #  | pdf-cj (Cangjie)                        | OpenPDF (Java)
 * ----+-----------------------------------------+---------------------------
 *  1  | Document(...)                           | new Document(...)
 *  2  | File(Path("f.pdf"), OpenMode.Write)     | new FileOutputStream("f.pdf")
 *  3  | Alignment.Center  (枚举)                | Element.ALIGN_CENTER  (int 1)
 *  4  | FontStyle.Bold    (枚举)                | Font.BOLD             (int 1)
 *  5  | Color(r, g, b)  pdf_cj.text.Color       | new Color(r,g,b)  java.awt.Color
 *  6  | Float32 参数（所有尺寸/坐标）              | float / int 参数
 *  7  | Font(bf, 12.0, FontStyle.Bold)          | new Font(bf, 12, Font.BOLD, color)（支持内联color）
 *  8  | chunk.setUnderline() / setStrikethrough() / setBackground(Color) | chunk.setUnderline(0.5f, -2f)
 *  9  | Paragraph("") 或 setSpacingAfter        | Chunk.NEWLINE
 * 10  | 必须定义命名类 <: PdfPageEventHelper     | 匿名内部类实现 PageEventHelper
 * 11  | 全部 unchecked exception                 | checked exception: DocumentException
 * 12  | File 对象写流                            | FileOutputStream 写流
 * 13  | writer.addOutline(title, dest)           | new PdfOutline(root, dest, title)
 * 14  | table.setWidths([1.0, 2.0, 2.0])        | table.setWidths(new float[]{1,2,2})
 * 15  | img.setAlignment(Alignment.Center)       | img.setAlignment(Image.MIDDLE)
 * 16  | Image 无 setSpacingBefore/After，用 Paragraph("") | img.setSpacingBefore/After(float) 支持
 * 17  | 数组字面量 [8.0,...] 推断 Float64，需 Float32(...) | Java int/float 混用无需显式转型
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 生成文件（输出到 examples/output/）:
 *   cj_s1_text.pdf         S1 文本与字体
 *   cj_s2_table.pdf        S2 表格
 *   cj_s3_image.pdf        S3 图片
 *   cj_s4_drawing.pdf      S4 底层绘图
 *   cj_s5_pagevent.pdf     S5 页面事件（页眉/页脚/页码）
 *   cj_s6_bookmark.pdf     S6 书签与超链接注释
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk, Anchor}
import pdf_cj.core.{PdfWriter, PdfContentByte, PdfPageEventHelper}
import pdf_cj.form.{PdfAnnotationFactory, PdfOutline, PdfDestination}
import pdf_cj.image.Image
import pdf_cj.table.{PdfPTable, PdfPCell}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment, VerticalAlignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

// ── 字体（模块级静态初始化，对应 Java 的 static final / static{} 块） ──────
// Java:    static BaseFont CJK_BF = BaseFont.createFont(...)  在 static{} 块里
// Cangjie: let CJK_BF = ...  在顶层（编译期初始化，无 static 关键字）
let FONT_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let IMG_DIR   = "images/"          // 相对于 examples/ 的路径
let OUT_DIR   = "output/"

let CJK_BF: BaseFont = BaseFont.createFont(FONT_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
// Java: BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
// Cangjie: 完全相同，常量名一致
let HELV_BF: BaseFont = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
let TIMES_BF: BaseFont = BaseFont.createFont(BaseFont.TIMES_ROMAN, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
let COUR_BF: BaseFont  = BaseFont.createFont(BaseFont.COURIER, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)

// ── 字体辅助（对应 Java 的 static Font cjk(float size)） ─────────────────
// Java: new Font(CJK_BF, size)               Cangjie: Font(CJK_BF, size)
// Java: new Font(CJK_BF, size, Font.BOLD)    Cangjie: Font(CJK_BF, size, FontStyle.Bold)
func cjk(size: Float32): Font      { Font(CJK_BF, size) }
func cjkBold(size: Float32): Font  { Font(CJK_BF, size, FontStyle.Bold) }
func helv(size: Float32): Font     { Font(HELV_BF, size) }

// ══════════════════════════════════════════════════════════════════════════════
// S1  文本与字体
// ══════════════════════════════════════════════════════════════════════════════
func section1_text(): Unit {
    try {
        println("S1: 文本与字体...")

        // ── 文档创建 ──────────────────────────────────────────────────────────
        // Java:    new Document(PageSize.A4, 72, 72, 72, 72)  -- 参数为 float/int
        // Cangjie: Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0) -- 参数为 Float32
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)

        // Java:    PdfWriter.getInstance(doc, new FileOutputStream("f.pdf"))
        // Cangjie: PdfWriter.getInstance(doc, File(Path("f.pdf"), OpenMode.Write))
        let file = File(Path(OUT_DIR + "cj_s1_text.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)

        // ── 文档元数据（两侧 API 完全相同） ───────────────────────────────────
        doc.addTitle("PDF Compare S1 - Text")
        doc.addAuthor("PdfCompare")
        doc.addSubject("Text and font comparison")
        doc.addCreator("pdf-cj")

        doc.open()

        // ── 标题段落 ──────────────────────────────────────────────────────────
        // Java:    new Paragraph("text", font)
        // Cangjie: Paragraph("text", font)
        let title = Paragraph("S1: PDF 文本与字体对比测试", cjkBold(20.0))
        // Java:    Element.ALIGN_CENTER (int 常量)
        // Cangjie: Alignment.Center    (枚举值)
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(16.0)
        doc.add(title)

        // ── 普通中文段落 ──────────────────────────────────────────────────────
        let body = Paragraph(
            "普通中文段落：这是使用 NotoSansCJK 嵌入字体渲染的中文正文。" +
            "两端对齐排版，行距 20pt，首行缩进 24pt。", cjk(12.0))
        // Java:    Element.ALIGN_JUSTIFIED
        // Cangjie: Alignment.Left（pdf-cj 当前未实现 Justified 对齐）
        // Java:    Element.ALIGN_JUSTIFIED
        // Cangjie: Alignment.Justified（现已支持两端对齐）
        body.setAlignment(Alignment.Justified)
        // Java: p.setLeading(20)
        // Cangjie: setLeading(20.0)（现已支持固定行距）
        body.setLeading(20.0)
        body.setFirstLineIndent(24.0)
        body.setSpacingAfter(10.0)
        doc.add(body)

        // ── Chunk 样式（颜色、下划线、删除线、背景高亮） ────────────────────
        // pdf-cj: Chunk.setColor / setUnderline / setStrikethrough / setBackground
        // Java:   chunk.setUnderline(thickness, yPos) / setBackground(color)
        let normalChunk = Chunk("默认  ", cjk(12.0))
        let boldChunk   = Chunk("粗体  ", cjkBold(12.0))

        // pdf-cj: Chunk.setColor(Color(r,g,b))
        // Java:   new Font(bf, size, style, new Color(r,g,b))  或 chunk.setFont(...)
        let coloredChunk = Chunk("彩色  ", cjk(12.0))
        // java: colored = new Chunk("彩色  ", new Font(CJK_BF, 12, Font.NORMAL, new Color(200,0,0)))
        // cangjie: chunk.setColor(...)
        coloredChunk.setColor(Color(200, 0, 0))

        // 下划线（与 Java 一致：默认黑色，线条颜色继承文字颜色）
        // java: chunk.setUnderline(0.6f, -2f)
        // cangjie: chunk.setUnderline()
        let underlineChunk = Chunk("下划线  ", cjk(12.0))
        _ = underlineChunk.setUnderline()

        // 删除线（与 Java 一致：默认黑色）
        // java: strike.setUnderline(0.6f, 4f)  // 用正 y 值模拟删除线
        // cangjie: chunk.setStrikethrough()
        let strikeChunk = Chunk("删除线  ", cjk(12.0))
        _ = strikeChunk.setStrikethrough()

        // 背景高亮
        // java: chunk.setBackground(new Color(255, 255, 0))
        // cangjie: chunk.setBackground(Color(255, 255, 0))
        let bgChunk = Chunk("背景高亮", cjk(12.0))
        _ = bgChunk.setBackground(Color(255, 255, 0))

        let phrase = Phrase()
        phrase.add(normalChunk)
        phrase.add(boldChunk)
        phrase.add(coloredChunk)
        phrase.add(underlineChunk)
        phrase.add(strikeChunk)
        phrase.add(bgChunk)
        doc.add(Paragraph(phrase))

        // ── Chunk.NEWLINE 等价物 ───────────────────────────────────────────
        // Java:    doc.add(Chunk.NEWLINE)
        // Cangjie: doc.add(Chunk.NEWLINE)  ← 完全相同！
        doc.add(Chunk.NEWLINE)
        doc.add(Chunk.NEWLINE)

        // ── 字体大小对比 ──────────────────────────────────────────────────────
        doc.add(Paragraph("字体大小对比：", cjkBold(12.0)))
        // 数组字面量 [8.0, ...] 推断为 Float64，需显式转 Float32 传给 cjk()
        for (size in [8.0, 10.0, 12.0, 14.0, 18.0, 24.0]) {
            let s = Float32(size)
            doc.add(Paragraph("${Int32(size)}pt: 中文示例 ABC 123", cjk(s)))
        }

        // ── 行距控制 ──────────────────────────────────────────────────────────
        // Java: leadingDemo.setLeading(28)
        // Cangjie: setLeading(28.0)（固定行距）
        let leadingDemo = Paragraph(
            "自定义行距（leading=28）：这段文字使用了更宽松的行距，" +
            "改善长文本的阅读体验。段落延续三行以上才能明显看出效果。" +
            "第二句，第三句。", cjk(12.0))
        leadingDemo.setLeading(28.0)
        leadingDemo.setSpacingBefore(6.0)
        leadingDemo.setSpacingAfter(12.0)
        doc.add(leadingDemo)

        // ── 对齐方式对比 ──────────────────────────────────────────────────────
        // Java: Element.ALIGN_LEFT / ALIGN_CENTER / ALIGN_RIGHT (int 常量)
        // Cangjie: Alignment.Left / .Center / .Right (枚举值)
        for ((label, align) in [
            ("左对齐",  Alignment.Left),
            ("居中对齐", Alignment.Center),
            ("右对齐",  Alignment.Right)
        ]) {
            let ap = Paragraph("${label}：示例文字 Demo Text 123", cjk(11.0))
            ap.setAlignment(align)
            doc.add(ap)
        }

        // ── 第 2 页：内置拉丁字体 ─────────────────────────────────────────────
        // Java / Cangjie: BaseFont.HELVETICA / TIMES_ROMAN / COURIER 常量名完全相同
        doc.newPage()
        doc.add(Paragraph("P2: 内置拉丁字体（Not Embedded）", cjkBold(14.0)))
        doc.add(Paragraph(""))
        doc.add(Paragraph("Helvetica: The quick brown fox jumps over the lazy dog. 0123456789", helv(12.0)))
        doc.add(Paragraph("Times:     The quick brown fox jumps over the lazy dog. 0123456789", Font(TIMES_BF, 12.0)))
        doc.add(Paragraph("Courier:   The quick brown fox jumps over the lazy dog. 0123456789", Font(COUR_BF, 12.0)))
        // Java: Font.BOLDITALIC (int)    Cangjie: FontStyle.BoldItalic (enum)
        doc.add(Paragraph("Helvetica Bold Italic: 12pt sample", Font(HELV_BF, 12.0, FontStyle.BoldItalic)))

        doc.close()
        file.close()
        println("  -> cj_s1_text.pdf")
    } catch (e: Exception) { println("  ✗ S1: ${e.message}") }
}

// ══════════════════════════════════════════════════════════════════════════════
// S2  表格
// ══════════════════════════════════════════════════════════════════════════════
func section2_table(): Unit {
    try {
        println("S2: 表格...")
        let doc = Document(PageSize.A4, 50.0, 50.0, 60.0, 50.0)
        let file = File(Path(OUT_DIR + "cj_s2_table.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.addTitle("PDF Compare S2 - Table")
        doc.open()

        doc.add(Paragraph("S2: 表格功能对比测试", cjkBold(18.0)))
        doc.add(Paragraph(""))

        // ── 2-A: 基础表格 ─────────────────────────────────────────────────────
        doc.add(Paragraph("2-A: 基础三列表格（setWidthPercentage + setWidths）", cjkBold(12.0)))

        // Java:    new PdfPTable(numColumns)     Cangjie: PdfPTable(numColumns)
        let t1 = PdfPTable(3)
        t1.setWidthPercentage(80.0)
        // Java:    table.setWidths(new float[]{1f, 2f, 1f})
        // Cangjie: table.setWidths([1.0, 2.0, 1.0])   — Array 字面量
        t1.setWidths([1.0, 2.0, 1.0])
        t1.setSpacingBefore(6.0)
        t1.setSpacingAfter(16.0)

        for (h in ["姓名", "电子邮件", "年龄"]) {
            // Java:    new PdfPCell(new Phrase(...))    Cangjie: PdfPCell(Phrase(...))
            let cell = PdfPCell(Phrase(h, cjkBold(11.0)))
            // Java:    new Color(r,g,b)  java.awt    Cangjie: Color(r,g,b)  pdf_cj.text
            cell.setBackgroundColor(Color(66, 139, 202))
            // Java:    Element.ALIGN_CENTER            Cangjie: Alignment.Center
            cell.setHorizontalAlignment(Alignment.Center)
            cell.setPadding(6.0)
            t1.addCell(cell)
        }
        let rows1 = [
            ["张三", "zhang@example.com", "25"],
            ["李四", "li@example.com",    "30"]
        ]
        for (row in rows1) {
            for (v in row) {
                let c = PdfPCell(Phrase(v, cjk(11.0)))
                c.setPadding(5.0)
                t1.addCell(c)
            }
        }
        doc.add(t1)

        // ── 2-B: Colspan 表格 ─────────────────────────────────────────────────
        doc.add(Paragraph("2-B: Colspan（跨列）", cjkBold(12.0)))
        let t2 = PdfPTable(4)
        t2.setWidthPercentage(100.0)
        t2.setSpacingBefore(6.0)
        t2.setSpacingAfter(16.0)

        let topCell = PdfPCell(Phrase("2024 年度销售报表", cjkBold(13.0)))
        topCell.setColspan(4)   // Java / Cangjie: 方法名完全相同
        topCell.setHorizontalAlignment(Alignment.Center)
        topCell.setBackgroundColor(Color(52, 152, 219))
        topCell.setPadding(10.0)
        t2.addCell(topCell)

        for (h in ["区域", "Q1", "Q2", "Q3"]) {
            let c = PdfPCell(Phrase(h, cjkBold(11.0)))
            c.setBackgroundColor(Color(189, 195, 199))
            c.setHorizontalAlignment(Alignment.Center)
            c.setPadding(6.0)
            t2.addCell(c)
        }
        let rows2 = [
            ["华北", "1200", "1350", "1480"],
            ["华东", "1500", "1620", "1750"],
            ["华南", "980",  "1050", "1180"]
        ]
        for (row in rows2) {
            var ci: Int64 = 0
            for (v in row) {
                let c = PdfPCell(Phrase(v, cjk(11.0)))
                c.setHorizontalAlignment(if (ci == 0) { Alignment.Left } else { Alignment.Center })
                c.setPadding(5.0)
                t2.addCell(c)
                ci += 1
            }
        }
        let sumLabel = PdfPCell(Phrase("合计", cjkBold(11.0)))
        sumLabel.setColspan(3)
        sumLabel.setHorizontalAlignment(Alignment.Right)
        sumLabel.setPadding(6.0)
        t2.addCell(sumLabel)
        let sumVal = PdfPCell(Phrase("4130", cjkBold(11.0)))
        sumVal.setHorizontalAlignment(Alignment.Center)
        sumVal.setPadding(6.0)
        t2.addCell(sumVal)
        doc.add(t2)

        // ── 2-C: Rowspan + 嵌套 Paragraph ────────────────────────────────────
        doc.add(Paragraph("2-C: Rowspan + 单元格内嵌段落", cjkBold(12.0)))
        let t3 = PdfPTable(3)
        t3.setWidthPercentage(100.0)
        t3.setSpacingBefore(6.0)
        t3.setSpacingAfter(16.0)
        t3.setWidths([1.0, 3.0, 2.0])

        for (h in ["分组", "描述", "状态"]) {
            let c = PdfPCell(Phrase(h, cjkBold(11.0)))
            c.setBackgroundColor(Color(149, 165, 166))
            c.setHorizontalAlignment(Alignment.Center)
            c.setPadding(6.0)
            t3.addCell(c)
        }

        // ★ Rowspan：Java / Cangjie 方法名完全相同
        let groupA = PdfPCell(Phrase("A 组", cjkBold(11.0)))
        groupA.setRowspan(2)   // 跨 2 行
        groupA.setVerticalAlignment(VerticalAlignment.Middle)
        groupA.setHorizontalAlignment(Alignment.Center)
        groupA.setBackgroundColor(Color(236, 240, 241))
        groupA.setPadding(6.0)
        t3.addCell(groupA)

        // ★ 单元格内嵌 Paragraph（Java / Cangjie 都用 cell.addElement(paragraph)）
        let descA1 = PdfPCell()
        let pA1 = Paragraph("功能模块 A1", cjkBold(11.0))
        pA1.setSpacingAfter(4.0)
        descA1.addElement(pA1)
        descA1.addElement(Paragraph("负责核心数据处理逻辑，支持多线程并发。", cjk(10.0)))
        descA1.setPadding(6.0)
        t3.addCell(descA1)

        let statusA1 = PdfPCell(Phrase("✓ 完成", cjk(11.0)))
        statusA1.setHorizontalAlignment(Alignment.Center)
        statusA1.setBackgroundColor(Color(212, 239, 223))
        statusA1.setPadding(6.0)
        t3.addCell(statusA1)

        // 第 2 行（groupA rowspan 占用 col0）
        let descA2 = PdfPCell(Paragraph("功能模块 A2：UI 层，依赖 A1 提供的接口。", cjk(11.0)))
        descA2.setPadding(6.0)
        t3.addCell(descA2)
        let statusA2 = PdfPCell(Phrase("进行中", cjk(11.0)))
        statusA2.setHorizontalAlignment(Alignment.Center)
        statusA2.setBackgroundColor(Color(253, 235, 208))
        statusA2.setPadding(6.0)
        t3.addCell(statusA2)

        let groupB = PdfPCell(Phrase("B 组", cjkBold(11.0)))
        groupB.setHorizontalAlignment(Alignment.Center)
        groupB.setBackgroundColor(Color(236, 240, 241))
        groupB.setPadding(6.0)
        t3.addCell(groupB)
        t3.addCell(PdfPCell(Phrase("功能模块 B1：独立服务，对外暴露 REST API。", cjk(11.0))))
        let statusB = PdfPCell(Phrase("待开始", cjk(11.0)))
        statusB.setHorizontalAlignment(Alignment.Center)
        statusB.setBackgroundColor(Color(235, 222, 240))
        statusB.setPadding(6.0)
        t3.addCell(statusB)
        doc.add(t3)

        // ── 2-D: headerRows（重复表头） ───────────────────────────────────────
        doc.add(Paragraph("2-D: 重复表头（headerRows=1，自动换页后会重复首行）", cjkBold(12.0)))
        let t4 = PdfPTable(3)
        t4.setWidthPercentage(100.0)
        t4.setSpacingBefore(6.0)
        // Java / Cangjie: setHeaderRows(n) 方法名完全相同
        t4.setHeaderRows(1)
        for (h in ["列 1", "列 2", "列 3"]) {
            let c = PdfPCell(Phrase(h, cjkBold(11.0)))
            c.setBackgroundColor(Color(52, 73, 94))
            c.setHorizontalAlignment(Alignment.Center)
            c.setPadding(6.0)
            t4.addCell(c)
        }
        var r: Int64 = 1
        while (r <= 5) {
            var c: Int64 = 1
            while (c <= 3) {
                t4.addCell(PdfPCell(Phrase("行${r}列${c}", cjk(10.0))))
                c += 1
            }
            r += 1
        }
        doc.add(t4)

        doc.close()
        file.close()
        println("  -> cj_s2_table.pdf")
    } catch (e: Exception) { println("  ✗ S2: ${e.message}") }
}

// ══════════════════════════════════════════════════════════════════════════════
// S3  图片
// ══════════════════════════════════════════════════════════════════════════════
func section3_image(): Unit {
    try {
        println("S3: 图片...")
        let doc = Document(PageSize.A4, 50.0, 50.0, 60.0, 50.0)
        let file = File(Path(OUT_DIR + "cj_s3_image.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.addTitle("PDF Compare S3 - Image")
        doc.open()

        doc.add(Paragraph("S3: 图片嵌入与缩放对比", cjkBold(18.0)))
        doc.add(Paragraph(""))

        let availW: Float32 = PageSize.A4.width - 100.0

        // ── 3-A: JPEG 嵌入 ─────────────────────────────────────────────────
        doc.add(Paragraph("3-A: JPEG 嵌入（river.jpg，scaleToFit）", cjkBold(12.0)))
        // Java:    Image.getInstance(path)  两侧静态工厂方法名完全相同
        // Cangjie: Image.getInstance(path)
        let img1 = Image.getInstance(IMG_DIR + "river.jpg")
        img1.scaleToFit(availW * 0.8, 200.0)   // Java: float  Cangjie: Float32
        // Java:    img.setAlignment(Image.MIDDLE)  int 常量
        // Cangjie: img.setAlignment(Alignment.Center)  枚举
        img1.setAlignment(Alignment.Center)
        // Java / Cangjie: setSpacingBefore/setSpacingAfter 方法名完全相同
        img1.setSpacingBefore(6.0)
        img1.setSpacingAfter(14.0)
        doc.add(img1)

        // ── 3-B: PNG 嵌入（scalePercent） ─────────────────────────────────
        doc.add(Paragraph("3-B: PNG 嵌入（mountain.png，scalePercent 30%）", cjkBold(12.0)))
        let img2 = Image.getInstance(IMG_DIR + "mountain.png")
        // Java / Cangjie: scalePercent(float) 方法名相同，参数类型 float/Float32
        img2.scalePercent(30.0)
        img2.setAlignment(Alignment.Center)
        img2.setSpacingBefore(6.0)
        img2.setSpacingAfter(14.0)
        doc.add(img2)

        // ── 3-C: 三种对齐方式 ──────────────────────────────────────────────
        doc.add(Paragraph("3-C: 三种对齐方式（nodes.jpeg，scalePercent 15%）", cjkBold(12.0)))
        for ((label, align) in [
            ("左对齐（Alignment.Left）",   Alignment.Left),
            ("居中（Alignment.Center）",   Alignment.Center),
            ("右对齐（Alignment.Right）",  Alignment.Right)
        ]) {
            doc.add(Paragraph("${label}：", cjk(11.0)))
            let imgX = Image.getInstance(IMG_DIR + "nodes.jpeg")
            imgX.scalePercent(15.0)
            imgX.setAlignment(align)
            imgX.setSpacingAfter(8.0)
            doc.add(imgX)
        }

        // ── 3-D: scaleAbsolute 固定尺寸 ────────────────────────────────────
        doc.add(Paragraph("3-D: scaleAbsolute（固定 150×100）", cjkBold(12.0)))
        let img3 = Image.getInstance(IMG_DIR + "nodes.jpeg")
        // Java / Cangjie: scaleAbsolute(w, h) 方法名完全相同
        img3.scaleAbsolute(150.0, 100.0)
        img3.setAlignment(Alignment.Center)
        doc.add(img3)

        // ── 3-E: 绝对定位 ──────────────────────────────────────────────────
        doc.newPage()
        doc.add(Paragraph("3-E: 绝对定位（setAbsolutePosition）", cjkBold(12.0)))
        doc.add(Paragraph("图片直接放置在 PDF 坐标系 (60, 500) 处，不受文档流影响：", cjk(11.0)))
        let img4 = Image.getInstance(IMG_DIR + "nodes.jpeg")
        img4.scaleAbsolute(180.0, 120.0)
        // Java / Cangjie: setAbsolutePosition(x, y) 方法名完全相同
        img4.setAbsolutePosition(60.0, 500.0)
        doc.add(img4)

        doc.close()
        file.close()
        println("  -> cj_s3_image.pdf")
    } catch (e: Exception) { println("  ✗ S3: ${e.message}") }
}

// ══════════════════════════════════════════════════════════════════════════════
// S4  底层绘图（PdfContentByte）
// ══════════════════════════════════════════════════════════════════════════════
func section4_drawing(): Unit {
    try {
        println("S4: 底层绘图...")
        let doc = Document(PageSize.A4, 50.0, 50.0, 60.0, 50.0)
        let file = File(Path(OUT_DIR + "cj_s4_drawing.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.addTitle("PDF Compare S4 - Drawing")
        doc.open()

        doc.add(Paragraph("S4: 底层绘图（PdfContentByte）", cjkBold(18.0)))
        // Java / Cangjie: writer.getDirectContent() 完全相同
        let cb = writer.getDirectContent()
        let pH = PageSize.A4.height

        // ── 4-A: 基本形状 ─────────────────────────────────────────────────
        // Java / Cangjie: saveState / restoreState / setLineWidth / setColorFill 完全相同
        cb.saveState()
        cb.setLineWidth(1.5)
        cb.setColorFill(Color(173, 216, 230))
        cb.setColorStroke(Color.BLACK)
        cb.rectangle(60.0, pH - 160.0, 100.0, 50.0)
        cb.fillStroke()

        cb.setColorFill(Color(255, 220, 220))
        cb.setColorStroke(Color(180, 0, 0))
        cb.roundRectangle(180.0, pH - 160.0, 100.0, 50.0, 10.0)
        cb.fillStroke()

        cb.setColorFill(Color(220, 255, 220))
        cb.setColorStroke(Color(0, 150, 0))
        cb.ellipse(300.0, pH - 160.0, 440.0, pH - 110.0)
        cb.fillStroke()
        cb.restoreState()

        // ── 4-B: 虚线样式 ──────────────────────────────────────────────────
        cb.saveState()
        cb.setColorStroke(Color(80, 80, 80))
        cb.setLineWidth(1.5)
        // Java / Cangjie: setLineDash 签名相同，但 Java 用 float[]，Cangjie 用 Array
        cb.setLineDash(0.0)            // 实线 -- Java: cb.setLineDash(0f)
        cb.moveTo(60.0, pH - 200.0); cb.lineTo(480.0, pH - 200.0); cb.stroke()

        cb.setLineDash(8.0, 3.0, 0.0) // 8-3 虚线
        cb.moveTo(60.0, pH - 220.0); cb.lineTo(480.0, pH - 220.0); cb.stroke()

        // Java:    cb.setLineDash(new float[]{3f, 2f, 1f, 2f}, 0f)
        // Cangjie: cb.setLineDash([3.0, 2.0, 1.0, 2.0], 0.0)   — Array 字面量
        cb.setLineDash([3.0, 2.0, 1.0, 2.0], 0.0)
        cb.moveTo(60.0, pH - 240.0); cb.lineTo(480.0, pH - 240.0); cb.stroke()
        cb.restoreState()

        // ── 4-C: CMYK 颜色 ────────────────────────────────────────────────
        // ★ 重要差异：
        //   OpenPDF 1.x: setCMYKColorFill(float,float,float,float)  — 0.0~1.0
        //   OpenPDF 2.x: setCMYKColorFill(int,int,int,int)          — 0~255（API 重大变更！）
        //   pdf-cj:      setCMYKColorFill(Float32,Float32,Float32,Float32) — 0.0~1.0（与1.x对齐）
        cb.saveState()
        cb.setLineWidth(0.5)
        let cmykColors: Array<Array<Float32>> = [
            [1.0, 0.0, 0.0, 0.0],
            [0.0, 1.0, 0.0, 0.0],
            [0.0, 0.0, 1.0, 0.0],
            [0.0, 0.0, 0.0, 1.0]
        ]
        var ci2: Int64 = 0
        while (ci2 < 4) {
            let c = cmykColors[ci2]
            cb.setCMYKColorFill(c[0], c[1], c[2], c[3])
            cb.rectangle(60.0 + Float32(ci2) * 70.0, pH - 290.0, 60.0, 35.0)
            cb.fill()
            ci2 += 1
        }
        cb.restoreState()

        // ── 4-D: 路径与贝塞尔曲线 ─────────────────────────────────────────
        cb.saveState()
        cb.setLineWidth(2.0)
        cb.setColorStroke(Color(255, 128, 0))
        cb.moveTo(60.0, pH - 360.0)
        // Java / Cangjie: curveTo(cp1x,cp1y, cp2x,cp2y, x,y) 完全相同
        cb.curveTo(130.0, pH - 310.0, 200.0, pH - 420.0, 270.0, pH - 340.0)
        cb.curveTo(340.0, pH - 270.0, 420.0, pH - 400.0, 480.0, pH - 330.0)
        cb.stroke()
        cb.restoreState()

        // ── 4-E: 裁剪路径（clip） ─────────────────────────────────────────
        cb.saveState()
        cb.ellipse(60.0, pH - 470.0, 240.0, pH - 380.0)
        cb.clip()
        cb.newPath()
        cb.setLineWidth(8.0)
        cb.setColorStroke(Color(255, 80, 80))
        var li: Int64 = 0
        while (li < 12) {
            let off = Float32(li) * 20.0
            cb.moveTo(60.0, pH - 470.0 + off)
            cb.lineTo(60.0 + off, pH - 380.0)
            cb.stroke()
            li += 1
        }
        cb.restoreState()
        cb.saveState()
        cb.setLineWidth(1.0)
        cb.setColorStroke(Color(100, 100, 100))
        cb.ellipse(60.0, pH - 470.0, 240.0, pH - 380.0)
        cb.stroke()
        cb.restoreState()

        // ── 4-F: 文字绝对定位 ─────────────────────────────────────────────
        // Java / Cangjie: beginText / endText / showTextAligned 完全相同
        let helvName = writer.addFont(HELV_BF)
        cb.beginText()
        cb.setFontAndSize(HELV_BF, helvName, 12.0)
        cb.setColorFill(Color.BLACK)
        // Java:    PdfContentByte.ALIGN_LEFT / ALIGN_CENTER / ALIGN_RIGHT (int)
        // Cangjie: PdfContentByte.ALIGN_LEFT / ALIGN_CENTER / ALIGN_RIGHT (Int64)
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT,   "Left  @(280)", 280.0, pH - 400.0, 0.0)
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER, "Center@(380)", 380.0, pH - 420.0, 0.0)
        cb.showTextAligned(PdfContentByte.ALIGN_RIGHT,  "Right @(480)", 480.0, pH - 440.0, 0.0)
        cb.setColorFill(Color(100, 0, 200))
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "Rotated 45", 300.0, pH - 500.0, 45.0)
        cb.endText()

        // ── 4-G: 灰度填充 ─────────────────────────────────────────────────
        // Java / Cangjie: setGrayFill(float) 完全相同
        cb.saveState()
        cb.setLineWidth(0.0)
        var gi: Int64 = 0
        while (gi < 5) {
            cb.setGrayFill(Float32(4 - gi) / 4.0)
            cb.rectangle(280.0 + Float32(gi) * 45.0, pH - 490.0, 40.0, 30.0)
            cb.fill()
            gi += 1
        }
        cb.restoreState()

        doc.close()
        file.close()
        println("  -> cj_s4_drawing.pdf")
    } catch (e: Exception) { println("  ✗ S4: ${e.message}") }
}

// ══════════════════════════════════════════════════════════════════════════════
// S5  页面事件（页眉 / 页脚 / 页码）
// ★ 关键差异：Java 匿名内部类  vs  Cangjie 命名类
// ══════════════════════════════════════════════════════════════════════════════

// ★ Cangjie 无匿名类，必须提前定义命名类
// ★ Java 可以直接 writer.setPageEvent(new PdfPageEventHelper() { @Override ... })
class HeaderFooterEvent <: PdfPageEventHelper {

    // onStartPage：每页内容写入之前执行（对应 Java @Override onStartPage）
    public override func onStartPage(writer: PdfWriter, document: Document): Unit {
        let cb = writer.getDirectContent()
        let pW = PageSize.A4.width
        let pH = PageSize.A4.height
        // 页眉线
        cb.saveState()
        cb.setColorStroke(Color(66, 139, 202))
        cb.setLineWidth(1.5)
        cb.moveTo(50.0, pH - 50.0)
        cb.lineTo(pW - 50.0, pH - 50.0)
        cb.stroke()
        // 页眉文字
        let hN = writer.addFont(HELV_BF)
        cb.beginText()
        cb.setFontAndSize(HELV_BF, hN, 9.0)
        cb.setColorFill(Color(100, 100, 100))
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT,  "PDF Compare S5 — Page Event Demo", 52.0, pH - 44.0, 0.0)
        cb.showTextAligned(PdfContentByte.ALIGN_RIGHT, "pdf-cj", pW - 52.0, pH - 44.0, 0.0)
        cb.endText()
        cb.restoreState()
    }

    // onEndPage：每页内容写完后执行
    public override func onEndPage(writer: PdfWriter, document: Document): Unit {
        let cb = writer.getDirectContent()
        let pW = PageSize.A4.width
        // 页脚线
        cb.saveState()
        cb.setColorStroke(Color(180, 180, 180))
        cb.setLineWidth(0.5)
        cb.moveTo(50.0, 45.0)
        cb.lineTo(pW - 50.0, 45.0)
        cb.stroke()
        // 页码居中
        let hN = writer.addFont(HELV_BF)
        cb.beginText()
        cb.setFontAndSize(HELV_BF, hN, 9.0)
        cb.setColorFill(Color(120, 120, 120))
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER,
            "第 ${writer.pageNumber} 页", pW / 2.0, 32.0, 0.0)
        cb.endText()
        cb.restoreState()
    }
}

func section5_pageEvent(): Unit {
    try {
        println("S5: 页面事件...")
        let doc = Document(PageSize.A4, 72.0, 72.0, 80.0, 60.0)
        let file = File(Path(OUT_DIR + "cj_s5_pagevent.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.addTitle("PDF Compare S5 - PageEvent")

        // ★ Java:    writer.setPageEvent(new PdfPageEventHelper() { ... })  匿名内部类
        // ★ Cangjie: writer.setPageEvent(HeaderFooterEvent())               实例化命名类
        writer.setPageEvent(HeaderFooterEvent())

        doc.open()
        var pg: Int64 = 1
        while (pg <= 3) {
            doc.add(Paragraph("第 ${pg} 页内容", cjkBold(16.0)))
            doc.add(Paragraph(""))
            var i: Int64 = 1
            while (i <= 8) {
                doc.add(Paragraph("第 ${pg} 页 · 第 ${i} 段：" +
                    "这是用于测试页眉页脚重复渲染的内容文字，确保每页都有完整的页眉线和页码。", cjk(12.0)))
                i += 1
            }
            if (pg < 3) { doc.newPage() }
            pg += 1
        }

        doc.close()
        file.close()
        println("  -> cj_s5_pagevent.pdf")
    } catch (e: Exception) { println("  ✗ S5: ${e.message}") }
}

// ══════════════════════════════════════════════════════════════════════════════
// S6  书签（Outline）与超链接注释
// ══════════════════════════════════════════════════════════════════════════════
func section6_bookmark(): Unit {
    try {
        println("S6: 书签与注释...")
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 60.0)
        let file = File(Path(OUT_DIR + "cj_s6_bookmark.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.addTitle("PDF Compare S6 - Bookmark & Annotation")
        doc.open()

        // ── 书签（Outline）────────────────────────────────────────────────
        // Java:    cb.getRootOutline() → new PdfOutline(root, dest, title)
        //          子书签: new PdfOutline(parent, dest, child_title)
        // Cangjie: writer.addOutline(title, dest) 返回 PdfOutline 顶层书签
        //          outline.addChild(PdfOutline(child_title, dest))

        let ch1Ref = writer.getCurrentPageReference()  // 当前页引用
        // Java:    new PdfDestination(PdfDestination.FITH)
        // Cangjie: PdfDestination(ch1Ref)
        let ch1 = writer.addOutline("第 1 章：文档基础", PdfDestination(ch1Ref))

        doc.add(Paragraph("第 1 章：文档基础", cjkBold(18.0)))
        doc.add(Paragraph(""))

        doc.add(Paragraph("1.1 文档生命周期", cjkBold(13.0)))
        let sec11Ref = writer.getCurrentPageReference()
        // Java:    new PdfOutline(bm1, dest, "1.1 ...")  parent 是构造参数
        // Cangjie: ch1.addChild(PdfOutline("1.1 ...", dest))  先创建再 addChild
        ch1.addChild(PdfOutline("1.1 文档生命周期", PdfDestination(sec11Ref)))
        doc.add(Paragraph("Document 对象管理 PDF 的页面布局、元数据和内容流。" +
            "通过 open() 开启写入，close() 完成所有对象的序列化。", cjk(12.0)))
        doc.add(Paragraph(""))

        doc.add(Paragraph("1.2 PdfWriter 与流", cjkBold(13.0)))
        let sec12Ref = writer.getCurrentPageReference()
        ch1.addChild(PdfOutline("1.2 PdfWriter 与流", PdfDestination(sec12Ref)))
        doc.add(Paragraph("PdfWriter 负责将 Document 的内容写入 OutputStream（Java）或 File（Cangjie）。", cjk(12.0)))

        // 第 2 章（新页）
        doc.newPage()
        let ch2Ref = writer.getCurrentPageReference()
        let ch2 = writer.addOutline("第 2 章：字体与排版", PdfDestination(ch2Ref))
        doc.add(Paragraph("第 2 章：字体与排版", cjkBold(18.0)))
        doc.add(Paragraph(""))

        let sec21Ref = writer.getCurrentPageReference()
        ch2.addChild(PdfOutline("2.1 字体嵌入与子集化", PdfDestination(sec21Ref)))
        doc.add(Paragraph("2.1 字体嵌入与子集化", cjkBold(13.0)))
        doc.add(Paragraph("两侧均支持 TrueType / OpenType 字体子集化嵌入，" +
            "生成的 PDF 字体名称格式为 ABCDEF+FontName。", cjk(12.0)))

        // ── 超链接注释 ────────────────────────────────────────────────────
        doc.add(Paragraph(""))
        doc.add(Paragraph("超链接注释（URI Annotation）：", cjkBold(13.0)))

        // ★ Java: Anchor 类（高层 API），可直接加入文档流，自动创建注释
        //   Anchor anchor = new Anchor("点击访问", font);
        //   anchor.setReference("https://...");
        //   doc.add(new Paragraph(anchor));
        //
        // ★ Cangjie: 与 Java 一致，直接使用 Anchor 高层 API
        let anchor = Anchor("← 点击访问 OpenPDF 项目主页（Anchor 高层 API）", cjk(12.0))
        anchor.setReference("https://github.com/LibrePDF/OpenPDF")
        let anchorPara = Paragraph()
        anchorPara.add(anchor)
        doc.add(anchorPara)

        doc.close()
        file.close()
        println("  -> cj_s6_bookmark.pdf")
    } catch (e: Exception) { println("  ✗ S6: ${e.message}") }
}

// ══════════════════════════════════════════════════════════════════════════════
// 主函数
// ══════════════════════════════════════════════════════════════════════════════
main(): Int64 {
    println("=== pdf-cj API 对比文档生成 ===\n")

    section1_text()
    section2_table()
    section3_image()
    section4_drawing()
    section5_pageEvent()
    section6_bookmark()

    println("\n=== 全部生成完毕 → output/ ===")
    println("对比命令（安装 qpdf + poppler-utils 后）：")
    println("  pdffonts output/cj_s1_text.pdf")
    println("  pdffonts ../compare/output/java_s1_text.pdf")
    println("  qpdf --qdf --object-streams=disable output/cj_s1_text.pdf /tmp/cj_norm.pdf")
    println("  qpdf --qdf --object-streams=disable ../compare/output/java_s1_text.pdf /tmp/java_norm.pdf")
    println("  diff /tmp/cj_norm.pdf /tmp/java_norm.pdf | head -60")
    0
}
