/**
 * PDF-CJ: Jp2Parser - JPEG2000 头部解析器
 * 支持 JP2 容器格式（.jp2）和 J2K 裸码流格式（.j2k）
 */
package pdf_cj.image

public struct Jp2Info {
    public var width: Int32
    public var height: Int32
    public var components: Int32
    public var colorSpace: String
    public var bitsPerComponent: Int32

    public init(width: Int32, height: Int32, components: Int32,
                colorSpace: String, bitsPerComponent: Int32) {
        this.width = width
        this.height = height
        this.components = components
        this.colorSpace = colorSpace
        this.bitsPerComponent = bitsPerComponent
    }
}

public class Jp2Parser {

    public static func parse(data: Array<UInt8>): ?Jp2Info {
        if (data.size < 12) { return None }
        if (isJp2Container(data)) { return parseJp2Container(data) }
        if (isJ2kStream(data)) { return parseJ2kStream(data) }
        None
    }

    // ── 格式检测 ─────────────────────────────────────────────────────────────

    // JP2 签名框: length=12 (00 00 00 0C), type="jP  " (6A 50 20 20)
    static func isJp2Container(data: Array<UInt8>): Bool {
        if (data.size < 8) { return false }
        data[0] == 0x00u8 && data[1] == 0x00u8 && data[2] == 0x00u8 && data[3] == 0x0Cu8 &&
        data[4] == 0x6Au8 && data[5] == 0x50u8 && data[6] == 0x20u8 && data[7] == 0x20u8
    }

    // J2K 码流: SOC (FF 4F) + SIZ (FF 51)
    static func isJ2kStream(data: Array<UInt8>): Bool {
        if (data.size < 4) { return false }
        data[0] == 0xFFu8 && data[1] == 0x4Fu8 && data[2] == 0xFFu8 && data[3] == 0x51u8
    }

    // ── JP2 容器解析 ─────────────────────────────────────────────────────────

    static func parseJp2Container(data: Array<UInt8>): ?Jp2Info {
        var offset: Int64 = 0
        var width: Int32 = 0
        var height: Int32 = 0
        var components: Int32 = 3
        var bpc: Int32 = 8
        var colorSpace: String = "DeviceRGB"

        while (offset + 8 <= data.size) {
            let boxLen = readBE32(data, offset)
            let boxType0 = data[offset + 4]
            let boxType1 = data[offset + 5]
            let boxType2 = data[offset + 6]
            let boxType3 = data[offset + 7]

            if (boxLen < 8) { break }

            // jp2h 框 (6A 70 32 68)
            if (boxType0 == 0x6Au8 && boxType1 == 0x70u8 &&
                boxType2 == 0x32u8 && boxType3 == 0x68u8) {
                let subEnd = offset + Int64(boxLen)
                var sub = offset + 8
                while (sub + 8 <= subEnd && sub + 8 <= data.size) {
                    let subLen = readBE32(data, sub)
                    let st0 = data[sub + 4]
                    let st1 = data[sub + 5]
                    let st2 = data[sub + 6]
                    let st3 = data[sub + 7]

                    if (subLen < 8) { break }

                    // ihdr 框 (69 68 64 72): height(4) width(4) NC(2) BPC(1) ...
                    if (st0 == 0x69u8 && st1 == 0x68u8 && st2 == 0x64u8 && st3 == 0x72u8) {
                        if (sub + 22 <= data.size) {
                            height = readBE32(data, sub + 8)
                            width  = readBE32(data, sub + 12)
                            components = Int32(readBE16(data, sub + 16))
                            bpc = (Int32(data[sub + 18]) & 0x7F) + 1
                        }
                    }

                    // colr 框 (63 6F 6C 72): METH(1) PREC(1) APPROX(1) EnumCS(4)
                    if (st0 == 0x63u8 && st1 == 0x6Fu8 && st2 == 0x6Cu8 && st3 == 0x72u8) {
                        if (sub + 15 <= data.size && data[sub + 8] == 0x01u8) {
                            let cs = readBE32(data, sub + 11)
                            colorSpace = csToString(cs, components)
                        }
                    }

                    sub += Int64(subLen)
                }
            }

            offset += Int64(boxLen)
        }

        if (width > 0 && height > 0) {
            Some(Jp2Info(width, height, components, colorSpace, bpc))
        } else {
            None
        }
    }

    // ── J2K 码流解析 ──────────────────────────────────────────────────────────

    static func parseJ2kStream(data: Array<UInt8>): ?Jp2Info {
        // SOC 在 offset 0，SIZ 在 offset 2
        // SIZ 结构: FF51 Lsiz(2) Rsiz(2) Xsiz(4) Ysiz(4) XOsiz(4) YOsiz(4)
        //           XTsiz(4) YTsiz(4) XTOsiz(4) YTOsiz(4) Csiz(2) [components...]
        // 最小需要 42 字节才能读到 Csiz
        if (data.size < 42) { return None }

        let lsiz = readBE16(data, 4)
        if (Int64(lsiz) + 4 > data.size) { return None }

        let xsiz  = readBE32(data, 8)
        let ysiz  = readBE32(data, 12)
        let xosiz = readBE32(data, 16)
        let yosiz = readBE32(data, 20)
        let csiz  = readBE16(data, 40)   // Csiz 在 SIZ marker offset 40

        let width  = xsiz - xosiz
        let height = ysiz - yosiz

        var bpc: Int32 = 8
        if (data.size >= 43) {
            // 第一分量 Ssiz 在 offset 42；低7位是深度-1
            bpc = (Int32(data[42]) & 0x7F) + 1
        }

        let colorSpace = csFromComponents(csiz)
        Some(Jp2Info(width, height, csiz, colorSpace, bpc))
    }

    // ── 辅助函数 ──────────────────────────────────────────────────────────────

    static func readBE32(data: Array<UInt8>, offset: Int64): Int32 {
        if (offset + 3 >= data.size) { return 0 }
        (Int32(data[offset]) << 24) | (Int32(data[offset + 1]) << 16) |
        (Int32(data[offset + 2]) << 8) | Int32(data[offset + 3])
    }

    static func readBE16(data: Array<UInt8>, offset: Int64): Int32 {
        if (offset + 1 >= data.size) { return 0 }
        (Int32(data[offset]) << 8) | Int32(data[offset + 1])
    }

    static func csToString(enumCS: Int32, components: Int32): String {
        match (enumCS) {
            case 16 => "DeviceRGB"
            case 17 => "DeviceGray"
            case 18 => "DeviceGray"
            case 21 => "DeviceCMYK"
            case _  => csFromComponents(components)
        }
    }

    static func csFromComponents(components: Int32): String {
        match (components) {
            case 1 => "DeviceGray"
            case 4 => "DeviceCMYK"
            case _ => "DeviceRGB"
        }
    }
}
