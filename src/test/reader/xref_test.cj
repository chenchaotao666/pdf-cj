/**
 * XRefTable / XRefParser 单元测试
 *
 * 策略：直接构造最小 xref 字节串，验证解析结果。
 * 不依赖磁盘 PDF 文件。
 */
package pdf_cj.test.reader

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.HashMap
import pdf_cj.reader.{XRefEntry, XRefTable, XRefParser}

// ===== XRefEntry / XRefTable 数据结构 =====

@Test
public class XRefEntryTests {

    @TestCase
    func testInUseEntry(): Unit {
        let e = XRefEntry(1234, 0, true)
        @Expect(e.getOffset(), 1234)
        @Expect(e.getGeneration(), 0)
        @Expect(e.isInUse(), true)
    }

    @TestCase
    func testFreeEntry(): Unit {
        let e = XRefEntry(0, 65535, false)
        @Expect(e.getOffset(), 0)
        @Expect(e.getGeneration(), 65535)
        @Expect(e.isInUse(), false)
    }
}

@Test
public class XRefTableTests {

    @TestCase
    func testEmptyTable(): Unit {
        let t = XRefTable()
        @Expect(t.getObjectCount(), 0)
        @Expect(t.hasObject(1), false)
    }

    @TestCase
    func testAddAndGetEntry(): Unit {
        let t = XRefTable()
        t.addEntry(1, XRefEntry(9, 0, true))
        @Expect(t.hasObject(1), true)
        @Expect(t.getOffset(1), 9)
    }

    @TestCase
    func testGetOffsetMissing(): Unit {
        let t = XRefTable()
        @Expect(t.getOffset(999), -1)
    }

    @TestCase
    func testGetObjectCount(): Unit {
        let t = XRefTable()
        t.addEntry(0, XRefEntry(0, 65535, false))
        t.addEntry(1, XRefEntry(9, 0, true))
        t.addEntry(2, XRefEntry(58, 0, true))
        @Expect(t.getObjectCount(), 3)
    }

    @TestCase
    func testGetAllObjectNumbers(): Unit {
        let t = XRefTable()
        t.addEntry(1, XRefEntry(9, 0, true))
        t.addEntry(3, XRefEntry(58, 0, true))
        let nums = t.getAllObjectNumbers()
        @Expect(nums.size, 2)
    }

    @TestCase
    func testTrailer(): Unit {
        let t = XRefTable()
        let trailer = HashMap<String, String>()
        trailer["Size"] = "10"
        trailer["Root"] = "1 0 R"
        t.setTrailer(trailer)
        match (t.getTrailer()) {
            case Some(tr) =>
                @Expect(tr.get("Size").isSome(), true)
                @Expect(tr.get("Root").isSome(), true)
            case None => @Fail("trailer should be set")
        }
    }
}

// ===== XRefParser 解析 =====

// 构建最小 xref 段字节数组（传统格式）
// 格式严格：每个条目恰好 20 字节（包括 \r\n）
func makeXRefBytes(): Array<UInt8> {
    // xref\n0 3\n0000000000 65535 f \r\n0000000009 00000 n \r\n0000000058 00000 n \r\ntrailer\n<< /Size 3 /Root 1 0 R >>\n
    let src =
        "xref\n" +
        "0 3\n" +
        "0000000000 65535 f \r\n" +
        "0000000009 00000 n \r\n" +
        "0000000058 00000 n \r\n" +
        "trailer\n" +
        "<< /Size 3 /Root 1 0 R >>\n"
    let arr = Array<UInt8>(src.size, repeat: 0)
    var i = 0
    for (r in src.runes()) {
        arr[i] = UInt8(UInt32(r))
        i += 1
    }
    arr
}

// startxref 定位测试数据
func makeStartXRefBytes(xrefOffset: Int64): Array<UInt8> {
    let src = "startxref\n${xrefOffset}\n%%EOF\n"
    let arr = Array<UInt8>(src.size, repeat: 0)
    var i = 0
    for (r in src.runes()) {
        arr[i] = UInt8(UInt32(r))
        i += 1
    }
    arr
}

@Test
public class XRefParserTests {

    @TestCase
    func testParseObjectCount(): Unit {
        let data = makeXRefBytes()
        let parser = XRefParser(data, 0)
        let table = parser.parse()
        @Expect(table.getObjectCount(), 3)
    }

    @TestCase
    func testParseObject0IsFree(): Unit {
        let data = makeXRefBytes()
        let table = XRefParser(data, 0).parse()
        match (table.getEntry(0)) {
            case Some(e) => @Expect(e.isInUse(), false)
            case None => @Fail("object 0 should exist")
        }
    }

    @TestCase
    func testParseObject1Offset(): Unit {
        let data = makeXRefBytes()
        let table = XRefParser(data, 0).parse()
        @Expect(table.getOffset(1), 9)
    }

    @TestCase
    func testParseObject2Offset(): Unit {
        let data = makeXRefBytes()
        let table = XRefParser(data, 0).parse()
        @Expect(table.getOffset(2), 58)
    }

    @TestCase
    func testObject1Generation(): Unit {
        let data = makeXRefBytes()
        let table = XRefParser(data, 0).parse()
        match (table.getEntry(1)) {
            case Some(e) => @Expect(e.getGeneration(), 0)
            case None => @Fail("object 1 should exist")
        }
    }

    @TestCase
    func testObject0Generation(): Unit {
        let data = makeXRefBytes()
        let table = XRefParser(data, 0).parse()
        match (table.getEntry(0)) {
            case Some(e) => @Expect(e.getGeneration(), 65535)
            case None => @Fail("object 0 should exist")
        }
    }

    @TestCase
    func testTrailerSizeKey(): Unit {
        let data = makeXRefBytes()
        let table = XRefParser(data, 0).parse()
        match (table.getTrailer()) {
            case Some(tr) =>
                match (tr.get("Size")) {
                    case Some(v) => @Expect(v, "3")
                    case None => @Fail("trailer Size should be present")
                }
            case None => @Fail("trailer should be parsed")
        }
    }

    @TestCase
    func testTrailerRootKey(): Unit {
        let data = makeXRefBytes()
        let table = XRefParser(data, 0).parse()
        match (table.getTrailer()) {
            case Some(tr) => @Expect(tr.get("Root").isSome(), true)
            case None => @Fail("trailer should be parsed")
        }
    }

    @TestCase
    func testHasObjectTrue(): Unit {
        let data = makeXRefBytes()
        let table = XRefParser(data, 0).parse()
        @Expect(table.hasObject(1), true)
        @Expect(table.hasObject(2), true)
    }

    @TestCase
    func testHasObjectFalse(): Unit {
        let data = makeXRefBytes()
        let table = XRefParser(data, 0).parse()
        @Expect(table.hasObject(99), false)
    }
}

@Test
public class FindStartXRefTests {

    @TestCase
    func testFindStartXRefSimple(): Unit {
        // startxref\n9\n%%EOF
        let data = makeStartXRefBytes(9)
        let offset = XRefParser.findStartXRef(data)
        @Expect(offset, 9)
    }

    @TestCase
    func testFindStartXRefLargeOffset(): Unit {
        let data = makeStartXRefBytes(12345)
        let offset = XRefParser.findStartXRef(data)
        @Expect(offset, 12345)
    }

    @TestCase
    func testFindStartXRefNotFound(): Unit {
        let src = "no xref here"
        let arr = Array<UInt8>(src.size, repeat: 0)
        var i = 0
        for (r in src.runes()) { arr[i] = UInt8(UInt32(r)); i += 1 }
        @Expect(XRefParser.findStartXRef(arr), -1)
    }
}
