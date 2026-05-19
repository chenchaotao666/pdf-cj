/**
 * PDF-CJ: CFFSubsetter - CFF（紧凑字体格式）子集化
 *
 * 算法：
 *   1. 从 CFF 头部导航到 CharStrings INDEX（经由 Name/TopDict/String/GlobalSubr INDEX）
 *   2. 从 TopDict 找到 CharStrings 偏移和 FDArray 偏移
 *   3. 重建 CharStrings INDEX：已用字形保留原始 charstring，未用字形替换为单字节 endchar(0x0e)
 *   4. 更新 TopDict 中的 FDArray 偏移引用（减去 delta）
 *   5. 更新 FDArray 中每个 FD dict 的 Private 偏移引用（减去 delta）
 *   6. 拼接 part1 + 新 CharStrings INDEX + part3
 *
 * 对于 NotoSansCJK（65535 字形，15MB）：
 *   仅用 50 个字形时，新 CharStrings INDEX ≈ 272KB，整体 CFF 从 15MB → ~1.5MB
 */
package pdf_cj.text

import std.collection.{HashMap, ArrayList}

/**
 * CFF 子集化器
 */
public class CFFSubsetter {
    private let cff: Array<UInt8>
    private let usedGlyphs: HashMap<UInt16, Bool>

    public init(cff: Array<UInt8>, usedGlyphs: HashMap<UInt16, Bool>) {
        this.cff = cff
        this.usedGlyphs = usedGlyphs
    }

    /**
     * 生成 CFF 子集数据
     * @return 子集 CFF 字节数组；若无法子集化则返回原始数据
     */
    public func generateSubset(): Array<UInt8> {
        if (cff.size < 8 || usedGlyphs.isEmpty()) { return cff }

        // === 1. 导航到 CharStrings INDEX，收集关键偏移 ===
        let hdrSize = Int64(cff[2])
        var pos = hdrSize

        pos = skipIndex(pos)             // Name INDEX
        let topDictIdxPos = pos
        pos = skipIndex(pos)             // TopDict INDEX
        pos = skipIndex(pos)             // String INDEX
        pos = skipIndex(pos)             // Global Subr INDEX

        // 读取 TopDict 条目（通常只有 1 个）
        let topDictOffset = getIndexItemOffset(cff, topDictIdxPos, 0)
        let topDictLen    = getIndexItemLength(cff, topDictIdxPos, 0)
        if (topDictOffset < 0 || topDictLen <= 0) { return cff }

        // === 2. 从 TopDict 解析 CharStrings 偏移和 FDArray 偏移 ===
        let charstringsOff = findDictInt(cff, topDictOffset, topDictLen, 17i32, -1i32)
        let fdArrayOff     = findDictInt(cff, topDictOffset, topDictLen, 12i32, 36i32)
        if (charstringsOff < 0) { return cff }

        // === 3. 读取 CharStrings INDEX 元数据 ===
        let csEnd = getIndexEnd(cff, charstringsOff)  // charstrings_off + INDEX 大小
        if (csEnd <= charstringsOff) { return cff }

        // === 4. 构建新 CharStrings INDEX ===
        let newCS = buildNewCharstrings(charstringsOff, csEnd)
        let delta = (csEnd - charstringsOff) - Int64(newCS.size)
        if (delta <= 0) { return cff }  // 没有实质缩减，不值得处理

        // === 5. 复制 part1（CharStrings 之前），更新 TopDict FDArray 偏移 ===
        let part1 = copyRange(cff, 0, charstringsOff)
        if (fdArrayOff >= 0) {
            let newFDArrayOff = fdArrayOff - delta
            updateDictInt32(part1, topDictOffset, topDictLen, 12i32, 36i32, newFDArrayOff)
        }

        // === 6. 复制 part3（CharStrings 之后 = FDArray+Private+LocalSubrs），更新 Private 偏移 ===
        let part3 = copyRange(cff, csEnd, cff.size)
        if (fdArrayOff >= 0 && fdArrayOff >= csEnd) {
            // FDArray 在 part3 中的位置
            let fdArrayInPart3 = fdArrayOff - csEnd
            updateFDPrivateOffsets(part3, fdArrayInPart3, delta)
        }

        // === 7. 拼接 part1 + newCS + part3 ===
        let totalSize = part1.size + newCS.size + part3.size
        let result = Array<UInt8>(Int64(totalSize), repeat: UInt8(0))
        var rpos: Int64 = 0
        for (i in 0..part1.size)  { result[rpos] = part1[i];  rpos += 1 }
        for (i in 0..newCS.size)  { result[rpos] = newCS[i];  rpos += 1 }
        for (i in 0..part3.size)  { result[rpos] = part3[i];  rpos += 1 }
        result
    }

    // ===== 构建新 CharStrings INDEX =====

    private func buildNewCharstrings(csOff: Int64, csEnd: Int64): Array<UInt8> {
        // 读取原始 INDEX 元数据
        let count = Int64(readUInt16(csOff))
        if (count == 0) { return buildEmptyIndex() }
        let offsize = Int64(cff[csOff + 2])
        if (offsize < 1 || offsize > 4) { return buildEmptyIndex() }
        let offsetsStart = csOff + 3
        let dataStart = offsetsStart + (count + 1) * offsize

        // 收集每个字形的 charstring 数据
        var pieces = ArrayList<Array<UInt8>>()
        let endchar = Array<UInt8>(1, repeat: UInt8(0x0E))  // minimal endchar
        var totalDataSize: Int64 = 0

        for (i in 0..count) {
            let gOff = readOffset(offsetsStart, offsize, i)
            let gEnd = readOffset(offsetsStart, offsize, i + 1)
            let gLen = gEnd - gOff
            if (isGlyphUsed(UInt16(i)) && gLen > 0 && gOff >= 0 && gEnd <= (csEnd - dataStart + 1)) {
                let abs = dataStart + gOff - 1
                if (abs >= 0 && abs + gLen <= cff.size) {
                    let piece = Array<UInt8>(gLen, repeat: UInt8(0))
                    for (j in 0..gLen) { piece[j] = cff[abs + j] }
                    pieces.add(piece)
                    totalDataSize += gLen
                } else {
                    pieces.add(endchar)
                    totalDataSize += 1
                }
            } else {
                pieces.add(endchar)
                totalDataSize += 1
            }
        }

        // 确定新 offsize（需容纳 totalDataSize + 1，因为偏移是 1-based）
        let maxOff = totalDataSize + 1
        let newOffsize: Int64 = if (maxOff <= 255) { 1 }
                                else if (maxOff <= 65535) { 2 }
                                else if (maxOff <= 16777215) { 3 }
                                else { 4 }

        // 写出新 INDEX
        let headerSize = 3 + (count + 1) * newOffsize
        let output = Array<UInt8>(Int64(headerSize) + totalDataSize, repeat: UInt8(0))
        var pos: Int64 = 0

        // count (2 bytes)
        output[pos] = UInt8((UInt64(count) >> 8) & 0xFF); pos += 1
        output[pos] = UInt8(UInt64(count) & 0xFF); pos += 1
        // offsize (1 byte)
        output[pos] = UInt8(newOffsize); pos += 1
        // offsets (1-based)
        var curOff: Int64 = 1
        for (i in 0..(count + 1)) {
            writeOffsetBE(output, pos, newOffsize, curOff)
            pos += newOffsize
            if (i < pieces.size) { curOff += pieces[i].size }
        }
        // data
        for (i in 0..pieces.size) {
            let p = pieces[i]
            for (j in 0..p.size) { output[pos] = p[j]; pos += 1 }
        }
        output
    }

    private func buildEmptyIndex(): Array<UInt8> {
        // Empty CFF INDEX: count=0 (2 bytes)
        let d = Array<UInt8>(2, repeat: UInt8(0))
        d
    }

    private func isGlyphUsed(gid: UInt16): Bool {
        usedGlyphs.contains(gid)
    }

    // ===== 更新 TopDict 中的 FDArray 偏移 =====

    /** 在 part1（TopDict INDEX 所在区域）中原地更新指定操作符的最后一个 int32 操作数 */
    private func updateDictInt32(data: Array<UInt8>, dictStart: Int64, dictLen: Int64,
                                 op1: Int32, op2: Int32, newValue: Int64): Unit {
        // 找到目标操作符之前的最后一个 int32 操作数并更新
        var pos: Int64 = dictStart
        let dictEnd = dictStart + dictLen
        var lastInt32Pos: Int64 = -1  // 最近一个 int32 操作数的位置

        while (pos < dictEnd) {
            let b = Int32(data[pos])
            if (b == 29) {
                // 5 字节 int32
                lastInt32Pos = pos
                pos += 5
            } else if (b == 28) {
                lastInt32Pos = -1  // int16，重置（我们只替换 int32）
                pos += 3
            } else if (32 <= b && b <= 246) {
                lastInt32Pos = -1
                pos += 1
            } else if (247 <= b && b <= 250) {
                lastInt32Pos = -1
                pos += 2
            } else if (251 <= b && b <= 254) {
                lastInt32Pos = -1
                pos += 2
            } else if (b == 12 && pos + 1 < dictEnd) {
                // 2 字节操作符
                let op2b = Int32(data[pos + 1])
                if (b == op1 && op2b == op2) {
                    // 找到目标操作符，更新之前的 int32 操作数
                    if (lastInt32Pos >= 0) {
                        writeInt32BE(data, lastInt32Pos + 1, newValue)
                        return
                    }
                }
                lastInt32Pos = -1
                pos += 2
            } else {
                // 单字节操作符
                if (b == op1 && op2 < 0) {
                    if (lastInt32Pos >= 0) {
                        writeInt32BE(data, lastInt32Pos + 1, newValue)
                        return
                    }
                }
                lastInt32Pos = -1
                pos += 1
            }
        }
    }

    // ===== 更新 FD dict 中的 Private 偏移 =====

    /** 在 part3 中更新 FDArray 内所有 FD dict 的 Private 偏移（减 delta） */
    private func updateFDPrivateOffsets(part3: Array<UInt8>, fdArrayPosInPart3: Int64, delta: Int64): Unit {
        if (fdArrayPosInPart3 < 0 || fdArrayPosInPart3 + 2 >= part3.size) { return }

        let count = Int64(readUInt16FromArray(part3, fdArrayPosInPart3))
        if (count == 0) { return }
        let offsize = Int64(part3[fdArrayPosInPart3 + 2])
        if (offsize < 1 || offsize > 4) { return }

        let offsetsStart = fdArrayPosInPart3 + 3
        let dataStart = offsetsStart + (count + 1) * offsize

        for (i in 0..count) {
            let itemOff = readOffsetFromArray(part3, offsetsStart, offsize, i)
            let itemEnd = readOffsetFromArray(part3, offsetsStart, offsize, i + 1)
            let itemLen = itemEnd - itemOff
            if (itemLen <= 0) { continue }

            // FD dict 在 part3 中的实际位置（偏移是 1-based）
            let fdStart = dataStart + itemOff - 1
            if (fdStart < 0 || fdStart + itemLen > part3.size) { continue }

            // Private 操作符 = 0x12 (18)，有 2 个操作数 [size, offset]
            // 找到最后一个 int32 操作数（即 Private offset）
            updateDictInt32Private(part3, fdStart, itemLen, delta)
        }
    }

    /**
     * 专门处理 FD dict 中 Private 操作符（0x12）的 offset 操作数更新
     * Private 有两个操作数：[size, offset]，我们要更新 offset（最后一个 int32）
     */
    private func updateDictInt32Private(data: Array<UInt8>, dictStart: Int64, dictLen: Int64, delta: Int64): Unit {
        var pos: Int64 = dictStart
        let dictEnd = dictStart + dictLen
        var lastInt32Pos: Int64 = -1

        while (pos < dictEnd) {
            let b = Int32(data[pos])
            if (b == 29) {
                lastInt32Pos = pos
                pos += 5
            } else if (b == 28) {
                lastInt32Pos = -1
                pos += 3
            } else if (32 <= b && b <= 246) {
                lastInt32Pos = -1
                pos += 1
            } else if (247 <= b && b <= 250) {
                lastInt32Pos = -1
                pos += 2
            } else if (251 <= b && b <= 254) {
                lastInt32Pos = -1
                pos += 2
            } else if (b == 12 && pos + 1 < dictEnd) {
                lastInt32Pos = -1
                pos += 2
            } else if (b == 18) {
                // Private 操作符：用之前的 int32 位置更新 offset
                if (lastInt32Pos >= 0) {
                    let oldOff = readInt32BE(data, lastInt32Pos + 1)
                    writeInt32BE(data, lastInt32Pos + 1, oldOff - delta)
                }
                return
            } else {
                lastInt32Pos = -1
                pos += 1
            }
        }
    }

    // ===== CFF INDEX 导航工具 =====

    /** 跳过一个 CFF INDEX，返回 INDEX 之后的位置 */
    private func skipIndex(pos: Int64): Int64 {
        if (pos + 2 > cff.size) { return pos }
        let count = Int64(readUInt16(pos))
        if (count == 0) { return pos + 2 }
        if (pos + 3 > cff.size) { return pos + 2 }
        let offsize = Int64(cff[pos + 2])
        if (offsize < 1 || offsize > 4) { return pos + 3 }
        let offsetsStart = pos + 3
        // 读取最后一个偏移（offsets[count]）确定数据大小
        let lastOffPos = offsetsStart + count * offsize
        if (lastOffPos + offsize > cff.size) { return pos + 3 }
        let lastOff = readOffsetFromCff(lastOffPos, offsize)
        // 数据区起始 = offsetsStart + (count+1)*offsize
        // 数据区大小 = lastOff - 1
        let dataAreaStart = offsetsStart + (count + 1) * offsize
        dataAreaStart + lastOff - 1
    }

    /** 获取 INDEX 中第 idx 个条目的数据偏移（1-based 转为绝对偏移，相对于 cff 起始） */
    private func getIndexItemOffset(data: Array<UInt8>, idxPos: Int64, idx: Int64): Int64 {
        if (idxPos + 2 > data.size) { return -1 }
        let count = Int64(readUInt16FromArray(data, idxPos))
        if (idx >= count) { return -1 }
        let offsize = Int64(data[idxPos + 2])
        if (offsize < 1 || offsize > 4) { return -1 }
        let offsetsStart = idxPos + 3
        let dataStart = offsetsStart + (count + 1) * offsize
        let off = readOffsetFromArray(data, offsetsStart, offsize, idx)
        dataStart + off - 1
    }

    /** 获取 INDEX 中第 idx 个条目的长度 */
    private func getIndexItemLength(data: Array<UInt8>, idxPos: Int64, idx: Int64): Int64 {
        if (idxPos + 2 > data.size) { return 0 }
        let count = Int64(readUInt16FromArray(data, idxPos))
        if (idx >= count) { return 0 }
        let offsize = Int64(data[idxPos + 2])
        if (offsize < 1 || offsize > 4) { return 0 }
        let offsetsStart = idxPos + 3
        let off0 = readOffsetFromArray(data, offsetsStart, offsize, idx)
        let off1 = readOffsetFromArray(data, offsetsStart, offsize, idx + 1)
        off1 - off0
    }

    /** 获取 cff 中 INDEX 的末端位置（INDEX 总字节数的结束位置） */
    private func getIndexEnd(data: Array<UInt8>, pos: Int64): Int64 {
        if (pos + 2 > data.size) { return pos }
        let count = Int64(readUInt16FromArray(data, pos))
        if (count == 0) { return pos + 2 }
        let offsize = Int64(data[pos + 2])
        if (offsize < 1 || offsize > 4) { return pos + 2 }
        let offsetsStart = pos + 3
        let lastOffPos = offsetsStart + count * offsize
        if (lastOffPos + offsize > data.size) { return pos + 3 }
        let lastOff = readOffsetFromArray(data, offsetsStart, offsize, count)
        let dataAreaStart = offsetsStart + (count + 1) * offsize
        dataAreaStart + lastOff - 1
    }

    // ===== CFF Dict 解析工具 =====

    /**
     * 在 dict 中找到指定操作符的第一个操作数值（用于查询偏移）
     * op2 = -1 表示单字节操作符
     * 返回 -1 表示未找到
     */
    private func findDictInt(data: Array<UInt8>, dictStart: Int64, dictLen: Int64,
                             op1: Int32, op2: Int32): Int64 {
        var pos = dictStart
        let dictEnd = dictStart + dictLen
        var stack = ArrayList<Int64>()

        while (pos < dictEnd) {
            let b = Int32(data[pos])
            if (b == 29 && pos + 5 <= dictEnd) {
                stack.add(readInt32BEFromArray(data, pos + 1))
                pos += 5
            } else if (b == 28 && pos + 3 <= dictEnd) {
                stack.add(readInt16BEFromArray(data, pos + 1))
                pos += 3
            } else if (32 <= b && b <= 246) {
                stack.add(Int64(b - 139))
                pos += 1
            } else if (247 <= b && b <= 250 && pos + 2 <= dictEnd) {
                stack.add(Int64((b - 247) * 256 + Int32(data[pos + 1]) + 108))
                pos += 2
            } else if (251 <= b && b <= 254 && pos + 2 <= dictEnd) {
                stack.add(Int64(-((b - 251) * 256 + Int32(data[pos + 1]) + 108)))
                pos += 2
            } else if (b == 12 && pos + 2 <= dictEnd) {
                let op2b = Int32(data[pos + 1])
                if (b == op1 && op2b == op2 && stack.size > 0) {
                    return stack[stack.size - 1]
                }
                stack = ArrayList<Int64>()
                pos += 2
            } else {
                if (b == op1 && op2 < 0 && stack.size > 0) {
                    return stack[stack.size - 1]
                }
                stack = ArrayList<Int64>()
                pos += 1
            }
        }
        -1
    }

    // ===== INDEX 偏移读写 =====

    /** 从 cff 中读取偏移表中第 i 个偏移值（1-based） */
    private func readOffset(offsetsStart: Int64, offsize: Int64, i: Int64): Int64 {
        readOffsetFromCff(offsetsStart + i * offsize, offsize)
    }

    private func readOffsetFromCff(pos: Int64, offsize: Int64): Int64 {
        if (pos + offsize > cff.size) { return 0 }
        match (offsize) {
            case 1 => Int64(cff[pos])
            case 2 => (Int64(cff[pos]) << 8) | Int64(cff[pos + 1])
            case 3 => (Int64(cff[pos]) << 16) | (Int64(cff[pos + 1]) << 8) | Int64(cff[pos + 2])
            case _ => (Int64(cff[pos]) << 24) | (Int64(cff[pos + 1]) << 16) |
                      (Int64(cff[pos + 2]) << 8) | Int64(cff[pos + 3])
        }
    }

    private func readOffsetFromArray(data: Array<UInt8>, offsetsStart: Int64, offsize: Int64, i: Int64): Int64 {
        let pos = offsetsStart + i * offsize
        if (pos + offsize > data.size) { return 0 }
        match (offsize) {
            case 1 => Int64(data[pos])
            case 2 => (Int64(data[pos]) << 8) | Int64(data[pos + 1])
            case 3 => (Int64(data[pos]) << 16) | (Int64(data[pos + 1]) << 8) | Int64(data[pos + 2])
            case _ => (Int64(data[pos]) << 24) | (Int64(data[pos + 1]) << 16) |
                      (Int64(data[pos + 2]) << 8) | Int64(data[pos + 3])
        }
    }

    /** 写入 1-based 偏移值到输出数组 */
    private func writeOffsetBE(buf: Array<UInt8>, pos: Int64, offsize: Int64, value: Int64): Unit {
        match (offsize) {
            case 1 =>
                buf[pos] = UInt8(value & 0xFF)
            case 2 =>
                buf[pos]     = UInt8((value >> 8) & 0xFF)
                buf[pos + 1] = UInt8(value & 0xFF)
            case 3 =>
                buf[pos]     = UInt8((value >> 16) & 0xFF)
                buf[pos + 1] = UInt8((value >> 8) & 0xFF)
                buf[pos + 2] = UInt8(value & 0xFF)
            case _ =>
                buf[pos]     = UInt8((value >> 24) & 0xFF)
                buf[pos + 1] = UInt8((value >> 16) & 0xFF)
                buf[pos + 2] = UInt8((value >> 8) & 0xFF)
                buf[pos + 3] = UInt8(value & 0xFF)
        }
    }

    // ===== 字节读写工具 =====

    private func readUInt16(pos: Int64): UInt16 {
        (UInt16(cff[pos]) << 8) | UInt16(cff[pos + 1])
    }

    private func readUInt16FromArray(data: Array<UInt8>, pos: Int64): UInt16 {
        (UInt16(data[pos]) << 8) | UInt16(data[pos + 1])
    }

    private func readInt32BEFromArray(data: Array<UInt8>, pos: Int64): Int64 {
        let v = (Int64(data[pos]) << 24) | (Int64(data[pos + 1]) << 16) |
                (Int64(data[pos + 2]) << 8) | Int64(data[pos + 3])
        if (v >= 0x80000000) { v - 0x100000000 } else { v }
    }

    private func readInt32BE(data: Array<UInt8>, pos: Int64): Int64 {
        readInt32BEFromArray(data, pos)
    }

    private func readInt16BEFromArray(data: Array<UInt8>, pos: Int64): Int64 {
        let v = (Int64(data[pos]) << 8) | Int64(data[pos + 1])
        if (v >= 32768) { v - 65536 } else { v }
    }

    private func writeInt32BE(buf: Array<UInt8>, pos: Int64, value: Int64): Unit {
        let v = UInt64(value) & 0xFFFFFFFFu64
        buf[pos]     = UInt8((v >> 24) & 0xFF)
        buf[pos + 1] = UInt8((v >> 16) & 0xFF)
        buf[pos + 2] = UInt8((v >> 8) & 0xFF)
        buf[pos + 3] = UInt8(v & 0xFF)
    }

    private func copyRange(data: Array<UInt8>, start: Int64, end: Int64): Array<UInt8> {
        let len = end - start
        if (len <= 0) { return Array<UInt8>(0, repeat: UInt8(0)) }
        let result = Array<UInt8>(len, repeat: UInt8(0))
        for (i in 0..len) { result[i] = data[start + i] }
        result
    }
}
