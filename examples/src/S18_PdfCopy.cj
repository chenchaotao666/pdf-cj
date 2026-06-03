package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.reader.{PdfReader, PdfCopy, PdfSmartCopy}
import pdf_cj.base.PdfFileOutputStream
import pdf_cj.image.Image
import pdf_cj.text.{Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize}
import std.fs.{File, OpenMode, Path}

let _s18_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s18_IMG  = "images/"
let _s18_OUT  = "output/"



func s18CreatePdfA(): Unit {
    let helvBf = newHelvBf()
    let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
    let file = File(Path(_s18_OUT + "cj_s18_source_a.pdf"), OpenMode.Write)
    PdfWriter.getInstance(doc, file)
    doc.open()
    for (i in 1..4) {
        if (i > 1) { doc.newPage() }
        var p = Paragraph("PDF-A: Page ${i}", Font(helvBf, 20.0, FontStyle.Bold))
        p.setAlignment(Alignment.Center)
        doc.add(p)
        doc.add(Paragraph("Document A, page ${i} of 3.", Font(helvBf, 12.0)))
        doc.add(Paragraph("Content: The quick brown fox jumps over the lazy dog.", Font(helvBf, 11.0)))
        if (i == 1) {
            try {
                let img = Image.getInstance(_s18_IMG + "mountain.png")
                img.scaleAbsolute(100.0, 70.0)
                doc.add(img)
            } catch (e: Exception) {}
        }
    }
    doc.close()
}

func s18CreatePdfB(): Unit {
    let helvBf = newHelvBf()
    let cjkBf = newCjkBf()
    let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
    let file = File(Path(_s18_OUT + "cj_s18_source_b.pdf"), OpenMode.Write)
    PdfWriter.getInstance(doc, file)
    doc.open()
    for (i in 1..3) {
        if (i > 1) { doc.newPage() }
        var p = Paragraph("PDF-B: Page ${i}", Font(helvBf, 20.0, FontStyle.Bold, Color(0, 0, 200)))
        p.setAlignment(Alignment.Center)
        doc.add(p)
        doc.add(Paragraph("Document B, page ${i} of 2.", Font(helvBf, 12.0)))
        doc.add(Paragraph("CJK: 这是文档B第${i}页。", Font(cjkBf, 12.0)))
        if (i == 1) {
            try {
                let img = Image.getInstance(_s18_IMG + "mountain.png")
                img.scaleAbsolute(100.0, 70.0)
                doc.add(img)
            } catch (e: Exception) {}
        }
    }
    doc.close()
}

func s18_pdfCopy(): Unit {
    println("S18: PdfCopy Demo")
    try {
        // Create source PDFs
        s18CreatePdfA()
        s18CreatePdfB()
        println("  Source PDFs created")

        let readerAInfo = PdfReader(_s18_OUT + "cj_s18_source_a.pdf")
        let readerBInfo = PdfReader(_s18_OUT + "cj_s18_source_b.pdf")
        println("  PDF-A: ${readerAInfo.getNumberOfPages()} pages")
        println("  PDF-B: ${readerBInfo.getNumberOfPages()} pages")
        readerAInfo.close()
        readerBInfo.close()

        // ---- Part 1: Merge all pages with PdfCopy ----
        try {
            let mergedDoc = Document()
            let mergedFile = File(Path(_s18_OUT + "cj_s18_copy_merged.pdf"), OpenMode.Write)
            let copy = PdfCopy(mergedDoc, PdfFileOutputStream(mergedFile))
            mergedDoc.open()

            let readerA = PdfReader(_s18_OUT + "cj_s18_source_a.pdf")
            let pagesA = readerA.getNumberOfPages()
            for (p in 1..(pagesA + 1)) {
                copy.addPage(copy.getImportedPage(readerA, Int32(p)))
            }
            println("  Added PDF-A: ${pagesA} pages")
            readerA.close()

            let readerB = PdfReader(_s18_OUT + "cj_s18_source_b.pdf")
            let pagesB = readerB.getNumberOfPages()
            for (p in 1..(pagesB + 1)) {
                copy.addPage(copy.getImportedPage(readerB, Int32(p)))
            }
            println("  Added PDF-B: ${pagesB} pages")
            readerB.close()

            mergedDoc.close()
            println("  Merged PDF: ${_s18_OUT}cj_s18_copy_merged.pdf")
        } catch (e: Exception) {
            println("  PdfCopy merge error: ${e.message}")
        }

        // ---- Part 2: Page selection (pages 1,3 from A) ----
        try {
            let selDoc = Document()
            let selFile = File(Path(_s18_OUT + "cj_s18_selected_pages.pdf"), OpenMode.Write)
            let selCopy = PdfCopy(selDoc, PdfFileOutputStream(selFile))
            selDoc.open()

            let readerA2 = PdfReader(_s18_OUT + "cj_s18_source_a.pdf")
            selCopy.selectPages(readerA2, "1,3")
            selCopy.close()
            readerA2.close()
            selDoc.close()
            println("  Selected pages (1,3) of PDF-A: ${_s18_OUT}cj_s18_selected_pages.pdf")
        } catch (e: Exception) {
            println("  Page selection error: ${e.message}")
        }

        // ---- Part 3: PdfSmartCopy (dedup resources) ----
        try {
            let smartDoc = Document()
            let smartFile = File(Path(_s18_OUT + "cj_s18_smart_copy.pdf"), OpenMode.Write)
            let smartCopy = PdfSmartCopy(smartDoc, PdfFileOutputStream(smartFile))
            smartDoc.open()

            let readerA3 = PdfReader(_s18_OUT + "cj_s18_source_a.pdf")
            let spA = readerA3.getNumberOfPages()
            for (p in 1..(spA + 1)) {
                smartCopy.addPage(smartCopy.getImportedPage(readerA3, Int32(p)))
            }
            readerA3.close()

            let readerB3 = PdfReader(_s18_OUT + "cj_s18_source_b.pdf")
            let spB = readerB3.getNumberOfPages()
            for (p in 1..(spB + 1)) {
                smartCopy.addPage(smartCopy.getImportedPage(readerB3, Int32(p)))
            }
            readerB3.close()

            smartDoc.close()
            println("  Smart copy PDF: ${_s18_OUT}cj_s18_smart_copy.pdf")
        } catch (e: Exception) {
            println("  PdfSmartCopy error: ${e.message}")
        }

        // ---- Part 4: Copy individual pages ----
        try {
            let readerA4 = PdfReader(_s18_OUT + "cj_s18_source_a.pdf")
            let readerB4 = PdfReader(_s18_OUT + "cj_s18_source_b.pdf")
            let indivDoc = Document()
            let indivFile = File(Path(_s18_OUT + "cj_s18_individual_pages.pdf"), OpenMode.Write)
            let indivCopy = PdfCopy(indivDoc, PdfFileOutputStream(indivFile))
            indivDoc.open()

            // Copy page 2 from A, page 1 from B, page 3 from A
            indivCopy.addPage(indivCopy.getImportedPage(readerA4, 2))
            indivCopy.addPage(indivCopy.getImportedPage(readerB4, 1))
            indivCopy.addPage(indivCopy.getImportedPage(readerA4, 3))

            readerA4.close()
            readerB4.close()
            indivDoc.close()
            println("  Individual pages copy: ${_s18_OUT}cj_s18_individual_pages.pdf")
        } catch (e: Exception) {
            println("  Individual pages error: ${e.message}")
        }

        println("  S18 done")
    } catch (e: Exception) {
        println("  ✗ S18: ${e.message}")
    }
}
