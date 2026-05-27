package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.barcode.{Barcode128, BarcodeEAN, Barcode39, BarcodeQRCode, BarcodePDF417}
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

        let cb = writer.getDirectContent()

        var title = Paragraph("S16: Barcode Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)

        // 1. Barcode128
        try {
            doc.add(Paragraph("1. Code-128:", Font(helvBf, 12.0)))
            let bc128 = Barcode128("OpenPDF-2.0.3")
            bc128.x = 72.0
            bc128.y = 700.0
            bc128.barHeight = 40.0
            bc128.moduleWidth = 1.5
            bc128.createImage(cb, Color(0, 0, 0), Color(0, 0, 0))
            doc.add(Paragraph(" ", Font(helvBf, 50.0)))
        } catch (e: Exception) {
            doc.add(Paragraph("1. Code-128 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 2. BarcodeEAN (EAN-13)
        try {
            doc.add(Paragraph("2. EAN-13:", Font(helvBf, 12.0)))
            let ean = BarcodeEAN("9781234567897")
            ean.x = 72.0
            ean.y = 620.0
            ean.barHeight = 60.0
            ean.moduleWidth = 2.0
            ean.createImage(cb, Color(0, 0, 0), Color(0, 0, 0))
            doc.add(Paragraph(" ", Font(helvBf, 70.0)))
        } catch (e: Exception) {
            doc.add(Paragraph("2. EAN-13 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 3. Barcode39
        try {
            doc.add(Paragraph("3. Code-39:", Font(helvBf, 12.0)))
            let bc39 = Barcode39("OPENPDF")
            bc39.x = 72.0
            bc39.y = 530.0
            bc39.barHeight = 40.0
            bc39.moduleWidth = 1.5
            bc39.createImage(cb, Color(0, 0, 0), Color(0, 0, 0))
            doc.add(Paragraph(" ", Font(helvBf, 50.0)))
        } catch (e: Exception) {
            doc.add(Paragraph("3. Code-39 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 4. QR Code
        try {
            doc.add(Paragraph("4. QR Code:", Font(helvBf, 12.0)))
            let qr = BarcodeQRCode("https://github.com/LibrePDF/OpenPDF")
            let qrImg = qr.createImage(cb, Color(0, 0, 0), Color(255, 255, 255))
            qrImg.setAbsolutePosition(72.0, 290.0)
            doc.add(qrImg)
            doc.add(Paragraph(" ", Font(helvBf, 180.0)))
        } catch (e: Exception) {
            doc.add(Paragraph("4. QR Code error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 5. PDF417
        try {
            doc.add(Paragraph("5. PDF417:", Font(helvBf, 12.0)))
            let pdf417 = BarcodePDF417("OpenPDF 2.0.3 PDF417 barcode demonstration")
            pdf417.x = 72.0
            pdf417.y = 200.0
            pdf417.createImage(cb, Color(0, 0, 0), Color(255, 255, 255))
            doc.add(Paragraph(" ", Font(helvBf, 30.0)))
        } catch (e: Exception) {
            doc.add(Paragraph("5. PDF417 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 6. Barcode128 with custom colors (blue bars)
        doc.newPage()
        try {
            doc.add(Paragraph("6. Code-128 with custom colors (blue bars):", Font(helvBf, 12.0)))
            let colorBc = Barcode128("COLOR-DEMO")
            colorBc.x = 72.0
            colorBc.y = 760.0
            colorBc.barHeight = 40.0
            colorBc.moduleWidth = 2.0
            colorBc.createImage(cb, Color(0, 0, 200), Color(200, 0, 0))
            doc.add(Paragraph(" ", Font(helvBf, 50.0)))
        } catch (e: Exception) {
            doc.add(Paragraph("6. Colored barcode error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 7. CJK QR Code
        try {
            doc.add(Paragraph("7. QR Code with CJK content:", Font(helvBf, 12.0)))
            let qrCjk = BarcodeQRCode("这是仓颉PDF库的二维码测试")
            let qrCjkImg = qrCjk.createImage(cb, Color(0, 0, 0), Color(255, 255, 255))
            qrCjkImg.setAbsolutePosition(72.0, 580.0)
            doc.add(qrCjkImg)
        } catch (e: Exception) {
            doc.add(Paragraph("7. CJK QR Code error: ${e.message}", Font(helvBf, 10.0)))
        }

        doc.close()
        println("  S16 done: ${_s16_OUT}cj_s16_barcode.pdf")
    } catch (e: Exception) {
        println("  ✗ S16: ${e.message}")
    }
}
