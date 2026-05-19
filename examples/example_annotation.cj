/**
 * PDF-CJ 注释功能示例
 * 演示文本注释、超链接注释和高亮注释。
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.form.PdfAnnotationFactory
import pdf_cj.text.{BaseFont, Font}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_BASE_AN: BaseFont = BaseFont.createFont(NOTO_CJK_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)

func cjkFontAn(size: Float32): Font { Font(CJK_BASE_AN, size) }

/**
 * 示例：添加文本注释、链接注释和高亮注释
 */
public func annotation1_text(): Unit {
    try {
        println("示例1：文本注释（气泡图标）...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_annotation_text.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = cjkFontAn(12.0)
        document.add(Paragraph("PDF 文本注释示例", cjkFontAn(18.0)))
        document.add(Paragraph(" ", font))
        document.add(Paragraph("页面右侧有一个注释气泡图标，点击后弹出说明文字。", font))

        let annot = PdfAnnotationFactory.createText(450.0, 700.0, "这是一条文本注释，可以附加说明信息。")
        annot.setTitle("作者备注")
        annot.setOpen(false)
        writer.addAnnotation(annot)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_annotation_text.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例：超链接注释（点击打开 URL）
 */
public func annotation2_link(): Unit {
    try {
        println("示例2：超链接注释...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_annotation_link.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = cjkFontAn(12.0)
        document.add(Paragraph("PDF 超链接注释示例", cjkFontAn(18.0)))
        document.add(Paragraph(" ", font))
        document.add(Paragraph("点击下方蓝色矩形区域可打开链接。", font))

        let linkRect = Rectangle(72.0, 680.0, 300.0, 700.0)
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

/**
 * 示例：高亮注释（标记重要文字区域）
 */
public func annotation3_highlight(): Unit {
    try {
        println("示例3：高亮注释...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_annotation_highlight.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = cjkFontAn(12.0)
        document.add(Paragraph("PDF 高亮注释示例", cjkFontAn(18.0)))
        document.add(Paragraph(" ", font))
        document.add(Paragraph("下方文字区域已被黄色高亮标记。", font))

        let hlRect = Rectangle(72.0, 680.0, 320.0, 696.0)
        let quadPoints: Array<Float32> = [72.0, 680.0, 320.0, 680.0, 72.0, 696.0, 320.0, 696.0]
        let highlight = PdfAnnotationFactory.createHighlight(hlRect, quadPoints)
        highlight.setColor(1.0, 1.0, 0.0)
        writer.addAnnotation(highlight)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_annotation_highlight.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 主函数
 */
main(): Int64 {
    println("=== PDF-CJ 注释功能验证 ===\n")

    annotation1_text()
    annotation2_link()
    annotation3_highlight()

    println("\n=== 验证完成 ===")
    println("请检查 output/ 目录中的 PDF 文件")
    println("  example_annotation_text.pdf      - 文本注释气泡")
    println("  example_annotation_link.pdf      - 超链接注释")
    println("  example_annotation_highlight.pdf - 黄色高亮注释")
    0
}
