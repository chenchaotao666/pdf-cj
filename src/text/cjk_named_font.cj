/**
 * PDF-CJ: CJKNamedFont - 预置 CMap 的命名 CJK 字体（不嵌入，对标 OpenPDF iText-Asian）
 *
 * 用法：BaseFont.createFontCJK("STSong-Light", "UniGB-UCS2-H")
 * 生成不嵌入字形的 Type0/CIDFontType0 字体，依赖阅读器自带的对应 CJK 字体渲染；
 * 字宽来自打包的 Adobe 度量（精确，非 DW=1000 近似）。
 *
 * 支持（中日韩）：
 *   STSong-Light       / UniGB-UCS2-H   (Adobe-GB1,    简体中文)
 *   MSung-Light        / UniCNS-UCS2-H  (Adobe-CNS1,   繁体中文)
 *   KozMinPro-Regular  / UniJIS-UCS2-H  (Adobe-Japan1, 日文)
 *   HYSMyeongJo-Medium / UniKS-UCS2-H   (Adobe-Korea1, 韩文)
 */
package pdf_cj.text

import std.convert.*

public class CJKNamedFont {
    public let fontName: String
    public let registry: String        // Adobe
    public let ordering: String        // GB1 / CNS1 / Japan1 / Korea1
    public let supplement: Int32
    public let cmapName: String         // UniGB-UCS2-H ...
    public let flags: Int32
    public let bbox: Array<Int32>       // [llx lly urx ury]
    public let ascent: Int32
    public let descent: Int32
    public let capHeight: Int32
    public let stemV: Int32
    public let italicAngle: Int32

    private let _ranges: Array<UInt8>   // 每条 6 字节：startU(2) endU(2) cid(2)，按 startU 升序
    private let _widths: Array<UInt8>   // 每对 4 字节：cid(2) width(2)，按 cid 升序

    private init(fontName: String, desc: String, cmapB64: String, wB64: String) {
        this.fontName = fontName
        // desc = "ordering|supp|flags|llx lly urx ury|ascent|descent|capheight|stemv|italic|cmapName"
        let parts = desc.split("|")
        this.registry = "Adobe"
        this.ordering = parts[0]
        this.supplement = cjkParseI32(parts[1], 0)
        this.flags = cjkParseI32(parts[2], 4)
        let bb = parts[3].split(" ")
        this.bbox = [cjkParseI32(bb[0], -25), cjkParseI32(bb[1], -254),
                     cjkParseI32(bb[2], 1000), cjkParseI32(bb[3], 880)]
        this.ascent = cjkParseI32(parts[4], 880)
        this.descent = cjkParseI32(parts[5], -120)
        this.capHeight = cjkParseI32(parts[6], 880)
        this.stemV = cjkParseI32(parts[7], 80)
        this.italicAngle = cjkParseI32(parts[8], 0)
        this.cmapName = parts[9]
        this._ranges = cjkB64Decode(cmapB64)
        this._widths = cjkB64Decode(wB64)
    }

    /** 按字体名构造；不支持的名字返回 None。 */
    public static func forFont(name: String): ?CJKNamedFont {
        match (cjkFontData(name)) {
            case Some((desc, cmapB64, wB64)) => Some(CJKNamedFont(name, desc, cmapB64, wB64))
            case None => None
        }
    }

    /** 该字体名是否受支持。 */
    public static func isSupported(name: String): Bool {
        match (cjkFontData(name)) {
            case Some(_) => true
            case None => false
        }
    }

    /** Unicode（BMP）→ CID；未映射返回 0。 */
    public func unicodeToCid(u: UInt32): UInt16 {
        if (u > 0xFFFF) { return 0 }
        let target = UInt16(u)
        let n = _ranges.size / 6
        var lo: Int64 = 0
        var hi: Int64 = n - 1
        while (lo <= hi) {
            let mid = (lo + hi) / 2
            let off = mid * 6
            let s = rd16(_ranges, off)
            let e = rd16(_ranges, off + 2)
            if (target < s) {
                hi = mid - 1
            } else if (target > e) {
                lo = mid + 1
            } else {
                let cid = rd16(_ranges, off + 4)
                return UInt16(UInt32(cid) + (u - UInt32(s)))
            }
        }
        0
    }

    /** CID 的字宽（1000 单位）；未列出取默认 1000。 */
    public func cidWidth(cid: UInt16): Int32 {
        let n = _widths.size / 4
        var lo: Int64 = 0
        var hi: Int64 = n - 1
        while (lo <= hi) {
            let mid = (lo + hi) / 2
            let off = mid * 4
            let c = rd16(_widths, off)
            if (cid < c) {
                hi = mid - 1
            } else if (cid > c) {
                lo = mid + 1
            } else {
                return Int32(rd16(_widths, off + 2))
            }
        }
        1000
    }

    private func rd16(d: Array<UInt8>, pos: Int64): UInt16 {
        (UInt16(d[pos]) << 8) | UInt16(d[pos + 1])
    }
}

// ── 工具 ────────────────────────────────────────────────────────────────────

func cjkParseI32(s: String, dft: Int32): Int32 {
    try { Int32.parse(s.trimAscii()) } catch (_: Exception) { dft }
}

// 极简 base64 解码（标准字母表，忽略换行/填充）
func cjkB64Decode(s: String): Array<UInt8> {
    let bytes = s.toArray()
    let out = CjkByteBuf()
    var buf: UInt32 = 0
    var bits: Int32 = 0
    for (b in bytes) {
        let v = cjkB64Val(b)
        if (v < 0) { continue }
        buf = (buf << 6) | UInt32(v)
        bits += 6
        if (bits >= 8) {
            bits -= 8
            out.add(UInt8((buf >> UInt32(bits)) & 0xFF))
        }
    }
    out.toArray()
}

func cjkB64Val(c: UInt8): Int32 {
    if (c >= 65 && c <= 90)  { return Int32(c) - 65 }
    if (c >= 97 && c <= 122) { return Int32(c) - 97 + 26 }
    if (c >= 48 && c <= 57)  { return Int32(c) - 48 + 52 }
    if (c == 43) { return 62 }
    if (c == 47) { return 63 }
    -1
}

// 简单可增长字节缓冲
class CjkByteBuf {
    private var _data: Array<UInt8> = Array<UInt8>(1024, repeat: UInt8(0))
    private var _size: Int64 = 0
    func add(b: UInt8): Unit {
        if (_size >= _data.size) {
            let bigger = Array<UInt8>(_data.size * 2, repeat: UInt8(0))
            for (i in 0.._size) { bigger[i] = _data[i] }
            _data = bigger
        }
        _data[_size] = b
        _size += 1
    }
    func toArray(): Array<UInt8> {
        let r = Array<UInt8>(_size, repeat: UInt8(0))
        for (i in 0.._size) { r[i] = _data[i] }
        r
    }
}
