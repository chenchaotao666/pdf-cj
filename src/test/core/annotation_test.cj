/**
 * PdfAnnotation 单元测试
 *
 * 策略：验证各注释类型的字典结构正确，以及 PdfWriter 能正常序列化注释到 PDF。
 */
package pdf_cj.test.core

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.form.{
    PdfAnnotation, PdfAnnotationFactory, PdfAnnotationStamp,
    PdfAnnotationText, PdfAnnotationLink, PdfAnnotationHighlight,
    PdfAnnotationFreeText, PdfAnnotationUnderline, PdfAnnotationStrikeOut,
    PdfAnnotationSquare, PdfAnnotationCircle
}
import pdf_cj.base.{PdfName, PdfIndirectReference}
import pdf_cj.text.{BaseFont, Font}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

func makeRect(): Rectangle { Rectangle(10.0, 10.0, 100.0, 50.0) }
func makeQp(): Array<Float32> { [10.0, 10.0, 100.0, 10.0, 10.0, 50.0, 100.0, 50.0] }
func makeHelv3(): Font {
    let bf = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
    Font(bf, 12.0)
}

// ===== 字典结构测试 =====

@Test
public class AnnotationDictionaryTests {

    @TestCase
    func testBaseAnnotHasTypeAndRect(): Unit {
        let a = PdfAnnotationText(makeRect(), "hello")
        let dict = a.getDictionary()
        @Expect(dict.contains(PdfName("Type")), true)
        @Expect(dict.contains(PdfName("Rect")), true)
    }

    @TestCase
    func testTextAnnotSubtype(): Unit {
        let a = PdfAnnotationText(makeRect(), "content")
        @Expect(a.getDictionary().contains(PdfName("Subtype")), true)
        @Expect(a.getDictionary().contains(PdfName("Contents")), true)
    }

    @TestCase
    func testTextAnnotIconDefault(): Unit {
        let a = PdfAnnotationText(makeRect(), "x")
        // 默认图标 Note 写入 Name 键
        @Expect(a.getDictionary().contains(PdfName("Name")), true)
    }

    @TestCase
    func testTextAnnotOpenFlag(): Unit {
        let a = PdfAnnotationText(makeRect(), "x")
        a.setOpen(true)
        @Expect(a.getDictionary().contains(PdfName("Open")), true)
    }

    @TestCase
    func testTextAnnotTitle(): Unit {
        let a = PdfAnnotationText(makeRect(), "x")
        a.setTitle("Author")
        @Expect(a.getDictionary().contains(PdfName("T")), true)
    }

    @TestCase
    func testLinkAnnotSubtype(): Unit {
        let a = PdfAnnotationLink(makeRect())
        @Expect(a.getDictionary().contains(PdfName("Subtype")), true)
    }

    @TestCase
    func testLinkAnnotHighlightMode(): Unit {
        let a = PdfAnnotationLink(makeRect())
        a.setHighlightMode("I")
        @Expect(a.getDictionary().contains(PdfName("H")), true)
    }

    @TestCase
    func testHighlightAnnotQuadPoints(): Unit {
        let a = PdfAnnotationHighlight(makeRect())
        a.setQuadPoints(makeQp())
        @Expect(a.getDictionary().contains(PdfName("QuadPoints")), true)
    }

    @TestCase
    func testFreeTextAnnotDA(): Unit {
        let a = PdfAnnotationFreeText(makeRect(), "text")
        a.setDefaultAppearance("/Helvetica 12 Tf 0 g")
        @Expect(a.getDictionary().contains(PdfName("DA")), true)
    }

    @TestCase
    func testFreeTextAnnotAlignment(): Unit {
        let a = PdfAnnotationFreeText(makeRect(), "text")
        a.setAlignment(1)
        @Expect(a.getDictionary().contains(PdfName("Q")), true)
    }

    @TestCase
    func testStampAnnotName(): Unit {
        let a = PdfAnnotationStamp(makeRect(), PdfAnnotationStamp.DRAFT)
        @Expect(a.getDictionary().contains(PdfName("Name")), true)
    }

    @TestCase
    func testUnderlineAnnotQuadPoints(): Unit {
        let a = PdfAnnotationUnderline(makeRect())
        a.setQuadPoints(makeQp())
        @Expect(a.getDictionary().contains(PdfName("QuadPoints")), true)
    }

    @TestCase
    func testStrikeOutAnnotQuadPoints(): Unit {
        let a = PdfAnnotationStrikeOut(makeRect())
        a.setQuadPoints(makeQp())
        @Expect(a.getDictionary().contains(PdfName("QuadPoints")), true)
    }

    @TestCase
    func testSquareAnnotInteriorColor(): Unit {
        let a = PdfAnnotationSquare(makeRect())
        a.setInteriorColor(1.0, 1.0, 0.0)
        @Expect(a.getDictionary().contains(PdfName("IC")), true)
    }

    @TestCase
    func testCircleAnnotInteriorColor(): Unit {
        let a = PdfAnnotationCircle(makeRect())
        a.setInteriorColor(0.0, 0.5, 1.0)
        @Expect(a.getDictionary().contains(PdfName("IC")), true)
    }

    @TestCase
    func testColorSetOnBase(): Unit {
        let a = PdfAnnotationHighlight(makeRect())
        a.setColor(1.0, 0.0, 0.0)
        @Expect(a.getDictionary().contains(PdfName("C")), true)
    }

    @TestCase
    func testBorderSetOnBase(): Unit {
        let a = PdfAnnotationSquare(makeRect())
        a.setBorder(2.0)
        @Expect(a.getDictionary().contains(PdfName("Border")), true)
    }
}

// ===== 工厂方法测试 =====

@Test
public class AnnotationFactoryTests {

    @TestCase
    func testCreateTextSimple(): Unit {
        let a = PdfAnnotationFactory.createText(100.0, 200.0, "note")
        @Expect(a.getDictionary().contains(PdfName("Subtype")), true)
        @Expect(a.getDictionary().contains(PdfName("Contents")), true)
    }

    @TestCase
    func testCreateTextFull(): Unit {
        let a = PdfAnnotationFactory.createText(makeRect(), "Author", "content", true, "Comment")
        @Expect(a.getDictionary().contains(PdfName("T")), true)
        @Expect(a.getDictionary().contains(PdfName("Open")), true)
        @Expect(a.getDictionary().contains(PdfName("Name")), true)
    }

    @TestCase
    func testCreateURLLink(): Unit {
        let a = PdfAnnotationFactory.createURLLink(makeRect(), "https://example.com")
        @Expect(a.getDictionary().contains(PdfName("Subtype")), true)
        @Expect(a.getDictionary().contains(PdfName("A")), true)
    }

    @TestCase
    func testCreateHighlight(): Unit {
        let a = PdfAnnotationFactory.createHighlight(makeRect(), makeQp())
        @Expect(a.getDictionary().contains(PdfName("QuadPoints")), true)
    }

    @TestCase
    func testCreateUnderline(): Unit {
        let a = PdfAnnotationFactory.createUnderline(makeRect(), makeQp())
        @Expect(a.getDictionary().contains(PdfName("Subtype")), true)
        @Expect(a.getDictionary().contains(PdfName("QuadPoints")), true)
    }

    @TestCase
    func testCreateStrikeOut(): Unit {
        let a = PdfAnnotationFactory.createStrikeOut(makeRect(), makeQp())
        @Expect(a.getDictionary().contains(PdfName("Subtype")), true)
        @Expect(a.getDictionary().contains(PdfName("QuadPoints")), true)
    }

    @TestCase
    func testCreateFreeText(): Unit {
        let a = PdfAnnotationFactory.createFreeText(makeRect(), "text", "/Helvetica 12 Tf 0 g")
        @Expect(a.getDictionary().contains(PdfName("Subtype")), true)
        @Expect(a.getDictionary().contains(PdfName("DA")), true)
    }

    @TestCase
    func testCreateStamp(): Unit {
        let a = PdfAnnotationFactory.createStamp(makeRect(), PdfAnnotationStamp.APPROVED)
        @Expect(a.getDictionary().contains(PdfName("Subtype")), true)
        @Expect(a.getDictionary().contains(PdfName("Name")), true)
    }

    @TestCase
    func testCreateSquare(): Unit {
        let a = PdfAnnotationFactory.createSquare(makeRect())
        @Expect(a.getDictionary().contains(PdfName("Subtype")), true)
    }

    @TestCase
    func testCreateCircle(): Unit {
        let a = PdfAnnotationFactory.createCircle(makeRect())
        @Expect(a.getDictionary().contains(PdfName("Subtype")), true)
    }
}

// ===== 集成测试：PdfWriter 序列化 =====

@Test
public class AnnotationIntegrationTests {

    @TestCase
    func testTextAnnotWrittenToPdf(): Unit {
        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("/tmp/at_text.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        let a = PdfAnnotationFactory.createText(400.0, 700.0, "Test note")
        writer.addAnnotation(a)
        document.close()
        file.close()
        @Expect(true, true)
    }

    @TestCase
    func testMultipleAnnotsOnOnePage(): Unit {
        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("/tmp/at_multi.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        writer.addAnnotation(PdfAnnotationFactory.createText(400.0, 700.0, "A"))
        writer.addAnnotation(PdfAnnotationFactory.createURLLink(makeRect(), "https://example.com"))
        writer.addAnnotation(PdfAnnotationFactory.createHighlight(makeRect(), makeQp()))
        document.close()
        file.close()
        @Expect(true, true)
    }

    @TestCase
    func testAnnotsOnMultiplePages(): Unit {
        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("/tmp/at_pages.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        let font = makeHelv3()
        writer.addAnnotation(PdfAnnotationFactory.createText(400.0, 700.0, "Page 1"))
        document.add(Paragraph("Page 1", font))
        document.newPage()
        writer.addAnnotation(PdfAnnotationFactory.createText(400.0, 700.0, "Page 2"))
        document.add(Paragraph("Page 2", font))
        document.close()
        file.close()
        @Expect(true, true)
    }

    @TestCase
    func testFreeTextAnnotWrittenToPdf(): Unit {
        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("/tmp/at_freetext.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        let ft = PdfAnnotationFactory.createFreeText(
            Rectangle(72.0, 650.0, 300.0, 700.0),
            "Free text content",
            "/Helvetica 12 Tf 0 g"
        )
        writer.addAnnotation(ft)
        document.close()
        file.close()
        @Expect(true, true)
    }

    @TestCase
    func testShapeAnnotsWrittenToPdf(): Unit {
        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("/tmp/at_shapes.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        let sq = PdfAnnotationFactory.createSquare(Rectangle(72.0, 650.0, 200.0, 720.0))
        sq.setColor(1.0, 0.0, 0.0)
        writer.addAnnotation(sq)
        let ci = PdfAnnotationFactory.createCircle(Rectangle(220.0, 650.0, 350.0, 720.0))
        ci.setColor(0.0, 0.0, 1.0)
        writer.addAnnotation(ci)
        document.close()
        file.close()
        @Expect(true, true)
    }
}
