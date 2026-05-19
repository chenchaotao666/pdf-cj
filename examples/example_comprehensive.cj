/**
 * PDF-CJ 综合示例
 * 展示库的所有核心功能
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.PdfWriter
import pdf_cj.table.{PdfPTable, PdfPCell}
import pdf_cj.codec.{ASCIIHexEncoder, ASCII85Encoder, FlateEncoder}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_BASE_FONT: BaseFont = BaseFont.createFont(NOTO_CJK_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)

func cjkFont(size: Float32): Font { Font(CJK_BASE_FONT, size) }
func cjkBold(size: Float32): Font { Font(CJK_BASE_FONT, size, FontStyle.Bold) }
func cjkItalic(size: Float32): Font { Font(CJK_BASE_FONT, size, FontStyle.Italic) }

/**
 * 示例1：文本与段落（字体、样式、颜色、Chunk 混排）
 */
public func exampleComprehensiveText(): Unit {
    try {
        println("示例1：文本与段落...")

        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_comprehensive_text.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.addTitle("PDF-CJ 综合功能 - 文本")
        document.addAuthor("仓颉开发者")
        document.open()

        let title = Paragraph("第一章：文本和段落功能", cjkBold(24.0))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        document.add(title)

        document.add(Paragraph("这是一个普通段落，使用标准字体。", cjkFont(12.0)))
        let boldPara = Paragraph("这是一个粗体段落，展示粗体效果。", cjkBold(12.0))
        boldPara.setAlignment(Alignment.Center)
        boldPara.setSpacingBefore(10.0)
        document.add(boldPara)

        // Chunk 混排
        let mixed = Paragraph()
        mixed.add(Chunk("这个段落包含", cjkFont(12.0)))
        mixed.add(Chunk("混合样式", cjkBold(12.0)))
        mixed.add(Chunk("的文本，", cjkFont(12.0)))
        mixed.add(Chunk("非常灵活！", cjkItalic(12.0)))
        mixed.setSpacingBefore(10.0)
        mixed.setSpacingAfter(10.0)
        document.add(mixed)

        // 彩色文字
        let redChunk = Chunk("这是红色文本", cjkBold(14.0))
        redChunk.setColor(Color.RED)
        let colorPara = Paragraph()
        colorPara.add(redChunk)
        colorPara.setSpacingAfter(20.0)
        document.add(colorPara)

        // 段落格式
        let advanced = Paragraph(
            "这是一个高级格式段落，展示缩进和行距控制。仓颉语言是华为推出的面向全场景应用开发的通用编程语言。",
            cjkFont(12.0)
        )
        advanced.setFirstLineIndent(20.0)
        advanced.setIndentationLeft(30.0)
        advanced.setIndentationRight(30.0)
        advanced.setLeading(20.0)
        document.add(advanced)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_comprehensive_text.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例2：表格功能（简单表格 + 复杂跨列表格）
 */
public func exampleComprehensiveTable(): Unit {
    try {
        println("示例2：表格功能...")

        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_comprehensive_table.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.addTitle("PDF-CJ 综合功能 - 表格")
        document.open()

        let titleFont  = cjkBold(20.0)
        let headerFont = cjkBold(12.0)
        let dataFont   = cjkFont(11.0)

        let title = Paragraph("第二章：表格功能", titleFont)
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        document.add(title)

        // 简单表格
        let simpleTable = PdfPTable(3)
        simpleTable.setWidthPercentage(100.0)
        simpleTable.setSpacingBefore(10.0)
        simpleTable.setSpacingAfter(20.0)

        for (text in ["产品", "数量", "价格"]) {
            let cell = PdfPCell(Phrase(text, headerFont))
            cell.setHorizontalAlignment(Alignment.Center)
            cell.setBackgroundColor(Color(200, 200, 200))
            cell.setPadding(5.0)
            simpleTable.addCell(cell)
        }
        for (row in [["苹果", "10", "¥50"], ["香蕉", "20", "¥30"], ["橙子", "15", "¥45"]]) {
            for (text in row) {
                let cell = PdfPCell(Phrase(text, dataFont))
                cell.setPadding(5.0)
                simpleTable.addCell(cell)
            }
        }
        document.add(simpleTable)

        // 复杂表格（跨列标题）
        let complexTable = PdfPTable(4)
        complexTable.setWidthPercentage(100.0)
        complexTable.setSpacingBefore(20.0)

        let topCell = PdfPCell(Phrase("销售报表", headerFont))
        topCell.setColspan(4)
        topCell.setHorizontalAlignment(Alignment.Center)
        topCell.setBackgroundColor(Color(100, 150, 200))
        topCell.setPadding(10.0)
        complexTable.addCell(topCell)

        for (h in ["区域", "Q1", "Q2", "Q3"]) {
            let cell = PdfPCell(Phrase(h, headerFont))
            cell.setHorizontalAlignment(Alignment.Center)
            cell.setBackgroundColor(Color(220, 220, 220))
            cell.setPadding(5.0)
            complexTable.addCell(cell)
        }
        for (row in [["北京", "100", "120", "150"], ["上海", "110", "130", "140"], ["广州", "90", "100", "110"]]) {
            for (text in row) {
                let cell = PdfPCell(Phrase(text, dataFont))
                cell.setPadding(5.0)
                cell.setHorizontalAlignment(Alignment.Center)
                complexTable.addCell(cell)
            }
        }
        document.add(complexTable)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_comprehensive_table.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例3：编码与压缩（ASCIIHex / ASCII85 / Flate）
 */
public func exampleComprehensiveCodec(): Unit {
    try {
        println("示例3：编码与压缩...")

        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_comprehensive_codec.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.addTitle("PDF-CJ 综合功能 - 编码")
        document.open()

        let titleFont  = cjkBold(20.0)
        let boldFont   = cjkBold(12.0)
        let normalFont = cjkFont(12.0)

        let title = Paragraph("第四章：编码和压缩功能", titleFont)
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        document.add(title)

        let data: Array<UInt8> = [UInt8(0x48), UInt8(0x65), UInt8(0x6C), UInt8(0x6C), UInt8(0x6F)]

        let hexResult = ASCIIHexEncoder.encode(data)
        let hexPara = Paragraph()
        hexPara.add(Chunk("ASCII Hex 编码：", boldFont))
        hexPara.add(Chunk(hexResult, normalFont))
        hexPara.setSpacingAfter(10.0)
        document.add(hexPara)

        let b85Result = ASCII85Encoder.encode(data)
        let b85Para = Paragraph()
        b85Para.add(Chunk("ASCII85 编码：", boldFont))
        b85Para.add(Chunk(b85Result, normalFont))
        b85Para.setSpacingAfter(10.0)
        document.add(b85Para)

        let _ = FlateEncoder.encode(data)
        let flatePara = Paragraph()
        flatePara.add(Chunk("Flate 压缩：", boldFont))
        flatePara.add(Chunk("已压缩（内部使用）", normalFont))
        document.add(flatePara)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_comprehensive_codec.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 主函数
 */
main(): Int64 {
    println("=== PDF-CJ 综合功能验证 ===\n")

    exampleComprehensiveText()
    exampleComprehensiveTable()
    exampleComprehensiveCodec()

    println("\n=== 验证完成 ===")
    println("请检查 output/ 目录中的 PDF 文件")
    0
}
