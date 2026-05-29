/**
 * PDF-CJ: Barcode128 - Code 128 B 条形码
 * 支持 ASCII 32-127 字符，含校验位
 */
package pdf_cj.barcode

import pdf_cj.core.PdfContentByte
import pdf_cj.text.Color
import pdf_cj.image.Image
import std.collection.ArrayList

// Code 128 B 每个符号的 [b1,s1,b2,s2,b3,s3] 宽度表（符号 0..106）
// 符号 0-94 对应 ASCII 32-126（值 = ASCII - 32）
// 符号 103=Start A, 104=Start B, 105=Start C, 106=Stop(7元素)
let C128_TABLE: Array<Int32> = [
    // 0-9
    2,1,2,2,2,2,  2,2,2,1,2,2,  2,2,2,2,2,1,  1,2,1,2,2,3,  1,2,1,3,2,2,
    1,3,1,2,2,2,  1,2,2,2,1,3,  1,2,2,3,1,2,  1,3,2,2,1,2,  2,2,1,2,1,3,
    // 10-19
    2,2,1,3,1,2,  2,3,1,2,1,2,  1,1,2,2,3,2,  1,2,2,1,3,2,  1,2,2,2,3,1,
    1,1,3,2,2,2,  1,2,3,1,2,2,  1,2,3,2,2,1,  2,2,3,2,1,1,  2,2,1,1,3,2,
    // 20-29
    2,2,1,2,3,1,  2,1,3,2,1,2,  2,2,3,1,1,2,  3,1,2,1,3,1,  3,1,1,2,2,2,
    3,2,1,1,2,2,  3,2,1,2,2,1,  3,1,2,2,1,2,  3,2,2,1,1,2,  3,2,2,2,1,1,
    // 30-39
    2,1,2,1,2,3,  2,1,2,3,2,1,  2,3,2,1,2,1,  1,1,1,3,2,3,  1,3,1,1,2,3,
    1,3,1,3,2,1,  1,1,2,3,1,3,  1,3,2,1,1,3,  1,3,2,3,1,1,  2,1,1,3,1,3,
    // 40-49
    2,3,1,1,1,3,  2,3,1,3,1,1,  1,1,2,1,3,3,  1,1,2,3,3,1,  1,3,2,1,3,1,
    1,1,3,1,2,3,  1,1,3,3,2,1,  1,3,3,1,2,1,  3,1,3,1,2,1,  2,1,1,3,3,1,
    // 50-59
    2,3,1,1,3,1,  2,1,3,1,1,3,  2,1,3,3,1,1,  2,1,3,1,3,1,  3,1,1,1,2,3,
    3,1,1,3,2,1,  3,3,1,1,2,1,  3,1,2,1,1,3,  3,1,2,3,1,1,  3,3,2,1,1,1,
    // 60-69
    3,1,4,1,1,1,  2,2,1,4,1,1,  4,3,1,1,1,1,  1,1,1,2,2,4,  1,1,1,4,2,2,
    1,2,1,1,2,4,  1,2,1,4,2,1,  1,4,1,1,2,2,  1,4,1,2,2,1,  1,1,2,2,1,4,
    // 70-79
    1,1,2,4,1,2,  1,2,2,1,1,4,  1,2,2,4,1,1,  1,4,2,1,1,2,  1,4,2,2,1,1,
    2,4,1,2,1,1,  2,2,1,1,1,4,  4,1,3,1,1,1,  2,4,1,1,1,2,  1,3,4,1,1,1,
    // 80-89
    1,1,1,2,4,2,  1,2,1,1,4,2,  1,2,1,2,4,1,  1,1,4,2,1,2,  1,2,4,1,1,2,
    1,2,4,2,1,1,  4,1,1,2,1,2,  4,2,1,1,1,2,  4,2,1,2,1,1,  2,1,2,1,4,1,
    // 90-99
    2,1,4,1,2,1,  4,1,2,1,2,1,  1,1,1,1,4,3,  1,1,1,3,4,1,  1,3,1,1,4,1,
    1,1,4,1,1,3,  1,1,4,3,1,1,  4,1,1,1,1,3,  4,1,1,3,1,1,  1,1,3,1,4,1,
    // 100-106
    1,1,4,1,3,1,  3,1,1,1,4,1,  4,1,1,1,3,1,
    2,1,1,4,1,2,  // 103 Start A
    2,1,1,2,1,4,  // 104 Start B
    2,1,1,2,3,2,  // 105 Start C
    2,3,3,1,1,1   // 106 Stop（只有 6 个值，后面补一个终止条 2）
]

// Stop 的额外终止条宽度（第 7 个元素）
let C128_STOP_TERM: Int32 = 2

/**
 * Code 128 B 条形码
 */
public class Barcode128 {
    public var code: String = ""
    public var x: Float32 = 50.0
    public var y: Float32 = 700.0
    public var barHeight: Float32 = 30.0
    public var moduleWidth: Float32 = 1.5  // 最窄模块宽度（pt）

    public init() {}

    public init(code: String) {
        this.code = code
    }

    /**
     * 渲染条形码到 cb，返回代表尺寸的 Image
     */
    public func createImage(cb: PdfContentByte, barColor: Color, textColor: Color): Image {
        let symbols = encode()
        let bars = symbolsToBars(symbols)
        let totalW = calcWidth(bars)
        renderLinearBarcode(cb, bars, x, y, moduleWidth, barHeight, barColor)
        let img = makeBarcodeImage(Int32(totalW), Int32(barHeight))
        img.setAbsolutePosition(x, y)
        img
    }

    /**
     * 计算所有 (宽, isBar) 中总模块数 × moduleWidth
     */
    private func calcWidth(bars: ArrayList<(Int32, Bool)>): Int32 {
        var total: Int32 = 0
        var i: Int64 = 0
        while (i < bars.size) {
            let (w, _) = bars[i]
            total += w
            i += 1
        }
        let pw = Float32(total) * moduleWidth
        Int32(pw) + 1
    }

    /**
     * 将 Code 128 B 符号列表转为 (宽度, isBar) 对
     */
    private func symbolsToBars(symbols: ArrayList<Int32>): ArrayList<(Int32, Bool)> {
        let result = ArrayList<(Int32, Bool)>()
        var i: Int64 = 0
        while (i < symbols.size) {
            let sym = symbols[i]
            if (sym == 106) {
                // Stop：6 元素 + 1 终止条
                let base = 106 * 6
                var j: Int32 = 0
                while (j < 6) {
                    let w = C128_TABLE[Int64(base) + Int64(j)]
                    result.add((w, j % 2 == 0))
                    j += 1
                }
                result.add((C128_STOP_TERM, true))
            } else {
                let base = Int64(sym) * 6
                var j: Int32 = 0
                while (j < 6) {
                    let w = C128_TABLE[base + Int64(j)]
                    result.add((w, j % 2 == 0))
                    j += 1
                }
            }
            i += 1
        }
        result
    }

    /**
     * 将字符串编码为 Code 128 B 符号序列
     * [Start B, data..., check, Stop]
     */
    private func encode(): ArrayList<Int32> {
        let result = ArrayList<Int32>()
        let startB: Int32 = 104
        result.add(startB)

        var checksum = startB
        var pos: Int32 = 1
        for (c in code.runes()) {
            let ascii = Int32(UInt32(c))
            if (ascii < 32 || ascii > 127) { continue }
            let sym = ascii - 32
            result.add(sym)
            checksum += pos * sym
            pos += 1
        }

        result.add(checksum % 103)
        result.add(106)  // Stop
        result
    }

    /**
     * 创建流式布局图片（像素级渲染，不写入 cb），用于 doc.add(img)
     */
    public func createFlowImage(barColor: Color): Image {
        let symbols = encode()
        let bars = symbolsToBars(symbols)
        var totalMods: Int32 = 0
        var i: Int64 = 0
        while (i < bars.size) {
            let (w, _) = bars[i]
            totalMods += w
            i += 1
        }
        let actualWidth = Float32(totalMods) * moduleWidth
        let img = makeBarsBitmapImage(bars, Int32(barHeight), barColor)
        img.scaleAbsolute(actualWidth, barHeight)
        img
    }

    /**
     * 获取条形码总宽度（pt）
     */
    public func getBarcodeWidth(): Float32 {
        let symbols = encode()
        let bars = symbolsToBars(symbols)
        var total: Int32 = 0
        var i: Int64 = 0
        while (i < bars.size) {
            let (w, _) = bars[i]
            total += w
            i += 1
        }
        Float32(total) * moduleWidth
    }
}
