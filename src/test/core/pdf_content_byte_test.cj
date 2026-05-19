/**
 * PdfContentByte 单元测试
 *
 * 策略：PdfContentByte 是纯粹的内容流字节生成器，输出完全确定。
 * 每个测试调用一个或一组算子，然后断言生成的字节字符串与 PDF 规范一致。
 */
package pdf_cj.test.core

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.core.{PdfContentByte}
import pdf_cj.text.{Color}

func contentOf(cb: PdfContentByte): String {
    let bytes = cb.toByteArray()
    var s = ""
    for (b in bytes) {
        s += String(Rune(UInt32(b)))
    }
    s
}

// ===== 路径构建算子 =====

@Test
public class PathOperatorTests {

    @TestCase
    func testMoveTo(): Unit {
        let cb = PdfContentByte()
        cb.moveTo(10.0, 20.5)
        @Expect(contentOf(cb), "10 20.5 m\n")
    }

    @TestCase
    func testLineTo(): Unit {
        let cb = PdfContentByte()
        cb.lineTo(100.0, 200.0)
        @Expect(contentOf(cb), "100 200 l\n")
    }

    @TestCase
    func testCurveTo(): Unit {
        let cb = PdfContentByte()
        cb.curveTo(10.0, 20.0, 30.0, 40.0, 50.0, 60.0)
        @Expect(contentOf(cb), "10 20 30 40 50 60 c\n")
    }

    @TestCase
    func testClosePath(): Unit {
        let cb = PdfContentByte()
        cb.closePath()
        @Expect(contentOf(cb), "h\n")
    }

    @TestCase
    func testRectangle(): Unit {
        let cb = PdfContentByte()
        cb.rectangle(10.0, 20.0, 100.0, 50.0)
        @Expect(contentOf(cb), "10 20 100 50 re\n")
    }

    @TestCase
    func testRoundRectangleClosesPath(): Unit {
        let cb = PdfContentByte()
        cb.roundRectangle(0.0, 0.0, 100.0, 50.0, 10.0)
        let s = contentOf(cb)
        @Expect(s.endsWith("h\n"), true)
        @Expect(s.contains(" m\n"), true)
        @Expect(s.contains(" c\n"), true)
    }

    @TestCase
    func testEllipseProducesArc(): Unit {
        let cb = PdfContentByte()
        cb.ellipse(0.0, 0.0, 100.0, 50.0)
        let s = contentOf(cb)
        @Expect(s.contains(" m\n"), true)
        @Expect(s.contains(" c\n"), true)
    }

    @TestCase
    func testArcZeroExtentProducesNothing(): Unit {
        let cb = PdfContentByte()
        cb.arc(0.0, 0.0, 100.0, 100.0, 0.0, 0.0)
        @Expect(contentOf(cb), "")
    }

    @TestCase
    func testArcNegativeExtentGoesClockwise(): Unit {
        let cb = PdfContentByte()
        cb.arc(0.0, 0.0, 100.0, 100.0, 90.0, -90.0)
        let s = contentOf(cb)
        @Expect(s.contains(" m\n"), true)
        @Expect(s.contains(" c\n"), true)
    }
}

// ===== 绘制算子 =====

@Test
public class DrawingOperatorTests {

    @TestCase
    func testStroke(): Unit {
        let cb = PdfContentByte()
        cb.stroke()
        @Expect(contentOf(cb), "S\n")
    }

    @TestCase
    func testFill(): Unit {
        let cb = PdfContentByte()
        cb.fill()
        @Expect(contentOf(cb), "f\n")
    }

    @TestCase
    func testEoFill(): Unit {
        let cb = PdfContentByte()
        cb.eoFill()
        @Expect(contentOf(cb), "f*\n")
    }

    @TestCase
    func testFillStroke(): Unit {
        let cb = PdfContentByte()
        cb.fillStroke()
        @Expect(contentOf(cb), "B\n")
    }

    @TestCase
    func testEoFillStroke(): Unit {
        let cb = PdfContentByte()
        cb.eoFillStroke()
        @Expect(contentOf(cb), "B*\n")
    }

    @TestCase
    func testNewPath(): Unit {
        let cb = PdfContentByte()
        cb.newPath()
        @Expect(contentOf(cb), "n\n")
    }

    @TestCase
    func testClip(): Unit {
        let cb = PdfContentByte()
        cb.clip()
        @Expect(contentOf(cb), "W\n")
    }

    @TestCase
    func testEoClip(): Unit {
        let cb = PdfContentByte()
        cb.eoClip()
        @Expect(contentOf(cb), "W*\n")
    }
}

// ===== 图形状态 =====

@Test
public class GraphicsStateTests {

    @TestCase
    func testSaveRestoreState(): Unit {
        let cb = PdfContentByte()
        cb.saveState()
        cb.restoreState()
        @Expect(contentOf(cb), "q\nQ\n")
    }

    @TestCase
    func testRestoreWithoutSaveIsNoop(): Unit {
        let cb = PdfContentByte()
        cb.restoreState()
        @Expect(contentOf(cb), "")
    }

    @TestCase
    func testSetLineWidth(): Unit {
        let cb = PdfContentByte()
        cb.setLineWidth(2.5)
        @Expect(contentOf(cb), "2.5 w\n")
    }

    @TestCase
    func testSetLineCap(): Unit {
        let cb = PdfContentByte()
        cb.setLineCap(1)
        @Expect(contentOf(cb), "1 J\n")
    }

    @TestCase
    func testSetLineJoin(): Unit {
        let cb = PdfContentByte()
        cb.setLineJoin(2)
        @Expect(contentOf(cb), "2 j\n")
    }

    @TestCase
    func testSetLineDashSolid(): Unit {
        let cb = PdfContentByte()
        cb.setLineDash(0.0)
        @Expect(contentOf(cb), "[] 0 d\n")
    }

    @TestCase
    func testSetLineDashOnOff(): Unit {
        let cb = PdfContentByte()
        cb.setLineDash(6.0, 3.0, 0.0)
        @Expect(contentOf(cb), "[6 3] 0 d\n")
    }

    @TestCase
    func testSetLineDashPattern(): Unit {
        let cb = PdfContentByte()
        cb.setLineDash([3.0, 1.0, 1.0, 1.0], 0.0)
        @Expect(contentOf(cb), "[3 1 1 1] 0 d\n")
    }

    @TestCase
    func testConcatCTM(): Unit {
        let cb = PdfContentByte()
        cb.concatCTM(1.0, 0.0, 0.0, 1.0, 50.0, 100.0)
        @Expect(contentOf(cb), "1 0 0 1 50 100 cm\n")
    }
}

// ===== 颜色算子 =====

@Test
public class ColorOperatorTests {

    @TestCase
    func testSetColorFillRGB(): Unit {
        let cb = PdfContentByte()
        cb.setColorFill(Color(255, 0, 0))
        @Expect(contentOf(cb), "1 0 0 rg\n")
    }

    @TestCase
    func testSetColorStrokeRGB(): Unit {
        let cb = PdfContentByte()
        cb.setColorStroke(Color(0, 0, 255))
        @Expect(contentOf(cb), "0 0 1 RG\n")
    }

    @TestCase
    func testSetGrayFill(): Unit {
        let cb = PdfContentByte()
        cb.setGrayFill(0.5)
        @Expect(contentOf(cb), "0.5 g\n")
    }

    @TestCase
    func testSetGrayStroke(): Unit {
        let cb = PdfContentByte()
        cb.setGrayStroke(0.0)
        @Expect(contentOf(cb), "0 G\n")
    }

    @TestCase
    func testSetCMYKColorFill(): Unit {
        let cb = PdfContentByte()
        cb.setCMYKColorFill(0.0, 1.0, 1.0, 0.0)
        @Expect(contentOf(cb), "0 1 1 0 k\n")
    }

    @TestCase
    func testSetCMYKColorStroke(): Unit {
        let cb = PdfContentByte()
        cb.setCMYKColorStroke(1.0, 0.0, 0.0, 0.0)
        @Expect(contentOf(cb), "1 0 0 0 K\n")
    }
}

// ===== 文本算子 =====

@Test
public class TextOperatorTests {

    @TestCase
    func testBeginEndText(): Unit {
        let cb = PdfContentByte()
        cb.beginText()
        cb.endText()
        @Expect(contentOf(cb), "BT\nET\n")
    }

    @TestCase
    func testBeginTextIdempotent(): Unit {
        let cb = PdfContentByte()
        cb.beginText()
        cb.beginText()
        cb.endText()
        @Expect(contentOf(cb), "BT\nET\n")
    }

    @TestCase
    func testSetFontAndSize(): Unit {
        let cb = PdfContentByte()
        cb.setFontAndSize("F1", 12.0)
        @Expect(contentOf(cb), "/F1 12 Tf\n")
    }

    @TestCase
    func testSetTextMatrix(): Unit {
        let cb = PdfContentByte()
        cb.setTextMatrix(100.0, 200.0)
        @Expect(contentOf(cb), "1 0 0 1 100 200 Tm\n")
    }

    @TestCase
    func testShowTextLatin(): Unit {
        let cb = PdfContentByte()
        cb.showText("Hello")
        @Expect(contentOf(cb), "(Hello) Tj\n")
    }

    @TestCase
    func testShowTextEscapeParens(): Unit {
        let cb = PdfContentByte()
        cb.showText("(test)")
        @Expect(contentOf(cb), "(\\(test\\)) Tj\n")
    }

    @TestCase
    func testSetCharacterSpacing(): Unit {
        let cb = PdfContentByte()
        cb.setCharacterSpacing(1.5)
        @Expect(contentOf(cb), "1.5 Tc\n")
    }

    @TestCase
    func testSetWordSpacing(): Unit {
        let cb = PdfContentByte()
        cb.setWordSpacing(2.0)
        @Expect(contentOf(cb), "2 Tw\n")
    }

    @TestCase
    func testSetTextRenderingMode(): Unit {
        let cb = PdfContentByte()
        cb.setTextRenderingMode(0)
        @Expect(contentOf(cb), "0 Tr\n")
    }

    @TestCase
    func testSetTextRise(): Unit {
        let cb = PdfContentByte()
        cb.setTextRise(4.0)
        @Expect(contentOf(cb), "4 Ts\n")
    }
}

// ===== showTextAligned =====

@Test
public class ShowTextAlignedTests {

    @TestCase
    func testLeftNoRotation(): Unit {
        let cb = PdfContentByte()
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "Hi", 100.0, 200.0, 0.0)
        let s = contentOf(cb)
        @Expect(s.contains("1 0 0 1 100 200 Tm"), true)
    }

    @TestCase
    func testCenterNoFont(): Unit {
        let cb = PdfContentByte()
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER, "Hi", 100.0, 200.0, 0.0)
        let s = contentOf(cb)
        @Expect(s.contains("1 0 0 1 100 200 Tm"), true)
    }

    @TestCase
    func testRotation90Deg(): Unit {
        let cb = PdfContentByte()
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "Hi", 100.0, 200.0, 90.0)
        let s = contentOf(cb)
        @Expect(s.contains("Tm"), true)
        @Expect(s.contains("0 1"), true)
    }
}

// ===== reset =====

@Test
public class ResetTests {

    @TestCase
    func testReset(): Unit {
        let cb = PdfContentByte()
        cb.moveTo(10.0, 10.0)
        cb.stroke()
        cb.reset()
        @Expect(contentOf(cb), "")
        @Expect(cb.size, 0)
    }
}

// ===== 复合场景 =====

@Test
public class CompositeTests {

    @TestCase
    func testDrawRectangleWithBorder(): Unit {
        let cb = PdfContentByte()
        cb.saveState()
        cb.setLineWidth(2.0)
        cb.setColorStroke(Color(0, 0, 0))
        cb.setColorFill(Color(200, 200, 200))
        cb.rectangle(10.0, 10.0, 100.0, 50.0)
        cb.fillStroke()
        cb.restoreState()
        let s = contentOf(cb)
        @Expect(s.contains("q\n"), true)
        @Expect(s.contains("2 w\n"), true)
        @Expect(s.contains("10 10 100 50 re\n"), true)
        @Expect(s.contains("B\n"), true)
        @Expect(s.contains("Q\n"), true)
    }

    @TestCase
    func testClipAndNewPath(): Unit {
        let cb = PdfContentByte()
        cb.rectangle(0.0, 0.0, 100.0, 100.0)
        cb.clip()
        cb.newPath()
        let s = contentOf(cb)
        @Expect(s.contains("W\n"), true)
        @Expect(s.contains("n\n"), true)
    }
}
