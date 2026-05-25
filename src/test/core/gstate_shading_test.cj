/**
 * 透明度与渐变单元测试（Phase 5.3）
 * 覆盖：PdfGState、PdfAxialShading、PdfRadialShading、PdfShadingPattern
 *        以及 PdfContentByte 新操作符
 */
package pdf_cj.test.core

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.core.{
    PdfContentByte,
    PdfGState, BlendMode,
    PdfAxialShading, PdfRadialShading,
    PdfShadingPattern
}
import pdf_cj.base.{PdfName}
import pdf_cj.text.Color

// ── 辅助 ──────────────────────────────────────────────────────────────────────

func cbStr53(cb: PdfContentByte): String {
    let bytes = cb.toByteArray()
    var s = ""
    for (b in bytes) { s += String(Rune(UInt32(b))) }
    s
}

// ═══════════════════════════════════════════════════════════════════════════
// PdfGState 测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class PdfGStateTests {

    @TestCase
    func testEmptyGStateHasNoAlphaOrBlend(): Unit {
        let gs = PdfGState()
        let dict = gs.toDictionary()
        @Expect(dict.contains(PdfName.ca), false)
        @Expect(dict.contains(PdfName.CA), false)
        @Expect(dict.contains(PdfName.BM), false)
    }

    @TestCase
    func testFillAlphaSetInDict(): Unit {
        let gs = PdfGState()
        gs.setFillAlpha(0.5)
        let dict = gs.toDictionary()
        @Expect(dict.contains(PdfName.ca), true)
        @Expect(dict.contains(PdfName.CA), false)
    }

    @TestCase
    func testFillAlphaValueStored(): Unit {
        let gs = PdfGState()
        gs.setFillAlpha(0.5)
        @Expect(gs.fillAlpha, 0.5)
    }

    @TestCase
    func testStrokeAlphaSetInDict(): Unit {
        let gs = PdfGState()
        gs.setStrokeAlpha(0.8)
        let dict = gs.toDictionary()
        @Expect(dict.contains(PdfName.ca), false)
        @Expect(dict.contains(PdfName.CA), true)
    }

    @TestCase
    func testStrokeAlphaValueStored(): Unit {
        let gs = PdfGState()
        gs.setStrokeAlpha(0.8)
        @Expect(gs.strokeAlpha, 0.8)
    }

    @TestCase
    func testBlendModeSetInDict(): Unit {
        let gs = PdfGState()
        gs.setBlendMode(BlendMode.MULTIPLY)
        let dict = gs.toDictionary()
        @Expect(dict.contains(PdfName.BM), true)
    }

    @TestCase
    func testBlendModeValue(): Unit {
        let gs = PdfGState()
        gs.setBlendMode(BlendMode.SCREEN)
        @Expect(gs.blendMode, "Screen")
    }

    @TestCase
    func testFullGStateAllFields(): Unit {
        let gs = PdfGState()
        gs.setFillAlpha(0.3)
        gs.setStrokeAlpha(0.7)
        gs.setBlendMode(BlendMode.OVERLAY)
        let dict = gs.toDictionary()
        @Expect(dict.contains(PdfName.ca), true)
        @Expect(dict.contains(PdfName.CA), true)
        @Expect(dict.contains(PdfName.BM), true)
    }

    @TestCase
    func testGStateDefaultValues(): Unit {
        let gs = PdfGState()
        @Expect(gs.fillAlpha, 1.0)
        @Expect(gs.strokeAlpha, 1.0)
        @Expect(gs.blendMode, "Normal")
    }

    @TestCase
    func testGStateZeroAlpha(): Unit {
        let gs = PdfGState()
        gs.setFillAlpha(0.0)
        @Expect(gs.fillAlpha, 0.0)
        let dict = gs.toDictionary()
        @Expect(dict.contains(PdfName.ca), true)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// BlendMode 常量测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class BlendModeTests {

    @TestCase
    func testAllBlendModeConstants(): Unit {
        @Expect(BlendMode.NORMAL,      "Normal")
        @Expect(BlendMode.MULTIPLY,    "Multiply")
        @Expect(BlendMode.SCREEN,      "Screen")
        @Expect(BlendMode.OVERLAY,     "Overlay")
        @Expect(BlendMode.DARKEN,      "Darken")
        @Expect(BlendMode.LIGHTEN,     "Lighten")
        @Expect(BlendMode.COLOR_DODGE, "ColorDodge")
        @Expect(BlendMode.COLOR_BURN,  "ColorBurn")
        @Expect(BlendMode.HARD_LIGHT,  "HardLight")
        @Expect(BlendMode.SOFT_LIGHT,  "SoftLight")
        @Expect(BlendMode.DIFFERENCE,  "Difference")
        @Expect(BlendMode.EXCLUSION,   "Exclusion")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// PdfAxialShading 测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class PdfAxialShadingTests {

    @TestCase
    func testDictHasRequiredKeys(): Unit {
        let s = PdfAxialShading(0.0, 0.0, Color.BLACK, 100.0, 0.0, Color.WHITE)
        let dict = s.toDictionary()
        @Expect(dict.contains(PdfName.SHADINGTYPE), true)
        @Expect(dict.contains(PdfName.COLORSPACE),  true)
        @Expect(dict.contains(PdfName.COORDS),      true)
        @Expect(dict.contains(PdfName.FUNCTION),    true)
        @Expect(dict.contains(PdfName.EXTEND),      true)
    }

    @TestCase
    func testShadingTypeIs2(): Unit {
        let s = PdfAxialShading(0.0, 0.0, Color.BLACK, 100.0, 0.0, Color.WHITE)
        let dict = s.toDictionary()
        match (dict.getAsNumber(PdfName.SHADINGTYPE)) {
            case Some(n) => @Expect(n.intVal(), Int64(2))
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testCoordsHas4Elements(): Unit {
        let s = PdfAxialShading(10.0, 20.0, Color.RED, 110.0, 20.0, Color.BLUE)
        let dict = s.toDictionary()
        match (dict.getAsArray(PdfName.COORDS)) {
            case Some(arr) => @Expect(arr.size, Int64(4))
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testColorSpaceIsDeviceRGB(): Unit {
        let s = PdfAxialShading(0.0, 0.0, Color.RED, 100.0, 0.0, Color.BLUE)
        let dict = s.toDictionary()
        match (dict.getAsName(PdfName.COLORSPACE)) {
            case Some(n) => @Expect(n.name, "DeviceRGB")
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testFunctionHasC0C1DomainN(): Unit {
        let s = PdfAxialShading(0.0, 0.0, Color.RED, 100.0, 0.0, Color.BLUE)
        let dict = s.toDictionary()
        match (dict.getAsDictionary(PdfName.FUNCTION)) {
            case Some(fn) =>
                @Expect(fn.contains(PdfName.C0),           true)
                @Expect(fn.contains(PdfName.C1),           true)
                @Expect(fn.contains(PdfName.DOMAIN),       true)
                @Expect(fn.contains(PdfName.N),            true)
                @Expect(fn.contains(PdfName.FUNCTIONTYPE), true)
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testC0HasThreeComponents(): Unit {
        let s = PdfAxialShading(0.0, 0.0, Color.RED, 100.0, 0.0, Color.BLUE)
        match (s.toDictionary().getAsDictionary(PdfName.FUNCTION)) {
            case Some(fn) =>
                match (fn.getAsArray(PdfName.C0)) {
                    case Some(c0) => @Expect(c0.size, Int64(3))
                    case None => @Expect(true, false)
                }
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testExtendHas2Elements(): Unit {
        let s = PdfAxialShading()
        match (s.toDictionary().getAsArray(PdfName.EXTEND)) {
            case Some(arr) => @Expect(arr.size, Int64(2))
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testDefaultFieldValues(): Unit {
        let s = PdfAxialShading()
        @Expect(s.x0, 0.0)
        @Expect(s.y0, 0.0)
        @Expect(s.x1, 100.0)
        @Expect(s.y1, 0.0)
        @Expect(s.extendBoth, true)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// PdfRadialShading 测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class PdfRadialShadingTests {

    @TestCase
    func testDictHasRequiredKeys(): Unit {
        let s = PdfRadialShading(100.0, 100.0, 0.0, Color.WHITE,
                                 100.0, 100.0, 50.0, Color.BLUE)
        let dict = s.toDictionary()
        @Expect(dict.contains(PdfName.SHADINGTYPE), true)
        @Expect(dict.contains(PdfName.COLORSPACE),  true)
        @Expect(dict.contains(PdfName.COORDS),      true)
        @Expect(dict.contains(PdfName.FUNCTION),    true)
        @Expect(dict.contains(PdfName.EXTEND),      true)
    }

    @TestCase
    func testShadingTypeIs3(): Unit {
        let s = PdfRadialShading(100.0, 100.0, 0.0, Color.WHITE,
                                 100.0, 100.0, 50.0, Color.BLUE)
        match (s.toDictionary().getAsNumber(PdfName.SHADINGTYPE)) {
            case Some(n) => @Expect(n.intVal(), Int64(3))
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testCoordsHas6Elements(): Unit {
        let s = PdfRadialShading(100.0, 100.0, 0.0, Color.WHITE,
                                 100.0, 100.0, 50.0, Color.BLUE)
        match (s.toDictionary().getAsArray(PdfName.COORDS)) {
            case Some(arr) => @Expect(arr.size, Int64(6))
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testColorSpaceIsDeviceRGB(): Unit {
        let s = PdfRadialShading(0.0, 0.0, 0.0, Color.RED, 0.0, 0.0, 50.0, Color.BLUE)
        match (s.toDictionary().getAsName(PdfName.COLORSPACE)) {
            case Some(n) => @Expect(n.name, "DeviceRGB")
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testDefaultFieldValues(): Unit {
        let s = PdfRadialShading()
        @Expect(s.r0, 0.0)
        @Expect(s.r1, 50.0)
        @Expect(s.cx0, 0.0)
        @Expect(s.cy0, 0.0)
        @Expect(s.extendBoth, true)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// PdfShadingPattern 测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class PdfShadingPatternTests {

    @TestCase
    func testDictHasRequiredKeys(): Unit {
        let pattern = PdfShadingPattern(PdfAxialShading())
        let dict = pattern.toDictionary()
        @Expect(dict.contains(PdfName.PATTERNTYPE), true)
        @Expect(dict.contains(PdfName.SHADING),     true)
        @Expect(dict.contains(PdfName.MATRIX),      true)
    }

    @TestCase
    func testPatternTypeIs2(): Unit {
        let pattern = PdfShadingPattern(PdfAxialShading())
        match (pattern.toDictionary().getAsNumber(PdfName.PATTERNTYPE)) {
            case Some(n) => @Expect(n.intVal(), Int64(2))
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testMatrixHas6Elements(): Unit {
        let pattern = PdfShadingPattern(PdfAxialShading())
        match (pattern.toDictionary().getAsArray(PdfName.MATRIX)) {
            case Some(arr) => @Expect(arr.size, Int64(6))
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testShadingDictEmbedded(): Unit {
        let shading = PdfRadialShading(100.0, 100.0, 0.0, Color.WHITE,
                                       100.0, 100.0, 50.0, Color.BLUE)
        let pattern = PdfShadingPattern(shading)
        match (pattern.toDictionary().getAsDictionary(PdfName.SHADING)) {
            case Some(sd) => @Expect(sd.contains(PdfName.SHADINGTYPE), true)
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testCustomMatrix(): Unit {
        let pattern = PdfShadingPattern(PdfAxialShading())
        pattern.setMatrix(2.0, 0.0, 0.0, 2.0, 50.0, 100.0)
        match (pattern.toDictionary().getAsArray(PdfName.MATRIX)) {
            case Some(arr) => @Expect(arr.size, Int64(6))
            case None => @Expect(true, false)
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// PdfContentByte 新操作符测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class ContentByteGStateTests {

    @TestCase
    func testSetExtGState(): Unit {
        let cb = PdfContentByte()
        cb.setExtGState("GS1")
        @Expect(cbStr53(cb), "/GS1 gs\n")
    }

    @TestCase
    func testSetColorFillPattern(): Unit {
        let cb = PdfContentByte()
        cb.setColorFillPattern("P1")
        @Expect(cbStr53(cb), "/Pattern cs\n/P1 scn\n")
    }

    @TestCase
    func testSetColorStrokePattern(): Unit {
        let cb = PdfContentByte()
        cb.setColorStrokePattern("P2")
        @Expect(cbStr53(cb), "/Pattern CS\n/P2 SCN\n")
    }

    @TestCase
    func testPaintShading(): Unit {
        let cb = PdfContentByte()
        cb.paintShading("Sh1")
        @Expect(cbStr53(cb), "/Sh1 sh\n")
    }

    @TestCase
    func testSaveRestoreWithGState(): Unit {
        let cb = PdfContentByte()
        cb.saveState()
        cb.setExtGState("GS1")
        cb.restoreState()
        @Expect(cbStr53(cb), "q\n/GS1 gs\nQ\n")
    }

    @TestCase
    func testPatternFillSequenceHasExpectedParts(): Unit {
        let cb = PdfContentByte()
        cb.saveState()
        cb.setColorFillPattern("P1")
        cb.rectangle(10.0, 10.0, 100.0, 50.0)
        cb.fill()
        cb.restoreState()
        let s = cbStr53(cb)
        @Expect(s.contains("/Pattern cs"), true)
        @Expect(s.contains("/P1 scn"),     true)
        @Expect(s.contains("f\n"),         true)
        @Expect(s.contains("q\n"),         true)
        @Expect(s.contains("Q\n"),         true)
    }

    @TestCase
    func testPaintShadingWithSaveRestore(): Unit {
        let cb = PdfContentByte()
        cb.saveState()
        cb.paintShading("Sh1")
        cb.restoreState()
        @Expect(cbStr53(cb), "q\n/Sh1 sh\nQ\n")
    }
}
