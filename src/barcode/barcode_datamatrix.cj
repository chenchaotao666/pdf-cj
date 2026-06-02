/**
 * PDF-CJ: BarcodeDatamatrix - Data Matrix ECC 200 条形码
 * 支持 ASCII 编码模式，自动选取合适的正方形符号尺寸。
 * 实现 Reed-Solomon ECC 200 纠错，满足 ISO/IEC 16022 规范。
 */
package pdf_cj.barcode

import pdf_cj.image.Image
import std.collection.ArrayList

// ── GF(256) for DataMatrix（本原多项式 0x12D） ────────────────────────────────

private func dmGfMul(a: Int32, b: Int32): Int32 {
    if (a == 0 || b == 0) { return 0 }
    var p: Int32 = 0
    var aa = a
    var bb = b
    var i: Int32 = 0
    while (i < 8) {
        if ((bb & 1) != 0) { p = p ^ aa }
        let carry = (aa & 0x80) != 0
        aa = (aa << 1) & 0xFF
        if (carry) { aa = aa ^ 0x2D }
        bb = bb >> 1
        i += 1
    }
    p
}

// ── 符号尺寸表（dataCapacity, eccWords, size） ────────────────────────────────

let DM_CAP:  Array<Int32> = [3,  5,  8,  12, 18, 22, 30, 36, 44, 62,  86,  114, 144, 174, 204, 280]
let DM_ECC:  Array<Int32> = [5,  7,  10, 12, 14, 18, 20, 24, 28, 36,  42,  48,  56,  68,  84,  112]
let DM_SIZE: Array<Int32> = [10, 12, 14, 16, 18, 20, 22, 24, 26, 32,  36,  40,  44,  48,  52,  64]

// ── Reed-Solomon ──────────────────────────────────────────────────────────────

private func rsEncode(data: Array<Int32>, nroots: Int32): Array<Int32> {
    // 构建生成多项式 g(x) = prod(x - alpha^i), i=1..nroots
    let gen = Array<Int32>(Int64(nroots + 1), repeat: 0)
    gen[0] = 1
    var i: Int32 = 0
    var alpha: Int32 = 1
    while (i < nroots) {
        var j: Int32 = i
        while (j >= 0) {
            gen[Int64(j + 1)] = gen[Int64(j + 1)] ^ dmGfMul(gen[Int64(j)], alpha)
            j -= 1
        }
        alpha = dmGfMul(alpha, 2)
        i += 1
    }
    let parity = Array<Int32>(Int64(nroots), repeat: 0)
    var k: Int32 = 0
    while (Int64(k) < data.size) {
        let feedback = data[Int64(k)] ^ parity[0]
        if (feedback != 0) {
            var j: Int32 = 0
            while (j < nroots - 1) {
                parity[Int64(j)] = parity[Int64(j + 1)] ^ dmGfMul(feedback, gen[Int64(nroots - 1 - j)])
                j += 1
            }
            parity[Int64(nroots - 1)] = dmGfMul(feedback, gen[0])
        } else {
            var j: Int32 = 0
            while (j < nroots - 1) {
                parity[Int64(j)] = parity[Int64(j + 1)]
                j += 1
            }
            parity[Int64(nroots - 1)] = 0
        }
        k += 1
    }
    parity
}

// ── ASCII 编码 ────────────────────────────────────────────────────────────────

private func dmEncodeASCII(text: String, capacity: Int32): Array<Int32> {
    let cw = ArrayList<Int32>()
    for (c in text.runes()) {
        let v = Int32(UInt32(c))
        if (v >= 0 && v <= 127) {
            cw.add(v + 1)
        } else {
            cw.add(235)
            cw.add(v - 128 + 1)
        }
    }
    let n = Int32(cw.size)
    if (n < capacity) {
        cw.add(129)   // PAD
    }
    var i: Int32 = n + 1
    while (i < capacity) {
        let r = ((149 * (i + 1)) % 253) + 1
        cw.add((129 - 1 + r) % 254 + 1)
        i += 1
    }
    let result = Array<Int32>(Int64(capacity), repeat: 0)
    var j: Int64 = 0
    while (j < Int64(capacity) && j < cw.size) {
        result[j] = cw[j]
        j += 1
    }
    result
}

// ── 模块放置 ──────────────────────────────────────────────────────────────────

private func setModule(matrix: Array<Array<Bool>>, r: Int32, c: Int32, n: Int32, v: Bool): Unit {
    var row = r
    var col = c
    if (row < 0) { row += n; col += 4 - ((n + 4) % 8) }
    if (col < 0) { col += n; row += 4 - ((n + 4) % 8) }
    if (row >= 0 && row < n && col >= 0 && col < n) {
        if (!matrix[Int64(row)][Int64(col)]) {
            matrix[Int64(row)][Int64(col)] = v
        }
    }
}

private func placeUtah(matrix: Array<Array<Bool>>, r: Int32, c: Int32, v: Int32, n: Int32): Unit {
    // 8-module Utah shape
    setModule(matrix, r - 2, c - 1, n, ((v >> 7) & 1) == 1)
    setModule(matrix, r - 2, c,     n, ((v >> 6) & 1) == 1)
    setModule(matrix, r - 1, c - 2, n, ((v >> 5) & 1) == 1)
    setModule(matrix, r - 1, c - 1, n, ((v >> 4) & 1) == 1)
    setModule(matrix, r - 1, c,     n, ((v >> 3) & 1) == 1)
    setModule(matrix, r,     c - 2, n, ((v >> 2) & 1) == 1)
    setModule(matrix, r,     c - 1, n, ((v >> 1) & 1) == 1)
    setModule(matrix, r,     c,     n, ((v >> 0) & 1) == 1)
}

private func cornerA(matrix: Array<Array<Bool>>, v: Int32, n: Int32): Unit {
    setModule(matrix, n - 1, 0,     n, ((v >> 7) & 1) == 1)
    setModule(matrix, n - 1, 1,     n, ((v >> 6) & 1) == 1)
    setModule(matrix, n - 1, 2,     n, ((v >> 5) & 1) == 1)
    setModule(matrix, 0,     n - 2, n, ((v >> 4) & 1) == 1)
    setModule(matrix, 0,     n - 1, n, ((v >> 3) & 1) == 1)
    setModule(matrix, 1,     n - 1, n, ((v >> 2) & 1) == 1)
    setModule(matrix, 2,     n - 1, n, ((v >> 1) & 1) == 1)
    setModule(matrix, 3,     n - 1, n, ((v >> 0) & 1) == 1)
}

private func cornerB(matrix: Array<Array<Bool>>, v: Int32, n: Int32): Unit {
    setModule(matrix, n - 3, 0,     n, ((v >> 7) & 1) == 1)
    setModule(matrix, n - 2, 0,     n, ((v >> 6) & 1) == 1)
    setModule(matrix, n - 1, 0,     n, ((v >> 5) & 1) == 1)
    setModule(matrix, 0,     n - 4, n, ((v >> 4) & 1) == 1)
    setModule(matrix, 0,     n - 3, n, ((v >> 3) & 1) == 1)
    setModule(matrix, 0,     n - 2, n, ((v >> 2) & 1) == 1)
    setModule(matrix, 0,     n - 1, n, ((v >> 1) & 1) == 1)
    setModule(matrix, 1,     n - 1, n, ((v >> 0) & 1) == 1)
}

private func cornerC(matrix: Array<Array<Bool>>, v: Int32, n: Int32): Unit {
    setModule(matrix, n - 3, 0,     n, ((v >> 7) & 1) == 1)
    setModule(matrix, n - 2, 0,     n, ((v >> 6) & 1) == 1)
    setModule(matrix, n - 1, 0,     n, ((v >> 5) & 1) == 1)
    setModule(matrix, 0,     n - 2, n, ((v >> 4) & 1) == 1)
    setModule(matrix, 0,     n - 1, n, ((v >> 3) & 1) == 1)
    setModule(matrix, 1,     n - 1, n, ((v >> 2) & 1) == 1)
    setModule(matrix, 2,     n - 1, n, ((v >> 1) & 1) == 1)
    setModule(matrix, 3,     n - 1, n, ((v >> 0) & 1) == 1)
}

private func cornerD(matrix: Array<Array<Bool>>, v: Int32, n: Int32): Unit {
    setModule(matrix, n - 1, 0,     n, ((v >> 7) & 1) == 1)
    setModule(matrix, n - 1, n - 1, n, ((v >> 6) & 1) == 1)
    setModule(matrix, 0,     n - 3, n, ((v >> 5) & 1) == 1)
    setModule(matrix, 0,     n - 2, n, ((v >> 4) & 1) == 1)
    setModule(matrix, 0,     n - 1, n, ((v >> 3) & 1) == 1)
    setModule(matrix, 1,     n - 3, n, ((v >> 2) & 1) == 1)
    setModule(matrix, 1,     n - 2, n, ((v >> 1) & 1) == 1)
    setModule(matrix, 1,     n - 1, n, ((v >> 0) & 1) == 1)
}

private func placeAllCodewords(n: Int32, codewords: Array<Int32>): Array<Array<Bool>> {
    let matrix = Array<Array<Bool>>(Int64(n), {_ => Array<Bool>(Int64(n), repeat: false)})

    var idx: Int32 = 0
    var row: Int32 = 4
    var col: Int32 = 0

    while (row < n || col < n) {
        // 特殊角
        if (row == n && col == 0) {
            if (Int64(idx) < codewords.size) { cornerA(matrix, codewords[Int64(idx)], n); idx += 1 }
        }
        if (row == n - 2 && col == 0 && n % 4 != 0) {
            if (Int64(idx) < codewords.size) { cornerB(matrix, codewords[Int64(idx)], n); idx += 1 }
        }
        if (row == n - 2 && col == 0 && n % 8 == 4) {
            if (Int64(idx) < codewords.size) { cornerC(matrix, codewords[Int64(idx)], n); idx += 1 }
        }
        if (row == n + 4 && col == 2 && n % 8 == 0) {
            if (Int64(idx) < codewords.size) { cornerD(matrix, codewords[Int64(idx)], n); idx += 1 }
        }

        // 向右上斜进
        var cont = true
        while (cont) {
            if (row >= 0 && row < n && col >= 0 && col < n) {
                if (Int64(idx) < codewords.size) {
                    placeUtah(matrix, row, col, codewords[Int64(idx)], n)
                    idx += 1
                }
            }
            row -= 2
            col += 2
            cont = !(row < 0 || col >= n)
        }
        row += 1
        col += 3

        // 向左下斜进
        cont = true
        while (cont) {
            if (row >= 0 && row < n && col >= 0 && col < n) {
                if (Int64(idx) < codewords.size) {
                    placeUtah(matrix, row, col, codewords[Int64(idx)], n)
                    idx += 1
                }
            }
            row += 2
            col -= 2
            cont = !(row >= n || col < 0)
        }
        row += 3
        col += 1
    }

    // 右下角两个固定模块
    if (!matrix[Int64(n - 1)][Int64(n - 1)]) { matrix[Int64(n - 1)][Int64(n - 1)] = true }
    if (!matrix[Int64(n - 2)][Int64(n - 1)]) { matrix[Int64(n - 2)][Int64(n - 1)] = true }

    matrix
}

// 添加边框定位图案（ISO/IEC 16022 ECC200）
// L-finder：底边和左边全黑；Timing：顶边和右边交替（偶数位黑）
private func addFinder(matrix: Array<Array<Bool>>, n: Int32): Unit {
    var i: Int32 = 0
    while (i < n) {
        matrix[Int64(n - 1)][Int64(i)] = true            // 底边全黑（L-finder）
        matrix[Int64(i)][0] = true                       // 左边全黑（L-finder）
        matrix[0][Int64(i)] = (i % 2 == 0)               // 顶边交替（Timing，偶数列黑）
        matrix[Int64(i)][Int64(n - 1)] = (i % 2 == 0)   // 右边交替（Timing，偶数行黑）
        i += 1
    }
}

// ── 矩阵 → BMP ────────────────────────────────────────────────────────────────

private func dmMatrixToBmp(matrix: Array<Array<Bool>>, n: Int32, cell: Int32): Array<UInt8> {
    let totalPx = n * cell
    let rowBytes = ((totalPx * 3 + 3) / 4) * 4
    let pixelSize = rowBytes * totalPx
    let fileSize = 54 + pixelSize
    let data = Array<UInt8>(Int64(fileSize), repeat: UInt8(0xFF))

    // BMP file header (14 bytes)
    data[0] = 0x42u8; data[1] = 0x4Du8   // "BM"
    writeLE32(data, 2, fileSize)
    data[6] = 0u8; data[7] = 0u8; data[8] = 0u8; data[9] = 0u8  // reserved
    writeLE32(data, 10, 54)               // pixel data offset

    // BITMAPINFOHEADER (40 bytes, starting at offset 14)
    writeLE32(data, 14, 40)               // biSize
    writeLE32(data, 18, totalPx)          // biWidth
    writeLE32(data, 22, totalPx)          // biHeight
    data[26] = UInt8(1); data[27] = UInt8(0)   // biPlanes = 1
    data[28] = UInt8(24); data[29] = UInt8(0)  // biBitCount = 24
    writeLE32(data, 30, 0)               // biCompression = BI_RGB
    writeLE32(data, 34, pixelSize)       // biSizeImage
    writeLE32(data, 38, 0)               // biXPelsPerMeter
    writeLE32(data, 42, 0)               // biYPelsPerMeter
    writeLE32(data, 46, 0)               // biClrUsed
    writeLE32(data, 50, 0)               // biClrImportant

    // BMP 从下往上
    var row: Int32 = 0
    while (row < n) {
        var cr: Int32 = 0
        while (cr < cell) {
            let bmpRow = totalPx - 1 - (row * cell + cr)
            var col: Int32 = 0
            while (col < n) {
                let dark = matrix[Int64(row)][Int64(col)]
                var cc: Int32 = 0
                while (cc < cell) {
                    let px = col * cell + cc
                    let off = Int64(54 + bmpRow * rowBytes + px * 3)
                    if (dark) {
                        data[off] = 0u8; data[off + 1] = 0u8; data[off + 2] = 0u8
                    }
                    cc += 1
                }
                col += 1
            }
            cr += 1
        }
        row += 1
    }
    data
}

// ── 公开类 ────────────────────────────────────────────────────────────────────

/**
 * DataMatrix ECC 200 条形码生成器
 *
 * 用法：
 *   let dm = BarcodeDatamatrix()
 *   dm.generate("Hello")
 *   let img = dm.createImage()
 *   img.scaleAbsolute(100, 100)
 *   doc.add(img)
 */
public class BarcodeDatamatrix {
    private var _matrix: ?Array<Array<Bool>> = None
    private var _n: Int32 = 0

    public init() {}

    /**
     * 编码文本，生成内部矩阵
     */
    public func generate(text: String): Unit {
        let textLen = Int32(text.size)
        var sizeIdx: Int64 = 0
        while (sizeIdx < Int64(DM_CAP.size)) {
            if (DM_CAP[sizeIdx] >= textLen) { break }
            sizeIdx += 1
        }
        if (sizeIdx >= Int64(DM_CAP.size)) {
            throw Exception("BarcodeDatamatrix: text too long")
        }
        let capacity = DM_CAP[sizeIdx]
        let eccWords  = DM_ECC[sizeIdx]
        let n         = DM_SIZE[sizeIdx]

        let data = dmEncodeASCII(text, capacity)
        let ecc  = rsEncode(data, eccWords)

        let all = Array<Int32>(Int64(capacity + eccWords), repeat: 0)
        var i: Int64 = 0
        while (i < Int64(capacity)) { all[i] = data[i]; i += 1 }
        var j: Int64 = 0
        while (j < Int64(eccWords)) { all[Int64(capacity) + j] = ecc[j]; j += 1 }

        let mat = placeAllCodewords(n, all)
        addFinder(mat, n)
        _matrix = Some(mat)
        _n = n
    }

    /**
     * 生成可直接 add 到 Document 的 Image（每个模块 4×4 像素）
     */
    public func createImage(): Image {
        match (_matrix) {
            case Some(mat) =>
                let bmpData = dmMatrixToBmp(mat, _n, 4)
                Image.getInstance(bmpData)
            case None =>
                throw Exception("BarcodeDatamatrix: call generate() first")
        }
    }
}
