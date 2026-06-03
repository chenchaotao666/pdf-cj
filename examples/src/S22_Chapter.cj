package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Chapter, Section}
import pdf_cj.core.PdfWriter
import pdf_cj.text.{Font, FontStyle, Color, Alignment}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let _s22_OUT  = "output/"



let _s22_BODY_TEXT =
    "This is a body paragraph demonstrating the Chapter/Section structure in pdf-cj. " +
    "The high-level document structure API allows you to create well-organized documents " +
    "with proper chapter and section numbering. "

func s22_chapter(): Unit {
    println("S22: Chapter & Section Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s22_OUT + "cj_s22_chapter.pdf"), OpenMode.Write)
        PdfWriter.getInstance(doc, file)
        doc.open()

        var docTitle = Paragraph("S22: Chapter & Section Demo", Font(cjkBf, 20.0, FontStyle.Bold))
        docTitle.setAlignment(Alignment.Center)
        docTitle.setSpacingAfter(30.0)
        doc.add(docTitle)

        // ---- Chapter 1: with chapter number shown ----
        var ch1TitlePara = Paragraph("Chapter 1: Introduction", Font(helvBf, 18.0, FontStyle.Bold, Color(0, 0, 150)))
        let chapter1 = Chapter(ch1TitlePara, 1)
        chapter1.setNumberDepth(1)

        var ch1Body = Paragraph(_s22_BODY_TEXT, Font(helvBf, 11.0))
        ch1Body.setSpacingBefore(8.0)
        ch1Body.setSpacingAfter(8.0)
        _ = chapter1.add(ch1Body)

        _ = chapter1.add(Paragraph("第一章：介绍 — 这是第一章的中文内容。", Font(cjkBf, 11.0)))

        // Section 1.1
        var sec11Para = Paragraph("1.1 Getting Started", Font(helvBf, 14.0, FontStyle.Bold))
        let section11 = chapter1.addSection(sec11Para)
        section11.setIndentationLeft(20.0)
        section11.setNumberDepth(2)

        var sec11Body = Paragraph("Section 1.1 discusses the basics of getting started with pdf-cj. " + _s22_BODY_TEXT, Font(helvBf, 11.0))
        sec11Body.setSpacingBefore(6.0)
        sec11Body.setSpacingAfter(6.0)
        _ = section11.add(sec11Body)
        _ = section11.add(Paragraph("1.1 入门指南：快速开始使用pdf-cj。", Font(cjkBf, 11.0)))

        // Section 1.2
        var sec12Para = Paragraph("1.2 Basic Concepts", Font(helvBf, 14.0, FontStyle.Bold))
        let section12 = chapter1.addSection(sec12Para)
        section12.setIndentationLeft(20.0)
        section12.setNumberDepth(2)

        _ = section12.add(Paragraph("Section 1.2 explains basic concepts. " + _s22_BODY_TEXT, Font(helvBf, 11.0)))
        _ = section12.add(Paragraph("1.2 基本概念：PDF文档的核心概念。", Font(cjkBf, 11.0)))

        // Nested section 1.2.1
        var sec121Para = Paragraph("1.2.1 Document Structure", Font(helvBf, 12.0, FontStyle.BoldItalic))
        let section121 = section12.addSection(sec121Para)
        section121.setIndentationLeft(40.0)
        section121.setNumberDepth(3)
        _ = section121.add(Paragraph("Nested section content: Documents consist of pages, which contain text and graphics.", Font(helvBf, 11.0)))
        _ = section121.add(Paragraph("嵌套章节内容：文档由页面组成，页面包含文字和图形。", Font(cjkBf, 11.0)))

        // Nested section 1.2.2
        var sec122Para = Paragraph("1.2.2 Content Elements", Font(helvBf, 12.0, FontStyle.BoldItalic))
        let section122 = section12.addSection(sec122Para)
        section122.setIndentationLeft(40.0)
        section122.setNumberDepth(3)
        _ = section122.add(Paragraph("Content elements include Chunk, Phrase, Paragraph, Table, Image, etc.", Font(helvBf, 11.0)))

        // Section 1.3
        var sec13Para = Paragraph("1.3 Hello World Example", Font(helvBf, 14.0, FontStyle.Bold))
        let section13 = chapter1.addSection(sec13Para)
        section13.setIndentationLeft(20.0)
        section13.setNumberDepth(2)
        _ = section13.add(Paragraph("A simple Hello World example demonstrates the basic document creation flow.", Font(helvBf, 11.0)))

        doc.add(chapter1)

        // ---- Chapter 2: hidden numbering (setNumberDepth(0)) ----
        doc.newPage()

        var ch2TitlePara = Paragraph("Chapter 2: Advanced Topics", Font(helvBf, 18.0, FontStyle.Bold, Color(0, 100, 0)))
        let chapter2 = Chapter(ch2TitlePara, 2)
        chapter2.setNumberDepth(0)  // hide chapter number prefix

        _ = chapter2.add(Paragraph("This chapter has setNumberDepth(0) — no automatic number prefix.", Font(helvBf, 11.0)))
        _ = chapter2.add(Paragraph("第二章：高级主题 — 编号深度为0，不显示章节编号前缀。", Font(cjkBf, 11.0)))
        _ = chapter2.add(Paragraph(_s22_BODY_TEXT + _s22_BODY_TEXT, Font(helvBf, 11.0)))

        // Section 2.1
        let section21 = chapter2.addSection(Paragraph("2.1 Fonts and Typography", Font(helvBf, 14.0, FontStyle.Bold)))
        section21.setIndentationLeft(20.0)
        section21.setNumberDepth(0)
        _ = section21.add(Paragraph("Fonts and typography are critical for professional PDFs. " + _s22_BODY_TEXT, Font(helvBf, 11.0)))
        _ = section21.add(Paragraph("2.1 字体与排版：专业PDF中字体非常重要。", Font(cjkBf, 11.0)))

        // Section 2.2
        let section22 = chapter2.addSection(Paragraph("2.2 Tables and Layouts", Font(helvBf, 14.0, FontStyle.Bold)))
        section22.setIndentationLeft(20.0)
        section22.setNumberDepth(0)
        _ = section22.add(Paragraph("Tables provide structured data presentation. " + _s22_BODY_TEXT, Font(helvBf, 11.0)))

        // Nested 2.2.1
        let section221 = section22.addSection(Paragraph("2.2.1 PdfPTable", Font(helvBf, 12.0, FontStyle.Italic)))
        section221.setIndentationLeft(40.0)
        _ = section221.add(Paragraph("PdfPTable is the primary table class in pdf-cj.", Font(helvBf, 11.0)))

        // Section 2.3
        let section23 = chapter2.addSection(Paragraph("2.3 Images and Graphics", Font(helvBf, 14.0, FontStyle.Bold)))
        section23.setIndentationLeft(20.0)
        section23.setNumberDepth(0)
        _ = section23.add(Paragraph("Images and vector graphics enhance document appearance. " + _s22_BODY_TEXT, Font(helvBf, 11.0)))

        doc.add(chapter2)

        doc.close()
        println("  S22 done: ${_s22_OUT}cj_s22_chapter.pdf")
    } catch (e: Exception) {
        println("  ✗ S22: ${e.message}")
    }
}
