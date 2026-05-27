package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.form.PdfFormFieldFactory
import pdf_cj.reader.{PdfReader, PdfStamper}
import pdf_cj.base.PdfFileOutputStream
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let _s17_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s17_OUT  = "output/"



// Create a simple 3-page source PDF
func s17CreateSourcePdf(): Unit {
    let helvBf = newHelvBf()
    let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
    let file = File(Path(_s17_OUT + "cj_s17_source.pdf"), OpenMode.Write)
    let writer = PdfWriter.getInstance(doc, file)
    doc.open()

    for (i in 1..4) {
        if (i > 1) {
            doc.newPage()
        }
        var p = Paragraph("Source PDF — Page ${i}", Font(helvBf, 18.0, FontStyle.Bold))
        p.setAlignment(Alignment.Center)
        doc.add(p)
        doc.add(Paragraph("This is page ${i} of the source document.", Font(helvBf, 12.0)))
        doc.add(Paragraph("Content: Lorem ipsum dolor sit amet, consectetur adipiscing elit.", Font(helvBf, 11.0)))
        doc.add(Paragraph("Page ${i} of 3", Font(helvBf, 10.0)))
    }
    doc.close()
}

// Create a form PDF with text fields
func s17CreateFormPdf(): Unit {
    let helvBf = newHelvBf()
    let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
    let file = File(Path(_s17_OUT + "cj_s17_form.pdf"), OpenMode.Write)
    let formWriter = PdfWriter.getInstance(doc, file)
    doc.open()

    doc.add(Paragraph("Form PDF", Font(helvBf, 18.0, FontStyle.Bold)))
    doc.add(Paragraph("Please fill in the fields below:", Font(helvBf, 12.0)))

    var y: Float32 = 680.0
    let labels = ["Name", "Email", "Company"]
    for (label in labels) {
        doc.add(Paragraph(label + ":", Font(helvBf, 11.0)))
        let tf = PdfFormFieldFactory.createTextField(label.toAsciiLower(), 200.0, y - 20.0, 280.0, 20.0)
        tf.setValue("")
        tf.generateAppearance()
        formWriter.addFormField(tf)
        y -= 40.0
    }
    doc.close()
}

func s17_readerStamper(): Unit {
    println("S17: Reader & Stamper Demo")
    let helvBf = newHelvBf()
    try {
        // Step 1: Create source PDF
        s17CreateSourcePdf()
        println("  Step 1: Source PDF created")

        // Step 2: Open with PdfReader, add watermark with PdfStamper
        try {
            let reader = PdfReader(_s17_OUT + "cj_s17_source.pdf")
            let outFile = File(Path(_s17_OUT + "cj_s17_reader_stamper.pdf"), OpenMode.Write)
            let stamper = PdfStamper(reader, PdfFileOutputStream(outFile))

            let numPages = reader.getNumberOfPages()
            println("  Source PDF pages: ${numPages}")
            let pg1Size = reader.getPageSize(1i32)
            println("  Page 1 size: ${pg1Size.width} x ${pg1Size.height}")

            // Add watermark to each page
            for (page in 1..(numPages + 1)) {
                // Over content (on top)
                let over = stamper.getOverContent(Int32(page))
                over.saveState()
                over.beginText()
                over.setFontAndSize("Helvetica", 60.0)
                over.setColorFill(Color(220, 0, 0))
                over.showTextAligned(PdfContentByte.ALIGN_CENTER, "WATERMARK", 297.0, 421.0, 45.0)
                over.endText()
                over.restoreState()

                // Under content (background)
                let under = stamper.getUnderContent(Int32(page))
                under.saveState()
                under.setColorFill(Color(240, 248, 255))
                under.rectangle(0.0, 0.0, 595.0, 842.0)
                under.fill()
                under.restoreState()

                // Page label
                over.beginText()
                over.setFontAndSize("Helvetica", 9.0)
                over.setColorFill(Color(80, 80, 80))
                over.setTextMatrix(72.0, 20.0)
                over.showText("Stamped — Page ${page} of ${numPages}")
                over.endText()
            }

            stamper.close()
            reader.close()
            println("  Step 2: Watermarked PDF created: ${_s17_OUT}cj_s17_reader_stamper.pdf")
        } catch (e: Exception) {
            println("  Step 2 error: ${e.message}")
        }

        // Step 3: Create form PDF
        s17CreateFormPdf()
        println("  Step 3: Form PDF created")

        // Step 4: Fill form with AcroFields
        try {
            let formReader = PdfReader(_s17_OUT + "cj_s17_form.pdf")
            let formFile = File(Path(_s17_OUT + "cj_s17_form_filled.pdf"), OpenMode.Write)
            let formStamper = PdfStamper(formReader, PdfFileOutputStream(formFile))

            let acroFields = formStamper.getAcroFields()
            try { _ = acroFields.setField("name", "张三 Jane Doe") } catch (e: Exception) { println("  name field: ${e.message}") }
            try { _ = acroFields.setField("email", "jane@example.com") } catch (e: Exception) { println("  email field: ${e.message}") }
            try { _ = acroFields.setField("company", "pdf-cj Corp") } catch (e: Exception) { println("  company field: ${e.message}") }

            formStamper.close()
            formReader.close()
            println("  Step 4: Form filled: ${_s17_OUT}cj_s17_form_filled.pdf")
        } catch (e: Exception) {
            println("  Step 4 error: ${e.message}")
        }

        println("  S17 done")
    } catch (e: Exception) {
        println("  ✗ S17: ${e.message}")
    }
}
