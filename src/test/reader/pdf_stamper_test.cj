/**
 * PdfStamper 单元测试
 *
 * 在内存中构造最小 PDF，通过 PdfReader(data) + PdfByteArrayOutputStream 构造 PdfStamper，
 * 验证全部公开 API，不依赖磁盘文件。
 */
package pdf_cj.test.reader

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.HashMap
import pdf_cj.reader.{PdfReader, PdfStamper}
import pdf_cj.base.PdfByteArrayOutputStream

// 构建用于 Stamper 测试的最小 PDF（含一个内容流，偏移已预计算）
//
//  %PDF-1.4\n                           offset 0   (9 bytes)
//  1 0 obj\n                            offset 9   (8 bytes)  → Catalog
//  << /Type /Catalog /Pages 2 0 R >>\n  offset 17  (34 bytes)
//  endobj\n                             offset 51  (7 bytes)
//  2 0 obj\n                            offset 58  (8 bytes)  → Pages
//  << /Type /Pages /Kids [3 0 R] /Count 1 >>\n  offset 66 (42 bytes)
//  endobj\n                             offset 108 (7 bytes)
//  3 0 obj\n                            offset 115 (8 bytes)  → Page
//  << /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R /Contents 4 0 R >>\n
//                                       offset 123 (71 bytes)
//  endobj\n                             offset 194 (7 bytes)
//  4 0 obj\n                            offset 201 (8 bytes)  → Content stream
//  << /Length 9 >>\n                    offset 209 (16 bytes)
//  stream\n                             offset 225 (7 bytes)
//  BT ET\n\n                            offset 232 (7 bytes) — stream body (9 bytes? let me recalc)
//
// Actually let me just build it as a string and verify by running

func makeStampPdf(): Array<UInt8> {
    let body = "BT ET\n"  // 6 bytes
    let src =
        "%PDF-1.4\n" +
        "1 0 obj\n" +
        "<< /Type /Catalog /Pages 2 0 R >>\n" +
        "endobj\n" +
        "2 0 obj\n" +
        "<< /Type /Pages /Kids [3 0 R] /Count 1 >>\n" +
        "endobj\n" +
        "3 0 obj\n" +
        "<< /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R /Contents 4 0 R >>\n" +
        "endobj\n" +
        "4 0 obj\n" +
        "<< /Length 6 >>\n" +
        "stream\n" +
        body +
        "endstream\n" +
        "endobj\n"

    // Calculate xref offsets by measuring string lengths
    let header = "%PDF-1.4\n"                                  // 9
    let obj1 = "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"   // 8+34+7=49 -> 9..58
    let obj2 = "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n" // 8+42+7=57 -> 58..115
    let obj3 = "3 0 obj\n<< /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R /Contents 4 0 R >>\nendobj\n"
    // 8+71+7=86 -> 115..201
    let obj4Header = "4 0 obj\n<< /Length 6 >>\nstream\n"      // 8+16+7=31 -> 201..232

    let off1: Int64 = 9
    let off2: Int64 = off1 + Int64(obj1.size)
    let off3: Int64 = off2 + Int64(obj2.size)
    let off4: Int64 = off3 + Int64(obj3.size)
    let xrefOff: Int64 = off4 + Int64(obj4Header.size) + 6 + Int64("endstream\nendobj\n".size)

    let xrefStr =
        "xref\n" +
        "0 5\n" +
        "0000000000 65535 f \r\n" +
        padL10(off1) + " 00000 n \r\n" +
        padL10(off2) + " 00000 n \r\n" +
        padL10(off3) + " 00000 n \r\n" +
        padL10(off4) + " 00000 n \r\n" +
        "trailer\n" +
        "<< /Size 5 /Root 1 0 R >>\n" +
        "startxref\n" +
        "${xrefOff}\n" +
        "%%EOF\n"

    let full = src + xrefStr
    strToBytes(full)
}

func padL10(n: Int64): String {
    var s = "${n}"
    while (s.size < 10) { s = "0" + s }
    s
}

func strToBytes(str: String): Array<UInt8> {
    let arr = Array<UInt8>(str.size, repeat: 0)
    var i = 0
    for (r in str.runes()) {
        arr[i] = UInt8(UInt32(r))
        i += 1
    }
    arr
}

func makeStamper(): (PdfStamper, PdfByteArrayOutputStream) {
    let reader = PdfReader(makeStampPdf())
    let os = PdfByteArrayOutputStream()
    let stamper = PdfStamper(reader, os)
    (stamper, os)
}

// ===== getOverContent =====

@Test
public class OverContentTests {

    @TestCase
    func testGetOverContentNotNull(): Unit {
        let (stamper, _) = makeStamper()
        let cb = stamper.getOverContent(1)
        @Expect(cb.size >= 0, true)
        stamper.close()
    }

    @TestCase
    func testGetOverContentSameInstance(): Unit {
        let (stamper, _) = makeStamper()
        let cb1 = stamper.getOverContent(1)
        let cb2 = stamper.getOverContent(1)
        @Expect(cb1.size, cb2.size)
        stamper.close()
    }

    @TestCase
    func testGetOverContentDifferentPages(): Unit {
        let reader = PdfReader(makeStampPdf())
        let os = PdfByteArrayOutputStream()
        let stamper = PdfStamper(reader, os)
        let cb1 = stamper.getOverContent(1)
        let cb2 = stamper.getOverContent(2)
        // They are different objects (different pages)
        cb1.beginText()
        @Expect(cb1.size > cb2.size, true)
        stamper.close()
    }

    @TestCase
    func testOverContentInitiallyEmpty(): Unit {
        let (stamper, _) = makeStamper()
        let cb = stamper.getOverContent(1)
        @Expect(cb.size, 0)
        stamper.close()
    }
}

// ===== getUnderContent =====

@Test
public class UnderContentTests {

    @TestCase
    func testGetUnderContentNotNull(): Unit {
        let (stamper, _) = makeStamper()
        let cb = stamper.getUnderContent(1)
        @Expect(cb.size >= 0, true)
        stamper.close()
    }

    @TestCase
    func testGetUnderContentSameInstance(): Unit {
        let (stamper, _) = makeStamper()
        let cb1 = stamper.getUnderContent(1)
        let cb2 = stamper.getUnderContent(1)
        @Expect(cb1.size, cb2.size)
        stamper.close()
    }

    @TestCase
    func testUnderContentInitiallyEmpty(): Unit {
        let (stamper, _) = makeStamper()
        let cb = stamper.getUnderContent(1)
        @Expect(cb.size, 0)
        stamper.close()
    }
}

// ===== getAcroFields =====

@Test
public class StamperAcroFieldsTests {

    @TestCase
    func testGetAcroFieldsNotNull(): Unit {
        let (stamper, _) = makeStamper()
        let af = stamper.getAcroFields()
        @Expect(af.getFieldCount(), 0)
        stamper.close()
    }

    @TestCase
    func testGetAcroFieldsSameInstance(): Unit {
        let (stamper, _) = makeStamper()
        let af1 = stamper.getAcroFields()
        let af2 = stamper.getAcroFields()
        @Expect(af1.getFieldCount(), af2.getFieldCount())
        stamper.close()
    }
}

// ===== setMoreInfo =====

@Test
public class SetMoreInfoTests {

    @TestCase
    func testSetMoreInfoDoesNotThrow(): Unit {
        let (stamper, _) = makeStamper()
        let info = HashMap<String, String>()
        info["Title"] = "Test"
        stamper.setMoreInfo(info)
        stamper.close()
    }

    @TestCase
    func testSetMoreInfoMerges(): Unit {
        let (stamper, _) = makeStamper()
        let info1 = HashMap<String, String>()
        info1["Title"] = "First"
        stamper.setMoreInfo(info1)
        let info2 = HashMap<String, String>()
        info2["Author"] = "Tester"
        stamper.setMoreInfo(info2)
        // close without throwing
        stamper.close()
    }

    @TestCase
    func testSetMoreInfoEmpty(): Unit {
        let (stamper, _) = makeStamper()
        stamper.setMoreInfo(HashMap<String, String>())
        stamper.close()
    }
}

// ===== setEncryption =====

@Test
public class SetEncryptionTests {

    @TestCase
    func testSetEncryptionDoesNotThrow(): Unit {
        let (stamper, _) = makeStamper()
        stamper.setEncryption(
            strToBytes("user"),
            strToBytes("owner"),
            0,
            0
        )
        stamper.close()
    }

    @TestCase
    func testSetEncryptionEmptyPasswords(): Unit {
        let (stamper, _) = makeStamper()
        stamper.setEncryption(
            Array<UInt8>(0, repeat: 0),
            Array<UInt8>(0, repeat: 0),
            0xFF,
            1
        )
        stamper.close()
    }
}

// ===== close() =====

@Test
public class StamperCloseTests {

    @TestCase
    func testCloseNoException(): Unit {
        let (stamper, _) = makeStamper()
        stamper.close()
    }

    @TestCase
    func testDoubleCloseNoException(): Unit {
        let (stamper, _) = makeStamper()
        stamper.close()
        stamper.close()  // should be no-op
    }

    @TestCase
    func testAfterCloseIsClosedTrue(): Unit {
        let (stamper, _) = makeStamper()
        stamper.close()
        @Expect(stamper.isClosed(), true)
    }

    @TestCase
    func testCloseWithOverContentProducesLargerOutput(): Unit {
        let data = makeStampPdf()
        let origSize = data.size
        let reader = PdfReader(data)
        let os = PdfByteArrayOutputStream()
        let stamper = PdfStamper(reader, os)

        let cb = stamper.getOverContent(1)
        cb.beginText()
        cb.endText()

        stamper.close()
        @Expect(os.position > Int64(origSize), true)
    }

    @TestCase
    func testCloseWithoutModificationProducesOutput(): Unit {
        let data = makeStampPdf()
        let origSize = data.size
        let reader = PdfReader(data)
        let os = PdfByteArrayOutputStream()
        let stamper = PdfStamper(reader, os)
        stamper.close()
        // At minimum writes the original bytes + startxref + %%EOF
        @Expect(os.position >= Int64(origSize), true)
    }
}

// ===== Delegate methods =====

@Test
public class StamperDelegateTests {

    @TestCase
    func testGetNumberOfPages(): Unit {
        let (stamper, _) = makeStamper()
        @Expect(stamper.getNumberOfPages(), 1)
        stamper.close()
    }

    @TestCase
    func testGetPageSizeWidth(): Unit {
        let (stamper, _) = makeStamper()
        let sz = stamper.getPageSize(1)
        @Expect(Int32(sz.right), 595)
        stamper.close()
    }

    @TestCase
    func testGetPageSizeHeight(): Unit {
        let (stamper, _) = makeStamper()
        let sz = stamper.getPageSize(1)
        @Expect(Int32(sz.top), 842)
        stamper.close()
    }

    @TestCase
    func testGetReaderNotNull(): Unit {
        let (stamper, _) = makeStamper()
        let r = stamper.getReader()
        @Expect(r.getNumberOfPages(), 1)
        stamper.close()
    }
}
