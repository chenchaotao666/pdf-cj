/**
 * PDF-CJ: Barcode Base - 条形码基础工具
 * 提供公共辅助函数：BMP 图像生成、条宽绘制
 */
package pdf_cj.barcode

import pdf_cj.core.PdfContentByte
import pdf_cj.text.Color
import pdf_cj.image.Image
import std.collection.ArrayList

// ─── BMP 辅助 ───────────────────────────────────────────────────────────────

/**
 * 生成一个纯白 24-bit BMP，宽高与条形码一致，供 Image.getInstance() 解析尺寸
 */
public func makeBarcodeImage(widthPx: Int32, heightPx: Int32): Image {
    let rowBytes = ((widthPx * 3 + 3) / 4) * 4
    let pixelSize = rowBytes * heightPx
    let fileSize = 54 + pixelSize
    let data = Array<UInt8>(Int64(fileSize), repeat: UInt8(0xFF))
    // BM 签名
    data[0] = UInt8(0x42)
    data[1] = UInt8(0x4D)
    // 文件大小（LE）
    writeLE32(data, 2, fileSize)
    // 像素数据偏移 = 54
    writeLE32(data, 10, 54)
    // DIB 头大小 = 40
    writeLE32(data, 14, 40)
    // 宽度
    writeLE32(data, 18, widthPx)
    // 高度
    writeLE32(data, 22, heightPx)
    // Planes = 1
    data[26] = UInt8(1)
    // BPP = 24
    data[28] = UInt8(24)
    // 压缩 = 0（其余字节已初始化为 0xFF，覆盖为 0）
    data[30] = UInt8(0)
    data[31] = UInt8(0)
    data[32] = UInt8(0)
    data[33] = UInt8(0)
    Image.getInstance(data)
}

func writeLE32(data: Array<UInt8>, offset: Int32, val: Int32): Unit {
    let o = Int64(offset)
    data[o]     = UInt8(val & 0xFF)
    data[o + 1] = UInt8((val >> 8) & 0xFF)
    data[o + 2] = UInt8((val >> 16) & 0xFF)
    data[o + 3] = UInt8((val >> 24) & 0xFF)
}

// ─── 绘图辅助 ────────────────────────────────────────────────────────────────

/**
 * 在 PdfContentByte 上绘制一个实心矩形条
 */
public func renderBar(cb: PdfContentByte, x: Float32, y: Float32, w: Float32, h: Float32, color: Color): Unit {
    cb.saveState()
    cb.setColorFill(color)
    cb.rectangle(x, y, w, h)
    cb.fill()
    cb.restoreState()
}

/**
 * 线性条形码通用渲染
 * bars: [宽度, 是否为条（true=条, false=空）]
 */
public func renderLinearBarcode(
    cb: PdfContentByte,
    bars: ArrayList<(Int32, Bool)>,
    x: Float32, y: Float32,
    moduleWidth: Float32, height: Float32,
    barColor: Color
): Float32 {
    var curX = x
    var i: Int64 = 0
    while (i < bars.size) {
        let (w, isBar) = bars[i]
        let pxW = Float32(w) * moduleWidth
        if (isBar) {
            renderBar(cb, curX, y, pxW, height, barColor)
        }
        curX += pxW
        i += 1
    }
    curX - x
}
