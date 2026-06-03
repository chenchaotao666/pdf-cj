package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.reader.{PdfReader, TextExtractor}
import pdf_cj.text.{Font, FontStyle}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let _s19_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s19_OUT  = "output/"



// Create source PDF with known text content
func s19CreateSourcePdf(): Unit {
    let helvBf = newHelvBf()
    let cjkBf = newCjkBf()
    let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
    let file = File(Path(_s19_OUT + "cj_s19_text_extract.pdf"), OpenMode.Write)
    let w = PdfWriter.getInstance(doc, file)
    w.setPdfVersion("1.7")
    doc.addTitle("S19 Text Extract Source")
    doc.addAuthor("pdf-cj Test")
    doc.addSubject("Text extraction test document")
    doc.addKeywords("test, extraction, pdf-cj")
    doc.open()

    doc.add(Paragraph("S19: Text Extraction Source PDF", Font(helvBf, 18.0, FontStyle.Bold)))
    doc.add(Paragraph("Page 1 of 2", Font(helvBf, 12.0)))
    doc.add(Paragraph("Known text line 1: The quick brown fox jumps over the lazy dog.", Font(helvBf, 11.0)))
    doc.add(Paragraph("Known text line 2: Pack my box with five dozen liquor jugs.", Font(helvBf, 11.0)))
    doc.add(Paragraph("Known text line 3: 中文文字提取测试内容。", Font(cjkBf, 11.0)))
    doc.add(Paragraph("Numbers: 1234567890", Font(helvBf, 11.0)))
    doc.add(Paragraph("Special: !@#$%^&*()_+", Font(helvBf, 11.0)))

    doc.newPage()
    doc.add(Paragraph("Page 2 of 2", Font(helvBf, 14.0, FontStyle.Bold)))
    doc.add(Paragraph("Second page content for extraction.", Font(helvBf, 11.0)))

    doc.close()
}

func s19_textExtract(): Unit {
    println("S19: Text Extract Demo")
    try {
        // Create source PDF
        s19CreateSourcePdf()
        println("  Source PDF saved: ${_s19_OUT}cj_s19_text_extract.pdf")

        // Read it with PdfReader
        let reader = PdfReader(_s19_OUT + "cj_s19_text_extract.pdf")

        println("\n=== PdfReader Info ===")
        println("Number of pages: ${reader.getNumberOfPages()}")
        let pg1 = reader.getPageSize(1i32)
        println("Page 1 size: ${pg1.width} x ${pg1.height}")
        let pg2 = reader.getPageSize(2i32)
        println("Page 2 size: ${pg2.width} x ${pg2.height}")
        println("PDF version: ${reader.getPdfVersion()}")

        // Get document info
        let info = reader.getInfo()
        println("\n=== Document Info (reader.getInfo()) ===")
        for ((key, value) in info) {
            println("  ${key}: ${value}")
        }

        // Text extraction
        println("\n=== Text Extraction ===")
        try {
            let page1Text = TextExtractor.extractPage(reader, 1i32)
            println("  Page 1 extracted text (first 200 chars):")
            let limit = if (page1Text.size > 200) { 200 } else { page1Text.size }
            println("  ${page1Text[0..limit]}")
        } catch (e: Exception) {
            println("  Page 1 extraction: ${e.message}")
        }

        try {
            let page2Text = TextExtractor.extractPage(reader, 2i32)
            println("  Page 2 extracted text (first 200 chars):")
            let limit2 = if (page2Text.size > 200) { 200 } else { page2Text.size }
            println("  ${page2Text[0..limit2]}")
        } catch (e: Exception) {
            println("  Page 2 extraction: ${e.message}")
        }

        try {
            let allText = TextExtractor.extractAll(reader)
            println("  All pages text length: ${allText.size} chars")
        } catch (e: Exception) {
            println("  extractAll: ${e.message}")
        }

        reader.close()
        println("\n  S19 done")
    } catch (e: Exception) {
        println("  ✗ S19: ${e.message}")
    }
}
