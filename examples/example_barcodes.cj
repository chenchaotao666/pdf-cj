/**
 * PDF-CJ 条形码示例（Phase 5.1）
 *
 * 演示五种条形码：
 *   1. Code 128 B
 *   2. EAN-13 / EAN-8
 *   3. Code 39
 *   4. QR Code
 *   5. PDF417
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.barcode.{Barcode128, BarcodeEAN, Barcode39, BarcodeQRCode, BarcodePDF417}
import pdf_cj.text.{BaseFont, Font, Color}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_BC = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_BASE_FONT_BC: BaseFont = BaseFont.createFont(NOTO_CJK_BC, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)

func cjkFontBC(size: Float32): Font {
    Font(CJK_BASE_FONT_BC, size)
}

// ─── 场景 1：线性条形码（Code 128, EAN, Code 39）────────────────────────────

public func exampleLinearBarcodes(): Unit {
    println("\n场景 1：线性条形码...")
    try {
        let doc = Document(PageSize.A4)
        let file = File(Path("output/example_linear_barcodes.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        let labelFont = cjkFontBC(10.0)
        let titleFont = cjkFontBC(14.0)

        doc.add(Paragraph("线性条形码示例", titleFont))
        doc.add(Paragraph(" ", cjkFontBC(6.0)))

        let cb = writer.getDirectContent()

        // ── Code 128 B ──────────────────────────────────────────────────────
        doc.add(Paragraph("Code 128 B：", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(4.0)))

        var yPos = writer.currentY - 35.0

        let bc128 = Barcode128("PDF-CJ 2025")
        bc128.x = 50.0
        bc128.y = yPos
        bc128.barHeight = 28.0
        bc128.moduleWidth = 1.6
        bc128.createImage(cb, Color.BLACK, Color.BLACK)

        doc.add(Paragraph(" ", cjkFontBC(40.0)))
        doc.add(Paragraph("  内容：PDF-CJ 2025", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(6.0)))

        // ── EAN-13 ──────────────────────────────────────────────────────────
        doc.add(Paragraph("EAN-13：", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(4.0)))

        yPos = writer.currentY - 35.0

        let ean13 = BarcodeEAN("978020137962")
        ean13.x = 50.0
        ean13.y = yPos
        ean13.barHeight = 28.0
        ean13.moduleWidth = 1.8
        ean13.createImage(cb, Color.BLACK, Color.BLACK)

        doc.add(Paragraph(" ", cjkFontBC(40.0)))
        doc.add(Paragraph("  ISBN：9-780-20-137962-4", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(6.0)))

        // ── EAN-8 ───────────────────────────────────────────────────────────
        doc.add(Paragraph("EAN-8：", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(4.0)))

        yPos = writer.currentY - 35.0

        let ean8 = BarcodeEAN("9638507")
        ean8.isEAN8 = true
        ean8.x = 50.0
        ean8.y = yPos
        ean8.barHeight = 28.0
        ean8.moduleWidth = 1.8
        ean8.createImage(cb, Color.DARK_GRAY, Color.BLACK)

        doc.add(Paragraph(" ", cjkFontBC(40.0)))
        doc.add(Paragraph("  EAN-8：96385070", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(6.0)))

        // ── Code 39 ─────────────────────────────────────────────────────────
        doc.add(Paragraph("Code 39：", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(4.0)))

        yPos = writer.currentY - 35.0

        let bc39 = Barcode39("PRODUCT-2025")
        bc39.x = 50.0
        bc39.y = yPos
        bc39.barHeight = 28.0
        bc39.moduleWidth = 1.2
        bc39.createImage(cb, Color.BLACK, Color.BLACK)

        doc.add(Paragraph(" ", cjkFontBC(40.0)))
        doc.add(Paragraph("  内容：PRODUCT-2025", labelFont))

        doc.close()
        file.close()
        println("✓ 场景 1 完成 → output/example_linear_barcodes.pdf")
    } catch (e: Exception) {
        println("✗ 场景 1 错误: ${e.message}")
    }
}

// ─── 场景 2：QR Code ────────────────────────────────────────────────────────

public func exampleQRCode(): Unit {
    println("\n场景 2：QR Code...")
    try {
        let doc = Document(PageSize.A4)
        let file = File(Path("output/example_qrcode.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        let labelFont = cjkFontBC(10.0)
        let titleFont = cjkFontBC(14.0)

        doc.add(Paragraph("QR Code 示例", titleFont))
        doc.add(Paragraph(" ", cjkFontBC(6.0)))

        let cb = writer.getDirectContent()

        // QR 码 1：短文本
        doc.add(Paragraph("Version 1（短文本）：", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(4.0)))

        var yPos = writer.currentY - 70.0

        let qr1 = BarcodeQRCode("Hi!")
        qr1.x = 50.0
        qr1.y = yPos
        qr1.moduleSize = 3.0
        qr1.quietZone = 4
        qr1.createImage(cb, Color.BLACK, Color.BLACK)

        doc.add(Paragraph(" ", cjkFontBC(80.0)))
        doc.add(Paragraph("  内容：Hi!", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(8.0)))

        // QR 码 2：URL
        doc.add(Paragraph("Version 3（URL）：", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(4.0)))

        yPos = writer.currentY - 90.0

        let qr2 = BarcodeQRCode("https://gitcode.com/pdf-cj")
        qr2.x = 50.0
        qr2.y = yPos
        qr2.moduleSize = 3.0
        qr2.createImage(cb, Color.BLACK, Color.BLACK)

        doc.add(Paragraph(" ", cjkFontBC(100.0)))
        doc.add(Paragraph("  内容：https://gitcode.com/pdf-cj", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(8.0)))

        // QR 码 3：中文
        doc.add(Paragraph("Version 5（中文）：", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(4.0)))

        yPos = writer.currentY - 100.0

        let qr3 = BarcodeQRCode("仓颉 PDF 库")
        qr3.x = 50.0
        qr3.y = yPos
        qr3.moduleSize = 3.0
        qr3.createImage(cb, Color.BLUE, Color.BLACK)

        doc.add(Paragraph(" ", cjkFontBC(110.0)))
        doc.add(Paragraph("  内容：仓颉 PDF 库（蓝色模块）", labelFont))

        doc.close()
        file.close()
        println("✓ 场景 2 完成 → output/example_qrcode.pdf")
    } catch (e: Exception) {
        println("✗ 场景 2 错误: ${e.message}")
    }
}

// ─── 场景 3：PDF417 ─────────────────────────────────────────────────────────

public func examplePDF417(): Unit {
    println("\n场景 3：PDF417...")
    try {
        let doc = Document(PageSize.A4)
        let file = File(Path("output/example_pdf417.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        let labelFont = cjkFontBC(10.0)
        let titleFont = cjkFontBC(14.0)

        doc.add(Paragraph("PDF417 条形码示例", titleFont))
        doc.add(Paragraph(" ", cjkFontBC(6.0)))

        let cb = writer.getDirectContent()

        // PDF417 - 短文本
        doc.add(Paragraph("短文本（5 列）：", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(4.0)))

        var yPos = writer.currentY - 40.0

        let p1 = BarcodePDF417("Hello PDF417")
        p1.x = 50.0
        p1.y = yPos
        p1.columns = 5
        p1.rowHeight = 4.0
        p1.moduleWidth = 1.0
        p1.createImage(cb, Color.BLACK, Color.BLACK)

        doc.add(Paragraph(" ", cjkFontBC(50.0)))
        doc.add(Paragraph("  内容：Hello PDF417", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(8.0)))

        // PDF417 - 长文本
        doc.add(Paragraph("长文本（8 列）：", labelFont))
        doc.add(Paragraph(" ", cjkFontBC(4.0)))

        yPos = writer.currentY - 50.0

        let p2 = BarcodePDF417("PDF417 is a stacked linear barcode format. It can encode large amounts of data.")
        p2.x = 50.0
        p2.y = yPos
        p2.columns = 8
        p2.rowHeight = 4.0
        p2.moduleWidth = 1.0
        p2.createImage(cb, Color.DARK_GRAY, Color.BLACK)

        doc.add(Paragraph(" ", cjkFontBC(60.0)))
        doc.add(Paragraph("  内容：PDF417 is a stacked linear barcode...", labelFont))

        doc.close()
        file.close()
        println("✓ 场景 3 完成 → output/example_pdf417.pdf")
    } catch (e: Exception) {
        println("✗ 场景 3 错误: ${e.message}")
    }
}

// ─── 主函数 ─────────────────────────────────────────────────────────────────

main(): Int64 {
    println("=== PDF-CJ 条形码示例 ===")

    exampleLinearBarcodes()
    exampleQRCode()
    examplePDF417()

    println("\n=== 完成 ===")
    println("请检查 output/ 目录：")
    println("  example_linear_barcodes.pdf — Code 128 / EAN-13 / EAN-8 / Code 39")
    println("  example_qrcode.pdf          — QR Code（3 个不同版本）")
    println("  example_pdf417.pdf          — PDF417（2 种列数）")
    0
}
