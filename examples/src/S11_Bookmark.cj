package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.PdfWriter
import pdf_cj.form.{PdfOutline, PdfDestination}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let _s11_OUT  = "output/"



func s11_bookmark(): Unit {
    println("S11: Bookmark & Outline Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s11_OUT + "cj_s11_bookmark.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        var title = Paragraph("S11: Bookmark & Outline Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)
        doc.add(Paragraph("Open the bookmarks panel to see the outline hierarchy.", Font(helvBf, 11.0)))
        doc.add(Paragraph("Click bookmarks to navigate; internal links also work inline.", Font(helvBf, 11.0)))

        // ---- Chapter 1 ----
        doc.add(Paragraph(" ", Font(helvBf, 4.0)))
        var ch1Title = Paragraph()
        let ch1Anchor = Chunk("Chapter 1: Introduction", Font(cjkBf, 16.0, FontStyle.Bold))
        _ = ch1Anchor.setLocalDestination("chapter1_dest")
        _ = ch1Title.add(ch1Anchor)
        ch1Title.setSpacingBefore(10.0)
        doc.add(ch1Title)
        doc.add(Paragraph("This is the introduction chapter. It covers basics.", Font(helvBf, 12.0)))
        doc.add(Paragraph("第一章：介绍 — 基础内容。", Font(cjkBf, 12.0)))

        var sec11Title = Paragraph("  1.1 Getting Started", Font(helvBf, 13.0, FontStyle.Bold))
        sec11Title.setSpacingBefore(12.0)
        doc.add(sec11Title)
        doc.add(Paragraph("  Section 1.1 content: Getting started with OpenPDF.", Font(helvBf, 11.0)))
        doc.add(Paragraph("  入门内容：如何开始使用OpenPDF。", Font(cjkBf, 11.0)))

        var sec12Title = Paragraph()
        let sec12Anchor = Chunk("  1.2 Basic Concepts", Font(helvBf, 13.0, FontStyle.Bold))
        _ = sec12Anchor.setLocalDestination("sec12_dest")
        _ = sec12Title.add(sec12Anchor)
        sec12Title.setSpacingBefore(12.0)
        doc.add(sec12Title)
        doc.add(Paragraph("  Section 1.2 content: Basic concepts in PDF generation.", Font(helvBf, 11.0)))

        // Nested section 1.2.1
        var sec121Title = Paragraph("    1.2.1 Documents and Pages", Font(helvBf, 12.0, FontStyle.Italic))
        sec121Title.setSpacingBefore(8.0)
        doc.add(sec121Title)
        doc.add(Paragraph("    Deep nested section content.", Font(helvBf, 11.0)))

        // Save page 1 reference for outlines before switching pages
        let page1Ref = writer.getCurrentPageReference()

        // ---- Chapter 2 on page 2 ----
        doc.newPage()

        var ch2Title = Paragraph("Chapter 2: Advanced Topics", Font(cjkBf, 16.0, FontStyle.Bold))
        ch2Title.setSpacingBefore(10.0)
        doc.add(ch2Title)
        doc.add(Paragraph("This chapter covers advanced PDF features.", Font(helvBf, 12.0)))
        doc.add(Paragraph("第二章：高级主题。", Font(cjkBf, 12.0)))

        var sec21Title = Paragraph("  2.1 Fonts and Typography", Font(helvBf, 13.0, FontStyle.Bold))
        sec21Title.setSpacingBefore(12.0)
        doc.add(sec21Title)
        doc.add(Paragraph("  Content about fonts and typography in PDF.", Font(helvBf, 11.0)))

        var sec22Title = Paragraph("  2.2 Images and Graphics", Font(helvBf, 13.0, FontStyle.Bold))
        sec22Title.setSpacingBefore(12.0)
        doc.add(sec22Title)
        doc.add(Paragraph("  Content about images and graphics.", Font(helvBf, 11.0)))

        // Internal navigation links
        doc.add(Paragraph(" ", Font(helvBf, 8.0)))
        doc.add(Paragraph("Internal navigation links:", Font(helvBf, 11.0, FontStyle.Bold)))

        var p1 = Paragraph()
        let link1 = Chunk("→ Jump to Chapter 1", Font(helvBf, 11.0, FontStyle.Underline, Color(0, 0, 255)))
        _ = link1.setLocalGoto("chapter1_dest")
        _ = p1.add(link1)
        doc.add(p1)

        var p2 = Paragraph()
        let link2 = Chunk("→ Jump to Section 1.2", Font(helvBf, 11.0, FontStyle.Underline, Color(0, 0, 255)))
        _ = link2.setLocalGoto("sec12_dest")
        _ = p2.add(link2)
        doc.add(p2)

        // Save page 2 reference for outlines
        let page2Ref = writer.getCurrentPageReference()

        // ---- Build outline hierarchy ----
        // Chapter 1 outline — Java setStyle(2) produces /F 1 (italic in PDF spec)
        let ch1Dest = PdfDestination(page1Ref)
        let ch1Outline = writer.addOutline("Chapter 1: Introduction", ch1Dest)
        ch1Outline.setItalic(true)
        ch1Outline.setColor(0.0, 0.0, 0.6)

        // Section 1.1 outline
        let sec11Child = PdfOutline("1.1 Getting Started", PdfDestination(page1Ref))
        ch1Outline.addChild(sec11Child)

        // Section 1.2 outline
        let sec12Child = PdfOutline("1.2 Basic Concepts", PdfDestination(page1Ref))
        ch1Outline.addChild(sec12Child)

        // Section 1.2.1 (nested under 1.2) — Java setStyle(1) produces /F 2 (bold in PDF spec)
        let sec121Child = PdfOutline("1.2.1 Documents and Pages", PdfDestination(page1Ref))
        sec121Child.setBold(true)
        sec12Child.addChild(sec121Child)

        // Chapter 2 outline — Java setStyle(2) produces /F 1 (italic in PDF spec)
        let ch2Dest = PdfDestination(page2Ref)
        let ch2Outline = writer.addOutline("Chapter 2: Advanced Topics", ch2Dest)
        ch2Outline.setItalic(true)
        ch2Outline.setColor(0.0, 0.4, 0.0)

        // Section 2.1 outline
        let sec21Child = PdfOutline("2.1 Fonts and Typography", PdfDestination(page2Ref))
        ch2Outline.addChild(sec21Child)

        // Section 2.2 outline
        let sec22Child = PdfOutline("2.2 Images and Graphics", PdfDestination(page2Ref))
        ch2Outline.addChild(sec22Child)

        doc.close()
        println("  S11 done: ${_s11_OUT}cj_s11_bookmark.pdf")
    } catch (e: Exception) {
        println("  ✗ S11: ${e.message}")
    }
}
