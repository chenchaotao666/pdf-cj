/**
 * PDF-CJ: FontSubsetting - 字体子集化
 * 只嵌入实际使用的字形，减小 PDF 文件体积
 *
 * 算法（紧凑子集化 + CIDToGIDMap 流）：
 *   1. 收集已用字形 GID 集合（含复合字形传递闭包）
 *   2. 将已用 GID 紧凑重映射到 0..N（避免巨大的 loca/hmtx 表）
 *   3. 生成极小 cmap（仅包含已用 Unicode→新 GID）
 *   4. 修补复合字形中的旧 GID 引用为新 GID
 *   5. 额外输出 CIDToGIDMap 数组（旧 GID → 新 GID），供 PDF 阅读器定位字形槽位
 *
 * 为什么需要 CIDToGIDMap 流：
 *   PDF 内容流写入的是原始 GID（作为 CID），CIDToGIDMap 将其映射到紧凑字体文件中的槽位。
 *   这样内容流不必修改，字体文件又能做到极小。
 */
package pdf_cj.text

import std.collection.{HashMap, ArrayList}

/**
 * 字体子集化类
 * 跟踪使用的字形并生成子集字体
 */
public class FontSubsetting {
    private var ttfFont: TrueTypeFont
    private var usedGlyphs: HashMap<UInt16, Bool> = HashMap<UInt16, Bool>()
    private var usedChars: HashMap<UInt32, UInt16> = HashMap<UInt32, UInt16>()  // unicode → 原始 GID
    private var glyphMapping: HashMap<UInt16, UInt16> = HashMap<UInt16, UInt16>()  // 旧 GID → 新紧凑 GID

    public init(font: TrueTypeFont) {
        this.ttfFont = font
        usedGlyphs[UInt16(0)] = true  // .notdef 必须包含
    }

    public func markGlyphUsed(glyphId: UInt16): Unit {
        usedGlyphs[glyphId] = true
    }

    public func markCharUsed(unicode: UInt32): Unit {
        let glyphId = ttfFont.getGlyphId(unicode)
        if (glyphId != 0) {
            usedGlyphs[glyphId] = true
            usedChars[unicode] = glyphId
        }
    }

    public func markStringUsed(text: String): Unit {
        for (ch in text.runes()) {
            markCharUsed(UInt32(ch))
        }
    }

    public func getUsedGlyphCount(): Int64 {
        usedGlyphs.size
    }

    public func isGlyphUsed(glyphId: UInt16): Bool {
        usedGlyphs.contains(glyphId)
    }

    // 保留旧接口兼容（不再用于子集生成，但外部可能调用）
    public func buildGlyphMapping(): Unit {
        var sorted = ArrayList<UInt16>()
        for ((gid, _) in usedGlyphs) { sorted.add(gid) }
        sortGlyphList(sorted)
        glyphMapping.clear()
        for (newGid in 0..sorted.size) {
            glyphMapping[sorted[newGid]] = UInt16(newGid)
        }
    }

    public func getNewGlyphId(oldGlyphId: UInt16): UInt16 {
        match (glyphMapping.get(oldGlyphId)) {
            case Some(gid) => gid
            case None => UInt16(0)
        }
    }

    // ===== 核心：生成紧凑子集 TTF =====

    /**
     * 生成子集字体二进制数据（紧凑算法）
     * 调用后 glyphMapping 已就绪，可再调用 buildCIDToGIDMapData()
     */
    public func generateSubsetFont(): Array<UInt8> {
        if (usedGlyphs.isEmpty()) {
            return Array<UInt8>(0, repeat: UInt8(0))
        }

        // 1. 传递闭包：确保复合字形所引用的分量字形也被包含
        computeGlyphClosure()

        // 2. 排序已用 GID，确保 .notdef(0) 在首位
        var sorted = ArrayList<UInt16>()
        if (!usedGlyphs.contains(UInt16(0))) { sorted.add(UInt16(0)) }
        for ((gid, _) in usedGlyphs) { sorted.add(gid) }
        sortGlyphList(sorted)

        let numGlyphs = Int32(sorted.size)

        // 3. 建立紧凑映射 oldGID → newGID (0, 1, 2, ...)
        glyphMapping.clear()
        for (newGid in 0..sorted.size) {
            glyphMapping[sorted[newGid]] = UInt16(newGid)
        }

        // 4. 构建紧凑 glyf + loca（long 格式）
        let locaSize = Int64(numGlyphs + 1) * 4
        let locaData = Array<UInt8>(locaSize, repeat: UInt8(0))
        var glyfPieces = ArrayList<Array<UInt8>>()
        var glyfOffset: Int32 = 0

        for (newGid in 0..sorted.size) {
            writeUInt32BE(UInt32(glyfOffset), locaData, Int64(newGid) * 4)
            let oldGid = sorted[newGid]
            var gdata = ttfFont.getGlyphData(Int32(oldGid))
            if (gdata.size > 0) {
                // 修补复合字形中的旧 GID 引用
                gdata = remapCompositeGlyph(gdata)
                glyfPieces.add(gdata)
                let aligned = Int32((gdata.size + 3) / 4 * 4)
                glyfOffset += aligned
            }
        }
        writeUInt32BE(UInt32(glyfOffset), locaData, Int64(sorted.size) * 4)

        let glyfData = Array<UInt8>(Int64(glyfOffset), repeat: UInt8(0))
        var glyfPos: Int64 = 0
        for (i in 0..glyfPieces.size) {
            let piece = glyfPieces[i]
            for (b in 0..piece.size) { glyfData[glyfPos + b] = piece[b] }
            glyfPos += Int64((piece.size + 3) / 4 * 4)
        }

        // 5. 构建紧凑 hmtx（4 字节/字形：advanceWidth + lsb=0）
        let hmtxData = Array<UInt8>(Int64(numGlyphs) * 4, repeat: UInt8(0))
        for (newGid in 0..sorted.size) {
            let oldGid = sorted[newGid]
            let w = UInt16(ttfFont.getGlyphWidth(oldGid))
            writeUInt16BE(w, hmtxData, Int64(newGid) * 4)
        }

        // 6. 更新 maxp
        let maxpData: Array<UInt8> = match (ttfFont.getRawTable("maxp")) {
            case Some(d) =>
                let copy = copyArray(d)
                writeUInt16BE(UInt16(numGlyphs), copy, 4)
                copy
            case None =>
                let d = Array<UInt8>(6, repeat: UInt8(0))
                writeUInt32BE(UInt32(0x00005000), d, 0)
                writeUInt16BE(UInt16(numGlyphs), d, 4)
                d
        }

        // 7. 更新 hhea：numberOfHMetrics = numGlyphs
        let hheaData: Array<UInt8> = match (ttfFont.getRawTable("hhea")) {
            case Some(d) =>
                let copy = copyArray(d)
                writeUInt16BE(UInt16(numGlyphs), copy, d.size - 2)
                copy
            case None => Array<UInt8>(0, repeat: UInt8(0))
        }

        // 8. 更新 head：indexToLocFormat = 1（long loca），清零 checkSumAdjustment
        let headData: Array<UInt8> = match (ttfFont.getRawTable("head")) {
            case Some(d) =>
                let copy = copyArray(d)
                for (i in 8..12) { copy[i] = UInt8(0) }   // checkSumAdjustment
                if (copy.size > 51) {
                    copy[50] = UInt8(0)
                    copy[51] = UInt8(1)  // indexToLocFormat = 1
                }
                copy
            case None => Array<UInt8>(0, repeat: UInt8(0))
        }

        // 9. 生成极小 cmap（仅已用字符）
        let cmapData = buildMinimalCmap()

        // 10. 组装字体表（不直通原始 cmap）
        let passThroughTags = ["name", "post", "OS/2", "cvt ", "fpgm", "prep", "kern"]
        var tableEntries = ArrayList<SubsetTableEntry>()
        tableEntries.add(SubsetTableEntry("head", headData))
        tableEntries.add(SubsetTableEntry("hhea", hheaData))
        tableEntries.add(SubsetTableEntry("maxp", maxpData))
        tableEntries.add(SubsetTableEntry("hmtx", hmtxData))
        tableEntries.add(SubsetTableEntry("loca", locaData))
        tableEntries.add(SubsetTableEntry("glyf", glyfData))
        tableEntries.add(SubsetTableEntry("cmap", cmapData))
        for (tag in passThroughTags) {
            match (ttfFont.getRawTable(tag)) {
                case Some(d) => tableEntries.add(SubsetTableEntry(tag, d))
                case None => ()
            }
        }

        assembleFontBinary(tableEntries)
    }

    /**
     * 构建 CIDToGIDMap 数组数据
     * 索引 = 旧 GID（= PDF 内容流中的 CID），值 = 紧凑字体文件中的新 GID
     * 必须在 generateSubsetFont() 之后调用（glyphMapping 已就绪）
     */
    public func buildCIDToGIDMapData(): Array<UInt8> {
        if (glyphMapping.isEmpty()) {
            // 最小有效映射：CID 0 → GID 0
            return Array<UInt8>(2, repeat: UInt8(0))
        }

        var maxOldGid: Int32 = 0
        for ((oldGid, _) in glyphMapping) {
            if (Int32(oldGid) > maxOldGid) { maxOldGid = Int32(oldGid) }
        }

        let dataSize = Int64(maxOldGid + 1) * 2
        let data = Array<UInt8>(dataSize, repeat: UInt8(0))
        for ((oldGid, newGid) in glyphMapping) {
            let off = Int64(oldGid) * 2
            data[off]     = UInt8((UInt32(newGid) >> 8) & 0xFF)
            data[off + 1] = UInt8(UInt32(newGid) & 0xFF)
        }
        data
    }

    // ===== 复合字形处理 =====

    /** 计算已用字形的传递闭包（复合字形引用的分量字形也必须包含） */
    private func computeGlyphClosure(): Unit {
        var changed = true
        while (changed) {
            changed = false
            var toAdd = ArrayList<UInt16>()
            for ((gid, _) in usedGlyphs) {
                let gdata = ttfFont.getGlyphData(Int32(gid))
                if (gdata.size < 10) { continue }
                if (readInt16At(gdata, 0) >= 0) { continue }  // simple glyph
                // 解析复合字形分量记录
                var pos: Int64 = 10
                while (pos + 4 <= gdata.size) {
                    let flags = UInt32(readUInt16At(gdata, pos)); pos += 2
                    let compGID = readUInt16At(gdata, pos); pos += 2
                    if (!usedGlyphs.contains(compGID)) {
                        toAdd.add(compGID)
                        changed = true
                    }
                    let moreComponents = (flags & 0x0020) != 0
                    let argsAreWords   = (flags & 0x0001) != 0
                    pos += if (argsAreWords) { 4 } else { 2 }
                    if      ((flags & 0x0008) != 0) { pos += 2 }
                    else if ((flags & 0x0040) != 0) { pos += 4 }
                    else if ((flags & 0x0080) != 0) { pos += 8 }
                    if (!moreComponents) { break }
                }
            }
            for (gid in toAdd) { usedGlyphs[gid] = true }
        }
    }

    /** 将复合字形数据中的旧 GID 引用替换为新紧凑 GID */
    private func remapCompositeGlyph(gdata: Array<UInt8>): Array<UInt8> {
        if (gdata.size < 10) { return gdata }
        if (readInt16At(gdata, 0) >= 0) { return gdata }  // simple glyph

        let result = copyArray(gdata)
        var pos: Int64 = 10
        while (pos + 4 <= result.size) {
            let flags = UInt32(readUInt16At(result, pos)); pos += 2
            let oldGID = readUInt16At(result, pos)
            let newGID = match (glyphMapping.get(oldGID)) {
                case Some(g) => g
                case None    => UInt16(0)
            }
            result[pos]     = UInt8((UInt32(newGID) >> 8) & 0xFF)
            result[pos + 1] = UInt8(UInt32(newGID) & 0xFF)
            pos += 2
            let moreComponents = (flags & 0x0020) != 0
            let argsAreWords   = (flags & 0x0001) != 0
            pos += if (argsAreWords) { 4 } else { 2 }
            if      ((flags & 0x0008) != 0) { pos += 2 }
            else if ((flags & 0x0040) != 0) { pos += 4 }
            else if ((flags & 0x0080) != 0) { pos += 8 }
            if (!moreComponents) { break }
        }
        result
    }

    // ===== 极小 cmap 生成（format 12） =====

    private func buildMinimalCmap(): Array<UInt8> {
        // 收集 (unicode, newGID) 对
        var pairs = ArrayList<CmapPair>()
        for ((unicode, oldGID) in usedChars) {
            match (glyphMapping.get(oldGID)) {
                case Some(newGID) =>
                    if (unicode <= 0x10FFFFu32) {
                        pairs.add(CmapPair(unicode, UInt32(newGID)))
                    }
                case None => ()
            }
        }

        // 按 unicode 排序
        for (i in 0..pairs.size) {
            for (j in 0..(pairs.size - i - 1)) {
                if (pairs[j].unicode > pairs[j + 1].unicode) {
                    let tmp = pairs[j]
                    pairs[j] = pairs[j + 1]
                    pairs[j + 1] = tmp
                }
            }
        }

        // 合并连续组 (startChar, endChar, startGlyph) ：unicode+1 && newGID+1
        var groups = ArrayList<CmapGroup>()
        if (pairs.size > 0) {
            var sChar = pairs[0].unicode
            var sGlyph = pairs[0].newGID
            var eChar = pairs[0].unicode
            var eGlyph = pairs[0].newGID
            for (i in 1..pairs.size) {
                let ch = pairs[i].unicode
                let gid = pairs[i].newGID
                if (ch == eChar + 1u32 && gid == eGlyph + 1u32) {
                    eChar = ch; eGlyph = gid
                } else {
                    groups.add(CmapGroup(sChar, eChar, sGlyph))
                    sChar = ch; sGlyph = gid; eChar = ch; eGlyph = gid
                }
            }
            groups.add(CmapGroup(sChar, eChar, sGlyph))
        }

        let nGroups = Int32(groups.size)
        // cmap 头(4) + 1个 encoding record(8) + format12 头(16) + groups(12 each)
        let subtableLen = 16 + nGroups * 12
        let totalLen = 4 + 8 + subtableLen
        let data = Array<UInt8>(Int64(totalLen), repeat: UInt8(0))
        var pos: Int64 = 0

        // cmap header
        writeUInt16BE(UInt16(0), data, pos); pos += 2   // version
        writeUInt16BE(UInt16(1), data, pos); pos += 2   // numTables

        // encoding record: Windows(3) / Unicode Full(10) → format 12
        writeUInt16BE(UInt16(3), data, pos); pos += 2   // platformID
        writeUInt16BE(UInt16(10), data, pos); pos += 2  // encodingID
        writeUInt32BE(UInt32(12), data, pos); pos += 4  // offset to subtable

        // format 12 subtable header
        writeUInt16BE(UInt16(12), data, pos); pos += 2  // format
        writeUInt16BE(UInt16(0), data, pos); pos += 2   // reserved
        writeUInt32BE(UInt32(subtableLen), data, pos); pos += 4
        writeUInt32BE(UInt32(0), data, pos); pos += 4   // language
        writeUInt32BE(UInt32(nGroups), data, pos); pos += 4

        for (i in 0..groups.size) {
            let g = groups[i]
            writeUInt32BE(g.startChar, data, pos); pos += 4
            writeUInt32BE(g.endChar, data, pos); pos += 4
            writeUInt32BE(g.startGlyph, data, pos); pos += 4
        }

        data
    }

    // ===== 字体二进制组装 =====

    private func assembleFontBinary(tableEntries: ArrayList<SubsetTableEntry>): Array<UInt8> {
        let numTables = tableEntries.size
        let headerSize: Int64 = 12 + Int64(numTables) * 16
        var offsets = Array<Int64>(numTables, repeat: Int64(0))
        var currentOffset = headerSize
        for (i in 0..numTables) {
            offsets[i] = currentOffset
            let len = Int64(tableEntries[i].data.size)
            currentOffset += (len + 3) / 4 * 4
        }
        let totalSize = currentOffset
        let output = Array<UInt8>(totalSize, repeat: UInt8(0))

        // Offset Table
        writeUInt32BE(UInt32(0x00010000), output, 0)
        writeUInt16BE(UInt16(numTables), output, 4)
        var sr = 1; var es = 0; var n = numTables
        while (n > 1) { n = n / 2; sr = sr * 2; es += 1 }
        writeUInt16BE(UInt16(sr * 16), output, 6)
        writeUInt16BE(UInt16(es), output, 8)
        writeUInt16BE(UInt16((numTables - sr) * 16), output, 10)

        // Table Directory
        var dirPos: Int64 = 12
        for (i in 0..numTables) {
            let entry = tableEntries[i]
            let tagBytes = entry.tag.toArray()
            for (j in 0..4) {
                if (j < tagBytes.size) { output[dirPos + Int64(j)] = UInt8(tagBytes[j]) }
            }
            dirPos += 4
            writeUInt32BE(calculateChecksum(entry.data), output, dirPos); dirPos += 4
            writeUInt32BE(UInt32(offsets[i]), output, dirPos); dirPos += 4
            writeUInt32BE(UInt32(entry.data.size), output, dirPos); dirPos += 4
        }

        // Table Data
        for (i in 0..numTables) {
            let d = tableEntries[i].data
            let base = offsets[i]
            for (j in 0..d.size) { output[base + Int64(j)] = d[j] }
        }

        output
    }

    // ===== 辅助方法 =====

    private func sortGlyphList(list: ArrayList<UInt16>): Unit {
        let n = list.size
        for (i in 0..n) {
            for (j in 0..(n - i - 1)) {
                if (list[j] > list[j + 1]) {
                    let tmp = list[j]
                    list[j] = list[j + 1]
                    list[j + 1] = tmp
                }
            }
        }
    }

    private func copyArray(src: Array<UInt8>): Array<UInt8> {
        let dst = Array<UInt8>(src.size, repeat: UInt8(0))
        for (i in 0..src.size) { dst[i] = src[i] }
        dst
    }

    private func readUInt16At(data: Array<UInt8>, pos: Int64): UInt16 {
        (UInt16(data[pos]) << 8) | UInt16(data[pos + 1])
    }

    private func readInt16At(data: Array<UInt8>, pos: Int64): Int32 {
        let v = Int32(readUInt16At(data, pos))
        if (v >= 32768) { v - 65536 } else { v }
    }

    private func calculateChecksum(data: Array<UInt8>): UInt32 {
        var sum: UInt64 = 0
        var i: Int64 = 0
        while (i + 3 < data.size) {
            let v = (UInt32(data[i]) << 24) | (UInt32(data[i+1]) << 16) |
                    (UInt32(data[i+2]) << 8)  |  UInt32(data[i+3])
            sum += UInt64(v)
            i += 4
        }
        if (i < data.size) {
            var v: UInt32 = 0
            for (j in i..data.size) { v = (v << 8) | UInt32(data[j]) }
            let shift = Int32(4 - (data.size - i)) * 8
            v = v << UInt32(shift)
            sum += UInt64(v)
        }
        UInt32(sum & UInt64(0xFFFFFFFF))
    }

    private func writeUInt32BE(value: UInt32, buf: Array<UInt8>, off: Int64): Unit {
        buf[off]     = UInt8((value >> 24) & 0xFF)
        buf[off + 1] = UInt8((value >> 16) & 0xFF)
        buf[off + 2] = UInt8((value >> 8)  & 0xFF)
        buf[off + 3] = UInt8(value & 0xFF)
    }

    private func writeUInt16BE(value: UInt16, buf: Array<UInt8>, off: Int64): Unit {
        buf[off]     = UInt8((UInt32(value) >> 8) & 0xFF)
        buf[off + 1] = UInt8(UInt32(value) & 0xFF)
    }

    /**
     * 对 CFF 字体数据进行子集化
     * 将未用字形的 charstring 替换为单字节 endchar，并更新受影响的偏移引用
     */
    public func generateCFFSubset(cffData: Array<UInt8>): Array<UInt8> {
        let subsetter = CFFSubsetter(cffData, usedGlyphs)
        subsetter.generateSubset()
    }

    public func getSubsetInfo(): String {
        var info = "Font Subsetting Information:\n"
        info = "${info}Used glyphs: ${usedGlyphs.size}\n"
        info = "${info}Used chars: ${usedChars.size}\n"
        info = "${info}Glyph IDs: "
        for ((gid, _) in usedGlyphs) { info = "${info}${gid} " }
        info
    }
}

// ===== 辅助数据类 =====

class SubsetTableEntry {
    public let tag: String
    public let data: Array<UInt8>
    public init(tag: String, data: Array<UInt8>) {
        this.tag = tag
        this.data = data
    }
}

class CmapPair {
    public var unicode: UInt32
    public var newGID: UInt32
    public init(unicode: UInt32, newGID: UInt32) {
        this.unicode = unicode
        this.newGID = newGID
    }
}

class CmapGroup {
    public var startChar: UInt32
    public var endChar: UInt32
    public var startGlyph: UInt32
    public init(startChar: UInt32, endChar: UInt32, startGlyph: UInt32) {
        this.startChar = startChar
        this.endChar = endChar
        this.startGlyph = startGlyph
    }
}

/**
 * 字体子集化工具类（保留接口兼容）
 */
public class FontSubsettingUtil {
    public static func isValidGlyphId(glyphId: UInt16, maxGlyphs: Int32): Bool {
        Int32(glyphId) >= 0 && Int32(glyphId) < maxGlyphs
    }

    public static func generateSubsetName(originalName: String, subset: String): String {
        "${subset}+${originalName}"
    }

    public static func generateSubsetPrefix(): String {
        "SUBSET"
    }
}
