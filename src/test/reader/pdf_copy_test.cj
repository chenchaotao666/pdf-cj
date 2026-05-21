/**
 * PdfCopy / PdfSmartCopy 单元测试
 *
 * 策略：用 makeMinimalPdf / makeMultiPagePdf 在内存中构造源 PDF，
 * 将结果写入 PdfByteArrayOutputStream，验证输出字节包含合法 PDF 结构。
 */
package pdf_cj.test.reader

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.reader.{PdfReader, PdfCopy, PdfSmartCopy, PdfImportedPage}
import pdf_cj.base.PdfByteArrayOutputStream
import pdf_cj.api.Document

// ─── 辅助 ──────────────────────────────────────────────────────────────────

func copyBytes(str: String): Array<UInt8> {
    let arr = Array<UInt8>(str.size, repeat: 0)
    var i = 0
    for (r in str.runes()) {
        arr[i] = UInt8(UInt32(r))
        i += 1
    }
    arr
}

func copyPadL10(n: Int64): String {
    var s = "${n}"
    while (s.size < 10) { s = "0" + s }
    s
}

// 单页 PDF（含内容流 "BT ET\n"）
func makeOnePdf(): Array<UInt8> {
    let body = "BT ET\n"  // 6 bytes
    let obj1 = "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
    let obj2 = "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"
    let obj3 = "3 0 obj\n<< /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R /Contents 4 0 R >>\nendobj\n"
    let obj4h = "4 0 obj\n<< /Length 6 >>\nstream\n"
    let obj4t = "endstream\nendobj\n"
    let header = "%PDF-1.4\n"

    let off1: Int64 = Int64(header.size)
    let off2: Int64 = off1 + Int64(obj1.size)
    let off3: Int64 = off2 + Int64(obj2.size)
    let off4: Int64 = off3 + Int64(obj3.size)
    let xrefOff: Int64 = off4 + Int64(obj4h.size) + 6 + Int64(obj4t.size)

    let xref =
        "xref\n0 5\n" +
        "0000000000 65535 f \r\n" +
        copyPadL10(off1) + " 00000 n \r\n" +
        copyPadL10(off2) + " 00000 n \r\n" +
        copyPadL10(off3) + " 00000 n \r\n" +
        copyPadL10(off4) + " 00000 n \r\n" +
        "trailer\n<< /Size 5 /Root 1 0 R >>\n" +
        "startxref\n${xrefOff}\n%%EOF\n"

    copyBytes(header + obj1 + obj2 + obj3 + obj4h + body + obj4t + xref)
}

// 两页 PDF（两页内容流相同）
func makeTwoPdf(): Array<UInt8> {
    let body = "BT ET\n"
    let obj1 = "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
    let obj2 = "2 0 obj\n<< /Type /Pages /Kids [3 0 R 5 0 R] /Count 2 >>\nendobj\n"
    let obj3 = "3 0 obj\n<< /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R /Contents 4 0 R >>\nendobj\n"
    let obj4h = "4 0 obj\n<< /Length 6 >>\nstream\n"
    let obj4t = "endstream\nendobj\n"
    let obj5 = "5 0 obj\n<< /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R /Contents 6 0 R >>\nendobj\n"
    let obj6h = "6 0 obj\n<< /Length 6 >>\nstream\n"
    let obj6t = "endstream\nendobj\n"
    let header = "%PDF-1.4\n"

    let off1: Int64 = Int64(header.size)
    let off2: Int64 = off1 + Int64(obj1.size)
    let off3: Int64 = off2 + Int64(obj2.size)
    let off4: Int64 = off3 + Int64(obj3.size)
    let off5: Int64 = off4 + Int64(obj4h.size) + 6 + Int64(obj4t.size)
    let off6: Int64 = off5 + Int64(obj5.size)
    let xrefOff: Int64 = off6 + Int64(obj6h.size) + 6 + Int64(obj6t.size)

    let xref =
        "xref\n0 7\n" +
        "0000000000 65535 f \r\n" +
        copyPadL10(off1) + " 00000 n \r\n" +
        copyPadL10(off2) + " 00000 n \r\n" +
        copyPadL10(off3) + " 00000 n \r\n" +
        copyPadL10(off4) + " 00000 n \r\n" +
        copyPadL10(off5) + " 00000 n \r\n" +
        copyPadL10(off6) + " 00000 n \r\n" +
        "trailer\n<< /Size 7 /Root 1 0 R >>\n" +
        "startxref\n${xrefOff}\n%%EOF\n"

    copyBytes(header + obj1 + obj2 + obj3 + obj4h + body + obj4t +
              obj5 + obj6h + body + obj6t + xref)
}

func containsString(data: Array<UInt8>, needle: String): Bool {
    let nb = copyBytes(needle)
    if (nb.size == 0 || data.size < nb.size) { return false }
    var i: Int64 = 0
    while (i <= Int64(data.size) - Int64(nb.size)) {
        var match_ = true
        for (j in 0..nb.size) {
            if (data[i + j] != nb[j]) { match_ = false; break }
        }
        if (match_) { return true }
        i += 1
    }
    false
}

func makeDoc(): Document { Document() }

// ===== parseRanges =====

@Test
public class ParseRangesTests {

    @TestCase
    func testSinglePage(): Unit {
        let r = PdfCopy.parseRanges("5")
        @Expect(r.size, 1)
        @Expect(r[0], 5)
    }

    @TestCase
    func testRange(): Unit {
        let r = PdfCopy.parseRanges("1-3")
        @Expect(r.size, 3)
        @Expect(r[0], 1)
        @Expect(r[1], 2)
        @Expect(r[2], 3)
    }

    @TestCase
    func testMixed(): Unit {
        let r = PdfCopy.parseRanges("1-3,5")
        @Expect(r.size, 4)
        @Expect(r[3], 5)
    }

    @TestCase
    func testDedup(): Unit {
        // 重复页码只出现一次
        let r = PdfCopy.parseRanges("1,1,2")
        @Expect(r.size, 2)
    }

    @TestCase
    func testEmpty(): Unit {
        let r = PdfCopy.parseRanges("")
        @Expect(r.size, 0)
    }

    @TestCase
    func testMultiRange(): Unit {
        let r = PdfCopy.parseRanges("1-2,4-5")
        @Expect(r.size, 4)
    }
}

// ===== PdfCopy 基本功能 =====

@Test
public class PdfCopyBasicTests {

    @TestCase
    func testGetImportedPage(): Unit {
        let reader = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        let page = copy.getImportedPage(reader, 1)
        @Expect(page.getPageNumber(), 1)
        reader.close()
    }

    @TestCase
    func testAddPageIncrementsCount(): Unit {
        let reader = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        @Expect(copy.getPageCount(), 0)
        copy.addPage(copy.getImportedPage(reader, 1))
        @Expect(copy.getPageCount(), 1)
        reader.close()
    }

    @TestCase
    func testAddDocumentAddsAllPages(): Unit {
        let reader = PdfReader(makeTwoPdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        copy.addDocument(reader)
        @Expect(copy.getPageCount(), 2)
        reader.close()
    }

    @TestCase
    func testSelectPagesAddsChosenPages(): Unit {
        let reader = PdfReader(makeTwoPdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        copy.selectPages(reader, "1")
        @Expect(copy.getPageCount(), 1)
        reader.close()
    }

    @TestCase
    func testSelectPagesRange(): Unit {
        let reader = PdfReader(makeTwoPdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        copy.selectPages(reader, "1-2")
        @Expect(copy.getPageCount(), 2)
        reader.close()
    }
}

// ===== PdfCopy close() 输出验证 =====

@Test
public class PdfCopyCloseTests {

    @TestCase
    func testCloseProducesOutput(): Unit {
        let reader = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        copy.addDocument(reader)
        copy.close()
        @Expect(os.position > 0, true)
        reader.close()
    }

    @TestCase
    func testCloseOutputHasPdfHeader(): Unit {
        let reader = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        copy.addDocument(reader)
        copy.close()
        let data = os.toByteArray()
        @Expect(containsString(data, "%PDF-"), true)
        reader.close()
    }

    @TestCase
    func testCloseOutputHasEof(): Unit {
        let reader = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        copy.addDocument(reader)
        copy.close()
        let data = os.toByteArray()
        @Expect(containsString(data, "%%EOF"), true)
        reader.close()
    }

    @TestCase
    func testCloseOutputHasCatalog(): Unit {
        let reader = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        copy.addDocument(reader)
        copy.close()
        let data = os.toByteArray()
        @Expect(containsString(data, "/Catalog"), true)
        reader.close()
    }

    @TestCase
    func testCloseTwiceNoException(): Unit {
        let reader = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        copy.addDocument(reader)
        copy.close()
        copy.close()
        @Expect(copy.isClosed(), true)
        reader.close()
    }

    @TestCase
    func testMergeMultipleSources(): Unit {
        let r1 = PdfReader(makeOnePdf())
        let r2 = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        copy.addDocument(r1)
        copy.addDocument(r2)
        @Expect(copy.getPageCount(), 2)
        copy.close()
        let data = os.toByteArray()
        @Expect(containsString(data, "%%EOF"), true)
        r1.close()
        r2.close()
    }
}

// ===== PdfImportedPage =====

@Test
public class PdfImportedPageTests {

    @TestCase
    func testGetWidth(): Unit {
        let reader = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        let page = copy.getImportedPage(reader, 1)
        @Expect(Int32(page.getWidth()), 595)
        reader.close()
    }

    @TestCase
    func testGetHeight(): Unit {
        let reader = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        let page = copy.getImportedPage(reader, 1)
        @Expect(Int32(page.getHeight()), 842)
        reader.close()
    }

    @TestCase
    func testGetContent(): Unit {
        let reader = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        let page = copy.getImportedPage(reader, 1)
        let content = page.getContent()
        @Expect(content.size > 0, true)
        reader.close()
    }

    @TestCase
    func testGetMediaBox(): Unit {
        let reader = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let copy = PdfCopy(makeDoc(), os)
        let page = copy.getImportedPage(reader, 1)
        match (page.getMediaBox()) {
            case Some(box) => @Expect(Int32(box.right), 595)
            case None => @Expect(true, false)
        }
        reader.close()
    }
}

// ===== PdfSmartCopy 去重 =====

@Test
public class PdfSmartCopyTests {

    @TestCase
    func testAddPage(): Unit {
        let reader = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let smart = PdfSmartCopy(makeDoc(), os)
        smart.addPage(smart.getImportedPage(reader, 1))
        @Expect(smart.getPageCount(), 1)
        reader.close()
    }

    @TestCase
    func testDedupSameContent(): Unit {
        // 两页内容相同 → 只写一份内容流
        let reader = PdfReader(makeTwoPdf())
        let os = PdfByteArrayOutputStream()
        let smart = PdfSmartCopy(makeDoc(), os)
        smart.addDocument(reader)
        @Expect(smart.getPageCount(), 2)
        @Expect(smart.getDedupedContentCount(), 1)  // 去重后只有1份内容流
        reader.close()
    }

    @TestCase
    func testDedupDifferentContent(): Unit {
        let r1 = PdfReader(makeOnePdf())
        let r2 = PdfReader(makeOnePdf())
        // 修改 r2 的第1页内容，使其与 r1 不同
        r2.setPageContent(1, copyBytes("q Q"))
        let os = PdfByteArrayOutputStream()
        let smart = PdfSmartCopy(makeDoc(), os)
        smart.addPage(smart.getImportedPage(r1, 1))
        smart.addPage(smart.getImportedPage(r2, 1))
        @Expect(smart.getDedupedContentCount(), 2)  // 内容不同，各写一份
        r1.close()
        r2.close()
    }

    @TestCase
    func testSmartCloseProducesValidPdf(): Unit {
        let reader = PdfReader(makeTwoPdf())
        let os = PdfByteArrayOutputStream()
        let smart = PdfSmartCopy(makeDoc(), os)
        smart.addDocument(reader)
        smart.close()
        let data = os.toByteArray()
        @Expect(containsString(data, "%PDF-"), true)
        @Expect(containsString(data, "%%EOF"), true)
        reader.close()
    }

    @TestCase
    func testSmartCloseNoException(): Unit {
        let reader = PdfReader(makeOnePdf())
        let os = PdfByteArrayOutputStream()
        let smart = PdfSmartCopy(makeDoc(), os)
        smart.addDocument(reader)
        smart.close()
        smart.close()  // 二次 close 不崩溃
        @Expect(smart.isClosed(), true)
        reader.close()
    }

    @TestCase
    func testSelectPages(): Unit {
        let reader = PdfReader(makeTwoPdf())
        let os = PdfByteArrayOutputStream()
        let smart = PdfSmartCopy(makeDoc(), os)
        smart.selectPages(reader, "1")
        @Expect(smart.getPageCount(), 1)
        reader.close()
    }
}
