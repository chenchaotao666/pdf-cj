package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.barcode.{Barcode128, BarcodeEAN, Barcode39, BarcodePDF417}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let _s16_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s16_OUT  = "output/"



func s16_barcode(): Unit {
    println("S16: Barcode Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s16_OUT + "cj_s16_barcode.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        var title = Paragraph("S16: Barcode Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)

        // 1. DataMatrix (not available in pdf-cj)
        doc.add(Paragraph("1. DataMatrix Barcode (BarcodeDatamatrix):", Font(helvBf, 12.0)))
        doc.add(Paragraph("1. DataMatrix error: BarcodeDatamatrix not available in pdf-cj", Font(helvBf, 10.0)))

        // 2. Code-128
        try {
            doc.add(Paragraph("2. Code-128:", Font(helvBf, 12.0)))
            let code128 = Barcode128("OpenPDF-2.0.3")
            code128.barHeight = 40.0
            let img = code128.createFlowImage(Color(0, 0, 0))
            img.setAlignment(Alignment.Left)
            img.setSpacingBefore(4.0)
            img.setSpacingAfter(10.0)
            doc.add(img)
        } catch (e: Exception) {
            doc.add(Paragraph("2. Code-128 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 3. Code-39
        try {
            doc.add(Paragraph("3. Code-39:", Font(helvBf, 12.0)))
            let code39 = Barcode39("OPENPDF")
            code39.barHeight = 40.0
            let img = code39.createFlowImage(Color(0, 0, 0))
            img.setAlignment(Alignment.Left)
            img.setSpacingBefore(4.0)
            img.setSpacingAfter(10.0)
            doc.add(img)
        } catch (e: Exception) {
            doc.add(Paragraph("3. Code-39 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 4. EAN-13
        try {
            doc.add(Paragraph("4. EAN-13:", Font(helvBf, 12.0)))
            let ean = BarcodeEAN("9781234567897")
            ean.barHeight = 60.0
            let img = ean.createFlowImage(Color(0, 0, 0))
            img.setAlignment(Alignment.Left)
            img.setSpacingBefore(4.0)
            img.setSpacingAfter(10.0)
            doc.add(img)
        } catch (e: Exception) {
            doc.add(Paragraph("4. EAN-13 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 5. EAN-8
        try {
            doc.add(Paragraph("5. EAN-8:", Font(helvBf, 12.0)))
            let ean8 = BarcodeEAN("12345670")
            ean8.isEAN8 = true
            ean8.barHeight = 50.0
            let img = ean8.createFlowImage(Color(0, 0, 0))
            img.setAlignment(Alignment.Left)
            img.setSpacingBefore(4.0)
            img.setSpacingAfter(10.0)
            doc.add(img)
        } catch (e: Exception) {
            doc.add(Paragraph("5. EAN-8 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 6. PDF417
        try {
            doc.add(Paragraph("6. PDF417:", Font(helvBf, 12.0)))
            let pdf417 = BarcodePDF417("OpenPDF 2.0.3 PDF417 barcode demonstration")
            let img = pdf417.createFlowImage(Color(0, 0, 0), 300.0, 80.0)
            img.setAlignment(Alignment.Left)
            img.setSpacingBefore(4.0)
            img.setSpacingAfter(10.0)
            doc.add(img)
        } catch (e: Exception) {
            doc.add(Paragraph("6. PDF417 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 7. Code-128 with custom colors (blue bars, red text)
        try {
            doc.add(Paragraph("7. Code-128 with custom colors (blue bars, red text):", Font(helvBf, 12.0)))
            let colorBarcode = Barcode128("COLOR-DEMO")
            colorBarcode.barHeight = 40.0
            let img = colorBarcode.createFlowImage(Color(0, 0, 255))
            img.setAlignment(Alignment.Left)
            img.setSpacingBefore(4.0)
            img.setSpacingAfter(10.0)
            doc.add(img)
        } catch (e: Exception) {
            doc.add(Paragraph("7. Colored barcode error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 8. UPC-A (approximated as EAN-13 with leading 0)
        try {
            doc.add(Paragraph("8. UPC-A:", Font(helvBf, 12.0)))
            let upca = BarcodeEAN("001234567890")
            upca.barHeight = 60.0
            let img = upca.createFlowImage(Color(0, 0, 0))
            img.setAlignment(Alignment.Left)
            img.setSpacingBefore(4.0)
            img.setSpacingAfter(10.0)
            doc.add(img)
        } catch (e: Exception) {
            doc.add(Paragraph("8. UPC-A error: ${e.message}", Font(helvBf, 10.0)))
        }

        doc.close()
        println("  S16 done: ${_s16_OUT}cj_s16_barcode.pdf")
    } catch (e: Exception) {
        println("  ✗ S16: ${e.message}")
    }
}
