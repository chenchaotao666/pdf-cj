/**
 * JPEG2000 解析器单元测试（Phase 5.2）
 * 覆盖：Jp2Parser 格式检测、JP2 容器解析、J2K 裸码流解析、Image 集成
 */
package pdf_cj.test.image

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.image.{Jp2Parser, Jp2Info}

// ── 构造最小 JP2 容器数据 ────────────────────────────────────────────────────
//
// JP2 文件结构（最小化）：
//   签名框 (12字节): 00 00 00 0C  6A 50 20 20  0D 0A 87 0A
//   jp2h  框 (45字节):
//     框头  (8): 00 00 00 2D  6A 70 32 68
//     ihdr (22): 00 00 00 16  69 68 64 72
//                 height(4)   width(4)   NC(2) BPC(1) C(1) UnkC(1) IPR(1)
//     colr (15): 00 00 00 0F  63 6F 6C 72
//                 METH(1) PREC(1) APPROX(1) EnumCS(4)
//
// ihdr: height=100 (00 00 00 64), width=200 (00 00 00 C8), NC=3, BPC=7 (=8-1)
// colr: METH=1, EnumCS=16 (DeviceRGB)

func makeJp2Data(width: Int32, height: Int32, components: Int32,
                 enumCS: Int32, bpc: Int32): Array<UInt8> {
    // BPC 字段存储 bpc-1 (低7位)，最高位0=无符号
    let bpcField = UInt8(bpc - 1)
    let h0 = UInt8((height >> 24) & 0xFF)
    let h1 = UInt8((height >> 16) & 0xFF)
    let h2 = UInt8((height >> 8)  & 0xFF)
    let h3 = UInt8(height & 0xFF)
    let w0 = UInt8((width >> 24) & 0xFF)
    let w1 = UInt8((width >> 16) & 0xFF)
    let w2 = UInt8((width >> 8)  & 0xFF)
    let w3 = UInt8(width & 0xFF)
    let nc0 = UInt8((components >> 8) & 0xFF)
    let nc1 = UInt8(components & 0xFF)
    let cs0 = UInt8((enumCS >> 24) & 0xFF)
    let cs1 = UInt8((enumCS >> 16) & 0xFF)
    let cs2 = UInt8((enumCS >> 8)  & 0xFF)
    let cs3 = UInt8(enumCS & 0xFF)

    [
        // 签名框 (12 bytes)
        0x00u8, 0x00u8, 0x00u8, 0x0Cu8,   // length = 12
        0x6Au8, 0x50u8, 0x20u8, 0x20u8,   // type "jP  "
        0x0Du8, 0x0Au8, 0x87u8, 0x0Au8,   // content
        // jp2h 框 (45 bytes)
        0x00u8, 0x00u8, 0x00u8, 0x2Du8,   // length = 45
        0x6Au8, 0x70u8, 0x32u8, 0x68u8,   // type "jp2h"
        // ihdr 子框 (22 bytes)
        0x00u8, 0x00u8, 0x00u8, 0x16u8,   // length = 22
        0x69u8, 0x68u8, 0x64u8, 0x72u8,   // type "ihdr"
        h0, h1, h2, h3,                   // height
        w0, w1, w2, w3,                   // width
        nc0, nc1,                         // NC (components)
        bpcField,                         // BPC
        0x07u8,                           // codec type
        0x00u8, 0x00u8,                   // UnkC, IPR
        // colr 子框 (15 bytes)
        0x00u8, 0x00u8, 0x00u8, 0x0Fu8,   // length = 15
        0x63u8, 0x6Fu8, 0x6Cu8, 0x72u8,   // type "colr"
        0x01u8,                           // METH = 1 (Enumerated Colorspace)
        0x00u8, 0x00u8,                   // PREC, APPROX
        cs0, cs1, cs2, cs3                // EnumCS
    ]
}

// 构造最小 J2K 裸码流数据（>= 43 字节）
func makeJ2kData(width: Int32, height: Int32, components: Int32, bpc: Int32): Array<UInt8> {
    // offset 0-1: SOC marker FF 4F
    // offset 2-3: SIZ marker FF 51
    // offset 4-5: Lsiz = 41 (0x0029) — SIZ segment length
    // offset 6-7: Rsiz = 0
    // offset 8-11: Xsiz
    // offset 12-15: Ysiz
    // offset 16-19: XOsiz = 0
    // offset 20-23: YOsiz = 0
    // offset 24-27: XTsiz = Xsiz
    // offset 28-31: YTsiz = Ysiz
    // offset 32-35: XTOsiz = 0
    // offset 36-39: YTOsiz = 0
    // offset 40-41: Csiz (number of components)
    // offset 42: Ssiz for first component (bpc-1 in low 7 bits)
    let bpcField = UInt8(bpc - 1)
    let x0 = UInt8((width >> 24) & 0xFF)
    let x1 = UInt8((width >> 16) & 0xFF)
    let x2 = UInt8((width >> 8)  & 0xFF)
    let x3 = UInt8(width & 0xFF)
    let y0 = UInt8((height >> 24) & 0xFF)
    let y1 = UInt8((height >> 16) & 0xFF)
    let y2 = UInt8((height >> 8)  & 0xFF)
    let y3 = UInt8(height & 0xFF)
    let c0 = UInt8((components >> 8) & 0xFF)
    let c1 = UInt8(components & 0xFF)

    [
        0xFFu8, 0x4Fu8,                         // SOC
        0xFFu8, 0x51u8,                         // SIZ
        0x00u8, 0x29u8,                         // Lsiz = 41
        0x00u8, 0x00u8,                         // Rsiz
        x0, x1, x2, x3,                        // Xsiz
        y0, y1, y2, y3,                        // Ysiz
        0x00u8, 0x00u8, 0x00u8, 0x00u8,         // XOsiz
        0x00u8, 0x00u8, 0x00u8, 0x00u8,         // YOsiz
        x0, x1, x2, x3,                        // XTsiz = Xsiz
        y0, y1, y2, y3,                        // YTsiz = Ysiz
        0x00u8, 0x00u8, 0x00u8, 0x00u8,         // XTOsiz
        0x00u8, 0x00u8, 0x00u8, 0x00u8,         // YTOsiz
        c0, c1,                                // Csiz
        bpcField, 0x01u8, 0x01u8,              // first component: Ssiz, XRsiz, YRsiz
        bpcField, 0x01u8, 0x01u8,              // second component (if RGB)
        bpcField, 0x01u8, 0x01u8               // third component (if RGB)
    ]
}

// ═══════════════════════════════════════════════════════════════════════════
// Jp2Parser 基础测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class Jp2ParserBasicTests {

    @TestCase
    func testParseEmptyReturnsNone(): Unit {
        let result = Jp2Parser.parse([])
        @Expect(result.isNone(), true)
    }

    @TestCase
    func testParseTooShortReturnsNone(): Unit {
        let result = Jp2Parser.parse([0x00u8, 0x00u8, 0x00u8])
        @Expect(result.isNone(), true)
    }

    @TestCase
    func testParseUnknownFormatReturnsNone(): Unit {
        let data = Array<UInt8>(20, repeat: 0xFFu8)
        let result = Jp2Parser.parse(data)
        @Expect(result.isNone(), true)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// JP2 容器解析测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class Jp2ContainerParserTests {

    @TestCase
    func testParseJp2RgbImageDimensions(): Unit {
        let data = makeJp2Data(200, 100, 3, 16, 8)
        let result = Jp2Parser.parse(data)
        @Expect(result.isSome(), true)
        if (let Some(info) <- result) {
            @Expect(info.width, 200)
            @Expect(info.height, 100)
        }
    }

    @TestCase
    func testParseJp2RgbComponents(): Unit {
        let data = makeJp2Data(200, 100, 3, 16, 8)
        let result = Jp2Parser.parse(data)
        if (let Some(info) <- result) {
            @Expect(info.components, 3)
        }
    }

    @TestCase
    func testParseJp2RgbColorSpace(): Unit {
        let data = makeJp2Data(200, 100, 3, 16, 8)
        let result = Jp2Parser.parse(data)
        if (let Some(info) <- result) {
            @Expect(info.colorSpace, "DeviceRGB")
        }
    }

    @TestCase
    func testParseJp2BitsPerComponent(): Unit {
        let data = makeJp2Data(200, 100, 3, 16, 8)
        let result = Jp2Parser.parse(data)
        if (let Some(info) <- result) {
            @Expect(info.bitsPerComponent, 8)
        }
    }

    @TestCase
    func testParseJp2GrayscaleColorSpace(): Unit {
        // EnumCS=17 → DeviceGray
        let data = makeJp2Data(64, 64, 1, 17, 8)
        let result = Jp2Parser.parse(data)
        if (let Some(info) <- result) {
            @Expect(info.colorSpace, "DeviceGray")
            @Expect(info.components, 1)
        }
    }

    @TestCase
    func testParseJp2SmallImage(): Unit {
        let data = makeJp2Data(1, 1, 1, 17, 8)
        let result = Jp2Parser.parse(data)
        if (let Some(info) <- result) {
            @Expect(info.width, 1)
            @Expect(info.height, 1)
        }
    }

    @TestCase
    func testParseJp2LargeImage(): Unit {
        let data = makeJp2Data(4096, 3000, 3, 16, 8)
        let result = Jp2Parser.parse(data)
        if (let Some(info) <- result) {
            @Expect(info.width, 4096)
            @Expect(info.height, 3000)
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// J2K 裸码流解析测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class J2kStreamParserTests {

    @TestCase
    func testParseJ2kDimensions(): Unit {
        let data = makeJ2kData(320, 240, 3, 8)
        let result = Jp2Parser.parse(data)
        @Expect(result.isSome(), true)
        if (let Some(info) <- result) {
            @Expect(info.width, 320)
            @Expect(info.height, 240)
        }
    }

    @TestCase
    func testParseJ2kComponents(): Unit {
        let data = makeJ2kData(320, 240, 3, 8)
        let result = Jp2Parser.parse(data)
        if (let Some(info) <- result) {
            @Expect(info.components, 3)
        }
    }

    @TestCase
    func testParseJ2kRgbColorSpace(): Unit {
        let data = makeJ2kData(320, 240, 3, 8)
        let result = Jp2Parser.parse(data)
        if (let Some(info) <- result) {
            @Expect(info.colorSpace, "DeviceRGB")
        }
    }

    @TestCase
    func testParseJ2kGrayscaleColorSpace(): Unit {
        let data = makeJ2kData(100, 100, 1, 8)
        let result = Jp2Parser.parse(data)
        if (let Some(info) <- result) {
            @Expect(info.colorSpace, "DeviceGray")
            @Expect(info.components, 1)
        }
    }

    @TestCase
    func testParseJ2kBitsPerComponent(): Unit {
        let data = makeJ2kData(100, 100, 3, 8)
        let result = Jp2Parser.parse(data)
        if (let Some(info) <- result) {
            @Expect(info.bitsPerComponent, 8)
        }
    }

    @TestCase
    func testParseJ2k16BitDepth(): Unit {
        let data = makeJ2kData(100, 100, 1, 16)
        let result = Jp2Parser.parse(data)
        if (let Some(info) <- result) {
            @Expect(info.bitsPerComponent, 16)
        }
    }

    @TestCase
    func testParseJ2kTooShortReturnsNone(): Unit {
        // < 42 bytes
        let data = makeJ2kData(100, 100, 3, 8)
        let shortData = Array<UInt8>(20, {i => data[i]})
        let result = Jp2Parser.parse(shortData)
        @Expect(result.isNone(), true)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// Jp2Info 结构体测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class Jp2InfoTests {

    @TestCase
    func testJp2InfoFields(): Unit {
        let info = Jp2Info(640, 480, 3, "DeviceRGB", 8)
        @Expect(info.width, 640)
        @Expect(info.height, 480)
        @Expect(info.components, 3)
        @Expect(info.colorSpace, "DeviceRGB")
        @Expect(info.bitsPerComponent, 8)
    }

    @TestCase
    func testJp2InfoGrayscale(): Unit {
        let info = Jp2Info(100, 100, 1, "DeviceGray", 8)
        @Expect(info.components, 1)
        @Expect(info.colorSpace, "DeviceGray")
    }

    @TestCase
    func testJp2InfoCmyk(): Unit {
        let info = Jp2Info(100, 100, 4, "DeviceCMYK", 8)
        @Expect(info.components, 4)
        @Expect(info.colorSpace, "DeviceCMYK")
    }
}
