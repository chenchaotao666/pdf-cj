/**
 * PdfReader 单元测试
 *
 * 策略：在内存中构造一个最小合法 PDF，通过 PdfReader(data) 构造函数
 * 测试全部公开 API，不依赖磁盘文件。
 *
 * 最小 PDF 结构（字节偏移已预先计算）：
 *   Obj 1 (Catalog)  at offset 9
 *   Obj 2 (Pages)    at offset 58
 *   Obj 3 (Page)     at offset 115
 *   xref section     at offset 186
 */
package pdf_cj.test.reader

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.HashMap
import pdf_cj.reader.{PdfReader, AcroFields}

// 将 ASCII 字符串转为字节数组（复用 tokenizer_test 中的同名辅助逻辑）
func pdfBytes(str: String): Array<UInt8> {
    let arr = Array<UInt8>(str.size, repeat: 0)
    var i = 0
    for (r in str.runes()) {
        arr[i] = UInt8(UInt32(r))
        i += 1
    }
    arr
}

/**
 * 构建最小合法 PDF（单页，MediaBox = [0 0 595 842]，无内容流，无 Info）
 *
 * 预计算字节偏移：
 *   %PDF-1.4\n                                          offset 0  (9 bytes)
 *   1 0 obj\n                                           offset 9  (8 bytes)  → obj1
 *   << /Type /Catalog /Pages 2 0 R >>\n                offset 17 (34 bytes)
 *   endobj\n                                            offset 51 (7 bytes)
 *   2 0 obj\n                                           offset 58 (8 bytes)  → obj2
 *   << /Type /Pages /Kids [3 0 R] /Count 1 >>\n        offset 66 (42 bytes)
 *   endobj\n                                            offset 108(7 bytes)
 *   3 0 obj\n                                           offset 115(8 bytes)  → obj3
 *   << /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R >>\n  offset 123(56 bytes)
 *   endobj\n                                            offset 179(7 bytes)
 *   xref\n...                                           offset 186
 */
func makeMinimalPdf(): Array<UInt8> {
    let src =
        "%PDF-1.4\n" +
        "1 0 obj\n" +
        "<< /Type /Catalog /Pages 2 0 R >>\n" +
        "endobj\n" +
        "2 0 obj\n" +
        "<< /Type /Pages /Kids [3 0 R] /Count 1 >>\n" +
        "endobj\n" +
        "3 0 obj\n" +
        "<< /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R >>\n" +
        "endobj\n" +
        "xref\n" +
        "0 4\n" +
        "0000000000 65535 f \r\n" +
        "0000000009 00000 n \r\n" +
        "0000000058 00000 n \r\n" +
        "0000000115 00000 n \r\n" +
        "trailer\n" +
        "<< /Size 4 /Root 1 0 R >>\n" +
        "startxref\n" +
        "186\n" +
        "%%EOF\n"
    pdfBytes(src)
}

/**
 * 带 Info 字典的 PDF（额外的 obj 4）
 *   Obj 4 (Info)     at offset 186
 *   xref section     at offset 233
 */
func makeMinimalPdfWithInfo(): Array<UInt8> {
    let src =
        "%PDF-1.4\n" +
        "1 0 obj\n" +
        "<< /Type /Catalog /Pages 2 0 R >>\n" +
        "endobj\n" +
        "2 0 obj\n" +
        "<< /Type /Pages /Kids [3 0 R] /Count 1 >>\n" +
        "endobj\n" +
        "3 0 obj\n" +
        "<< /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R >>\n" +
        "endobj\n" +
        "4 0 obj\n" +
        "<< /Title (Test PDF) /Author (Tester) >>\n" +
        "endobj\n" +
        "xref\n" +
        "0 5\n" +
        "0000000000 65535 f \r\n" +
        "0000000009 00000 n \r\n" +
        "0000000058 00000 n \r\n" +
        "0000000115 00000 n \r\n" +
        "0000000186 00000 n \r\n" +
        "trailer\n" +
        "<< /Size 5 /Root 1 0 R /Info 4 0 R >>\n" +
        "startxref\n" +
        "233\n" +
        "%%EOF\n"
    pdfBytes(src)
}

// ===== 基本构造与页数 =====

@Test
public class PdfReaderConstructionTests {

    @TestCase
    func testConstructionNoException(): Unit {
        let data = makeMinimalPdf()
        let reader = PdfReader(data)
        reader.close()
    }

    @TestCase
    func testGetNumberOfPages(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        @Expect(reader.getNumberOfPages(), 1)
        reader.close()
    }

    @TestCase
    func testGetFileName(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        @Expect(reader.getFileName(), "")
        reader.close()
    }
}

// ===== 页面尺寸 =====

@Test
public class PdfReaderPageSizeTests {

    @TestCase
    func testPageSizeWidth(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        let sz = reader.getPageSize(1)
        @Expect(Int32(sz.right), 595)
        reader.close()
    }

    @TestCase
    func testPageSizeHeight(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        let sz = reader.getPageSize(1)
        @Expect(Int32(sz.top), 842)
        reader.close()
    }

    @TestCase
    func testPageSizeOrigin(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        let sz = reader.getPageSize(1)
        @Expect(Int32(sz.left), 0)
        @Expect(Int32(sz.bottom), 0)
        reader.close()
    }

    @TestCase
    func testPageSizeOutOfRange(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        // 越界时返回 A4 缺省尺寸
        let sz = reader.getPageSize(99)
        @Expect(Int32(sz.right), 595)
        reader.close()
    }
}

// ===== 内容流 =====

@Test
public class PdfReaderContentTests {

    @TestCase
    func testGetPageContentEmptyWhenNoStream(): Unit {
        // 最小 PDF 无内容流，应返回空字节数组
        let reader = PdfReader(makeMinimalPdf())
        let content = reader.getPageContent(1)
        @Expect(content.size, 0)
        reader.close()
    }

    @TestCase
    func testSetAndGetPageContent(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        let data = pdfBytes("BT /F1 12 Tf 100 700 Td (Hello) Tj ET")
        reader.setPageContent(1, data)
        let got = reader.getPageContent(1)
        @Expect(got.size, data.size)
        reader.close()
    }

    @TestCase
    func testSetPageContentPreservesBytes(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        let src = pdfBytes("q Q")
        reader.setPageContent(1, src)
        let got = reader.getPageContent(1)
        @Expect(got[0], src[0])
        @Expect(got[1], src[1])
        @Expect(got[2], src[2])
        reader.close()
    }

    @TestCase
    func testSetPageContentOverwrite(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        reader.setPageContent(1, pdfBytes("first"))
        reader.setPageContent(1, pdfBytes("second"))
        let got = reader.getPageContent(1)
        @Expect(got.size, 6)  // "second"
        reader.close()
    }
}

// ===== 文档信息 =====

@Test
public class PdfReaderInfoTests {

    @TestCase
    func testGetInfoEmptyWhenNoInfo(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        let info = reader.getInfo()
        @Expect(info.size, 0)
        reader.close()
    }

    @TestCase
    func testGetInfoCloseDoesNotCrash(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        let _ = reader.getInfo()
        reader.close()
    }
}

// ===== AcroFields =====

@Test
public class PdfReaderAcroFieldsTests {

    @TestCase
    func testGetAcroFieldsNotNull(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        let af = reader.getAcroFields()
        @Expect(af.getFieldCount(), 0)
        reader.close()
    }

    @TestCase
    func testGetAcroFieldsSameInstance(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        let af1 = reader.getAcroFields()
        let af2 = reader.getAcroFields()
        // 同一实例：字段数相同
        @Expect(af1.getFieldCount(), af2.getFieldCount())
        reader.close()
    }
}

// ===== close() =====

@Test
public class PdfReaderCloseTests {

    @TestCase
    func testCloseNoException(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        reader.close()
        // 二次 close 也不应崩溃
        reader.close()
    }

    @TestCase
    func testAfterCloseNumberOfPagesIsZero(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        reader.close()
        @Expect(reader.getNumberOfPages(), 0)
    }
}

// ===== isEncrypted / getPdfVersion =====

@Test
public class PdfReaderMetaTests {

    @TestCase
    func testIsEncryptedFalse(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        @Expect(reader.isEncrypted(), false)
        reader.close()
    }

    @TestCase
    func testGetPdfVersionNotEmpty(): Unit {
        let reader = PdfReader(makeMinimalPdf())
        let ver = reader.getPdfVersion()
        @Expect(ver.size > 0, true)
        reader.close()
    }
}
