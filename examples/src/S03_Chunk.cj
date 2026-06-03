package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Chunk}
import pdf_cj.core.PdfWriter
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize}
import std.fs.{File, OpenMode, Path}

let _s03_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s03_OUT  = "output/"

func s03_chunk(): Unit {
    println("S03: Chunk Demo")
    try {
        let cjkBf  = BaseFont.createFont(_s03_FONT, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
        let helvBf = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)

        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s03_OUT + "cj_s03_chunk.pdf"), OpenMode.Write)
        PdfWriter.getInstance(doc, file)
        doc.open()

        var title = Paragraph("S03: Chunk Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)

        // 1. Basic Chunk constructor
        let c1 = Chunk("1. Basic Chunk text  ", Font(helvBf, 12.0))
        doc.add(Paragraph(c1))

        // 2. Chunk with font (setFont replaces the font after construction)
        let c2 = Chunk("2. Chunk with font: ", Font(helvBf, 12.0))
        c2.setFont(Font(helvBf, 14.0, FontStyle.Bold, Color(0, 0, 255)))
        doc.add(Paragraph(c2))

        // 3. Chunk with underline (custom thickness=0.5, yPos=-2 below baseline)
        var p3 = Paragraph()
        let c3 = Chunk("3. Underlined chunk text", Font(helvBf, 12.0))
        _ = c3.setUnderline(0.5, -2.0)
        _ = p3.add(c3)
        doc.add(p3)

        // 4. Strikethrough simulation via setUnderline with positive yPos
        var p4 = Paragraph()
        let c4 = Chunk("4. Strikethrough simulation", Font(helvBf, 12.0))
        _ = c4.setUnderline(0.6, 4.0)
        _ = p4.add(c4)
        doc.add(p4)

        // 5. Multiple underlines (called twice)
        var p5 = Paragraph()
        let c5 = Chunk("5. Double underline chunk", Font(helvBf, 12.0))
        _ = c5.setUnderline(0.5, -2.0)
        _ = c5.setUnderline(0.5, -5.0)
        _ = p5.add(c5)
        doc.add(p5)

        // 6. Background color with padding (extraLeft, extraBottom, extraRight, extraTop)
        var p6 = Paragraph()
        let c6 = Chunk("6. Background color chunk", Font(helvBf, 12.0))
        _ = c6.setBackground(Color(255, 255, 0), 1.0, 1.0, 1.0, 2.0)
        _ = p6.add(c6)
        doc.add(p6)

        // 7. Anchor URL
        var p7 = Paragraph("7. Anchor URL: ")
        let c7 = Chunk("Click here for OpenPDF", Font(helvBf, 12.0, FontStyle.Underline, Color(0, 0, 255)))
        _ = c7.setAnchor("https://github.com/LibrePDF/OpenPDF")
        _ = p7.add(c7)
        doc.add(p7)

        // 8. Local destination and goto
        var p8dest = Paragraph()
        let destChunk = Chunk("8a. [Destination: section1]", Font(helvBf, 12.0))
        _ = destChunk.setLocalDestination("section1")
        _ = p8dest.add(destChunk)
        doc.add(p8dest)

        var p8goto = Paragraph()
        let gotoChunk = Chunk("8b. Jump to section1 above", Font(helvBf, 12.0, FontStyle.Underline, Color(0, 0, 255)))
        _ = gotoChunk.setLocalGoto("section1")
        _ = p8goto.add(gotoChunk)
        doc.add(p8goto)

        // 9. Generic tag
        var p9 = Paragraph()
        let c9 = Chunk("9. Chunk with generic tag", Font(helvBf, 12.0))
        _ = c9.setGenericTag("myTag")
        _ = p9.add(c9)
        doc.add(p9)

        // 10. Chunk.NEWLINE
        var p10 = Paragraph("10. Before NEWLINE")
        _ = p10.add(Chunk.NEWLINE)
        _ = p10.add(Chunk("After NEWLINE", Font(helvBf, 12.0)))
        doc.add(p10)

        // 11. TAB character
        var p11 = Paragraph("11. Tab:")
        _ = p11.add(Chunk("\t", Font(helvBf, 12.0)))
        _ = p11.add(Chunk("After tab", Font(helvBf, 12.0)))
        doc.add(p11)

        // 12. append()
        let c12 = Chunk("12. First part", Font(helvBf, 12.0))
        _ = c12.append(" — appended part")
        doc.add(Paragraph(c12))

        // 13. getWidthPoint()
        let c13 = Chunk("13. Width measurement", Font(helvBf, 12.0))
        let width = c13.getWidthPoint()
        doc.add(Paragraph(c13))
        doc.add(Paragraph("    (width = ${width} pt)", Font(helvBf, 10.0)))

        // 14. Chunk.NEWPAGE
        var p14 = Paragraph("14. Before NEWPAGE — next content on new page")
        _ = p14.add(Chunk.NEWPAGE)
        doc.add(p14)
        doc.add(Paragraph("After NEWPAGE — on page 2", Font(helvBf, 14.0)))

        // 15. CJK Chunk with background
        let cjkChunk = Chunk("15. CJK块: 这是仓颉文字块测试", Font(cjkBf, 14.0))
        _ = cjkChunk.setBackground(Color(200, 230, 255), 1.0, 1.0, 1.0, 2.0)
        doc.add(Paragraph(cjkChunk))

        doc.close()
        println("  S03 done: ${_s03_OUT}cj_s03_chunk.pdf")
    } catch (e: Exception) {
        println("  ✗ S03: ${e.message}")
    }
}
