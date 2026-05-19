/**
 * PDF-CJ 中文字体示例
 * 演示如何使用中文字体创建 PDF 文档
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Chunk, Phrase}
import pdf_cj.core.PdfWriter
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_BASE_FONT: BaseFont = BaseFont.createFont(NOTO_CJK_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)

func cjkFont(size: Float32): Font { Font(CJK_BASE_FONT, size) }
func cjkBoldFont(size: Float32): Font { Font(CJK_BASE_FONT, size, FontStyle.Bold) }

/**
 * 示例1：中文段落与标题
 */
public func exampleChineseText(): Unit {
    try {
        println("示例1：中文段落与标题...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_chinese_text.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)

        document.addTitle("中文字体示例")
        document.addAuthor("PDF-CJ")
        document.open()

        let titleFont = cjkBoldFont(20.0)
        let bodyFont  = cjkFont(12.0)

        let title = Paragraph("你好，PDF-CJ！", titleFont)
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        document.add(title)

        let body1 = Paragraph("这是使用 PDF-CJ 库创建的中文 PDF 文档示例。", bodyFont)
        body1.setSpacingAfter(10.0)
        document.add(body1)

        let body2 = Paragraph("PDF-CJ 是用仓颉语言编写的原生 PDF 库，支持创建和编辑 PDF 文件。", bodyFont)
        body2.setSpacingAfter(10.0)
        document.add(body2)

        let intro = Paragraph("主要特性包括：", bodyFont)
        intro.setSpacingAfter(5.0)
        document.add(intro)

        for (feature in [
            "支持 Unicode 编码的中文字体",
            "支持 TrueType 和 OpenType 字体",
            "完整的文本、表格、图片支持"
        ]) {
            let item = Paragraph("• " + feature, bodyFont)
            item.setIndentationLeft(20.0)
            item.setSpacingAfter(4.0)
            document.add(item)
        }

        document.close()
        file.close()
        println("✓ 成功创建: output/example_chinese_text.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例2：混合样式与颜色
 */
public func exampleChineseStyles(): Unit {
    try {
        println("示例2：混合样式与颜色...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_chinese_styles.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let normalFont = cjkFont(12.0)
        let boldFont   = cjkBoldFont(12.0)
        let italicFont = Font(CJK_BASE_FONT, 12.0, FontStyle.Italic)
        let bigFont    = cjkBoldFont(18.0)

        let title = Paragraph("样式与颜色演示", bigFont)
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        document.add(title)

        // 不同字重
        document.add(Paragraph("普通文字（Regular）", normalFont))
        document.add(Paragraph("粗体文字（Bold）", boldFont))
        document.add(Paragraph("斜体文字（Italic）", italicFont))

        // 混合样式段落
        let mixed = Paragraph()
        mixed.add(Chunk("这个段落包含", normalFont))
        mixed.add(Chunk("混合样式", boldFont))
        mixed.add(Chunk("的文本，", normalFont))
        mixed.add(Chunk("非常灵活", italicFont))
        mixed.add(Chunk("！", normalFont))
        mixed.setSpacingBefore(15.0)
        mixed.setSpacingAfter(15.0)
        document.add(mixed)

        // 彩色文字
        let redChunk = Chunk("红色文本  ", normalFont)
        redChunk.setColor(Color.RED)
        let blueChunk = Chunk("蓝色文本  ", normalFont)
        blueChunk.setColor(Color.BLUE)
        let greenChunk = Chunk("绿色文本", normalFont)
        greenChunk.setColor(Color(0, 150, 0))
        let colorPara = Paragraph()
        colorPara.add(redChunk)
        colorPara.add(blueChunk)
        colorPara.add(greenChunk)
        document.add(colorPara)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_chinese_styles.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例3：段落对齐与缩进
 */
public func exampleChineseLayout(): Unit {
    try {
        println("示例3：段落对齐与缩进...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_chinese_layout.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let bodyFont = cjkFont(12.0)
        let text = "这是一段用于演示对齐方式的中文文本，内容足够长以便观察不同对齐效果。仓颉语言是华为推出的面向全场景的通用编程语言。"

        for ((label, align) in [
            ("左对齐",   Alignment.Left),
            ("居中对齐", Alignment.Center),
            ("右对齐",   Alignment.Right)
        ]) {
            let p = Paragraph(label + "：" + text, bodyFont)
            p.setAlignment(align)
            p.setSpacingBefore(10.0)
            p.setSpacingAfter(10.0)
            document.add(p)
        }

        // 首行缩进
        let indented = Paragraph("首行缩进：" + text, bodyFont)
        indented.setFirstLineIndent(24.0)
        indented.setSpacingBefore(10.0)
        document.add(indented)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_chinese_layout.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 主函数
 */
main(): Int64 {
    println("=== PDF-CJ 中文字体功能验证 ===\n")

    exampleChineseText()
    exampleChineseStyles()
    exampleChineseLayout()

    println("\n=== 验证完成 ===")
    println("请检查 output/ 目录中的 PDF 文件")
    0
}
