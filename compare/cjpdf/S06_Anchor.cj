package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk, Anchor}
import pdf_cj.core.PdfWriter
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let _s06_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s06_OUT  = "output/"



func s06_anchor(): Unit {
    println("S06: Anchor Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s06_OUT + "cj_s06_anchor.pdf"), OpenMode.Write)
        PdfWriter.getInstance(doc, file)
        doc.open()

        var title = Paragraph("S06: Anchor Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)

        let linkFont = Font(helvBf, 12.0, FontStyle.Normal, Color(0, 0, 200))

        // 1. Basic external URL anchor
        let a1 = Anchor("1. OpenPDF GitHub Page", linkFont)
        a1.setReference("https://github.com/LibrePDF/OpenPDF")
        doc.add(Paragraph(a1))

        // 2. Anchor with setName() - named anchor (internal destination)
        let namedAnchor = Anchor("2a. [Named Anchor: top-section]", Font(helvBf, 12.0))
        namedAnchor.setName("top-section")
        doc.add(Paragraph(namedAnchor))

        doc.add(Paragraph("Some content below the named anchor...", Font(helvBf, 11.0)))
        doc.add(Paragraph("More content...", Font(helvBf, 11.0)))

        // 3. Anchor embedded inside Paragraph
        var p3 = Paragraph("3. Inline anchor: Visit ", Font(helvBf, 12.0))
        let a3 = Anchor("Google", linkFont)
        a3.setReference("https://www.google.com")
        _ = p3.add(a3)
        _ = p3.add(Chunk(" for searching.", Font(helvBf, 12.0)))
        doc.add(p3)

        // 4. Anchor added directly to document
        let a4 = Anchor("4. Direct anchor to Apache", linkFont)
        a4.setReference("https://www.apache.org")
        doc.add(a4)

        // 5. Mixed text + Anchor in same paragraph
        var p5 = Paragraph()
        _ = p5.add(Chunk("5. Start of paragraph. ", Font(helvBf, 12.0)))
        let a5a = Anchor("First link", linkFont)
        a5a.setReference("https://example.com/1")
        _ = p5.add(a5a)
        _ = p5.add(Chunk(" — middle text — ", Font(helvBf, 12.0)))
        let a5b = Anchor("Second link", linkFont)
        a5b.setReference("https://example.com/2")
        _ = p5.add(a5b)
        _ = p5.add(Chunk(" — end.", Font(helvBf, 12.0)))
        doc.add(p5)

        // 6. Internal link (goto named anchor)
        var p6 = Paragraph("6. Internal link: ")
        let a6 = Anchor("Jump to top-section", linkFont)
        a6.setReference("#top-section")
        _ = p6.add(a6)
        doc.add(p6)

        // 7. Named anchor with reference (both name and ref set)
        let a7 = Anchor("7. Anchor with both name and reference", linkFont)
        a7.setName("dual-anchor")
        a7.setReference("https://example.com/dual")
        doc.add(Paragraph(a7))

        // 8. CJK anchor
        let cjkLink = Font(cjkBf, 13.0, FontStyle.Normal, Color(0, 0, 200))
        let a8 = Anchor("8. 中文链接：点击访问百度", cjkLink)
        a8.setReference("https://www.baidu.com")
        doc.add(Paragraph(a8))

        // 9. Paragraph with multiple mixed anchors
        var p9 = Paragraph()
        _ = p9.add(Chunk("9. 文字 ", Font(cjkBf, 12.0)))
        let a9 = Anchor("中文链接", cjkLink)
        a9.setReference("https://example.com/cjk")
        _ = p9.add(a9)
        _ = p9.add(Chunk(" and ", Font(helvBf, 12.0)))
        let a9b = Anchor("English link", linkFont)
        a9b.setReference("https://example.com/en")
        _ = p9.add(a9b)
        _ = p9.add(Chunk(" in one paragraph.", Font(helvBf, 12.0)))
        doc.add(p9)

        // 10. Anchor as named destination for second page
        doc.newPage()
        let pageAnchor = Anchor("10. [Page 2 Named Anchor]", Font(helvBf, 12.0))
        pageAnchor.setName("page2-anchor")
        doc.add(Paragraph(pageAnchor))
        doc.add(Paragraph("This is page 2 content.", Font(helvBf, 12.0)))

        // Back reference from page 2 to page 1
        var backRef = Paragraph("Back: ")
        let backLink = Anchor("Return to top-section", linkFont)
        backLink.setReference("#top-section")
        _ = backRef.add(backLink)
        doc.add(backRef)

        doc.close()
        println("  S06 done: ${_s06_OUT}cj_s06_anchor.pdf")
    } catch (e: Exception) {
        println("  ✗ S06: ${e.message}")
    }
}
