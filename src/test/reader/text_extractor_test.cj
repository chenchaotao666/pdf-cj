/**
 * ContentStreamParser / TextExtractor 单元测试
 *
 * 直接向 ContentStreamParser.parse() 传入内容流字节，无需磁盘 PDF 文件。
 * 集成测试通过内存构造最小 PDF，验证 TextExtractor.extractPage()。
 */
package pdf_cj.test.reader

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.ArrayList
import pdf_cj.reader.{ContentStreamParser, TextFragment, TextExtractor, PdfReader}

// ─── 辅助函数 ─────────────────────────────────────────────────────────────────

func teBytes(s: String): Array<UInt8> {
    let arr = Array<UInt8>(s.size, repeat: 0)
    var i = 0
    for (r in s.runes()) { arr[i] = UInt8(UInt32(r)); i += 1 }
    arr
}

func tePad10(n: Int64): String {
    var s = "${n}"
    while (s.size < 10) { s = "0" + s }
    s
}

// 构造内存 PDF（单页，内含两段文本）
func makeExtractPdf(): Array<UInt8> {
    let body = "BT\n/Helvetica 12 Tf\n1 0 0 1 100 700 Tm\n(Hello PDF) Tj\nET\n" +
               "BT\n/Helvetica 12 Tf\n1 0 0 1 100 650 Tm\n(World) Tj\nET\n"
    let bodyLen = body.size
    let header = "%PDF-1.4\n"
    let obj1 = "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
    let obj2 = "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"
    let obj3 = "3 0 obj\n<< /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R" +
               " /Contents 4 0 R /Resources << /ProcSet [/PDF /Text] >> >>\nendobj\n"
    let obj4h = "4 0 obj\n<< /Length ${bodyLen} >>\nstream\n"
    let obj4t = "endstream\nendobj\n"
    let off1 = Int64(header.size)
    let off2 = off1 + Int64(obj1.size)
    let off3 = off2 + Int64(obj2.size)
    let off4 = off3 + Int64(obj3.size)
    let xrefOff = off4 + Int64(obj4h.size) + Int64(bodyLen) + Int64(obj4t.size)
    let xref =
        "xref\n0 5\n" +
        "0000000000 65535 f \r\n" +
        tePad10(off1) + " 00000 n \r\n" +
        tePad10(off2) + " 00000 n \r\n" +
        tePad10(off3) + " 00000 n \r\n" +
        tePad10(off4) + " 00000 n \r\n" +
        "trailer\n<< /Size 5 /Root 1 0 R >>\n" +
        "startxref\n${xrefOff}\n%%EOF\n"
    teBytes(header + obj1 + obj2 + obj3 + obj4h + body + obj4t + xref)
}

// ===== Tj 操作符 =====

@Test
public class TjTests {

    @TestCase
    func testSimpleTj(): Unit {
        let frags = ContentStreamParser.parse(teBytes("BT\n(Hello) Tj\nET\n"))
        @Expect(frags.size, 1)
        @Expect(frags[0].text == "Hello", true)
    }

    @TestCase
    func testTjDefaultPosition(): Unit {
        let frags = ContentStreamParser.parse(teBytes("BT\n(text) Tj\nET\n"))
        @Expect(frags.size, 1)
        @Expect(Int32(frags[0].x), 0)
        @Expect(Int32(frags[0].y), 0)
    }

    @TestCase
    func testTjDefaultFontSize(): Unit {
        let frags = ContentStreamParser.parse(teBytes("BT\n(text) Tj\nET\n"))
        @Expect(frags.size, 1)
        @Expect(Int32(frags[0].fontSize), 12)
    }

    @TestCase
    func testTjOutsideBtIgnored(): Unit {
        // Tj 在 BT/ET 块外应被忽略
        let frags = ContentStreamParser.parse(teBytes("(should ignore) Tj\n"))
        @Expect(frags.size, 0)
    }

    @TestCase
    func testTjEmptyStringIgnored(): Unit {
        let frags = ContentStreamParser.parse(teBytes("BT\n() Tj\nET\n"))
        @Expect(frags.size, 0)
    }
}

// ===== Tf 操作符 =====

@Test
public class TfTests {

    @TestCase
    func testTfSetsFontName(): Unit {
        let frags = ContentStreamParser.parse(
            teBytes("BT\n/Helvetica-Bold 36 Tf\n(text) Tj\nET\n"))
        @Expect(frags.size, 1)
        @Expect(frags[0].fontName == "Helvetica-Bold", true)
    }

    @TestCase
    func testTfSetsFontSize(): Unit {
        let frags = ContentStreamParser.parse(
            teBytes("BT\n/Helvetica 24 Tf\n(text) Tj\nET\n"))
        @Expect(frags.size, 1)
        @Expect(Int32(frags[0].fontSize), 24)
    }
}

// ===== Tm 操作符 =====

@Test
public class TmTests {

    @TestCase
    func testTmSetsPosition(): Unit {
        let frags = ContentStreamParser.parse(
            teBytes("BT\n1 0 0 1 100 700 Tm\n(text) Tj\nET\n"))
        @Expect(frags.size, 1)
        @Expect(Int32(frags[0].x), 100)
        @Expect(Int32(frags[0].y), 700)
    }

    @TestCase
    func testTmWithScale(): Unit {
        // 缩放分量在提取时不影响 x/y（仅取 e、f）
        let frags = ContentStreamParser.parse(
            teBytes("BT\n2 0 0 2 200 500 Tm\n(text) Tj\nET\n"))
        @Expect(frags.size, 1)
        @Expect(Int32(frags[0].x), 200)
        @Expect(Int32(frags[0].y), 500)
    }

    @TestCase
    func testMultipleTm(): Unit {
        let frags = ContentStreamParser.parse(
            teBytes("BT\n1 0 0 1 50 800 Tm\n(A) Tj\n1 0 0 1 300 800 Tm\n(B) Tj\nET\n"))
        @Expect(frags.size, 2)
        // 同行，按 x 排序
        @Expect(frags[0].text == "A", true)
        @Expect(frags[1].text == "B", true)
    }
}

// ===== Td 操作符 =====

@Test
public class TdTests {

    @TestCase
    func testTdMovesPosition(): Unit {
        let frags = ContentStreamParser.parse(
            teBytes("BT\n0 700 Td\n(text) Tj\nET\n"))
        @Expect(frags.size, 1)
        @Expect(Int32(frags[0].y), 700)
    }

    @TestCase
    func testTdRelativeMove(): Unit {
        let frags = ContentStreamParser.parse(
            teBytes("BT\n0 700 Td\n(Line1) Tj\n0 -50 Td\n(Line2) Tj\nET\n"))
        @Expect(frags.size, 2)
        // 排序后 Line1 在上
        @Expect(frags[0].text == "Line1", true)
        @Expect(frags[1].text == "Line2", true)
        @Expect(frags[0].y > frags[1].y, true)
    }
}

// ===== TJ 数组操作符 =====

@Test
public class TJTests {

    @TestCase
    func testTJArray(): Unit {
        let frags = ContentStreamParser.parse(
            teBytes("BT\n[(Hello) ( World)] TJ\nET\n"))
        @Expect(frags.size, 1)
        @Expect(frags[0].text == "Hello World", true)
    }

    @TestCase
    func testTJArrayWithKerning(): Unit {
        // 数字（字距）应被忽略，字符串拼接
        let frags = ContentStreamParser.parse(
            teBytes("BT\n[(Hel) -50 (lo)] TJ\nET\n"))
        @Expect(frags.size, 1)
        @Expect(frags[0].text == "Hello", true)
    }

    @TestCase
    func testTJEmptyArray(): Unit {
        let frags = ContentStreamParser.parse(
            teBytes("BT\n[] TJ\nET\n"))
        @Expect(frags.size, 0)
    }
}

// ===== 十六进制字符串 =====

@Test
public class HexStringTests {

    @TestCase
    func testHexString(): Unit {
        // <48656C6C6F> = "Hello"
        let frags = ContentStreamParser.parse(
            teBytes("BT\n<48656C6C6F> Tj\nET\n"))
        @Expect(frags.size, 1)
        @Expect(frags[0].text == "Hello", true)
    }
}

// ===== 阅读顺序排序 =====

@Test
public class ReadingOrderTests {

    @TestCase
    func testTopBeforeBottom(): Unit {
        // 内容流先写底部，再写顶部，排序后顶部应在前
        let cs = "BT\n1 0 0 1 100 600 Tm\n(Bottom) Tj\n1 0 0 1 100 700 Tm\n(Top) Tj\nET\n"
        let frags = ContentStreamParser.parse(teBytes(cs))
        @Expect(frags.size, 2)
        @Expect(frags[0].text == "Top", true)
        @Expect(frags[1].text == "Bottom", true)
    }

    @TestCase
    func testLeftBeforeRight(): Unit {
        let cs = "BT\n1 0 0 1 300 700 Tm\n(Right) Tj\n1 0 0 1 100 700 Tm\n(Left) Tj\nET\n"
        let frags = ContentStreamParser.parse(teBytes(cs))
        @Expect(frags.size, 2)
        @Expect(frags[0].text == "Left", true)
        @Expect(frags[1].text == "Right", true)
    }

    @TestCase
    func testFourFragments(): Unit {
        let cs =
            "BT\n" +
            "1 0 0 1 100 600 Tm\n(BL) Tj\n" +
            "1 0 0 1 300 600 Tm\n(BR) Tj\n" +
            "1 0 0 1 100 700 Tm\n(TL) Tj\n" +
            "1 0 0 1 300 700 Tm\n(TR) Tj\n" +
            "ET\n"
        let frags = ContentStreamParser.parse(teBytes(cs))
        @Expect(frags.size, 4)
        @Expect(frags[0].text == "TL", true)
        @Expect(frags[1].text == "TR", true)
        @Expect(frags[2].text == "BL", true)
        @Expect(frags[3].text == "BR", true)
    }
}

// ===== assembleText =====

@Test
public class AssembleTextTests {

    @TestCase
    func testEmptyFrags(): Unit {
        let frags = ArrayList<TextFragment>()
        let text = ContentStreamParser.assembleText(frags)
        @Expect(text == "", true)
    }

    @TestCase
    func testSingleFrag(): Unit {
        let frags = ContentStreamParser.parse(teBytes("BT\n(Hello) Tj\nET\n"))
        let text = ContentStreamParser.assembleText(frags)
        @Expect(text == "Hello", true)
    }

    @TestCase
    func testSameLineJoinedWithSpace(): Unit {
        let cs = "BT\n1 0 0 1 100 700 Tm\n(A) Tj\n1 0 0 1 200 700 Tm\n(B) Tj\nET\n"
        let frags = ContentStreamParser.parse(teBytes(cs))
        let text = ContentStreamParser.assembleText(frags)
        @Expect(text == "A B", true)
    }

    @TestCase
    func testDifferentLinesJoinedWithNewline(): Unit {
        let cs = "BT\n1 0 0 1 100 700 Tm\n(Line1) Tj\n1 0 0 1 100 650 Tm\n(Line2) Tj\nET\n"
        let frags = ContentStreamParser.parse(teBytes(cs))
        let text = ContentStreamParser.assembleText(frags)
        @Expect(text == "Line1\nLine2", true)
    }
}

// ===== TextExtractor 集成测试 =====

@Test
public class TextExtractorTests {

    @TestCase
    func testExtractPageReturnsText(): Unit {
        let reader = PdfReader(makeExtractPdf())
        let text = TextExtractor.extractPage(reader, 1)
        @Expect(text.size > 0, true)
        reader.close()
    }

    @TestCase
    func testExtractPageContent(): Unit {
        let reader = PdfReader(makeExtractPdf())
        let text = TextExtractor.extractPage(reader, 1)
        @Expect(text == "Hello PDF\nWorld", true)
        reader.close()
    }

    @TestCase
    func testExtractAll(): Unit {
        let reader = PdfReader(makeExtractPdf())
        let text = TextExtractor.extractAll(reader)
        @Expect(text.size > 0, true)
        reader.close()
    }

    @TestCase
    func testExtractAllSinglePage(): Unit {
        let reader = PdfReader(makeExtractPdf())
        let page1 = TextExtractor.extractPage(reader, 1)
        let all = TextExtractor.extractAll(reader)
        @Expect(all == page1, true)
        reader.close()
    }
}
