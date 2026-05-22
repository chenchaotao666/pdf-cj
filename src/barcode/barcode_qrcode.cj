/**
 * PDF-CJ: BarcodeQRCode - QR 码（Version 1-10, Byte 模式, Level M）
 * 实现：GF(256) Reed-Solomon 纠错 + 模块矩阵 + Mask 0
 */
package pdf_cj.barcode

import pdf_cj.core.PdfContentByte
import pdf_cj.text.Color
import pdf_cj.image.Image
import std.collection.ArrayList

// ── GF(256) 算术（本原多项式 0x11D）─────────────────────────────────────────

let GF_EXP: Array<Int32> = buildGfExp()
let GF_LOG: Array<Int32>  = buildGfLog(GF_EXP)

func buildGfExp(): Array<Int32> {
    let exp = Array<Int32>(512, repeat: 0)
    var x: Int32 = 1
    var i: Int32 = 0
    while (i < 255) {
        exp[Int64(i)] = x
        x = x * 2
        if (x >= 256) { x = x ^ 0x11D }
        i += 1
    }
    var j: Int32 = 255
    while (j < 512) {
        exp[Int64(j)] = exp[Int64(j - 255)]
        j += 1
    }
    exp
}

func buildGfLog(exp: Array<Int32>): Array<Int32> {
    let log = Array<Int32>(256, repeat: 0)
    var i: Int32 = 0
    while (i < 255) {
        log[Int64(exp[Int64(i)])] = i
        i += 1
    }
    log
}

func gfMul(a: Int32, b: Int32): Int32 {
    if (a == 0 || b == 0) { return 0 }
    GF_EXP[Int64(GF_LOG[Int64(a)] + GF_LOG[Int64(b)])]
}

func gfDiv(a: Int32, b: Int32): Int32 {
    if (a == 0) { return 0 }
    GF_EXP[Int64((GF_LOG[Int64(a)] - GF_LOG[Int64(b)] + 255) % 255)]
}

func gfPow(x: Int32, power: Int32): Int32 {
    GF_EXP[Int64((GF_LOG[Int64(x)] * power) % 255)]
}

// ── Reed-Solomon 纠错码 ──────────────────────────────────────────────────────

// 生成 RS 生成多项式
func rsGeneratorPoly(degree: Int32): Array<Int32> {
    var g = Array<Int32>(Int64(degree + 1), repeat: 0)
    g[0] = 1
    var i: Int32 = 0
    while (i < degree) {
        let root = GF_EXP[Int64(i)]
        var j: Int32 = i
        while (j >= 0) {
            g[Int64(j + 1)] = g[Int64(j + 1)] ^ gfMul(g[Int64(j)], root)
            j -= 1
        }
        g[0] = gfMul(g[0], root)
        i += 1
    }
    g
}

// 计算 RS 纠错码字
func rsCalcEC(data: Array<Int32>, ecCount: Int32): Array<Int32> {
    let gen = rsGeneratorPoly(ecCount)
    let result = Array<Int32>(Int64(ecCount), repeat: 0)
    // 多项式除法
    var i: Int64 = 0
    while (i < data.size) {
        let coef = data[i] ^ result[0]
        var j: Int64 = 0
        while (j < Int64(ecCount) - 1) {
            result[j] = result[j + 1] ^ gfMul(gen[Int64(ecCount) - 1 - j], coef)
            j += 1
        }
        result[Int64(ecCount) - 1] = gfMul(gen[0], coef)
        i += 1
    }
    result
}

// ── QR 版本参数（Byte 模式，Level M）────────────────────────────────────────

// [版本, 矩阵尺寸, 数据码字数, EC 码字数]
let QR_VERSION_INFO: Array<Array<Int32>> = [
    [1,  21, 16, 10],
    [2,  25, 28, 16],
    [3,  29, 44, 26],
    [4,  33, 64, 36],
    [5,  37, 86, 48],
    [6,  41, 108, 64],
    [7,  45, 124, 72],
    [8,  49, 154, 88],
    [9,  53, 182, 110],
    [10, 57, 216, 130]
]

// 格式信息（Level M + Mask 0），XOR 掩码后的 15 位
let QR_FORMAT_M_MASK0: Int32 = 0x5412  // Level M(01) + Mask 0(000) = 010000000000 ... pre-computed

// BCH 纠错：生成格式信息 15 位
func qrFormatBits(ecLevel: Int32, maskPattern: Int32): Int32 {
    // ecLevel: 0=M,1=L,2=H,3=Q (QR format bits for M=01)
    let data = (ecLevel << 3) | maskPattern  // 5 bits
    var remainder = data << 10
    let poly: Int32 = 0x537
    var i: Int32 = 14
    while (i >= 10) {
        if (((remainder >> i) & 1) != 0) {
            remainder = remainder ^ (poly << (i - 10))
        }
        i -= 1
    }
    let bits = (data << 10) | remainder
    bits ^ 0x5412  // XOR 掩码
}

// ── QR 矩阵生成 ─────────────────────────────────────────────────────────────

/**
 * QR 码条形码（Version 1-10, Byte 模式, Level M, Mask 0）
 */
public class BarcodeQRCode {
    public var code: String = ""
    public var x: Float32 = 50.0
    public var y: Float32 = 700.0
    public var moduleSize: Float32 = 3.0  // 每个模块的点大小（pt）
    public var quietZone: Int32 = 4       // 静区模块数

    public init() {}

    public init(code: String) {
        this.code = code
    }

    public func createImage(cb: PdfContentByte, barColor: Color, textColor: Color): Image {
        let matrix = buildMatrix()
        let size = matrix.size
        let moduleCount = Int32(size) + quietZone * 2
        let totalPts = Float32(moduleCount) * moduleSize
        let totalPx = Int32(totalPts) + 1

        cb.saveState()
        // 绘制静区背景（白色）
        cb.setColorFill(Color.WHITE)
        cb.rectangle(x, y, totalPts, totalPts)
        cb.fill()
        // 绘制模块
        cb.setColorFill(barColor)
        var row: Int64 = 0
        while (row < Int64(size)) {
            var col: Int64 = 0
            while (col < Int64(size)) {
                if (matrix[row][col]) {
                    let px = x + Float32(quietZone + Int32(col)) * moduleSize
                    let py = y + Float32(moduleCount - 1 - quietZone - Int32(row)) * moduleSize
                    cb.rectangle(px, py, moduleSize, moduleSize)
                    cb.fill()
                }
                col += 1
            }
            row += 1
        }
        cb.restoreState()

        let img = makeBarcodeImage(totalPx, totalPx)
        img.setAbsolutePosition(x, y)
        img
    }

    // ── 矩阵构建 ─────────────────────────────────────────────────────────────

    private func buildMatrix(): Array<Array<Bool>> {
        let version = selectVersion()
        let vi = QR_VERSION_INFO[Int64(version - 1)]
        let size = vi[1]
        let dataCW = vi[2]
        let ecCW = vi[3]

        // 初始化矩阵
        let matrix = Array<Array<Bool>>(Int64(size), {_ => Array<Bool>(Int64(size), repeat: false)})
        let reserved = Array<Array<Bool>>(Int64(size), {_ => Array<Bool>(Int64(size), repeat: false)})

        // 放置固定图案
        placeFinderPattern(matrix, reserved, 0, 0)
        placeFinderPattern(matrix, reserved, 0, size - 7)
        placeFinderPattern(matrix, reserved, size - 7, 0)
        placeTimingPattern(matrix, reserved, size)
        placeFormatInfo(matrix, reserved, size)
        if (version >= 7) {
            placeVersionInfo(matrix, reserved, size, version)
        }
        // 对齐图案（版本 2+）
        if (version >= 2) {
            placeAlignmentPatterns(matrix, reserved, version, size)
        }

        // 数据编码
        let dataBytes = encodeData()
        let dataCodewords = padData(dataBytes, dataCW)
        let ecCodewords = rsCalcEC(dataCodewords, ecCW)

        // 合并所有码字
        let allCW = Array<Int32>(Int64(dataCW + ecCW), repeat: 0)
        var i: Int64 = 0
        while (i < Int64(dataCW)) { allCW[i] = dataCodewords[i]; i += 1 }
        while (i < Int64(dataCW + ecCW)) { allCW[i] = ecCodewords[i - Int64(dataCW)]; i += 1 }

        // 数据放置（之字形扫描）
        placeData(matrix, reserved, allCW, size)

        // 应用 Mask 0（row % 2 == 0）
        applyMask0(matrix, reserved, size)

        matrix
    }

    // ── 固定图案 ─────────────────────────────────────────────────────────────

    private func placeFinderPattern(matrix: Array<Array<Bool>>, reserved: Array<Array<Bool>>,
                                     row: Int32, col: Int32): Unit {
        let pat = [
            [true,true,true,true,true,true,true],
            [true,false,false,false,false,false,true],
            [true,false,true,true,true,false,true],
            [true,false,true,true,true,false,true],
            [true,false,true,true,true,false,true],
            [true,false,false,false,false,false,true],
            [true,true,true,true,true,true,true]
        ]
        var r: Int32 = 0
        while (r < 7) {
            var c: Int32 = 0
            while (c < 7) {
                matrix[Int64(row + r)][Int64(col + c)] = pat[Int64(r)][Int64(c)]
                reserved[Int64(row + r)][Int64(col + c)] = true
                c += 1
            }
            r += 1
        }
        // 分隔符（1 模块空白带）
        var i: Int32 = -1
        while (i <= 7) {
            setIfValid(matrix, reserved, row - 1, col + i, false)
            setIfValid(matrix, reserved, row + 7, col + i, false)
            setIfValid(matrix, reserved, row + i, col - 1, false)
            setIfValid(matrix, reserved, row + i, col + 7, false)
            i += 1
        }
    }

    private func setIfValid(matrix: Array<Array<Bool>>, reserved: Array<Array<Bool>>,
                             r: Int32, c: Int32, val: Bool): Unit {
        if (r >= 0 && r < Int32(matrix.size) && c >= 0 && c < Int32(matrix.size)) {
            matrix[Int64(r)][Int64(c)] = val
            reserved[Int64(r)][Int64(c)] = true
        }
    }

    private func placeTimingPattern(matrix: Array<Array<Bool>>, reserved: Array<Array<Bool>>, size: Int32): Unit {
        var i: Int32 = 8
        while (i < size - 8) {
            let dark = i % 2 == 0
            matrix[6][Int64(i)] = dark
            reserved[6][Int64(i)] = true
            matrix[Int64(i)][6] = dark
            reserved[Int64(i)][6] = true
            i += 1
        }
    }

    private func placeFormatInfo(matrix: Array<Array<Bool>>, reserved: Array<Array<Bool>>, size: Int32): Unit {
        // Level M, Mask 0
        let bits = qrFormatBits(1, 0)  // ecLevel M=01=1, mask=0
        let formatBits = Array<Bool>(15, repeat: false)
        var i: Int32 = 0
        while (i < 15) {
            formatBits[Int64(14 - i)] = ((bits >> i) & 1) == 1
            i += 1
        }

        // 格式信息位位置（固定位置）
        let row1 = [0,1,2,3,4,5,7,8,8,8,8,8,8,8,8]
        let col1 = [8,8,8,8,8,8,8,8,7,5,4,3,2,1,0]
        let row2: Array<Int32> = [size-1,size-2,size-3,size-4,size-5,size-6,size-7,size-8,8,8,8,8,8,8,8]
        let col2: Array<Int32> = [8,8,8,8,8,8,8,8,size-8,size-7,size-6,size-5,size-4,size-3,size-2]

        var j: Int32 = 0
        while (j < 15) {
            matrix[Int64(row1[Int64(j)])][Int64(col1[Int64(j)])] = formatBits[Int64(j)]
            reserved[Int64(row1[Int64(j)])][Int64(col1[Int64(j)])] = true
            matrix[Int64(row2[Int64(j)])][Int64(col2[Int64(j)])] = formatBits[Int64(j)]
            reserved[Int64(row2[Int64(j)])][Int64(col2[Int64(j)])] = true
            j += 1
        }
        // 暗模块
        matrix[Int64(size - 8)][8] = true
        reserved[Int64(size - 8)][8] = true
    }

    private func placeVersionInfo(matrix: Array<Array<Bool>>, reserved: Array<Array<Bool>>, size: Int32, version: Int32): Unit {
        // 版本 7+ 才需要，此处简化省略版本信息编码
        var r: Int32 = 0
        while (r < 3) {
            var c: Int32 = 0
            while (c < 6) {
                reserved[Int64(r)][Int64(size - 11 + c)] = true
                reserved[Int64(size - 11 + c)][Int64(r)] = true
                c += 1
            }
            r += 1
        }
    }

    private func placeAlignmentPatterns(matrix: Array<Array<Bool>>, reserved: Array<Array<Bool>>, version: Int32, size: Int32): Unit {
        // 版本 2-6 对齐图案中心坐标表
        let centers: Array<Array<Int32>> = [
            [],           // v1
            [18],         // v2
            [22],         // v3
            [26],         // v4
            [30],         // v5
            [34],         // v6
            [22,38],      // v7
            [24,42],      // v8
            [26,46],      // v9
            [28,50]       // v10
        ]
        if (version < 2 || version > 10) { return }
        let pts = centers[Int64(version - 1)]
        // 对所有坐标对放置对齐图案
        let allPts = ArrayList<Int32>()
        allPts.add(6)
        var k: Int64 = 0
        while (k < pts.size) {
            allPts.add(pts[k])
            k += 1
        }
        var i: Int64 = 0
        while (i < allPts.size) {
            var j: Int64 = 0
            while (j < allPts.size) {
                let cr = allPts[i]
                let cc = allPts[j]
                if (!reserved[Int64(cr)][Int64(cc)]) {
                    placeAlignPattern(matrix, reserved, cr, cc)
                }
                j += 1
            }
            i += 1
        }
    }

    private func placeAlignPattern(matrix: Array<Array<Bool>>, reserved: Array<Array<Bool>>, cr: Int32, cc: Int32): Unit {
        let pat = [
            [true,true,true,true,true],
            [true,false,false,false,true],
            [true,false,true,false,true],
            [true,false,false,false,true],
            [true,true,true,true,true]
        ]
        var r: Int32 = 0
        while (r < 5) {
            var c: Int32 = 0
            while (c < 5) {
                let mr = cr - 2 + r
                let mc = cc - 2 + c
                matrix[Int64(mr)][Int64(mc)] = pat[Int64(r)][Int64(c)]
                reserved[Int64(mr)][Int64(mc)] = true
                c += 1
            }
            r += 1
        }
    }

    // ── 数据放置 ─────────────────────────────────────────────────────────────

    private func placeData(matrix: Array<Array<Bool>>, reserved: Array<Array<Bool>>,
                           codewords: Array<Int32>, size: Int32): Unit {
        var bitIdx: Int32 = 0
        let totalBits = codewords.size * 8
        var col = size - 1
        var goUp = true

        while (col > 0) {
            if (col == 6) { col -= 1 }  // 跳过计时列
            var row: Int32 = if (goUp) { size - 1 } else { 0 }
            var rowDelta: Int32 = if (goUp) { -1 } else { 1 }
            var rowCount: Int32 = 0
            while (rowCount < size) {
                var c2: Int32 = 0
                while (c2 <= 1) {
                    let mc = col - c2
                    let mr = row
                    if (!reserved[Int64(mr)][Int64(mc)] && Int64(bitIdx) < Int64(totalBits)) {
                        let cwIdx = Int64(bitIdx / 8)
                        let bitPos = 7 - (bitIdx % 8)
                        let dark = ((codewords[cwIdx] >> bitPos) & 1) == 1
                        matrix[Int64(mr)][Int64(mc)] = dark
                        bitIdx += 1
                    }
                    c2 += 1
                }
                row += rowDelta
                rowCount += 1
            }
            col -= 2
            goUp = !goUp
        }
    }

    private func applyMask0(matrix: Array<Array<Bool>>, reserved: Array<Array<Bool>>, size: Int32): Unit {
        // Mask 0: (row + col) % 2 == 0
        var r: Int32 = 0
        while (r < size) {
            var c: Int32 = 0
            while (c < size) {
                if (!reserved[Int64(r)][Int64(c)] && (r + c) % 2 == 0) {
                    matrix[Int64(r)][Int64(c)] = !matrix[Int64(r)][Int64(c)]
                }
                c += 1
            }
            r += 1
        }
    }

    // ── 数据编码 ─────────────────────────────────────────────────────────────

    private func encodeData(): Array<UInt8> {
        let bytes = ArrayList<UInt8>()
        for (c in code.runes()) {
            let v = UInt32(c)
            if (v < 128u32) {
                bytes.add(UInt8(v))
            } else if (v < 0x800u32) {
                bytes.add(UInt8(0xC0u32 | (v >> 6)))
                bytes.add(UInt8(0x80u32 | (v & 0x3Fu32)))
            } else {
                bytes.add(UInt8(0xE0u32 | (v >> 12)))
                bytes.add(UInt8(0x80u32 | ((v >> 6) & 0x3Fu32)))
                bytes.add(UInt8(0x80u32 | (v & 0x3Fu32)))
            }
        }
        let arr = Array<UInt8>(bytes.size, repeat: UInt8(0))
        var i: Int64 = 0
        while (i < bytes.size) { arr[i] = bytes[i]; i += 1 }
        arr
    }

    private func padData(rawBytes: Array<UInt8>, dataCW: Int32): Array<Int32> {
        // 构建比特流
        let bits = ArrayList<Int32>()
        // 模式指示（字节模式 = 0100）
        appendBits(bits, 4, 4)
        // 字符计数
        let cnt: Int32 = Int32(rawBytes.size)
        appendBits(bits, cnt, 8)
        // 数据字节
        var i: Int64 = 0
        while (i < Int64(cnt)) {
            appendBits(bits, Int32(rawBytes[i]), 8)
            i += 1
        }
        // 终止符（最多 4 位）
        let maxBits = Int64(dataCW) * 8
        var termBits: Int32 = 4
        if (bits.size + 4 > maxBits) {
            termBits = Int32(maxBits - bits.size)
        }
        var t: Int32 = 0
        while (t < termBits) { bits.add(0); t += 1 }
        // 字节对齐
        while (bits.size % 8 != 0) { bits.add(0) }
        // 填充码字
        let padBytes: Array<Int32> = [0xEC, 0x11]
        var padIdx: Int32 = 0
        while (bits.size < maxBits) {
            appendBits(bits, padBytes[Int64(padIdx % 2)], 8)
            padIdx += 1
        }
        // 转为码字数组
        let cw = Array<Int32>(Int64(dataCW), repeat: 0)
        var j: Int64 = 0
        while (j < Int64(dataCW)) {
            var byte: Int32 = 0
            var k: Int32 = 0
            while (k < 8) {
                byte = byte * 2 + bits[j * 8 + Int64(k)]
                k += 1
            }
            cw[j] = byte
            j += 1
        }
        cw
    }

    private func appendBits(bits: ArrayList<Int32>, value: Int32, length: Int32): Unit {
        var i = length - 1
        while (i >= 0) {
            bits.add((value >> i) & 1)
            i -= 1
        }
    }

    private func selectVersion(): Int32 {
        let byteCount = countUtf8Bytes()
        // 找能容纳数据的最小版本（Level M）
        // capacity = dataCW - 2（mode 4 bit + count 8 bit = 1.5 bytes）
        var i: Int64 = 0
        while (i < QR_VERSION_INFO.size) {
            let vi = QR_VERSION_INFO[i]
            let cap = vi[2] - 2  // 2 bytes overhead for mode+count
            if (byteCount <= cap) { return vi[0] }
            i += 1
        }
        10  // 最大支持版本
    }

    private func countUtf8Bytes(): Int32 {
        var cnt: Int32 = 0
        for (c in code.runes()) {
            let v = UInt32(c)
            if (v < 128u32) { cnt += 1 }
            else if (v < 0x800u32) { cnt += 2 }
            else { cnt += 3 }
        }
        cnt
    }
}
