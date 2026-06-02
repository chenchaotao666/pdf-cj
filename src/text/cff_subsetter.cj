/**
 * PDF-CJ: CFFSubsetter - CFF 子集化（三级优化）
 *
 *   1. CharStrings INDEX 紧凑化：count = maxUsedGID+1
 *   2. FD 级别子集化：未使用 FD 的 Local Subrs → 空 INDEX
 *   3. 子程序级别子集化：解析各 charstring，找出被调用的子程序（传递闭包），
 *      未被调用的子程序替换为单字节 return(0x0B)，大幅缩小 Local Subrs INDEX
 */
package pdf_cj.text

import std.collection.{HashMap, ArrayList}

public class CFFSubsetter {
    private let cff: Array<UInt8>
    private let usedGlyphs: HashMap<UInt16, Bool>

    public init(cff: Array<UInt8>, usedGlyphs: HashMap<UInt16, Bool>) {
        this.cff = cff
        this.usedGlyphs = usedGlyphs
    }

    public func generateSubset(): Array<UInt8> {
        if (cff.size < 8 || usedGlyphs.isEmpty()) { return cff }

        let hdrSize = Int64(cff[2])
        var pos = hdrSize
        pos = skipIndex(pos)
        let topDictIdxPos = pos
        pos = skipIndex(pos)
        pos = skipIndex(pos)
        pos = skipIndex(pos)

        let topDictOffset = getIndexItemOffset(cff, topDictIdxPos, 0)
        let topDictLen    = getIndexItemLength(cff, topDictIdxPos, 0)
        if (topDictOffset < 0 || topDictLen <= 0) { return cff }

        let charstringsOff = findDictInt(cff, topDictOffset, topDictLen, 17i32, -1i32)
        let fdArrayOff     = findDictInt(cff, topDictOffset, topDictLen, 12i32, 36i32)
        let fdSelectOff    = findDictInt(cff, topDictOffset, topDictLen, 12i32, 37i32)
        if (charstringsOff < 0) { return cff }

        let csEnd = getIndexEnd(cff, charstringsOff)
        if (csEnd <= charstringsOff) { return cff }

        let newCS = buildNewCharstrings(charstringsOff, csEnd)
        let csDelta = (csEnd - charstringsOff) - Int64(newCS.size)

        let nGlyphs = Int64(readUInt16(charstringsOff))
        let usedFDs = findUsedFDs(fdSelectOff, nGlyphs)

        let newFDArrayAbsStart = charstringsOff + Int64(newCS.size)
        var newPart3 = Array<UInt8>(0, repeat: UInt8(0))
        if (fdArrayOff >= csEnd) {
            newPart3 = buildNewFDSection(fdArrayOff, newFDArrayAbsStart, usedFDs,
                                         charstringsOff, fdSelectOff)
        } else {
            let part3old = copyRange(cff, csEnd, cff.size)
            if (fdArrayOff >= 0) {
                updateFDPrivateOffsets(part3old, fdArrayOff - csEnd, csDelta)
            }
            newPart3 = part3old
        }

        let part1 = copyRange(cff, 0, charstringsOff)
        if (fdArrayOff >= csEnd) {
            updateDictInt32(part1, topDictOffset, topDictLen, 12i32, 36i32, newFDArrayAbsStart)
        } else if (fdArrayOff >= 0) {
            updateDictInt32(part1, topDictOffset, topDictLen, 12i32, 36i32, fdArrayOff - csDelta)
        }

        let totalSize = part1.size + newCS.size + newPart3.size
        if (totalSize <= 0 || Int64(totalSize) >= Int64(cff.size)) { return cff }
        let result = Array<UInt8>(Int64(totalSize), repeat: UInt8(0))
        var rpos: Int64 = 0
        for (i in 0..part1.size)    { result[rpos] = part1[i];    rpos += 1 }
        for (i in 0..newCS.size)    { result[rpos] = newCS[i];    rpos += 1 }
        for (i in 0..newPart3.size) { result[rpos] = newPart3[i]; rpos += 1 }
        result
    }

    // ===== 找出实际用到的 FD =====

    private func findUsedFDs(fdSelectOff: Int64, nGlyphs: Int64): HashMap<Int32, Bool> {
        let used = HashMap<Int32, Bool>()
        if (fdSelectOff < 0 || fdSelectOff >= cff.size) { return used }
        let fmt = Int32(cff[fdSelectOff])
        if (fmt == 0) {
            for ((gid, _) in usedGlyphs) {
                let g = Int64(gid)
                let p = fdSelectOff + 1 + g
                if (p < cff.size) { used[Int32(cff[p])] = true }
            }
        } else if (fmt == 3) {
            let nRanges = (Int64(cff[fdSelectOff + 1]) << 8) | Int64(cff[fdSelectOff + 2])
            let rs = fdSelectOff + 3
            var ranges = ArrayList<(Int64, Int32)>()
            var r: Int64 = 0
            while (r < nRanges) {
                let off = rs + r * 3
                if (off + 2 >= cff.size) { break }
                ranges.add(((Int64(cff[off]) << 8) | Int64(cff[off + 1]), Int32(cff[off + 2])))
                r += 1
            }
            for ((gid, _) in usedGlyphs) {
                let g = Int64(gid)
                var fd: Int32 = 0
                for (ri in 0..ranges.size) {
                    let (sg, rfd) = ranges[ri]
                    if (sg <= g) { fd = rfd } else { break }
                }
                used[fd] = true
            }
        }
        used
    }

    // 找出属于特定 FD 的已用 GID
    private func getUsedGIDsForFD(fdIdx: Int32, fdSelectOff: Int64, nGlyphs: Int64): ArrayList<Int64> {
        let result = ArrayList<Int64>()
        if (fdSelectOff < 0 || fdSelectOff >= cff.size) { return result }
        let fmt = Int32(cff[fdSelectOff])
        if (fmt == 0) {
            for ((gid, _) in usedGlyphs) {
                let g = Int64(gid)
                let p = fdSelectOff + 1 + g
                if (p < cff.size && Int32(cff[p]) == fdIdx) { result.add(g) }
            }
        } else if (fmt == 3) {
            let nRanges = (Int64(cff[fdSelectOff + 1]) << 8) | Int64(cff[fdSelectOff + 2])
            let rs = fdSelectOff + 3
            var ranges = ArrayList<(Int64, Int32)>()
            var r: Int64 = 0
            while (r < nRanges) {
                let off = rs + r * 3
                if (off + 2 >= cff.size) { break }
                ranges.add(((Int64(cff[off]) << 8) | Int64(cff[off + 1]), Int32(cff[off + 2])))
                r += 1
            }
            for ((gid, _) in usedGlyphs) {
                let g = Int64(gid)
                var fd: Int32 = 0
                for (ri in 0..ranges.size) {
                    let (sg, rfd) = ranges[ri]
                    if (sg <= g) { fd = rfd } else { break }
                }
                if (fd == fdIdx) { result.add(g) }
            }
        }
        result
    }

    // ===== 构建新 FD 段 =====

    private func buildNewFDSection(
        fdArrayOff: Int64, newFDArrayAbsStart: Int64,
        usedFDs: HashMap<Int32, Bool>,
        charstringsOff: Int64, fdSelectOff: Int64
    ): Array<UInt8> {
        if (fdArrayOff < 0 || fdArrayOff + 3 > cff.size) {
            return Array<UInt8>(0, repeat: UInt8(0))
        }
        let fdCount = Int64(readUInt16(fdArrayOff))
        if (fdCount == 0) { return Array<UInt8>(0, repeat: UInt8(0)) }
        let fdOffsize = Int64(cff[fdArrayOff + 2])
        if (fdOffsize < 1 || fdOffsize > 4) { return Array<UInt8>(0, repeat: UInt8(0)) }
        let fdDataStart = fdArrayOff + 3 + (fdCount + 1) * fdOffsize

        // 解析每个 FD 的 Private DICT 信息
        var fdInfos = ArrayList<(Int64, Int64, Int64)>()
        for (fi in 0..fdCount) {
            let o1 = readOffsetFromCff(fdArrayOff + 3 + fi * fdOffsize, fdOffsize)
            let o2 = readOffsetFromCff(fdArrayOff + 3 + (fi + 1) * fdOffsize, fdOffsize)
            if (o2 <= o1) { fdInfos.add((0i64, 0i64, -1i64)); continue }
            let fdStart = fdDataStart + o1 - 1
            let fdLen = o2 - o1
            let privSize = findDictFirstInt(cff, fdStart, fdLen, 18i32)
            let privOff  = findDictInt(cff, fdStart, fdLen, 18i32, -1i32)
            var subrsRel: Int64 = -1
            if (privOff > 0 && privSize > 0) {
                subrsRel = findDictInt(cff, privOff, privSize, 19i32, -1i32)
            }
            fdInfos.add((privOff, privSize, subrsRel))
        }

        // 预构建 CharStrings 数据索引（用于子程序解析）
        let nGlyphs = Int64(readUInt16(charstringsOff))

        // 为每个 FD 构建 PrivDict + LocalSubrs
        var fdPieces = ArrayList<(Array<UInt8>, Array<UInt8>)>()
        for (fi in 0..fdCount) {
            let (privOff, privSize, subrsRel) = fdInfos[fi]
            let isFDUsed = usedFDs.contains(Int32(fi))

            // 是否需要为该 FD 输出 LocalSubrs：FD 被使用且原本有 Subrs
            let emitSubrs = isFDUsed && subrsRel >= 0

            // 新 PrivateDict（删除旧 Subrs 条目，按需追加新 Subrs 偏移）
            var newPriv: Array<UInt8>
            if (privOff > 0 && privSize > 0 && privOff + privSize <= cff.size) {
                let origPriv = copyRange(cff, privOff, privOff + privSize)
                newPriv = buildPrivateDict(origPriv, emitSubrs)
            } else {
                newPriv = Array<UInt8>(0, repeat: UInt8(0))
            }

            // 新 LocalSubrs（紧跟 Private DICT，偏移 = newPriv.size）
            var newSubrs: Array<UInt8>
            if (emitSubrs) {
                let subrsAbs = privOff + subrsRel
                if (subrsAbs > 0 && subrsAbs < cff.size) {
                    let subrsEnd = getIndexEnd(cff, subrsAbs)
                    if (subrsEnd > subrsAbs) {
                        // 子程序级子集化
                        let gidsForFD = getUsedGIDsForFD(Int32(fi), fdSelectOff, nGlyphs)
                        let neededSubrs = findNeededSubrs(gidsForFD, charstringsOff, subrsAbs)
                        newSubrs = subsetSubrsIndex(subrsAbs, subrsEnd, neededSubrs)
                    } else {
                        newSubrs = emptyIndex()
                    }
                } else {
                    newSubrs = emptyIndex()
                }
            } else {
                newSubrs = Array<UInt8>(0, repeat: UInt8(0))
            }
            fdPieces.add((newPriv, newSubrs))
        }

        // 计算 FDArray INDEX 大小（privSize 操作数用新 Private DICT 大小）
        var fdDictDataSize: Int64 = 0
        for (fi in 0..fdCount) {
            let (newPriv, _) = fdPieces[fi]
            let pse = if (newPriv.size > 0) { cffIntSize(Int64(newPriv.size)) } else { 1 }
            fdDictDataSize += pse + 5 + 1
        }
        let fdIdxOffsize: Int64 = if (fdDictDataSize + 1 <= 255) { 1 }
                                  else if (fdDictDataSize + 1 <= 65535) { 2 }
                                  else { 4 }
        let fdIdxSize = 3 + (fdCount + 1) * fdIdxOffsize + fdDictDataSize

        // 计算新 PrivateDict 绝对偏移
        var cumAbsOff = newFDArrayAbsStart + fdIdxSize
        var newPrivAbsOffs = ArrayList<Int64>()
        for (fi in 0..fdCount) {
            newPrivAbsOffs.add(cumAbsOff)
            let (newPriv, newSubrs) = fdPieces[fi]
            cumAbsOff += newPriv.size + newSubrs.size
        }

        let totalSize = cumAbsOff - newFDArrayAbsStart
        let out = Array<UInt8>(Int64(totalSize), repeat: UInt8(0))
        var wp: Int64 = 0

        out[wp] = UInt8((UInt64(fdCount) >> 8) & 0xFF); wp += 1
        out[wp] = UInt8(UInt64(fdCount) & 0xFF);        wp += 1
        out[wp] = UInt8(fdIdxOffsize);                   wp += 1

        let offTableStart = wp
        wp += (fdCount + 1) * fdIdxOffsize

        var fd1Based = ArrayList<Int64>()
        fd1Based.add(1i64)
        let fdDictDataStart = wp
        for (fi in 0..fdCount) {
            let (newPriv, _) = fdPieces[fi]
            let privAbsOff = newPrivAbsOffs[fi]
            let psBytes = encodeCFFInt(Int64(newPriv.size))
            for (b in 0..psBytes.size) { out[wp] = psBytes[b]; wp += 1 }
            let v = UInt64(privAbsOff) & 0xFFFFFFFFu64
            out[wp] = 29u8; wp += 1
            out[wp] = UInt8((v >> 24) & 0xFF); wp += 1
            out[wp] = UInt8((v >> 16) & 0xFF); wp += 1
            out[wp] = UInt8((v >> 8) & 0xFF);  wp += 1
            out[wp] = UInt8(v & 0xFF);          wp += 1
            out[wp] = 18u8; wp += 1
            fd1Based.add(wp - fdDictDataStart + 1)
        }
        for (fi in 0..(fdCount + 1)) {
            writeOffsetBE(out, offTableStart + fi * fdIdxOffsize, fdIdxOffsize, fd1Based[fi])
        }
        for (fi in 0..fdCount) {
            let (newPriv, newSubrs) = fdPieces[fi]
            for (b in 0..newPriv.size)  { out[wp] = newPriv[b];  wp += 1 }
            for (b in 0..newSubrs.size) { out[wp] = newSubrs[b]; wp += 1 }
        }
        out
    }

    // ===== 子程序级子集化 =====

    // 计算 Local Subrs INDEX 的偏置值
    private func localSubrBias(count: Int64): Int64 {
        if (count < 1240) { 107 }
        else if (count < 33900) { 1131 }
        else { 32768 }
    }

    // 找出所有被用到的子程序索引（传递闭包）
    private func findNeededSubrs(
        gids: ArrayList<Int64>, charstringsOff: Int64, localSubrsAbs: Int64
    ): HashMap<Int64, Bool> {
        let needed = HashMap<Int64, Bool>()
        if (gids.isEmpty()) { return needed }

        let subrsCount = Int64(readUInt16(localSubrsAbs))
        let bias = localSubrBias(subrsCount)

        let subrsOffsize = Int64(cff[localSubrsAbs + 2])
        if (subrsOffsize < 1 || subrsOffsize > 4) { return needed }
        let subrsOffsetsStart = localSubrsAbs + 3
        let subrsDataStart = subrsOffsetsStart + (subrsCount + 1) * subrsOffsize

        // 预先读取所有子程序的字节范围
        var subrPieces = ArrayList<(Int64, Int64)>()  // (dataStart, length)
        for (si in 0..subrsCount) {
            let o1 = readOffsetFromCff(subrsOffsetsStart + si * subrsOffsize, subrsOffsize)
            let o2 = readOffsetFromCff(subrsOffsetsStart + (si + 1) * subrsOffsize, subrsOffsize)
            let abs1 = subrsDataStart + o1 - 1
            let len  = o2 - o1
            if (abs1 >= 0 && abs1 + len <= cff.size && len > 0) {
                subrPieces.add((abs1, len))
            } else {
                subrPieces.add((-1i64, 0i64))
            }
        }

        // 对每个用到的 GID，解析 charstring，收集被调用的子程序
        let csOffsize = Int64(cff[charstringsOff + 2])
        let csCount   = Int64(readUInt16(charstringsOff))
        if (csOffsize < 1 || csOffsize > 4) { return needed }
        let csOffsetsStart = charstringsOff + 3
        let csDataStart    = csOffsetsStart + (csCount + 1) * csOffsize

        for (gi in 0..gids.size) {
            let gid = gids[gi]
            if (gid < 0 || gid >= csCount) { continue }
            let o1 = readOffsetFromCff(csOffsetsStart + gid * csOffsize, csOffsize)
            let o2 = readOffsetFromCff(csOffsetsStart + (gid + 1) * csOffsize, csOffsize)
            let abs1 = csDataStart + o1 - 1
            let len  = o2 - o1
            if (abs1 >= 0 && abs1 + len <= cff.size && len > 0) {
                collectCalledSubrs(abs1, len, subrPieces, bias, needed, 0i32, 0i32)
            }
        }
        needed
    }

    /**
     * 解析 Type 2 charstring，递归收集被调用的 Local Subrs 索引。
     * 返回更新后的 hint 数量（供上层继续解析时使用）。
     *
     * 关键：必须正确处理 hintmask(19) / cntrmask(20)——
     * 这两个操作符后面跟着 ceil(numHints/8) 字节的 mask 数据，
     * 不能当作普通操作数解析，否则会漏掉真正的 callsubr。
     */
    private func collectCalledSubrs(
        dataAbs: Int64, dataLen: Int64,
        subrPieces: ArrayList<(Int64, Int64)>,
        bias: Int64,
        needed: HashMap<Int64, Bool>,
        depth: Int32,
        numHintsIn: Int32
    ): Int32 {
        if (depth > 10 || dataLen <= 0) { return numHintsIn }
        var i: Int64 = 0
        var stack = ArrayList<Int64>()
        var numHints: Int32 = numHintsIn

        while (i < dataLen) {
            let bPos = dataAbs + i
            if (bPos >= cff.size) { break }
            let b = Int32(cff[bPos])

            if (b == 10) {
                // callsubr：弹出栈顶 + 偏置 = 子程序索引
                if (stack.size > 0) {
                    let biasedIdx = stack[stack.size - 1]
                    stack.remove((stack.size - 1)..stack.size)
                    let actualIdx = biasedIdx + bias
                    if (actualIdx >= 0 && Int64(actualIdx) < subrPieces.size) {
                        if (!needed.contains(actualIdx)) {
                            needed[actualIdx] = true
                            let (sAbs, sLen) = subrPieces[Int64(actualIdx)]
                            if (sAbs >= 0 && sLen > 0) {
                                numHints = collectCalledSubrs(sAbs, sLen, subrPieces, bias,
                                                             needed, depth + 1, numHints)
                            }
                        }
                    }
                }
                i += 1
            } else if (b == 11 || b == 14) {
                break  // return / endchar
            } else if (b == 1 || b == 3) {
                // hstem / vstem：每对操作数 = 1 条 hint
                numHints += Int32(stack.size) / 2
                stack = ArrayList<Int64>()
                i += 1
            } else if (b == 18 || b == 23) {
                // hstemhm / vstemhm：同上
                numHints += Int32(stack.size) / 2
                stack = ArrayList<Int64>()
                i += 1
            } else if (b == 19 || b == 20) {
                // hintmask / cntrmask：栈里残留的操作数视为隐式 vstemhm
                numHints += Int32(stack.size) / 2
                stack = ArrayList<Int64>()
                // 跳过 ceil(numHints/8) 字节的 mask 数据
                let maskBytes = Int64((numHints + 7) / 8)
                i += 1 + maskBytes
            } else if (b == 29) {
                // callgsubr：不追踪全局子程序，只弹栈
                if (stack.size > 0) { stack.remove((stack.size - 1)..stack.size) }
                i += 1
            } else if (b == 28) {
                if (bPos + 2 < cff.size) {
                    let v = (Int64(cff[bPos + 1]) << 8) | Int64(cff[bPos + 2])
                    stack.add(if (v >= 32768) { v - 65536 } else { v })
                }
                i += 3
            } else if (b == 255) {
                // 4 字节定点数（charstring 专用，非整数）
                i += 5
            } else if (32 <= b && b <= 246) {
                stack.add(Int64(b - 139)); i += 1
            } else if (247 <= b && b <= 250) {
                if (bPos + 1 < cff.size) {
                    stack.add(Int64((b - 247) * 256 + Int32(cff[bPos + 1]) + 108))
                }
                i += 2
            } else if (251 <= b && b <= 254) {
                if (bPos + 1 < cff.size) {
                    stack.add(Int64(-((b - 251) * 256 + Int32(cff[bPos + 1]) + 108)))
                }
                i += 2
            } else if (b == 12) {
                // escape 操作符（2 字节）
                stack = ArrayList<Int64>()
                i += 2
            } else {
                // 其他单字节操作符
                stack = ArrayList<Int64>()
                i += 1
            }
        }
        numHints
    }

    // 重建 Local Subrs INDEX，未使用条目替换为单字节 return(0x0B)
    private func subsetSubrsIndex(
        subrsAbs: Int64, subrsEnd: Int64, needed: HashMap<Int64, Bool>
    ): Array<UInt8> {
        let count = Int64(readUInt16(subrsAbs))
        if (count == 0) { return emptyIndex() }
        let offsize = Int64(cff[subrsAbs + 2])
        if (offsize < 1 || offsize > 4) { return emptyIndex() }
        let offsetsStart = subrsAbs + 3
        let dataStart    = offsetsStart + (count + 1) * offsize

        let retByte = Array<UInt8>(1, repeat: 11u8)  // return(0x0B)
        var pieces = ArrayList<Array<UInt8>>()
        var totalDataSize: Int64 = 0

        for (si in 0..count) {
            let o1 = readOffsetFromCff(offsetsStart + si * offsize, offsize)
            let o2 = readOffsetFromCff(offsetsStart + (si + 1) * offsize, offsize)
            let abs1 = dataStart + o1 - 1
            let len  = o2 - o1
            if (needed.contains(Int64(si)) && abs1 >= 0 && abs1 + len <= cff.size && len > 0) {
                pieces.add(copyRange(cff, abs1, abs1 + len))
                totalDataSize += len
            } else {
                pieces.add(retByte)
                totalDataSize += 1
            }
        }

        let maxOff = totalDataSize + 1
        let newOffsize: Int64 = if (maxOff <= 255) { 1 }
                                else if (maxOff <= 65535) { 2 }
                                else if (maxOff <= 16777215) { 3 }
                                else { 4 }

        let hdrSize = 3 + (count + 1) * newOffsize
        let out = Array<UInt8>(Int64(hdrSize) + totalDataSize, repeat: UInt8(0))
        var wp: Int64 = 0
        out[wp] = UInt8((UInt64(count) >> 8) & 0xFF); wp += 1
        out[wp] = UInt8(UInt64(count) & 0xFF);        wp += 1
        out[wp] = UInt8(newOffsize);                   wp += 1
        var curOff: Int64 = 1
        for (i in 0..(count + 1)) {
            writeOffsetBE(out, wp, newOffsize, curOff)
            wp += newOffsize
            if (i < pieces.size) { curOff += pieces[i].size }
        }
        for (i in 0..pieces.size) {
            let p = pieces[i]
            for (j in 0..p.size) { out[wp] = p[j]; wp += 1 }
        }
        out
    }

    // ===== Private DICT 修改 =====

    /**
     * 重建 Private DICT：复制除 Subrs(19) 外的所有 operand-operator 条目，
     * 若 emitSubrs 则在末尾追加一个新的 Subrs 条目，偏移 = 新 Private DICT 大小
     *（使 LocalSubrs 紧跟其后）。偏移用固定 3 字节 int16(op 28) 编码，避免循环依赖。
     *
     * 关键：CFF DICT 中操作数必须紧邻其操作符，不能用哑整数填充残留在栈上，
     * 否则阅读器解析 Private DICT 时会因 "non-empty stack" 报错。
     */
    private func buildPrivateDict(origPriv: Array<UInt8>, emitSubrs: Bool): Array<UInt8> {
        var kept = ArrayList<UInt8>()
        var pos: Int64 = 0
        var opStart: Int64 = 0   // 当前 operand 序列起点

        while (pos < origPriv.size) {
            let b = Int32(origPriv[pos])
            if (b == 28) { pos += 3 }            // int16 operand
            else if (b == 29) { pos += 5 }       // int32 operand
            else if (b == 30) {                  // real number operand（nibble 流）
                pos += 1
                var done = false
                while (pos < origPriv.size && !done) {
                    let nib = Int32(origPriv[pos]); pos += 1
                    if ((nib & 0x0F) == 0x0F || (nib & 0xF0) == 0xF0) { done = true }
                }
            }
            else if (32 <= b && b <= 246) { pos += 1 }       // 1 字节整数
            else if (247 <= b && b <= 254) { pos += 2 }      // 2 字节整数
            else if (b == 12) {
                // 2 字节操作符：复制整段 operand+operator
                for (j in opStart..(pos + 2)) { kept.add(origPriv[j]) }
                pos += 2
                opStart = pos
            }
            else {
                // 1 字节操作符
                if (b == 19) {
                    // Subrs：丢弃此条目（不复制）
                    pos += 1
                    opStart = pos
                } else {
                    for (j in opStart..(pos + 1)) { kept.add(origPriv[j]) }
                    pos += 1
                    opStart = pos
                }
            }
        }

        if (!emitSubrs) {
            let r = Array<UInt8>(kept.size, repeat: UInt8(0))
            for (i in 0..kept.size) { r[i] = kept[i] }
            return r
        }

        // 追加新 Subrs 条目：偏移 = 新 Private DICT 大小（base + 4）
        let base = kept.size
        let newSize = base + 4
        let result = Array<UInt8>(newSize, repeat: UInt8(0))
        for (i in 0..base) { result[i] = kept[i] }
        result[base]     = 28u8                              // int16 operand
        result[base + 1] = UInt8((newSize >> 8) & 0xFF)
        result[base + 2] = UInt8(newSize & 0xFF)
        result[base + 3] = 19u8                              // Subrs 操作符
        result
    }

    // ===== CharStrings INDEX 紧凑化 =====

    private func buildNewCharstrings(csOff: Int64, csEnd: Int64): Array<UInt8> {
        let originalCount = Int64(readUInt16(csOff))
        if (originalCount == 0) { return emptyIndex() }
        let offsize = Int64(cff[csOff + 2])
        if (offsize < 1 || offsize > 4) { return emptyIndex() }
        // 必须保持 numGlyphs 不变：charset 和 FDSelect（在 part1 中完整保留）
        // 都是按原始字形数编码的。裁剪 count 会破坏三者一致性，导致字体无法解析。
        // 未用字形替换为单字节 endchar(0x0E)，offset 表略大但数据区极小。
        let count = originalCount
        let offsetsStart = csOff + 3
        let dataStart    = offsetsStart + (originalCount + 1) * offsize
        let endchar = Array<UInt8>(1, repeat: 14u8)
        var pieces = ArrayList<Array<UInt8>>()
        var totalDataSize: Int64 = 0
        for (i in 0..count) {
            let gOff = readOffsetFromCff(offsetsStart + i * offsize, offsize)
            let gEnd = readOffsetFromCff(offsetsStart + (i + 1) * offsize, offsize)
            let gLen = gEnd - gOff
            if (isGlyphUsed(UInt16(i)) && gLen > 0 && gOff >= 0 && gEnd <= (csEnd - dataStart + 1)) {
                let abs = dataStart + gOff - 1
                if (abs >= 0 && abs + gLen <= cff.size) {
                    pieces.add(copyRange(cff, abs, abs + gLen))
                    totalDataSize += gLen
                } else {
                    pieces.add(endchar); totalDataSize += 1
                }
            } else {
                pieces.add(endchar); totalDataSize += 1
            }
        }
        let maxOff = totalDataSize + 1
        let newOffsize: Int64 = if (maxOff <= 255) { 1 }
                                else if (maxOff <= 65535) { 2 }
                                else if (maxOff <= 16777215) { 3 }
                                else { 4 }
        let hdrSize = 3 + (count + 1) * newOffsize
        let output = Array<UInt8>(Int64(hdrSize) + totalDataSize, repeat: UInt8(0))
        var pos: Int64 = 0
        output[pos] = UInt8((UInt64(count) >> 8) & 0xFF); pos += 1
        output[pos] = UInt8(UInt64(count) & 0xFF);        pos += 1
        output[pos] = UInt8(newOffsize);                   pos += 1
        var curOff: Int64 = 1
        for (i in 0..(count + 1)) {
            writeOffsetBE(output, pos, newOffsize, curOff)
            pos += newOffsize
            if (i < pieces.size) { curOff += pieces[i].size }
        }
        for (i in 0..pieces.size) {
            let p = pieces[i]
            for (j in 0..p.size) { output[pos] = p[j]; pos += 1 }
        }
        output
    }

    // ===== 辅助 =====

    private func cffIntSize(value: Int64): Int64 {
        if (-107 <= value && value <= 107) { 1 }
        else if (-1131 <= value && value <= 1131) { 2 }
        else if (-32768 <= value && value <= 32767) { 3 }
        else { 5 }
    }

    private func encodeCFFInt(value: Int64): Array<UInt8> {
        if (-107 <= value && value <= 107) {
            Array<UInt8>(1, repeat: UInt8(value + 139))
        } else if (108 <= value && value <= 1131) {
            let r = Array<UInt8>(2, repeat: UInt8(0))
            r[0] = UInt8((value - 108) / 256 + 247)
            r[1] = UInt8((value - 108) % 256)
            r
        } else if (-1131 <= value && value <= -108) {
            let r = Array<UInt8>(2, repeat: UInt8(0))
            r[0] = UInt8((-value - 108) / 256 + 251)
            r[1] = UInt8((-value - 108) % 256)
            r
        } else if (-32768 <= value && value <= 32767) {
            let r = Array<UInt8>(3, repeat: UInt8(0))
            r[0] = 28u8
            r[1] = UInt8((UInt64(value) >> 8) & 0xFF)
            r[2] = UInt8(UInt64(value) & 0xFF)
            r
        } else {
            let r = Array<UInt8>(5, repeat: UInt8(0))
            let v = UInt64(value) & 0xFFFFFFFFu64
            r[0] = 29u8
            r[1] = UInt8((v >> 24) & 0xFF); r[2] = UInt8((v >> 16) & 0xFF)
            r[3] = UInt8((v >> 8) & 0xFF);  r[4] = UInt8(v & 0xFF)
            r
        }
    }

    private func emptyIndex(): Array<UInt8> { Array<UInt8>(2, repeat: UInt8(0)) }

    private func isGlyphUsed(gid: UInt16): Bool { usedGlyphs.contains(gid) }

    private func findDictFirstInt(data: Array<UInt8>, dictStart: Int64, dictLen: Int64, op1: Int32): Int64 {
        var pos = dictStart
        let dictEnd = dictStart + dictLen
        var stack = ArrayList<Int64>()
        while (pos < dictEnd) {
            let b = Int32(data[pos])
            if (b == 29 && pos + 5 <= dictEnd) { stack.add(readInt32BEFromArray(data, pos + 1)); pos += 5 }
            else if (b == 28 && pos + 3 <= dictEnd) { stack.add(readInt16BEFromArray(data, pos + 1)); pos += 3 }
            else if (32 <= b && b <= 246) { stack.add(Int64(b - 139)); pos += 1 }
            else if (247 <= b && b <= 250 && pos + 2 <= dictEnd) {
                stack.add(Int64((b - 247) * 256 + Int32(data[pos + 1]) + 108)); pos += 2 }
            else if (251 <= b && b <= 254 && pos + 2 <= dictEnd) {
                stack.add(Int64(-((b - 251) * 256 + Int32(data[pos + 1]) + 108))); pos += 2 }
            else if (b == 12 && pos + 2 <= dictEnd) { stack = ArrayList<Int64>(); pos += 2 }
            else {
                if (b == op1 && stack.size >= 1) { return stack[0] }
                stack = ArrayList<Int64>(); pos += 1
            }
        }
        -1
    }

    private func updateDictInt32(data: Array<UInt8>, dictStart: Int64, dictLen: Int64,
                                 op1: Int32, op2: Int32, newValue: Int64): Unit {
        var pos: Int64 = dictStart
        let dictEnd = dictStart + dictLen
        var lastInt32Pos: Int64 = -1
        while (pos < dictEnd) {
            let b = Int32(data[pos])
            if (b == 29) { lastInt32Pos = pos; pos += 5 }
            else if (b == 28) { lastInt32Pos = -1; pos += 3 }
            else if (32 <= b && b <= 246) { lastInt32Pos = -1; pos += 1 }
            else if (247 <= b && b <= 250) { lastInt32Pos = -1; pos += 2 }
            else if (251 <= b && b <= 254) { lastInt32Pos = -1; pos += 2 }
            else if (b == 12 && pos + 1 < dictEnd) {
                let op2b = Int32(data[pos + 1])
                if (b == op1 && op2b == op2 && lastInt32Pos >= 0) {
                    writeInt32BE(data, lastInt32Pos + 1, newValue); return
                }
                lastInt32Pos = -1; pos += 2
            } else {
                if (b == op1 && op2 < 0 && lastInt32Pos >= 0) {
                    writeInt32BE(data, lastInt32Pos + 1, newValue); return
                }
                lastInt32Pos = -1; pos += 1
            }
        }
    }

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
            if (itemEnd <= itemOff) { continue }
            let fdStart = dataStart + itemOff - 1
            if (fdStart < 0 || fdStart + (itemEnd - itemOff) > part3.size) { continue }
            updateDictInt32Private(part3, fdStart, itemEnd - itemOff, delta)
        }
    }

    private func updateDictInt32Private(data: Array<UInt8>, dictStart: Int64, dictLen: Int64, delta: Int64): Unit {
        var pos: Int64 = dictStart
        let dictEnd = dictStart + dictLen
        var lastInt32Pos: Int64 = -1
        while (pos < dictEnd) {
            let b = Int32(data[pos])
            if (b == 29) { lastInt32Pos = pos; pos += 5 }
            else if (b == 28) { lastInt32Pos = -1; pos += 3 }
            else if (32 <= b && b <= 246) { lastInt32Pos = -1; pos += 1 }
            else if (247 <= b && b <= 250) { lastInt32Pos = -1; pos += 2 }
            else if (251 <= b && b <= 254) { lastInt32Pos = -1; pos += 2 }
            else if (b == 12 && pos + 1 < dictEnd) { lastInt32Pos = -1; pos += 2 }
            else if (b == 18) {
                if (lastInt32Pos >= 0) {
                    let oldOff = readInt32BE(data, lastInt32Pos + 1)
                    writeInt32BE(data, lastInt32Pos + 1, oldOff - delta)
                }
                return
            } else { lastInt32Pos = -1; pos += 1 }
        }
    }

    private func skipIndex(pos: Int64): Int64 {
        if (pos + 2 > cff.size) { return pos }
        let count = Int64(readUInt16(pos))
        if (count == 0) { return pos + 2 }
        if (pos + 3 > cff.size) { return pos + 2 }
        let offsize = Int64(cff[pos + 2])
        if (offsize < 1 || offsize > 4) { return pos + 3 }
        let lastOffPos = pos + 3 + count * offsize
        if (lastOffPos + offsize > cff.size) { return pos + 3 }
        let lastOff = readOffsetFromCff(lastOffPos, offsize)
        pos + 3 + (count + 1) * offsize + lastOff - 1
    }

    private func getIndexItemOffset(data: Array<UInt8>, idxPos: Int64, idx: Int64): Int64 {
        if (idxPos + 2 > data.size) { return -1 }
        let count = Int64(readUInt16FromArray(data, idxPos))
        if (idx >= count) { return -1 }
        let offsize = Int64(data[idxPos + 2])
        if (offsize < 1 || offsize > 4) { return -1 }
        let offsetsStart = idxPos + 3
        let dataStart = offsetsStart + (count + 1) * offsize
        dataStart + readOffsetFromArray(data, offsetsStart, offsize, idx) - 1
    }

    private func getIndexItemLength(data: Array<UInt8>, idxPos: Int64, idx: Int64): Int64 {
        if (idxPos + 2 > data.size) { return 0 }
        let count = Int64(readUInt16FromArray(data, idxPos))
        if (idx >= count) { return 0 }
        let offsize = Int64(data[idxPos + 2])
        if (offsize < 1 || offsize > 4) { return 0 }
        let offsetsStart = idxPos + 3
        readOffsetFromArray(data, offsetsStart, offsize, idx + 1) -
        readOffsetFromArray(data, offsetsStart, offsize, idx)
    }

    private func getIndexEnd(data: Array<UInt8>, pos: Int64): Int64 {
        if (pos + 2 > data.size) { return pos }
        let count = Int64(readUInt16FromArray(data, pos))
        if (count == 0) { return pos + 2 }
        let offsize = Int64(data[pos + 2])
        if (offsize < 1 || offsize > 4) { return pos + 2 }
        let offsetsStart = pos + 3
        pos + 3 + (count + 1) * offsize + readOffsetFromArray(data, offsetsStart, offsize, count) - 1
    }

    private func findDictInt(data: Array<UInt8>, dictStart: Int64, dictLen: Int64,
                             op1: Int32, op2: Int32): Int64 {
        var pos = dictStart
        let dictEnd = dictStart + dictLen
        var stack = ArrayList<Int64>()
        while (pos < dictEnd) {
            let b = Int32(data[pos])
            if (b == 29 && pos + 5 <= dictEnd) { stack.add(readInt32BEFromArray(data, pos + 1)); pos += 5 }
            else if (b == 28 && pos + 3 <= dictEnd) { stack.add(readInt16BEFromArray(data, pos + 1)); pos += 3 }
            else if (32 <= b && b <= 246) { stack.add(Int64(b - 139)); pos += 1 }
            else if (247 <= b && b <= 250 && pos + 2 <= dictEnd) {
                stack.add(Int64((b - 247) * 256 + Int32(data[pos + 1]) + 108)); pos += 2 }
            else if (251 <= b && b <= 254 && pos + 2 <= dictEnd) {
                stack.add(Int64(-((b - 251) * 256 + Int32(data[pos + 1]) + 108))); pos += 2 }
            else if (b == 12 && pos + 2 <= dictEnd) {
                let op2b = Int32(data[pos + 1])
                if (b == op1 && op2b == op2 && stack.size > 0) { return stack[stack.size - 1] }
                stack = ArrayList<Int64>(); pos += 2
            } else {
                if (b == op1 && op2 < 0 && stack.size > 0) { return stack[stack.size - 1] }
                stack = ArrayList<Int64>(); pos += 1
            }
        }
        -1
    }

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

    private func writeOffsetBE(buf: Array<UInt8>, pos: Int64, offsize: Int64, value: Int64): Unit {
        match (offsize) {
            case 1 => buf[pos] = UInt8(value & 0xFF)
            case 2 => buf[pos] = UInt8((value >> 8) & 0xFF); buf[pos + 1] = UInt8(value & 0xFF)
            case 3 =>
                buf[pos] = UInt8((value >> 16) & 0xFF)
                buf[pos + 1] = UInt8((value >> 8) & 0xFF)
                buf[pos + 2] = UInt8(value & 0xFF)
            case _ =>
                buf[pos] = UInt8((value >> 24) & 0xFF); buf[pos + 1] = UInt8((value >> 16) & 0xFF)
                buf[pos + 2] = UInt8((value >> 8) & 0xFF); buf[pos + 3] = UInt8(value & 0xFF)
        }
    }

    private func readUInt16(pos: Int64): UInt16 { (UInt16(cff[pos]) << 8) | UInt16(cff[pos + 1]) }

    private func readUInt16FromArray(data: Array<UInt8>, pos: Int64): UInt16 {
        (UInt16(data[pos]) << 8) | UInt16(data[pos + 1])
    }

    private func readInt32BEFromArray(data: Array<UInt8>, pos: Int64): Int64 {
        let v = (Int64(data[pos]) << 24) | (Int64(data[pos + 1]) << 16) |
                (Int64(data[pos + 2]) << 8) | Int64(data[pos + 3])
        if (v >= 0x80000000) { v - 0x100000000 } else { v }
    }

    private func readInt32BE(data: Array<UInt8>, pos: Int64): Int64 { readInt32BEFromArray(data, pos) }

    private func readInt16BEFromArray(data: Array<UInt8>, pos: Int64): Int64 {
        let v = (Int64(data[pos]) << 8) | Int64(data[pos + 1])
        if (v >= 32768) { v - 65536 } else { v }
    }

    private func writeInt32BE(buf: Array<UInt8>, pos: Int64, value: Int64): Unit {
        let v = UInt64(value) & 0xFFFFFFFFu64
        buf[pos] = UInt8((v >> 24) & 0xFF); buf[pos + 1] = UInt8((v >> 16) & 0xFF)
        buf[pos + 2] = UInt8((v >> 8) & 0xFF); buf[pos + 3] = UInt8(v & 0xFF)
    }

    private func copyRange(data: Array<UInt8>, start: Int64, end: Int64): Array<UInt8> {
        let len = end - start
        if (len <= 0) { return Array<UInt8>(0, repeat: UInt8(0)) }
        let result = Array<UInt8>(len, repeat: UInt8(0))
        for (i in 0..len) { result[i] = data[start + i] }
        result
    }
}
