package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.{PdfWriter, PdfContentByte, ColumnText}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let _s21_OUT  = "output/"



let _s21_ARTICLE_LEFT =
    "The ancient art of PDF generation has long fascinated developers. " +
    "pdf-cj provides a rich set of tools for creating professional documents. " +
    "With ColumnText, you can lay out content in multiple columns, wrap text, " +
    "and handle overflow seamlessly across pages. " +
    "This left column demonstrates a long article that flows from the first page " +
    "to subsequent pages, illustrating the power of ColumnText layout. " +
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " +
    "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. " +
    "Ut enim ad minim veniam, quis nostrud exercitation ullamco. " +
    "Duis aute irure dolor in reprehenderit in voluptate velit esse. " +
    "Cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat. " +
    "Cupidatat non proident, sunt in culpa qui officia deserunt mollit. " +
    "Anim id est laborum. Sed ut perspiciatis unde omnis iste natus error. " +
    "Sit voluptatem accusantium doloremque laudantium, totam rem aperiam. " +
    "Eaque ipsa quae ab illo inventore veritatis et quasi architecto. " +
    "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit. "

let _s21_ARTICLE_RIGHT =
    "右栏内容：这是右侧栏的中文文章内容，用于展示ColumnText的多栏排版功能。" +
    "PDF文档的多栏排版在报纸、杂志等出版物中非常常见。" +
    "pdf-cj的ColumnText类提供了强大的文字排版功能，支持多栏布局。" +
    "通过setSimpleColumn方法可以设置栏的边界，通过go方法可以渲染内容。" +
    "当内容超出当前栏的边界时，可以检测溢出状态并翻页继续排版。" +
    "这种能力使得pdf-cj非常适合用于生成复杂的报告、书籍和杂志等文档。" +
    "Right column: Text extraction and layout in multiple columns. " +
    "ColumnText supports both simple columns and complex custom shapes. " +
    "You can mix CJK and Latin text in the same column layout. " +
    "The overflow handling ensures all content is properly rendered. " +
    "Additional text to ensure this column also overflows to the next page. " +
    "More content here to demonstrate multi-page column text rendering. "

func s21_columnText(): Unit {
    println("S21: ColumnText Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 50.0, 50.0, 72.0, 60.0)
        let file = File(Path(_s21_OUT + "cj_s21_column_text.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        var cb = writer.getDirectContent()
        let _s21_HELV_NAME = writer.addFont(helvBf)
        let _s21_CJK_NAME = writer.addFont(cjkBf)

        // Page dimensions
        let pageWidth: Float32 = doc.pageSize.width
        let pageHeight: Float32 = doc.pageSize.height
        let leftMargin: Float32 = 50.0
        let rightMargin: Float32 = 50.0
        let topMargin: Float32 = 72.0
        let bottomMargin: Float32 = 60.0
        let colGap: Float32 = 20.0
        let colWidth: Float32 = (pageWidth - leftMargin - rightMargin - colGap) / 2.0

        // Column bounds
        let col1LLX: Float32 = leftMargin
        let col1URX: Float32 = leftMargin + colWidth
        let col2LLX: Float32 = leftMargin + colWidth + colGap
        let col2URX: Float32 = pageWidth - rightMargin
        let colTop: Float32 = pageHeight - topMargin
        let colBottom: Float32 = bottomMargin

        // Title
        cb.beginText()
        cb.setFontAndSize(cjkBf, _s21_CJK_NAME, 18.0)
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER, "S21: ColumnText Demo — 多栏排版", pageWidth / 2.0, pageHeight - 50.0, 0.0)
        cb.endText()

        // Draw column divider
        cb.saveState()
        cb.setColorStroke(Color(200, 200, 200))
        cb.setLineWidth(0.5)
        cb.moveTo((col1URX + col2LLX) / 2.0, colTop - 30.0)
        cb.lineTo((col1URX + col2LLX) / 2.0, colBottom)
        cb.stroke()
        cb.restoreState()

        // Build content for both columns
        var ct1 = ColumnText(cb)
        ct1.setAlignment(Alignment.Justified)
        ct1.setLeading(0.0, 1.4)

        var leftHeader = Paragraph("Left Column: English Article", Font(helvBf, 12.0, FontStyle.Bold))
        leftHeader.setSpacingAfter(8.0)
        ct1.addElement(leftHeader)

        for (i in 0..3) {
            var p = Paragraph(_s21_ARTICLE_LEFT, Font(helvBf, 10.0))
            p.setAlignment(Alignment.Justified)
            p.setSpacingAfter(6.0)
            ct1.addElement(p)
        }

        var ct2 = ColumnText(cb)
        ct2.setAlignment(Alignment.Justified)
        ct2.setLeading(0.0, 1.4)
        ct2.setIndent(10.0)
        ct2.setFollowingIndent(0.0)
        ct2.setRightIndent(5.0)

        var rightHeader = Paragraph("右栏：中文文章", Font(cjkBf, 12.0, FontStyle.Bold))
        rightHeader.setSpacingAfter(8.0)
        ct2.addElement(rightHeader)

        for (i in 0..3) {
            var p = Paragraph(_s21_ARTICLE_RIGHT, Font(cjkBf, 10.0))
            p.setAlignment(Alignment.Justified)
            p.setSpacingAfter(6.0)
            ct2.addElement(p)
        }

        // Render columns page by page
        var done1 = false
        var done2 = false
        var firstPage = true
        var pageNum = 1

        while (!done1 || !done2) {
            if (!firstPage) {
                doc.newPage()
                cb = writer.getDirectContent()

                // Redraw divider
                cb.saveState()
                cb.setColorStroke(Color(200, 200, 200))
                cb.setLineWidth(0.5)
                cb.moveTo((col1URX + col2LLX) / 2.0, colTop)
                cb.lineTo((col1URX + col2LLX) / 2.0, colBottom)
                cb.stroke()
                cb.restoreState()

                ct1 = ColumnText(cb)
                ct1.setAlignment(Alignment.Justified)
                ct1.setLeading(0.0, 1.4)

                ct2 = ColumnText(cb)
                ct2.setAlignment(Alignment.Justified)
                ct2.setLeading(0.0, 1.4)
            }

            // Render left column
            if (!done1) {
                let topY = if (firstPage) { colTop - 30.0 } else { colTop }
                ct1.setSimpleColumn(col1LLX, colBottom, col1URX, topY)
                let status1 = ct1.go()
                done1 = !ct1.hasMoreText()
            }

            // Render right column
            if (!done2) {
                let topY = if (firstPage) { colTop - 30.0 } else { colTop }
                ct2.setSimpleColumn(col2LLX, colBottom, col2URX, topY)
                let status2 = ct2.go()
                done2 = !ct2.hasMoreText()
            }

            // Page footer
            cb.beginText()
            cb.setFontAndSize(helvBf, _s21_HELV_NAME, 8.0)
            cb.setColorFill(Color(128, 128, 128))
            cb.showTextAligned(PdfContentByte.ALIGN_CENTER,
                "Page ${pageNum} — S21 ColumnText Demo", pageWidth / 2.0, 30.0, 0.0)
            cb.endText()

            firstPage = false
            pageNum += 1

            if (pageNum > 10) {
                break
            }
        }

        doc.close()
        println("  S21 done: ${_s21_OUT}cj_s21_column_text.pdf")
    } catch (e: Exception) {
        println("  ✗ S21: ${e.message}")
    }
}
