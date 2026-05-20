/**
 * PDF-CJ 注释功能示例
 * 演示文本注释、超链接、高亮、自由文本、图章、下划线、删除线、矩形/圆形注释。
 *
 * 注意：
 *   - 文本注释（气泡图标）需在 PDF 阅读器中开启"显示注释"才可见
 *   - 链接注释本身不可见，需配合 PdfContentByte 画出可视区域
 *   - 自由文本注释若无 AP 流则不可见，示例改用 PdfContentByte 直接绘制
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.form.{PdfAnnotationFactory, PdfAnnotationStamp}
import pdf_cj.text.{BaseFont, Font, Color}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_BASE_AN: BaseFont = BaseFont.createFont(NOTO_CJK_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
let HELV_AN: BaseFont = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)

func cjkFontAn(size: Float32): Font { Font(CJK_BASE_AN, size) }

// ─────────────────────────────────────────────────────────────────────────────
// 示例1：文本注释（气泡图标）
//   annotation 本身写入 /Annots；页面上额外画一个箭头指示图标位置。
// ─────────────────────────────────────────────────────────────────────────────

public func annotation1_text(): Unit {
    try {
        println("示例1：文本注释（气泡图标）...")

        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("output/example_annotation_text.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = cjkFontAn(12.0)
        document.add(Paragraph("PDF 文本注释示例", cjkFontAn(18.0)))
        document.add(Paragraph(" ", font))
        document.add(Paragraph("文本注释（Text Annotation）会在页面上渲染为一个可点击的图标。", font))
        document.add(Paragraph("单击图标即可弹出注释内容。下方有两个示例图标，请点击查看。", font))
        document.add(Paragraph(" ", font))

        // 注释图标放在段落文字下方的固定位置，方便用户找到并点击
        // PDF 坐标系原点在左下角，A4 高度 842pt，上边距 72pt
        // 段落文字约占 y=680 以上，图标放在 y=620 和 y=560 处
        let iconX: Float32 = 80.0
        let icon1Y: Float32 = 620.0   // Note 图标底部 y
        let icon2Y: Float32 = 560.0   // Comment 图标底部 y
        let iconSize: Float32 = 20.0

        let a1 = PdfAnnotationFactory.createText(
            Rectangle(iconX, icon1Y, iconX + iconSize, icon1Y + iconSize),
            "备注", "这是 Note 类型的文本注释，存储在 PDF /Annots 字典中。单击图标即可弹出此内容。", false, "Note")
        writer.addAnnotation(a1)

        let a2 = PdfAnnotationFactory.createText(
            Rectangle(iconX, icon2Y, iconX + iconSize, icon2Y + iconSize),
            "审阅意见", "这是 Comment 类型，open=true 表示默认展开弹窗。", true, "Comment")
        writer.addAnnotation(a2)

        // 在内容流中画可见的标注，明确告知用户图标位置和操作方式
        let cb = writer.getDirectContent()
        let helvName = writer.addFont(HELV_AN)
        let cjkName  = writer.addFont(CJK_BASE_AN)
        cb.saveState()

        // 图标1 标注区域
        cb.setColorStroke(Color(60, 120, 200))
        cb.setLineWidth(1.0)
        cb.rectangle(iconX - 2.0, icon1Y - 2.0, iconSize + 4.0, iconSize + 4.0)
        cb.stroke()
        cb.setColorFill(Color(40, 40, 40))
        cb.beginText()
        cb.setFontAndSize(CJK_BASE_AN, cjkName, 10.0)
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "<-- 单击此图标（Note 类型）", iconX + iconSize + 8.0, icon1Y + 5.0, 0.0)
        cb.endText()

        // 图标2 标注区域
        cb.setColorStroke(Color(60, 120, 200))
        cb.rectangle(iconX - 2.0, icon2Y - 2.0, iconSize + 4.0, iconSize + 4.0)
        cb.stroke()
        cb.setColorFill(Color(40, 40, 40))
        cb.beginText()
        cb.setFontAndSize(CJK_BASE_AN, cjkName, 10.0)
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "<-- 单击此图标（Comment 类型，默认展开）", iconX + iconSize + 8.0, icon2Y + 5.0, 0.0)
        cb.endText()

        cb.restoreState()

        document.close()
        file.close()
        println("✓ 成功创建: output/example_annotation_text.pdf")
        println("  提示：在 PDF 阅读器中开启【显示注释/批注】即可看到气泡弹出内容")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 示例2：超链接注释
//   链接注释本身透明，用 PdfContentByte 画出可见的蓝色下划线文字区域。
// ─────────────────────────────────────────────────────────────────────────────

public func annotation2_link(): Unit {
    try {
        println("示例2：超链接注释...")

        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("output/example_annotation_link.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = cjkFontAn(12.0)
        document.add(Paragraph("PDF 超链接注释示例", cjkFontAn(18.0)))
        document.add(Paragraph(" ", font))
        document.add(Paragraph("下方蓝色文字是超链接热区，点击可跳转到对应 URL。", font))
        document.add(Paragraph(" ", font))

        // 定义链接热区坐标（PDF 坐标，从下往上）
        let linkLeft: Float32 = 72.0
        let linkBottom: Float32 = 710.0
        let linkRight: Float32 = 340.0
        let linkTop: Float32 = 726.0

        // 1. 用 PdfContentByte 画可见的蓝色链接文字
        let cb = writer.getDirectContent()
        let helvName = writer.addFont(HELV_AN)
        cb.saveState()
        // 蓝色文字
        cb.setColorFill(Color(0, 102, 204))
        cb.beginText()
        cb.setFontAndSize(HELV_AN, helvName, 12.0)
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "https://www.example.com", linkLeft, linkBottom + 2.0, 0.0)
        cb.endText()
        // 蓝色下划线
        cb.setColorStroke(Color(0, 102, 204))
        cb.setLineWidth(0.8)
        cb.moveTo(linkLeft, linkBottom)
        cb.lineTo(linkRight, linkBottom)
        cb.stroke()
        cb.restoreState()

        // 2. 叠加透明链接注释（点击热区）
        let linkRect = Rectangle(linkLeft, linkBottom, linkRight, linkTop)
        let linkAnnot = PdfAnnotationFactory.createURLLink(linkRect, "https://www.example.com")
        linkAnnot.setHighlightMode("I")
        writer.addAnnotation(linkAnnot)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_annotation_link.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 示例3：高亮 / 下划线 / 删除线注释
// ─────────────────────────────────────────────────────────────────────────────

public func annotation3_highlight(): Unit {
    try {
        println("示例3：高亮 / 下划线 / 删除线...")

        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("output/example_annotation_highlight.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = cjkFontAn(12.0)
        document.add(Paragraph("PDF 标记注释示例", cjkFontAn(18.0)))
        document.add(Paragraph(" ", font))
        document.add(Paragraph("高亮注释（Highlight）：黄色背景覆盖文字区域。", font))
        document.add(Paragraph("下划线注释（Underline）：蓝色下划线标记文字区域。", font))
        document.add(Paragraph("删除线注释（StrikeOut）：红色删除线标记待删文字。", font))

        // 坐标：在段落文字所在行对应的 PDF 坐标位置
        // 高亮：第一段文字行（约 y=750）
        let hlRect = Rectangle(72.0, 749.0, 360.0, 765.0)
        let hlQp: Array<Float32> = [72.0, 749.0, 360.0, 749.0, 72.0, 765.0, 360.0, 765.0]
        let hl = PdfAnnotationFactory.createHighlight(hlRect, hlQp)
        hl.setColor(1.0, 1.0, 0.0)
        writer.addAnnotation(hl)

        // 下划线：第二段文字行（约 y=730）
        let ulRect = Rectangle(72.0, 729.0, 330.0, 745.0)
        let ulQp: Array<Float32> = [72.0, 729.0, 330.0, 729.0, 72.0, 745.0, 330.0, 745.0]
        let ul = PdfAnnotationFactory.createUnderline(ulRect, ulQp)
        ul.setColor(0.0, 0.4, 1.0)
        writer.addAnnotation(ul)

        // 删除线：第三段文字行（约 y=709）
        let soRect = Rectangle(72.0, 709.0, 310.0, 725.0)
        let soQp: Array<Float32> = [72.0, 709.0, 310.0, 709.0, 72.0, 725.0, 310.0, 725.0]
        let so = PdfAnnotationFactory.createStrikeOut(soRect, soQp)
        so.setColor(1.0, 0.0, 0.0)
        writer.addAnnotation(so)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_annotation_highlight.pdf")
        println("  提示：高亮/下划线/删除线依赖 PDF 阅读器渲染注释层")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 示例4：自由文本注释（Free Text）
//   PDF 规范中 FreeText 需要 AP 流才能保证跨阅读器渲染。
//   此处用 PdfContentByte 直接绘制可见文字 + 标注框，
//   同时写入 FreeText annotation 存储元数据。
// ─────────────────────────────────────────────────────────────────────────────

public func annotation4_freetext(): Unit {
    try {
        println("示例4：自由文本注释...")

        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("output/example_annotation_freetext.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = cjkFontAn(12.0)
        document.add(Paragraph("PDF 自由文本注释示例", cjkFontAn(18.0)))
        document.add(Paragraph(" ", font))
        document.add(Paragraph("自由文本注释直接显示在页面上，无需点击。", font))

        let ftLeft: Float32 = 72.0
        let ftBottom: Float32 = 650.0
        let ftRight: Float32 = 380.0
        let ftTop: Float32 = 695.0

        // 用 PdfContentByte 画可见的标注框 + 文字（跨阅读器兼容）
        let cb = writer.getDirectContent()
        let helvName = writer.addFont(HELV_AN)
        let cjkName = writer.addFont(CJK_BASE_AN)

        cb.saveState()
        // 淡黄色背景
        cb.setColorFill(Color(255, 255, 200))
        cb.rectangle(ftLeft, ftBottom, ftRight - ftLeft, ftTop - ftBottom)
        cb.fill()
        // 橙色边框
        cb.setColorStroke(Color(220, 140, 0))
        cb.setLineWidth(1.0)
        cb.rectangle(ftLeft, ftBottom, ftRight - ftLeft, ftTop - ftBottom)
        cb.stroke()
        // 注释文字（中文）
        cb.setColorFill(Color(60, 60, 60))
        cb.beginText()
        cb.setFontAndSize(CJK_BASE_AN, cjkName, 11.0)
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "自由文本注释内容：这里显示标注说明。", ftLeft + 6.0, ftBottom + 22.0, 0.0)
        cb.endText()
        cb.beginText()
        cb.setFontAndSize(helvName, 8.0)
        cb.setColorFill(Color(140, 100, 0))
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "FreeText Annotation", ftLeft + 6.0, ftBottom + 6.0, 0.0)
        cb.endText()
        cb.restoreState()

        // 同时写入 FreeText annotation（PDF 元数据，部分阅读器会渲染）
        let ft = PdfAnnotationFactory.createFreeText(
            Rectangle(ftLeft, ftBottom, ftRight, ftTop),
            "自由文本注释内容：这里显示标注说明。",
            "/Helvetica 11 Tf 0 g"
        )
        ft.setColor(0.86, 0.55, 0.0)
        writer.addAnnotation(ft)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_annotation_freetext.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 示例5：图章注释
// ─────────────────────────────────────────────────────────────────────────────

public func annotation5_stamp(): Unit {
    try {
        println("示例5：图章注释...")

        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("output/example_annotation_stamp.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = cjkFontAn(12.0)
        document.add(Paragraph("PDF 图章注释示例", cjkFontAn(18.0)))
        document.add(Paragraph(" ", font))
        document.add(Paragraph("三种预定义图章（需支持注释渲染的 PDF 阅读器）：Approved / Confidential / Draft。", font))

        let stamp1 = PdfAnnotationFactory.createStamp(Rectangle(72.0, 680.0, 200.0, 730.0), PdfAnnotationStamp.APPROVED)
        writer.addAnnotation(stamp1)

        let stamp2 = PdfAnnotationFactory.createStamp(Rectangle(220.0, 680.0, 360.0, 730.0), PdfAnnotationStamp.CONFIDENTIAL)
        writer.addAnnotation(stamp2)

        let stamp3 = PdfAnnotationFactory.createStamp(Rectangle(380.0, 680.0, 500.0, 730.0), PdfAnnotationStamp.DRAFT)
        writer.addAnnotation(stamp3)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_annotation_stamp.pdf")
        println("  提示：图章渲染依赖 PDF 阅读器（Adobe Acrobat 支持最佳）")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 示例6：形状注释（矩形 + 圆形）
// ─────────────────────────────────────────────────────────────────────────────

public func annotation6_shapes(): Unit {
    try {
        println("示例6：形状注释（矩形 + 圆形）...")

        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("output/example_annotation_shapes.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = cjkFontAn(12.0)
        document.add(Paragraph("PDF 形状注释示例", cjkFontAn(18.0)))
        document.add(Paragraph(" ", font))
        document.add(Paragraph("红色矩形注释和蓝色圆形注释（Square / Circle）。", font))

        // 矩形注释（红色边框，黄色填充）
        let sq = PdfAnnotationFactory.createSquare(Rectangle(72.0, 550.0, 220.0, 630.0))
        sq.setColor(0.8, 0.0, 0.0)
        sq.setInteriorColor(1.0, 1.0, 0.8)
        sq.setBorder(2.0)
        writer.addAnnotation(sq)

        // 圆形注释（蓝色边框，浅蓝填充）
        let ci = PdfAnnotationFactory.createCircle(Rectangle(240.0, 550.0, 390.0, 630.0))
        ci.setColor(0.0, 0.2, 0.8)
        ci.setInteriorColor(0.85, 0.92, 1.0)
        ci.setBorder(2.0)
        writer.addAnnotation(ci)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_annotation_shapes.pdf")
        println("  提示：Square/Circle 注释由 PDF 阅读器渲染注释层（非页面内容流）")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 主函数
// ─────────────────────────────────────────────────────────────────────────────

main(): Int64 {
    println("=== PDF-CJ 注释功能验证 ===\n")

    annotation1_text()
    annotation2_link()
    annotation3_highlight()
    annotation4_freetext()
    annotation5_stamp()
    annotation6_shapes()

    println("\n=== 验证完成 ===")
    println("请检查 output/ 目录中的 PDF 文件:")
    println("  example_annotation_text.pdf      - 文本注释（右侧气泡，需开启阅读器注释显示）")
    println("  example_annotation_link.pdf      - 蓝色可见链接 + 点击热区")
    println("  example_annotation_highlight.pdf - 高亮 / 下划线 / 删除线")
    println("  example_annotation_freetext.pdf  - 自由文本（直接绘制 + annotation 元数据）")
    println("  example_annotation_stamp.pdf     - 图章注释")
    println("  example_annotation_shapes.pdf    - 矩形 + 圆形注释")
    0
}
