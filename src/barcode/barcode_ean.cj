/**
 * PDF-CJ: BarcodeEAN - EAN-13 / EAN-8 条形码
 * 支持 EAN-13（13 位）和 EAN-8（8 位）
 */
package pdf_cj.barcode

import pdf_cj.core.PdfContentByte
import pdf_cj.text.Color
import pdf_cj.image.Image
import std.collection.ArrayList

// EAN L-码宽度 [space, bar, space, bar]（共 4 个元素，7 模块）
let EAN_L: Array<Int32> = [
    3,2,1,1,  // 0
    2,2,2,1,  // 1
    2,1,2,2,  // 2
    1,4,1,1,  // 3
    1,1,3,2,  // 4
    1,2,3,1,  // 5
    1,1,1,4,  // 6
    1,3,1,2,  // 7
    1,2,1,3,  // 8
    3,1,1,2   // 9
]

// EAN G-码宽度（L 的宽度逆序）[space, bar, space, bar]
let EAN_G: Array<Int32> = [
    1,1,2,3,  // 0
    1,2,2,2,  // 1
    2,2,1,2,  // 2
    1,1,4,1,  // 3
    2,3,1,1,  // 4
    1,3,2,1,  // 5
    4,1,1,1,  // 6
    2,1,3,1,  // 7
    3,1,2,1,  // 8
    2,1,1,3   // 9
]

// EAN R-码宽度（L 的补码）[bar, space, bar, space]
let EAN_R: Array<Int32> = [
    3,2,1,1,  // 0
    2,2,2,1,  // 1
    2,1,2,2,  // 2
    1,4,1,1,  // 3
    1,1,3,2,  // 4
    1,2,3,1,  // 5
    1,1,1,4,  // 6
    1,3,1,2,  // 7
    1,2,1,3,  // 8
    3,1,1,2   // 9
]

// EAN-13 奇偶校验表（第一位 0-9 → 6 位编码方式，0=L, 1=G）
let EAN13_PARITY: Array<Array<Int32>> = [
    [0,0,0,0,0,0],  // 0: LLLLLL
    [0,0,1,0,1,1],  // 1: LLGLGG
    [0,0,1,1,0,1],  // 2: LLGGLG
    [0,0,1,1,1,0],  // 3: LLGGGL
    [0,1,0,0,1,1],  // 4: LGLLGG
    [0,1,1,0,0,1],  // 5: LGGLLG
    [0,1,1,1,0,0],  // 6: LGGGLL
    [0,1,0,1,0,1],  // 7: LGLGLG
    [0,1,0,1,1,0],  // 8: LGLGGL
    [0,1,1,0,1,0]   // 9: LGGLGL
]

/**
 * EAN-13 / EAN-8 条形码
 */
public class BarcodeEAN {
    public var code: String = ""           // 12 位（EAN-13，自动计算校验）或 7 位（EAN-8）
    public var x: Float32 = 50.0
    public var y: Float32 = 700.0
    public var barHeight: Float32 = 30.0
    public var moduleWidth: Float32 = 1.5
    public var isEAN8: Bool = false

    public init() {}

    public init(code: String) {
        this.code = code
    }

    /**
     * 渲染并返回 Image
     */
    public func createImage(cb: PdfContentByte, barColor: Color, textColor: Color): Image {
        let bars = if (isEAN8) { encodeEAN8() } else { encodeEAN13() }
        let totalW = calcTotalModules(bars)
        renderLinearBarcode(cb, bars, x, y, moduleWidth, barHeight, barColor)
        let img = makeBarcodeImage(Int32(Float32(totalW) * moduleWidth) + 1, Int32(barHeight))
        img.setAbsolutePosition(x, y)
        img
    }

    private func calcTotalModules(bars: ArrayList<(Int32, Bool)>): Int32 {
        var total: Int32 = 0
        var i: Int64 = 0
        while (i < bars.size) {
            let (w, _) = bars[i]
            total += w
            i += 1
        }
        total
    }

    // ── EAN-13 编码 ───────────────────────────────────────────────────────────

    private func encodeEAN13(): ArrayList<(Int32, Bool)> {
        let result = ArrayList<(Int32, Bool)>()
        let digits = buildEAN13Digits()

        // 左保护（1,1,1 → bar,space,bar）
        result.add((1, true))
        result.add((1, false))
        result.add((1, true))

        let parity = EAN13_PARITY[Int64(digits[0])]

        // 左半（6 位，L 或 G 编码，起始为 space）
        var i: Int32 = 1
        while (i <= 6) {
            let d = digits[Int64(i)]
            let enc = parity[Int64(i - 1)]
            let base = Int64(d) * 4
            let tbl = if (enc == 0) { EAN_L } else { EAN_G }
            // s, b, s, b
            result.add((tbl[base],     false))
            result.add((tbl[base + 1], true))
            result.add((tbl[base + 2], false))
            result.add((tbl[base + 3], true))
            i += 1
        }

        // 中心保护（space,bar,space,bar,space = 5 模块）
        result.add((1, false))
        result.add((1, true))
        result.add((1, false))
        result.add((1, true))
        result.add((1, false))

        // 右半（6 位，R 编码，起始为 bar）
        var j: Int32 = 7
        while (j <= 12) {
            let d = digits[Int64(j)]
            let base = Int64(d) * 4
            // b, s, b, s
            result.add((EAN_R[base],     true))
            result.add((EAN_R[base + 1], false))
            result.add((EAN_R[base + 2], true))
            result.add((EAN_R[base + 3], false))
            j += 1
        }

        // 右保护（1,1,1 → bar,space,bar）
        result.add((1, true))
        result.add((1, false))
        result.add((1, true))

        result
    }

    /**
     * 构建 EAN-13 的 13 位数字数组（index 12 为校验位）
     */
    private func buildEAN13Digits(): Array<Int32> {
        let digits = Array<Int32>(13, repeat: 0)
        var idx: Int32 = 0
        for (c in code.runes()) {
            let ch = Int32(UInt32(c))
            if (ch >= 48 && ch <= 57 && idx < 13) {
                digits[Int64(idx)] = ch - 48
                idx += 1
            }
        }
        if (idx <= 12) {
            // 自动计算校验位
            var sum: Int32 = 0
            var k: Int32 = 0
            while (k < 12) {
                let w: Int32 = if (k % 2 == 0) { 1 } else { 3 }
                sum += digits[Int64(k)] * w
                k += 1
            }
            digits[12] = (10 - sum % 10) % 10
        }
        digits
    }

    // ── EAN-8 编码 ────────────────────────────────────────────────────────────

    private func encodeEAN8(): ArrayList<(Int32, Bool)> {
        let result = ArrayList<(Int32, Bool)>()
        let digits = buildEAN8Digits()

        // 左保护
        result.add((1, true))
        result.add((1, false))
        result.add((1, true))

        // 左 4 位（L 编码）
        var i: Int32 = 0
        while (i < 4) {
            let d = digits[Int64(i)]
            let base = Int64(d) * 4
            result.add((EAN_L[base],     false))
            result.add((EAN_L[base + 1], true))
            result.add((EAN_L[base + 2], false))
            result.add((EAN_L[base + 3], true))
            i += 1
        }

        // 中心保护
        result.add((1, false))
        result.add((1, true))
        result.add((1, false))
        result.add((1, true))
        result.add((1, false))

        // 右 4 位（R 编码）
        var j: Int32 = 4
        while (j < 8) {
            let d = digits[Int64(j)]
            let base = Int64(d) * 4
            result.add((EAN_R[base],     true))
            result.add((EAN_R[base + 1], false))
            result.add((EAN_R[base + 2], true))
            result.add((EAN_R[base + 3], false))
            j += 1
        }

        // 右保护
        result.add((1, true))
        result.add((1, false))
        result.add((1, true))

        result
    }

    private func buildEAN8Digits(): Array<Int32> {
        let digits = Array<Int32>(8, repeat: 0)
        var idx: Int32 = 0
        for (c in code.runes()) {
            let ch = Int32(UInt32(c))
            if (ch >= 48 && ch <= 57 && idx < 8) {
                digits[Int64(idx)] = ch - 48
                idx += 1
            }
        }
        if (idx <= 7) {
            var sum: Int32 = 0
            var k: Int32 = 0
            while (k < 7) {
                let w: Int32 = if (k % 2 == 0) { 3 } else { 1 }
                sum += digits[Int64(k)] * w
                k += 1
            }
            digits[7] = (10 - sum % 10) % 10
        }
        digits
    }
}
