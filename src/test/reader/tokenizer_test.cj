/**
 * PdfTokenizer 单元测试
 *
 * 策略：直接构造 ASCII 字节数组，验证每类 PDF token 的解析结果。
 * 不依赖磁盘文件，不依赖 PdfWriter。
 */
package pdf_cj.test.reader

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.reader.{PdfTokenizer, TokenType, Token}

// 将 ASCII 字符串转为字节数组（仅用于 ASCII PDF 内容）
func b(str: String): Array<UInt8> {
    let arr = Array<UInt8>(str.size, repeat: 0)
    var i = 0
    for (r in str.runes()) {
        arr[i] = UInt8(UInt32(r))
        i += 1
    }
    arr
}

func tokenType(tok: ?Token): String {
    match (tok) {
        case None => "None"
        case Some(t) => match (t.getType()) {
            case Number => "Number"
            case String => "String"
            case Name => "Name"
            case Keyword => "Keyword"
            case StartArray => "StartArray"
            case EndArray => "EndArray"
            case StartDict => "StartDict"
            case EndDict => "EndDict"
            case Ref => "Ref"
            case Boolean => "Boolean"
            case Null => "Null"
            case Stream => "Stream"
            case EndOfFile => "EndOfFile"
            case Unknown => "Unknown"
        }
    }
}

func tokenValue(tok: ?Token): String {
    match (tok) {
        case None => ""
        case Some(t) => t.getValue()
    }
}

// ===== 基本 Token 类型 =====

@Test
public class NumberTokenTests {

    @TestCase
    func testInteger(): Unit {
        let tok = PdfTokenizer(b("42"))
        @Expect(tokenType(tok.nextToken()), "Number")
        @Expect(tokenValue(PdfTokenizer(b("42")).nextToken()), "42")
    }

    @TestCase
    func testNegativeInteger(): Unit {
        let tok = PdfTokenizer(b("-7"))
        @Expect(tokenType(tok.nextToken()), "Number")
        @Expect(tokenValue(tok.nextToken()), "")  // already consumed
    }

    @TestCase
    func testReal(): Unit {
        let tok = PdfTokenizer(b("3.14"))
        @Expect(tokenType(tok.nextToken()), "Number")
        @Expect(tokenValue(PdfTokenizer(b("3.14")).nextToken()), "3.14")
    }

    @TestCase
    func testZero(): Unit {
        @Expect(tokenType(PdfTokenizer(b("0")).nextToken()), "Number")
    }

    @TestCase
    func testMultipleNumbers(): Unit {
        let tok = PdfTokenizer(b("1 2 3"))
        @Expect(tokenValue(tok.nextToken()), "1")
        @Expect(tokenValue(tok.nextToken()), "2")
        @Expect(tokenValue(tok.nextToken()), "3")
    }
}

@Test
public class NameTokenTests {

    @TestCase
    func testSimpleName(): Unit {
        let tok = PdfTokenizer(b("/Type"))
        @Expect(tokenType(tok.nextToken()), "Name")
        @Expect(tokenValue(PdfTokenizer(b("/Type")).nextToken()), "Type")
    }

    @TestCase
    func testNameWithDigits(): Unit {
        @Expect(tokenType(PdfTokenizer(b("/F1")).nextToken()), "Name")
        @Expect(tokenValue(PdfTokenizer(b("/F1")).nextToken()), "F1")
    }

    @TestCase
    func testNameStopsAtWhitespace(): Unit {
        let tok = PdfTokenizer(b("/Pages 5"))
        @Expect(tokenValue(tok.nextToken()), "Pages")
        @Expect(tokenType(tok.nextToken()), "Number")
    }

    @TestCase
    func testNameStopsAtDelimiter(): Unit {
        let tok = PdfTokenizer(b("/Type/Page"))
        @Expect(tokenValue(tok.nextToken()), "Type")
        @Expect(tokenValue(tok.nextToken()), "Page")
    }
}

@Test
public class StringTokenTests {

    @TestCase
    func testSimpleString(): Unit {
        let tok = PdfTokenizer(b("(Hello)"))
        @Expect(tokenType(tok.nextToken()), "String")
        @Expect(tokenValue(PdfTokenizer(b("(Hello)")).nextToken()), "Hello")
    }

    @TestCase
    func testStringWithSpaces(): Unit {
        @Expect(tokenValue(PdfTokenizer(b("(Hello World)")).nextToken()), "Hello World")
    }

    @TestCase
    func testStringNestedParens(): Unit {
        @Expect(tokenValue(PdfTokenizer(b("(a(b)c)")).nextToken()), "a(b)c")
    }

    @TestCase
    func testStringEscapeNewline(): Unit {
        // (Hello\nWorld) → value contains LF byte
        let tok = PdfTokenizer(b("(Hello\\nWorld)"))
        let v = tokenValue(tok.nextToken())
        @Expect(v.size > 5, true)
    }

    @TestCase
    func testEmptyString(): Unit {
        @Expect(tokenValue(PdfTokenizer(b("()")).nextToken()), "")
    }

    @TestCase
    func testHexString(): Unit {
        // <4142> → raw hex chars "4142"
        let tok = PdfTokenizer(b("<4142>"))
        @Expect(tokenType(tok.nextToken()), "String")
    }

    @TestCase
    func testHexStringEmpty(): Unit {
        @Expect(tokenType(PdfTokenizer(b("<>")).nextToken()), "String")
    }
}

@Test
public class DictArrayTokenTests {

    @TestCase
    func testStartDict(): Unit {
        @Expect(tokenType(PdfTokenizer(b("<<")).nextToken()), "StartDict")
        @Expect(tokenValue(PdfTokenizer(b("<<")).nextToken()), "<<")
    }

    @TestCase
    func testEndDict(): Unit {
        @Expect(tokenType(PdfTokenizer(b(">>")).nextToken()), "EndDict")
    }

    @TestCase
    func testStartArray(): Unit {
        @Expect(tokenType(PdfTokenizer(b("[")).nextToken()), "StartArray")
    }

    @TestCase
    func testEndArray(): Unit {
        @Expect(tokenType(PdfTokenizer(b("]")).nextToken()), "EndArray")
    }

    @TestCase
    func testFullDict(): Unit {
        // << /Type /Page >> → StartDict, Name("Type"), Name("Page"), EndDict
        let tok = PdfTokenizer(b("<< /Type /Page >>"))
        @Expect(tokenType(tok.nextToken()), "StartDict")
        @Expect(tokenValue(tok.nextToken()), "Type")   // /Type
        @Expect(tokenValue(tok.nextToken()), "Page")   // /Page
        @Expect(tokenType(tok.nextToken()), "EndDict")
    }
}

@Test
public class BoolNullTokenTests {

    @TestCase
    func testTrue(): Unit {
        let tok = PdfTokenizer(b("true"))
        let t = tok.nextToken()
        @Expect(tokenType(t), "Boolean")
        @Expect(tokenValue(PdfTokenizer(b("true")).nextToken()), "true")
    }

    @TestCase
    func testFalse(): Unit {
        let tok = PdfTokenizer(b("false"))
        @Expect(tokenType(tok.nextToken()), "Boolean")
        @Expect(tokenValue(PdfTokenizer(b("false")).nextToken()), "false")
    }

    @TestCase
    func testNull(): Unit {
        let tok = PdfTokenizer(b("null"))
        @Expect(tokenType(tok.nextToken()), "Null")
    }

    @TestCase
    func testBoolInContext(): Unit {
        // /Filter true false → Name, Boolean, Boolean
        let tok = PdfTokenizer(b("/Flag true"))
        @Expect(tokenType(tok.nextToken()), "Name")
        @Expect(tokenType(tok.nextToken()), "Boolean")
    }
}

@Test
public class RefKeywordTokenTests {

    @TestCase
    func testRefToken(): Unit {
        // "R" alone → Ref
        let tok = PdfTokenizer(b("R"))
        @Expect(tokenType(tok.nextToken()), "Ref")
        @Expect(tokenValue(PdfTokenizer(b("R")).nextToken()), "R")
    }

    @TestCase
    func testIndirectRefSequence(): Unit {
        // "1 0 R" → Number, Number, Ref
        let tok = PdfTokenizer(b("1 0 R"))
        @Expect(tokenType(tok.nextToken()), "Number")
        @Expect(tokenValue(tok.nextToken()), "0")
        @Expect(tokenType(tok.nextToken()), "Ref")
    }

    @TestCase
    func testObjKeyword(): Unit {
        let tok = PdfTokenizer(b("obj"))
        @Expect(tokenType(tok.nextToken()), "Keyword")
        @Expect(tokenValue(PdfTokenizer(b("obj")).nextToken()), "obj")
    }

    @TestCase
    func testEndobjKeyword(): Unit {
        @Expect(tokenValue(PdfTokenizer(b("endobj")).nextToken()), "endobj")
    }

    @TestCase
    func testXrefKeyword(): Unit {
        @Expect(tokenValue(PdfTokenizer(b("xref")).nextToken()), "xref")
    }

    @TestCase
    func testTrailerKeyword(): Unit {
        @Expect(tokenValue(PdfTokenizer(b("trailer")).nextToken()), "trailer")
    }

    @TestCase
    func testStartxrefKeyword(): Unit {
        @Expect(tokenValue(PdfTokenizer(b("startxref")).nextToken()), "startxref")
    }
}

@Test
public class CommentSkipTests {

    @TestCase
    func testCommentSkipped(): Unit {
        // "% comment\n42" → Number(42)
        let tok = PdfTokenizer(b("% comment\n42"))
        @Expect(tokenType(tok.nextToken()), "Number")
        @Expect(tokenValue(PdfTokenizer(b("% comment\n42")).nextToken()), "42")
    }

    @TestCase
    func testPdfHeaderComment(): Unit {
        // "%PDF-1.4\n1" → Number(1)
        let tok = PdfTokenizer(b("%PDF-1.4\n1"))
        @Expect(tokenType(tok.nextToken()), "Number")
    }

    @TestCase
    func testMultipleComments(): Unit {
        let tok = PdfTokenizer(b("% c1\n% c2\n/Type"))
        @Expect(tokenType(tok.nextToken()), "Name")
    }
}

@Test
public class EOFTests {

    @TestCase
    func testEmptyData(): Unit {
        let tok = PdfTokenizer(b(""))
        @Expect(tok.nextToken().isNone(), true)
    }

    @TestCase
    func testOnlyWhitespace(): Unit {
        let tok = PdfTokenizer(b("   \n\t"))
        @Expect(tok.nextToken().isNone(), true)
    }

    @TestCase
    func testIsEOFTrue(): Unit {
        let tok = PdfTokenizer(b(""))
        @Expect(tok.isEOF(), true)
    }

    @TestCase
    func testIsEOFFalse(): Unit {
        let tok = PdfTokenizer(b("42"))
        @Expect(tok.isEOF(), false)
    }
}

@Test
public class PeekTests {

    @TestCase
    func testPeekDoesNotAdvance(): Unit {
        let tok = PdfTokenizer(b("42 99"))
        let t1 = tok.peekToken()
        let t2 = tok.peekToken()
        @Expect(tokenValue(t1), tokenValue(t2))
    }

    @TestCase
    func testPeekThenNext(): Unit {
        let tok = PdfTokenizer(b("/Type /Page"))
        tok.peekToken()
        @Expect(tokenValue(tok.nextToken()), "Type")
        @Expect(tokenValue(tok.nextToken()), "Page")
    }
}

@Test
public class PositionTests {

    @TestCase
    func testGetPosition(): Unit {
        let tok = PdfTokenizer(b("42"))
        @Expect(tok.getPosition(), 0)
        tok.nextToken()
        @Expect(tok.getPosition() > 0, true)
    }

    @TestCase
    func testSetPosition(): Unit {
        let tok = PdfTokenizer(b("/Type /Page"))
        tok.nextToken()  // consume /Type
        tok.setPosition(0)
        @Expect(tokenValue(tok.nextToken()), "Type")
    }

    @TestCase
    func testGetLength(): Unit {
        let data = b("hello")
        let tok = PdfTokenizer(data)
        @Expect(tok.getLength(), 5)
    }
}

@Test
public class StreamContentTests {

    @TestCase
    func testReadStreamContent(): Unit {
        // "BT ET\nendstream"
        let raw = b("BT ET\nendstream")
        let tok = PdfTokenizer(raw)
        let content = tok.readStreamContent()
        // content should be "BT ET" (5 bytes, LF trimmed)
        @Expect(content.size, 5)
    }

    @TestCase
    func testReadStreamContentEmpty(): Unit {
        // "\nendstream"
        let raw = b("\nendstream")
        let tok = PdfTokenizer(raw)
        let content = tok.readStreamContent()
        @Expect(content.size, 0)
    }

    @TestCase
    func testReadStreamContentCRLF(): Unit {
        // "data\r\nendstream"
        let raw = b("data\r\nendstream")
        let tok = PdfTokenizer(raw)
        let content = tok.readStreamContent()
        @Expect(content.size, 4)  // "data"
    }
}
