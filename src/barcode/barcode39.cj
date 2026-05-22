/**
 * PDF-CJ: Barcode39 - Code 39 条形码
 * 支持字符集：0-9, A-Z, -(minus), .(period), space, $, /, +, %
 * 含起始/终止符 *
 */
package pdf_cj.barcode

import pdf_cj.core.PdfContentByte
import pdf_cj.text.Color
import pdf_cj.image.Image
import std.collection.ArrayList

// C39 字符集字符串（包含起始/终止 '*'）
let C39_CHARS: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%*"

// 每个字符 9 元素序列 [b1,s1,b2,s2,b3,s3,b4,s4,b5]，1=窄，3=宽
// 索引：对应 C39_CHARS 中的位置
let C39_PAT: Array<Int32> = [
    // '0' 000110100
    1,1,1,3,3,1,3,1,1,
    // '1' 100100001
    3,1,1,3,1,1,1,1,3,
    // '2' 001100001
    1,1,3,3,1,1,1,1,3,
    // '3' 101100000
    3,1,3,3,1,1,1,1,1,
    // '4' 000110001
    1,1,1,3,3,1,1,1,3,
    // '5' 100110000
    3,1,1,3,3,1,1,1,1,
    // '6' 001110000
    1,1,3,3,3,1,1,1,1,
    // '7' 000100101
    1,1,1,3,1,1,3,1,3,
    // '8' 100100100
    3,1,1,3,1,1,3,1,1,
    // '9' 001100100
    1,1,3,3,1,1,3,1,1,
    // 'A' 100001001
    3,1,1,1,1,3,1,1,3,
    // 'B' 001001001
    1,1,3,1,1,3,1,1,3,
    // 'C' 101001000
    3,1,3,1,1,3,1,1,1,
    // 'D' 000011001
    1,1,1,1,3,3,1,1,3,
    // 'E' 100011000
    3,1,1,1,3,3,1,1,1,
    // 'F' 001011000
    1,1,3,1,3,3,1,1,1,
    // 'G' 000001101
    1,1,1,1,1,3,3,1,3,
    // 'H' 100001100
    3,1,1,1,1,3,3,1,1,
    // 'I' 001001100
    1,1,3,1,1,3,3,1,1,
    // 'J' 000011100
    1,1,1,1,3,3,3,1,1,
    // 'K' 100000011
    3,1,1,1,1,1,1,3,3,
    // 'L' 001000011
    1,1,3,1,1,1,1,3,3,
    // 'M' 101000010
    3,1,3,1,1,1,1,3,1,
    // 'N' 000010011
    1,1,1,1,3,1,1,3,3,
    // 'O' 100010010
    3,1,1,1,3,1,1,3,1,
    // 'P' 001010010
    1,1,3,1,3,1,1,3,1,
    // 'Q' 000000111
    1,1,1,1,1,1,3,3,3,
    // 'R' 100000110
    3,1,1,1,1,1,3,3,1,
    // 'S' 001000110
    1,1,3,1,1,1,3,3,1,
    // 'T' 000010110
    1,1,1,1,3,1,3,3,1,
    // 'U' 110000001
    3,3,1,1,1,1,1,1,3,
    // 'V' 011000001
    1,3,3,1,1,1,1,1,3,
    // 'W' 111000000
    3,3,3,1,1,1,1,1,1,
    // 'X' 010000101
    1,3,1,1,1,1,3,1,3,
    // 'Y' 110000100
    3,3,1,1,1,1,3,1,1,
    // 'Z' 011000100
    1,3,3,1,1,1,3,1,1,
    // '-' 000100011
    1,1,1,3,1,1,1,3,3,
    // '.' 100100010
    3,1,1,3,1,1,1,3,1,
    // ' ' 011100000
    1,3,3,3,1,1,1,1,1,
    // '$' 010101000
    1,3,1,3,1,3,1,1,1,
    // '/' 010100010
    1,3,1,3,1,1,1,3,1,
    // '+' 010001010
    1,3,1,1,1,3,1,3,1,
    // '%' 000101010
    1,1,1,3,1,3,1,3,1,
    // '*' 010010100
    1,3,1,1,3,1,3,1,1
]

/**
 * Code 39 条形码
 */
public class Barcode39 {
    public var code: String = ""
    public var x: Float32 = 50.0
    public var y: Float32 = 700.0
    public var barHeight: Float32 = 30.0
    public var moduleWidth: Float32 = 1.2
    public var interCharGap: Int32 = 1

    public init() {}

    public init(code: String) {
        this.code = code
    }

    public func createImage(cb: PdfContentByte, barColor: Color, textColor: Color): Image {
        let bars = encode()
        var totalMod: Int32 = 0
        var ii: Int64 = 0
        while (ii < bars.size) {
            let (w, _) = bars[ii]
            totalMod += w
            ii += 1
        }
        renderLinearBarcode(cb, bars, x, y, moduleWidth, barHeight, barColor)
        let img = makeBarcodeImage(Int32(Float32(totalMod) * moduleWidth) + 1, Int32(barHeight))
        img.setAbsolutePosition(x, y)
        img
    }

    private func encode(): ArrayList<(Int32, Bool)> {
        let result = ArrayList<(Int32, Bool)>()
        appendSym(result, r'*')
        result.add((interCharGap, false))
        for (c in code.runes()) {
            let up = toUpperRune(c)
            let idx = findChar(up)
            if (idx >= 0) {
                appendSymIdx(result, idx)
                result.add((interCharGap, false))
            }
        }
        appendSym(result, r'*')
        result
    }

    private func appendSym(result: ArrayList<(Int32, Bool)>, c: Rune): Unit {
        let idx = findChar(c)
        if (idx >= 0) { appendSymIdx(result, idx) }
    }

    private func appendSymIdx(result: ArrayList<(Int32, Bool)>, idx: Int32): Unit {
        let base = Int64(idx) * 9
        var j: Int32 = 0
        while (j < 9) {
            let w = C39_PAT[base + Int64(j)]
            result.add((w, j % 2 == 0))
            j += 1
        }
    }

    private func findChar(c: Rune): Int32 {
        var idx: Int32 = 0
        for (r in C39_CHARS.runes()) {
            if (UInt32(r) == UInt32(c)) { return idx }
            idx += 1
        }
        -1
    }

    private func toUpperRune(c: Rune): Rune {
        let code = UInt32(c)
        if (code >= 97u32 && code <= 122u32) {
            Rune(code - 32u32)
        } else {
            c
        }
    }
}
