/**
 * 条形码单元测试（Phase 5.1）
 * 覆盖：Code 128, EAN-13/8, Code 39, QR Code, PDF417
 */
package pdf_cj.test.barcode

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.barcode.{
    Barcode128, BarcodeEAN, Barcode39,
    BarcodeQRCode, BarcodePDF417
}
import pdf_cj.core.PdfContentByte
import pdf_cj.text.Color

// ─── 辅助 ────────────────────────────────────────────────────────────────────

func cbStr(cb: PdfContentByte): String {
    let bytes = cb.toByteArray()
    var s = ""
    for (b in bytes) { s += String(Rune(UInt32(b))) }
    s
}

// ═══════════════════════════════════════════════════════════════════════════
// Barcode128 测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class Barcode128Tests {

    @TestCase
    func testDefaultProperties(): Unit {
        let b = Barcode128()
        @Expect(b.code, "")
        @Expect(b.barHeight, 30.0)
        @Expect(b.moduleWidth, 1.5)
    }

    @TestCase
    func testInitWithCode(): Unit {
        let b = Barcode128("HELLO")
        @Expect(b.code, "HELLO")
    }

    @TestCase
    func testGetBarcodeWidthNonZero(): Unit {
        let b = Barcode128("ABC")
        @Expect(b.getBarcodeWidth() > 0.0, true)
    }

    @TestCase
    func testGetBarcodeWidthLongerCode(): Unit {
        let b1 = Barcode128("A")
        let b2 = Barcode128("ABCDEFGH")
        @Expect(b2.getBarcodeWidth() > b1.getBarcodeWidth(), true)
    }

    @TestCase
    func testCreateImageReturnsImage(): Unit {
        let b = Barcode128("TEST")
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainWidth > 0.0, true)
        @Expect(img.plainHeight > 0.0, true)
    }

    @TestCase
    func testCreateImageRendersContent(): Unit {
        let b = Barcode128("A")
        b.x = 10.0
        b.y = 100.0
        let cb = PdfContentByte()
        b.createImage(cb, Color.BLACK, Color.BLACK)
        let content = cbStr(cb)
        @Expect(content.size > 0, true)
        @Expect(content.contains("rg"), true)   // setColorFill
        @Expect(content.contains(" re\n"), true) // rectangle
        @Expect(content.contains("f\n"), true)   // fill
    }

    @TestCase
    func testNumericDigits(): Unit {
        let b = Barcode128("0123456789")
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainWidth > 0.0, true)
    }

    @TestCase
    func testSpecialChars(): Unit {
        let b = Barcode128("Hello World!")
        @Expect(b.getBarcodeWidth() > 0.0, true)
    }

    @TestCase
    func testWidthIncludesStartStopCheck(): Unit {
        let b = Barcode128("")
        // 即使空字符串也有起始/校验/终止符
        @Expect(b.getBarcodeWidth() > 0.0, true)
    }

    @TestCase
    func testCustomHeight(): Unit {
        let b = Barcode128("X")
        b.barHeight = 50.0
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainHeight > 0.0, true)
    }

    @TestCase
    func testCustomModuleWidth(): Unit {
        let b1 = Barcode128("A")
        let w1 = b1.getBarcodeWidth()
        let b2 = Barcode128("A")
        b2.moduleWidth = 3.0
        let w2 = b2.getBarcodeWidth()
        @Expect(w2 > w1, true)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// BarcodeEAN 测试（EAN-13）
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class BarcodeEANTests {

    @TestCase
    func testDefaultProperties(): Unit {
        let b = BarcodeEAN()
        @Expect(b.isEAN8, false)
        @Expect(b.barHeight, 30.0)
    }

    @TestCase
    func testInitWithCode(): Unit {
        let b = BarcodeEAN("978020137962")
        @Expect(b.code, "978020137962")
    }

    @TestCase
    func testEAN13CreateImage(): Unit {
        let b = BarcodeEAN("978020137962")
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainWidth > 0.0, true)
        @Expect(img.plainHeight > 0.0, true)
    }

    @TestCase
    func testEAN13RendersContent(): Unit {
        let b = BarcodeEAN("978020137962")
        let cb = PdfContentByte()
        b.createImage(cb, Color.BLACK, Color.BLACK)
        let content = cbStr(cb)
        @Expect(content.contains("rg"), true)
        @Expect(content.contains(" re\n"), true)
    }

    @TestCase
    func testEAN8CreateImage(): Unit {
        let b = BarcodeEAN("9638507")
        b.isEAN8 = true
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainWidth > 0.0, true)
    }

    @TestCase
    func testEAN13CheckDigitAuto(): Unit {
        // EAN-13 checksum for "978020137962" → check = 4
        // Just verify it creates without error
        let b = BarcodeEAN("978020137962")
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainWidth > 0.0, true)
    }

    @TestCase
    func testEAN8CheckDigitAuto(): Unit {
        let b = BarcodeEAN("9638507")
        b.isEAN8 = true
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainWidth > 0.0, true)
    }

    @TestCase
    func testEAN13WiderThanEAN8(): Unit {
        let b13 = BarcodeEAN("978020137962")
        let b8  = BarcodeEAN("9638507")
        b8.isEAN8 = true
        let cb1 = PdfContentByte()
        let cb2 = PdfContentByte()
        let img13 = b13.createImage(cb1, Color.BLACK, Color.BLACK)
        let img8  = b8.createImage(cb2, Color.BLACK, Color.BLACK)
        @Expect(img13.plainWidth > img8.plainWidth, true)
    }

    @TestCase
    func testPositionSetting(): Unit {
        let b = BarcodeEAN("123456789012")
        b.x = 30.0
        b.y = 200.0
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.absoluteX, 30.0)
        @Expect(img.absoluteY, 200.0)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// Barcode39 测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class Barcode39Tests {

    @TestCase
    func testDefaultProperties(): Unit {
        let b = Barcode39()
        @Expect(b.code, "")
        @Expect(b.moduleWidth, 1.2)
        @Expect(b.interCharGap, 1)
    }

    @TestCase
    func testInitWithCode(): Unit {
        let b = Barcode39("HELLO")
        @Expect(b.code, "HELLO")
    }

    @TestCase
    func testCreateImageNonZero(): Unit {
        let b = Barcode39("CODE39")
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainWidth > 0.0, true)
        @Expect(img.plainHeight > 0.0, true)
    }

    @TestCase
    func testRendersContent(): Unit {
        let b = Barcode39("A")
        let cb = PdfContentByte()
        b.createImage(cb, Color.BLACK, Color.BLACK)
        let content = cbStr(cb)
        @Expect(content.contains("rg"), true)
        @Expect(content.contains(" re\n"), true)
        @Expect(content.contains("f\n"), true)
    }

    @TestCase
    func testLowerCaseConverted(): Unit {
        let b1 = Barcode39("ABC")
        let b2 = Barcode39("abc")
        let cb1 = PdfContentByte()
        let cb2 = PdfContentByte()
        let img1 = b1.createImage(cb1, Color.BLACK, Color.BLACK)
        let img2 = b2.createImage(cb2, Color.BLACK, Color.BLACK)
        // 大小写应生成相同宽度
        @Expect(img1.plainWidth, img2.plainWidth)
    }

    @TestCase
    func testNumericCode(): Unit {
        let b = Barcode39("12345")
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainWidth > 0.0, true)
    }

    @TestCase
    func testSpecialChars(): Unit {
        let b = Barcode39("-. $/+%")
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainWidth > 0.0, true)
    }

    @TestCase
    func testLongerCodeIsWider(): Unit {
        let b1 = Barcode39("A")
        let b2 = Barcode39("ABCDEF")
        let cb1 = PdfContentByte()
        let cb2 = PdfContentByte()
        let img1 = b1.createImage(cb1, Color.BLACK, Color.BLACK)
        let img2 = b2.createImage(cb2, Color.BLACK, Color.BLACK)
        @Expect(img2.plainWidth > img1.plainWidth, true)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// BarcodeQRCode 测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class BarcodeQRCodeTests {

    @TestCase
    func testDefaultProperties(): Unit {
        let b = BarcodeQRCode()
        @Expect(b.code, "")
        @Expect(b.moduleSize, 3.0)
        @Expect(b.quietZone, 4)
    }

    @TestCase
    func testInitWithCode(): Unit {
        let b = BarcodeQRCode("HELLO QR")
        @Expect(b.code, "HELLO QR")
    }

    @TestCase
    func testCreateImageShortCode(): Unit {
        let b = BarcodeQRCode("Hi")
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainWidth > 0.0, true)
        @Expect(img.plainHeight > 0.0, true)
    }

    @TestCase
    func testCreateImageRendersContent(): Unit {
        let b = BarcodeQRCode("QR")
        let cb = PdfContentByte()
        b.createImage(cb, Color.BLACK, Color.BLACK)
        let content = cbStr(cb)
        @Expect(content.size > 0, true)
        @Expect(content.contains(" re\n"), true)
    }

    @TestCase
    func testSquareImage(): Unit {
        let b = BarcodeQRCode("TEST")
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainWidth, img.plainHeight)
    }

    @TestCase
    func testVersion1Size(): Unit {
        // Version 1: 21 modules + 2*4 quiet = 29 modules × 3.0pt = 87pt
        let b = BarcodeQRCode("Hi")
        b.moduleSize = 3.0
        b.quietZone = 4
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        // (21 + 8) * 3 = 87, but +1 for image, so 88
        @Expect(img.plainWidth >= 87.0, true)
    }

    @TestCase
    func testCustomModuleSize(): Unit {
        let b1 = BarcodeQRCode("A")
        b1.moduleSize = 2.0
        let b2 = BarcodeQRCode("A")
        b2.moduleSize = 4.0
        let cb1 = PdfContentByte()
        let cb2 = PdfContentByte()
        let img1 = b1.createImage(cb1, Color.BLACK, Color.BLACK)
        let img2 = b2.createImage(cb2, Color.BLACK, Color.BLACK)
        @Expect(img2.plainWidth > img1.plainWidth, true)
    }

    @TestCase
    func testLongerCodeUsesHigherVersion(): Unit {
        let b1 = BarcodeQRCode("Hi")
        let b2 = BarcodeQRCode("This is a longer string that needs more QR modules to encode")
        let cb1 = PdfContentByte()
        let cb2 = PdfContentByte()
        let img1 = b1.createImage(cb1, Color.BLACK, Color.BLACK)
        let img2 = b2.createImage(cb2, Color.BLACK, Color.BLACK)
        @Expect(img2.plainWidth >= img1.plainWidth, true)
    }

    @TestCase
    func testPositionSetting(): Unit {
        let b = BarcodeQRCode("X")
        b.x = 100.0
        b.y = 300.0
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.absoluteX, 100.0)
        @Expect(img.absoluteY, 300.0)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// BarcodePDF417 测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class BarcodePDF417Tests {

    @TestCase
    func testDefaultProperties(): Unit {
        let b = BarcodePDF417()
        @Expect(b.code, "")
        @Expect(b.columns, 5)
        @Expect(b.rowHeight, 4.0)
        @Expect(b.moduleWidth, 1.0)
    }

    @TestCase
    func testInitWithCode(): Unit {
        let b = BarcodePDF417("Hello PDF417")
        @Expect(b.code, "Hello PDF417")
    }

    @TestCase
    func testCreateImageNonZero(): Unit {
        let b = BarcodePDF417("Test")
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainWidth > 0.0, true)
        @Expect(img.plainHeight > 0.0, true)
    }

    @TestCase
    func testRendersContent(): Unit {
        let b = BarcodePDF417("Data")
        let cb = PdfContentByte()
        b.createImage(cb, Color.BLACK, Color.BLACK)
        let content = cbStr(cb)
        @Expect(content.size > 0, true)
        @Expect(content.contains(" re\n"), true)
    }

    @TestCase
    func testPositionSetting(): Unit {
        let b = BarcodePDF417("X")
        b.x = 20.0
        b.y = 150.0
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.absoluteX, 20.0)
        @Expect(img.absoluteY, 150.0)
    }

    @TestCase
    func testCustomColumns(): Unit {
        let b1 = BarcodePDF417("Hello World")
        b1.columns = 3
        let b2 = BarcodePDF417("Hello World")
        b2.columns = 8
        let cb1 = PdfContentByte()
        let cb2 = PdfContentByte()
        let img1 = b1.createImage(cb1, Color.BLACK, Color.BLACK)
        let img2 = b2.createImage(cb2, Color.BLACK, Color.BLACK)
        // 更多列 = 更宽
        @Expect(img2.plainWidth > img1.plainWidth, true)
    }

    @TestCase
    func testCustomRowHeight(): Unit {
        let b = BarcodePDF417("Test")
        b.rowHeight = 8.0
        let cb = PdfContentByte()
        let img = b.createImage(cb, Color.BLACK, Color.BLACK)
        @Expect(img.plainHeight > 0.0, true)
    }

    @TestCase
    func testLongerDataMoreRows(): Unit {
        let b1 = BarcodePDF417("A")
        let b2 = BarcodePDF417("This is a much longer string that should result in more rows")
        let cb1 = PdfContentByte()
        let cb2 = PdfContentByte()
        let img1 = b1.createImage(cb1, Color.BLACK, Color.BLACK)
        let img2 = b2.createImage(cb2, Color.BLACK, Color.BLACK)
        @Expect(img2.plainHeight >= img1.plainHeight, true)
    }
}
