/**
 * CMYKColor / GrayColor 单元测试
 *
 * 策略：
 *   - 结构体字段：构造后各分量值正确
 *   - 预定义常量：值符合颜色规范
 *   - PdfContentByte 算子：setColorFill/Stroke 输出正确的 PDF 算子
 */
package pdf_cj.test.core

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.core.PdfContentByte
import pdf_cj.text.{Color, CMYKColor, GrayColor}

func cbContent(cb: PdfContentByte): String {
    let bytes = cb.toByteArray()
    var s = ""
    for (b in bytes) {
        s += String(Rune(UInt32(b)))
    }
    s
}

// ===== CMYKColor 结构体 =====

@Test
public class CMYKColorTests {

    @TestCase
    func testConstruction(): Unit {
        let c = CMYKColor(0.1, 0.2, 0.3, 0.4)
        @Expect(c.cyan,    0.1)
        @Expect(c.magenta, 0.2)
        @Expect(c.yellow,  0.3)
        @Expect(c.black,   0.4)
    }

    @TestCase
    func testBlackConstant(): Unit {
        let c = CMYKColor.BLACK
        @Expect(c.cyan,    0.0)
        @Expect(c.magenta, 0.0)
        @Expect(c.yellow,  0.0)
        @Expect(c.black,   1.0)
    }

    @TestCase
    func testWhiteConstant(): Unit {
        let c = CMYKColor.WHITE
        @Expect(c.cyan,    0.0)
        @Expect(c.magenta, 0.0)
        @Expect(c.yellow,  0.0)
        @Expect(c.black,   0.0)
    }

    @TestCase
    func testCyanConstant(): Unit {
        let c = CMYKColor.CYAN
        @Expect(c.cyan,    1.0)
        @Expect(c.magenta, 0.0)
        @Expect(c.yellow,  0.0)
        @Expect(c.black,   0.0)
    }

    @TestCase
    func testMagentaConstant(): Unit {
        let c = CMYKColor.MAGENTA
        @Expect(c.cyan,    0.0)
        @Expect(c.magenta, 1.0)
        @Expect(c.yellow,  0.0)
        @Expect(c.black,   0.0)
    }

    @TestCase
    func testYellowConstant(): Unit {
        let c = CMYKColor.YELLOW
        @Expect(c.cyan,    0.0)
        @Expect(c.magenta, 0.0)
        @Expect(c.yellow,  1.0)
        @Expect(c.black,   0.0)
    }
}

// ===== GrayColor 结构体 =====

@Test
public class GrayColorTests {

    @TestCase
    func testConstruction(): Unit {
        let g = GrayColor(0.7)
        @Expect(g.gray, 0.7)
    }

    @TestCase
    func testBlackConstant(): Unit {
        @Expect(GrayColor.BLACK.gray, 0.0)
    }

    @TestCase
    func testWhiteConstant(): Unit {
        @Expect(GrayColor.WHITE.gray, 1.0)
    }

    @TestCase
    func testGrayConstant(): Unit {
        @Expect(GrayColor.GRAY.gray, 0.5)
    }

    @TestCase
    func testDarkGrayConstant(): Unit {
        @Expect(GrayColor.DARK_GRAY.gray, 0.25)
    }

    @TestCase
    func testLightGrayConstant(): Unit {
        @Expect(GrayColor.LIGHT_GRAY.gray, 0.75)
    }
}

// ===== PdfContentByte 算子输出 =====

@Test
public class ColorSpaceOperatorTests {

    // --- RGB ---
    @TestCase
    func testRgbFillOperator(): Unit {
        let cb = PdfContentByte()
        cb.setColorFill(Color(255, 0, 0))
        let out = cbContent(cb)
        @Expect(out.contains("rg"), true)
        @Expect(out.contains("RG"), false)
    }

    @TestCase
    func testRgbStrokeOperator(): Unit {
        let cb = PdfContentByte()
        cb.setColorStroke(Color(0, 255, 0))
        let out = cbContent(cb)
        @Expect(out.contains("RG"), true)
        @Expect(out.contains("rg"), false)
    }

    // --- Gray ---
    @TestCase
    func testGrayColorFillOperator(): Unit {
        let cb = PdfContentByte()
        cb.setColorFill(GrayColor(0.5))
        let out = cbContent(cb)
        @Expect(out.contains(" g\n"), true)
        @Expect(out.contains(" G\n"), false)
    }

    @TestCase
    func testGrayColorStrokeOperator(): Unit {
        let cb = PdfContentByte()
        cb.setColorStroke(GrayColor(0.0))
        let out = cbContent(cb)
        @Expect(out.contains(" G\n"), true)
        @Expect(out.contains(" g\n"), false)
    }

    @TestCase
    func testGrayFillBlackOutput(): Unit {
        let cb = PdfContentByte()
        cb.setColorFill(GrayColor.BLACK)
        @Expect(cbContent(cb), "0 g\n")
    }

    @TestCase
    func testGrayStrokeWhiteOutput(): Unit {
        let cb = PdfContentByte()
        cb.setColorStroke(GrayColor.WHITE)
        @Expect(cbContent(cb), "1 G\n")
    }

    // --- CMYK ---
    @TestCase
    func testCmykColorFillOperator(): Unit {
        let cb = PdfContentByte()
        cb.setColorFill(CMYKColor(1.0, 0.0, 0.0, 0.0))
        let out = cbContent(cb)
        @Expect(out.contains(" k\n"), true)
        @Expect(out.contains(" K\n"), false)
    }

    @TestCase
    func testCmykColorStrokeOperator(): Unit {
        let cb = PdfContentByte()
        cb.setColorStroke(CMYKColor(0.0, 0.0, 0.0, 1.0))
        let out = cbContent(cb)
        @Expect(out.contains(" K\n"), true)
        @Expect(out.contains(" k\n"), false)
    }

    @TestCase
    func testCmykBlackFillOutput(): Unit {
        let cb = PdfContentByte()
        cb.setColorFill(CMYKColor.BLACK)
        @Expect(cbContent(cb), "0 0 0 1 k\n")
    }

    @TestCase
    func testCmykCyanStrokeOutput(): Unit {
        let cb = PdfContentByte()
        cb.setColorStroke(CMYKColor.CYAN)
        @Expect(cbContent(cb), "1 0 0 0 K\n")
    }

    // --- 混合使用：算子不互相污染 ---
    @TestCase
    func testMixedColorSpaces(): Unit {
        let cb = PdfContentByte()
        cb.setColorFill(Color(255, 0, 0))        // rg
        cb.setColorStroke(GrayColor(0.5))        // G
        cb.setColorFill(CMYKColor(1.0, 0.0, 0.0, 0.0)) // k
        let out = cbContent(cb)
        @Expect(out.contains("rg"), true)
        @Expect(out.contains(" G\n"), true)
        @Expect(out.contains(" k\n"), true)
    }
}
