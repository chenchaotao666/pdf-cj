package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.PdfWriter
import pdf_cj.reader.{PdfReader, TextExtractor}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}
import std.collection.HashMap

let _s23_OUT  = "output/"



func s23_metadata(): Unit {
    println("S23: Metadata Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s23_OUT + "cj_s23_metadata.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)

        // Set PDF version BEFORE open
        writer.setPdfVersion("1.7")

        // Set metadata BEFORE doc.open()
        doc.addTitle("S23 Metadata Demo Document")
        doc.addAuthor("pdf-cj Test Author")
        doc.addSubject("Demonstrating PDF metadata features")
        doc.addKeywords("pdf-cj, metadata, PDF, Cangjie, test")
        doc.addCreator("S23_Metadata.cj")
        doc.addCreationDate()

        doc.open()

        // Add JavaScript
        try {
            doc.addJavaScript("// PDF JavaScript\nvar docTitle = this.info.Title;")
        } catch (e: Exception) {
            println("  addJavaScript: ${e.message}")
        }

        // Title
        var title = Paragraph("S23: Metadata Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)

        doc.add(Paragraph("This document demonstrates all PDF metadata setting methods.", Font(helvBf, 11.0)))
        doc.add(Paragraph("Open document properties in a PDF viewer to see the metadata.", Font(helvBf, 11.0)))

        doc.add(Paragraph(" ", Font(helvBf, 8.0)))
        doc.add(Paragraph("Metadata Set:", Font(helvBf, 12.0, FontStyle.Bold)))
        doc.add(Paragraph("• Title: S23 Metadata Demo Document", Font(helvBf, 11.0)))
        doc.add(Paragraph("• Author: pdf-cj Test Author", Font(helvBf, 11.0)))
        doc.add(Paragraph("• Subject: Demonstrating PDF metadata features", Font(helvBf, 11.0)))
        doc.add(Paragraph("• Keywords: pdf-cj, metadata, PDF, Cangjie, test", Font(helvBf, 11.0)))
        doc.add(Paragraph("• Creator: S23_Metadata.cj", Font(helvBf, 11.0)))
        doc.add(Paragraph("• Creation Date: (auto-set)", Font(helvBf, 11.0)))
        doc.add(Paragraph("• PDF Version: 1.7", Font(helvBf, 11.0)))
        doc.add(Paragraph("• JavaScript: embedded document script", Font(helvBf, 11.0)))

        doc.add(Paragraph(" ", Font(helvBf, 8.0)))
        doc.add(Paragraph("CJK metadata: 这是包含中文元数据的PDF文档。", Font(cjkBf, 12.0)))
        doc.add(Paragraph("语言: 仓颉编程语言 (Cangjie Programming Language)", Font(cjkBf, 11.0)))

        doc.close()
        println("  S23 PDF saved: ${_s23_OUT}cj_s23_metadata.pdf")

        // Read back and print metadata
        let reader = PdfReader(_s23_OUT + "cj_s23_metadata.pdf")
        println("\n=== Reading back metadata with PdfReader ===")
        println("Number of pages: ${reader.getNumberOfPages()}")
        let pgSize = reader.getPageSize(1i32)
        println("Page size: ${pgSize.width} x ${pgSize.height}")
        println("PDF version: ${reader.getPdfVersion()}")

        let info = reader.getInfo()
        println("\n--- Document Info Dictionary ---")
        for ((key, value) in info) {
            println("  ${key} = ${value}")
        }

        reader.close()
        println("\n  S23 done")
    } catch (e: Exception) {
        println("  ✗ S23: ${e.message}")
    }
}
