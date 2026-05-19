/**
 * PDF-CJ 页面事件示例
 * 演示 PdfPageEventHelper 的核心 hook：水印、页码、页眉线、段落计数。
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.{PdfWriter, PdfContentByte, PdfPageEventHelper}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_BASE: BaseFont = BaseFont.createFont(NOTO_CJK_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)

func cjkFont(size: Float32): Font { Font(CJK_BASE, size) }
func cjkBold(size: Float32): Font { Font(CJK_BASE, size, FontStyle.Bold) }

// ─────────────────────────────────────────────────────────────────────────────
// 示例1：水印 + 页码
//   onEndPage：在每页内容写完后画对角线水印文字和右下角页码
// ─────────────────────────────────────────────────────────────────────────────

class WatermarkPageEvent <: PdfPageEventHelper {
    private let _watermarkText: String
    private let _helv: BaseFont

    public init(text: String) {
        _watermarkText = text
        _helv = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
    }

    public override func onEndPage(writer: PdfWriter, document: Document): Unit {
        let cb = writer.getDirectContent()
        let pageSize = document.pageSize

        // 水印：灰色、旋转 45°、居中
        let helvName = writer.addFont(_helv)
        cb.saveState()
        cb.setGrayFill(0.85)
        cb.beginText()
        cb.setFontAndSize(helvName, 60.0)
        let cx = pageSize.width / 2.0
        let cy = pageSize.height / 2.0
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER, _watermarkText, cx, cy, 45.0)
        cb.endText()
        cb.restoreState()

        // 页码：右下角
        cb.saveState()
        cb.setGrayFill(0.3)
        cb.beginText()
        cb.setFontAndSize(helvName, 10.0)
        let pageNum = "- ${writer.pageNumber} -"
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER, pageNum,
                           pageSize.width / 2.0, 20.0, 0.0)
        cb.endText()
        cb.restoreState()
    }
}

public func pageEvent1_watermark(): Unit {
    try {
        println("示例1：水印 + 页码...")

        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("output/example_page_event_watermark.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)

        writer.setPageEvent(WatermarkPageEvent("CONFIDENTIAL"))
        document.open()

        let titleFont = cjkBold(18.0)
        let bodyFont  = cjkFont(12.0)

        document.add(Paragraph("第一页内容", titleFont))
        for (i in 0..8) {
            document.add(Paragraph(
                "这是正文段落 ${i + 1}，展示水印叠加在页面内容之上的效果。仓颉语言具有简洁优雅的语法设计。",
                bodyFont))
        }

        document.newPage()
        document.add(Paragraph("第二页内容", titleFont))
        for (i in 0..5) {
            document.add(Paragraph("第二页段落 ${i + 1}：水印和页码在每一页都会自动生成。", bodyFont))
        }

        document.close()
        file.close()
        println("✓ 成功创建: output/example_page_event_watermark.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 示例2：页眉线
//   onStartPage：每页开头画一条分隔线 + 文档标题
// ─────────────────────────────────────────────────────────────────────────────

class HeaderLineEvent <: PdfPageEventHelper {
    private let _title: String
    private let _titleFont: BaseFont  // 支持中文的字体
    private let _helv: BaseFont       // 用于 ASCII 页码

    public init(title: String, titleFont: BaseFont) {
        _title = title
        _titleFont = titleFont
        _helv = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
    }

    public override func onStartPage(writer: PdfWriter, document: Document): Unit {
        let cb = writer.getDirectContent()
        let w = document.pageSize.width
        let h = document.pageSize.height
        let margin: Float32 = 50.0
        let lineY: Float32 = h - 42.0

        // 页眉横线
        cb.saveState()
        cb.setColorStroke(Color(52, 152, 219))
        cb.setLineWidth(1.5)
        cb.moveTo(margin, lineY)
        cb.lineTo(w - margin, lineY)
        cb.stroke()

        // 标题文字（使用支持中文的字体）
        let titleFontName = writer.addFont(_titleFont)
        cb.setColorFill(Color(52, 152, 219))
        cb.beginText()
        cb.setFontAndSize(_titleFont, titleFontName, 9.0)
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, _title, margin, lineY + 5.0, 0.0)
        cb.endText()
        cb.restoreState()
    }

    public override func onEndPage(writer: PdfWriter, document: Document): Unit {
        let cb = writer.getDirectContent()
        let w = document.pageSize.width
        let margin: Float32 = 50.0

        // 页脚横线 + 页码
        cb.saveState()
        cb.setColorStroke(Color(189, 195, 199))
        cb.setLineWidth(0.5)
        cb.moveTo(margin, 30.0)
        cb.lineTo(w - margin, 30.0)
        cb.stroke()

        cb.setColorFill(Color(127, 140, 141))
        cb.beginText()
        cb.setFontAndSize(writer.addFont(_helv), 8.0)
        cb.showTextAligned(PdfContentByte.ALIGN_RIGHT,
                           "Page ${writer.pageNumber}", w - margin, 18.0, 0.0)
        cb.endText()
        cb.restoreState()
    }
}

public func pageEvent2_header(): Unit {
    try {
        println("示例2：页眉线 + 页脚页码...")

        let document = Document(PageSize.A4, 50.0, 50.0, 60.0, 50.0)
        let file = File(Path("output/example_page_event_header.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)

        writer.setPageEvent(HeaderLineEvent("PDF-CJ 技术文档  |  2024", CJK_BASE))
        document.open()

        let titleFont = cjkBold(16.0)
        let bodyFont  = cjkFont(11.0)

        document.add(Paragraph("第一章  概述", titleFont))
        for (i in 0..12) {
            document.add(Paragraph(
                "段落 ${i + 1}：仓颉是华为推出的面向全场景应用开发的通用编程语言，支持多范式、多后端编程模型。",
                bodyFont))
        }

        document.newPage()
        document.add(Paragraph("第二章  核心特性", titleFont))
        for (i in 0..6) {
            document.add(Paragraph("段落 ${i + 1}：本章介绍仓颉的类型系统、并发模型和内存安全机制。", bodyFont))
        }

        document.close()
        file.close()
        println("✓ 成功创建: output/example_page_event_header.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 示例3：段落计数
//   onParagraph / onParagraphEnd：统计文档中的段落数量和位置
// ─────────────────────────────────────────────────────────────────────────────

class ParagraphCounterEvent <: PdfPageEventHelper {
    public var paragraphCount: Int32 = 0
    public var lastParagraphY: Float32 = 0.0

    public override func onParagraph(writer: PdfWriter, document: Document, y: Float32): Unit {
        paragraphCount += 1
    }

    public override func onParagraphEnd(writer: PdfWriter, document: Document, y: Float32): Unit {
        lastParagraphY = y
    }
}

public func pageEvent3_counter(): Unit {
    try {
        println("示例3：段落计数器...")

        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("output/example_page_event_counter.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)

        let counter = ParagraphCounterEvent()
        writer.setPageEvent(counter)
        document.open()

        let titleFont = cjkBold(16.0)
        let bodyFont  = cjkFont(12.0)

        document.add(Paragraph("段落计数示例", titleFont))
        for (i in 0..10) {
            document.add(Paragraph("段落 ${i + 1}：仓颉语言的类型系统是静态强类型，支持类型推断。", bodyFont))
        }

        document.close()
        file.close()

        println("  - 共检测到 ${counter.paragraphCount} 个段落")
        println("  - 最后一段结束 Y 坐标：${counter.lastParagraphY}")
        println("✓ 成功创建: output/example_page_event_counter.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 主函数
// ─────────────────────────────────────────────────────────────────────────────

main(): Int64 {
    println("=== PDF-CJ 页面事件功能验证 ===\n")

    pageEvent1_watermark()
    pageEvent2_header()
    pageEvent3_counter()

    println("\n=== 验证完成 ===")
    println("请检查 output/ 目录中的 PDF 文件")
    println("")
    println("验收清单:")
    println("  example_page_event_watermark.pdf - 对角线水印 + 居中页码（每页自动生成）")
    println("  example_page_event_header.pdf    - 蓝色页眉线 + 灰色页脚页码")
    println("  example_page_event_counter.pdf   - 段落计数（控制台打印总数）")
    0
}
