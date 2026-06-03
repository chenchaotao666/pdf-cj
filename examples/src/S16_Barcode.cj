package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.barcode.{Barcode128, BarcodeEAN, Barcode39, BarcodePDF417, BarcodeDatamatrix}
import pdf_cj.text.{Font, FontStyle, Color, Alignment}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let _s16_OUT = "output/"

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

        // 1. DataMatrix
        try {
            doc.add(Paragraph("1. DataMatrix Barcode (BarcodeDatamatrix):", Font(helvBf, 12.0)))
            let dm = BarcodeDatamatrix()
            dm.generate("pdf-cj 0.1.0")
            let dmImg = dm.createImage()
            dmImg.scaleAbsolute(100.0, 100.0)
            dmImg.setAlignment(Alignment.Left)
            dmImg.setSpacingBefore(4.0)
            dmImg.setSpacingAfter(10.0)
            doc.add(dmImg)
        } catch (e: Exception) {
            doc.add(Paragraph("1. DataMatrix error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 2. Code-128
        try {
            doc.add(Paragraph("2. Code-128:", Font(helvBf, 12.0)))
            let code128 = Barcode128("pdf-cj-0.1.0")
            code128.barHeight = 40.0
            code128.moduleWidth = 0.8
            let img = code128.createFlowImage(Color(0, 0, 0))
            img.setAlignment(Alignment.Left)
            img.setSpacingBefore(4.0)
            img.setSpacingAfter(2.0)
            doc.add(img)
            let lbl2 = Paragraph("pdf-cj-0.1.0", Font(helvBf, 8.0))
            lbl2.setAlignment(Alignment.Left)
            lbl2.setSpacingAfter(10.0)
            doc.add(lbl2)
        } catch (e: Exception) {
            doc.add(Paragraph("2. Code-128 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 3. Code-39
        try {
            doc.add(Paragraph("3. Code-39:", Font(helvBf, 12.0)))
            let code39 = Barcode39("PDF-CJ")
            code39.barHeight = 40.0
            code39.moduleWidth = 0.8
            let img = code39.createFlowImage(Color(0, 0, 0))
            img.setAlignment(Alignment.Left)
            img.setSpacingBefore(4.0)
            img.setSpacingAfter(2.0)
            doc.add(img)
            let lbl3 = Paragraph("*PDF-CJ*", Font(helvBf, 8.0))
            lbl3.setAlignment(Alignment.Left)
            lbl3.setSpacingAfter(10.0)
            doc.add(lbl3)
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
            img.setSpacingAfter(2.0)
            doc.add(img)
            let lbl4 = Paragraph("9781234567897", Font(helvBf, 8.0))
            lbl4.setAlignment(Alignment.Left)
            lbl4.setSpacingAfter(10.0)
            doc.add(lbl4)
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
            img.setSpacingAfter(2.0)
            doc.add(img)
            let lbl5 = Paragraph("12345670", Font(helvBf, 8.0))
            lbl5.setAlignment(Alignment.Left)
            lbl5.setSpacingAfter(10.0)
            doc.add(lbl5)
        } catch (e: Exception) {
            doc.add(Paragraph("5. EAN-8 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 6. PDF417
        try {
            doc.add(Paragraph("6. PDF417:", Font(helvBf, 12.0)))
            let pdf417 = BarcodePDF417("pdf-cj 0.1.0 PDF417 barcode demonstration")
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
            colorBarcode.moduleWidth = 0.8
            let img = colorBarcode.createFlowImage(Color(0, 0, 255), Color(255, 0, 0))
            img.setAlignment(Alignment.Left)
            img.setSpacingBefore(4.0)
            img.setSpacingAfter(2.0)
            doc.add(img)
            let lbl7 = Paragraph("COLOR-DEMO", Font(helvBf, 8.0))
            lbl7.setAlignment(Alignment.Left)
            lbl7.setSpacingAfter(10.0)
            doc.add(lbl7)
        } catch (e: Exception) {
            doc.add(Paragraph("7. Colored barcode error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 8. UPC-A — page 2 (matches Java layout)
        doc.newPage()
        // (encoded as EAN-13 with leading 0: "0" + "012345678905" → "0012345678905")
        try {
            doc.add(Paragraph("8. UPC-A:", Font(helvBf, 12.0)))
            let upca = BarcodeEAN("0012345678905")
            upca.barHeight = 60.0
            let img = upca.createFlowImage(Color(0, 0, 0))
            img.setAlignment(Alignment.Left)
            img.setSpacingBefore(4.0)
            img.setSpacingAfter(2.0)
            doc.add(img)
            let lbl8 = Paragraph("0012345678905", Font(helvBf, 8.0))
            lbl8.setAlignment(Alignment.Left)
            lbl8.setSpacingAfter(10.0)
            doc.add(lbl8)
        } catch (e: Exception) {
            doc.add(Paragraph("8. UPC-A error: ${e.message}", Font(helvBf, 10.0)))
        }

        doc.close()
        println("  S16 done: ${_s16_OUT}cj_s16_barcode.pdf")
    } catch (e: Exception) {
        println("  ✗ S16: ${e.message}")
    }
}
