/**
 * PDF-CJ: TrueTypeFont - TrueType 字体文件读取
 * 参考 OpenPDF 的 TrueTypeFont 实现
 */
package pdf_cj.text

import std.fs.*
import std.collection.{HashMap, ArrayList}
import pdf_cj.util.PdfException

/**
 * TrueType 字体读取器
 * 读取和解析 TTF/TTC 文件
 */
public class TrueTypeFont {
    private var fileName: String = ""
    private var fontData: Array<UInt8> = Array<UInt8>(0, repeat: UInt8(0))
    private var offset: Int64 = 0  // TTC 文件中的字体偏移

    // 字体表
    private var tables: HashMap<String, TableEntry> = HashMap<String, TableEntry>()

    // 字体度量
    private var unitsPerEm: Int32 = 1000
    private var ascent: Int32 = 880
    private var descent: Int32 = -120
    private var capHeight: Int32 = 880

    // cmap 表：Unicode 到 Glyph ID 的映射
    private var cmapTable: HashMap<UInt32, UInt16> = HashMap<UInt32, UInt16>()

    // hmtx 表：字形宽度数据
    private var glyphWidths: Array<Int32> = Array<Int32>(0, repeat: Int32(0))
    private var numberOfHMetrics: Int32 = 0

    // kern 表：字距调整数据（左字形 ID << 16 | 右字形 ID -> 调整值）
    private var kernPairs: HashMap<UInt32, Int32> = HashMap<UInt32, Int32>()

    // kern 表：字符对间距调整
    private var kerningPairs: HashMap<UInt32, Int32> = HashMap<UInt32, Int32>()

    /**
     * 构造函数
     */
    public init(fontPath: String) {
        this.fileName = fontPath
        readFontFile(fontPath)
    }

    /**
     * 读取字体文件
     * 使用高效的批量读取方式加载整个文件
     */
    private func readFontFile(path: String): Unit {
        try {
            let file = File(Path(path), OpenMode.Read)

            // 使用 64KB 缓冲区批量读取整个文件
            let bufferSize: Int64 = 65536    // 64KB 缓冲区
            let buffer = Array<UInt8>(bufferSize, repeat: UInt8(0))

            var chunks = ArrayList<Array<UInt8>>()
            var totalRead: Int64 = 0

            while (true) {
                let bytesRead = file.read(buffer)
                if (bytesRead <= 0) {
                    break
                }

                // 复制这一块
                let chunk = Array<UInt8>(bytesRead, repeat: UInt8(0))
                for (i in 0..bytesRead) {
                    chunk[i] = buffer[i]
                }
                chunks.add(chunk)
                totalRead += bytesRead
            }

            file.close()

            // 合并所有块
            fontData = Array<UInt8>(totalRead, repeat: UInt8(0))
            var offset: Int64 = 0
            for (chunkIndex in 0..chunks.size) {
                let chunk = chunks[chunkIndex]
                for (i in 0..chunk.size) {
                    fontData[offset + i] = chunk[i]
                }
                offset += chunk.size
            }

            // 解析字体
            parseFontTables()
        } catch (e: Exception) {
            throw PdfException("Failed to read font file: ${path}, error: ${e.message}")
        }
    }

    /**
     * 解析字体表
     */
    private func parseFontTables(): Unit {
        var pos: Int64 = 0

        // 读取字体类型标识
        let tag = readUInt32(pos)
        pos += 4

        // 检查是否为 TTC (TrueType Collection)
        if (tag == 0x74746366) {  // 'ttcf'
            parseTTC(pos)
        } else {
            // 单一 TTF 文件
            parseTTF(0)
        }
    }

    /**
     * 解析 TTC 文件
     */
    private func parseTTC(pos: Int64): Unit {
        var currentPos = pos

        // 读取版本
        let majorVersion = readUInt16(currentPos)
        currentPos += 2
        let minorVersion = readUInt16(currentPos)
        currentPos += 2

        // 读取字体数量
        let numFonts = readUInt32(currentPos)
        currentPos += 4

        // 读取第一个字体的偏移（简化：只使用第一个字体）
        this.offset = Int64(readUInt32(currentPos))

        // 解析该字体
        parseTTF(this.offset)
    }

    /**
     * 解析 TTF 文件
     */
    private func parseTTF(startOffset: Int64): Unit {
        var pos = startOffset

        // 跳过 scaler type (4 bytes)
        pos += 4

        // 读取表数量
        let numTables = readUInt16(pos)
        pos += 2

        // 跳过 searchRange, entrySelector, rangeShift
        pos += 6

        // 读取所有表的目录
        for (i in 0..numTables) {
            let tag = readTag(pos)
            pos += 4

            let checksum = readUInt32(pos)
            pos += 4

            let tableOffset = readUInt32(pos)
            pos += 4

            let tableLength = readUInt32(pos)
            pos += 4

            let entry = TableEntry(
                tag,
                checksum,
                Int64(tableOffset),
                Int64(tableLength)
            )
            tables[tag] = entry
        }

        // 读取重要的表
        readHeadTable()
        readHheaTable()
        readMaxpTable()
        readCmapTable()
        readHmtxTable()
        readKernTable()
    }

    /**
     * 读取 head 表
     */
    private func readHeadTable(): Unit {
        match (tables.get("head")) {
            case Some(entry) =>
                // 注意：Table Directory 中的 offset 是绝对偏移（相对于文件开始）
                // 不需要再加上 TTC 的 offset
                let tablePos = entry.offset

                // 检查是否在读取范围内
                if (tablePos + 20 > fontData.size) {
                    throw PdfException("head table offset ${tablePos} is beyond loaded data size ${fontData.size}")
                }

                var pos = tablePos

                // 跳过版本、修订版本、校验和调整、魔数
                pos += 16

                // 读取 flags
                pos += 2

                // 读取 unitsPerEm
                unitsPerEm = Int32(readUInt16(pos))
                pos += 2
            case None =>
                throw PdfException("head table not found")
        }
    }

    /**
     * 读取 hhea 表
     */
    private func readHheaTable(): Unit {
        match (tables.get("hhea")) {
            case Some(entry) =>
                // Table Directory 中的 offset 是绝对偏移
                var pos = entry.offset

                // 跳过版本
                pos += 4

                // 读取 ascent
                ascent = readInt16(pos)
                pos += 2

                // 读取 descent
                descent = readInt16(pos)
                pos += 2

                // 跳过 lineGap, advanceWidthMax, minLeftSideBearing, minRightSideBearing
                // maxExtent, caretSlopeRise, caretSlopeRun, caretOffset, reserved[4]
                pos += 26

                // 读取 numberOfHMetrics
                numberOfHMetrics = Int32(readUInt16(pos))
                pos += 2
            case None =>
                throw PdfException("hhea table not found")
        }
    }

    /**
     * 读取 maxp 表
     */
    private func readMaxpTable(): Unit {
        match (tables.get("maxp")) {
            case Some(entry) =>
                // maxp 表包含字体的最大值信息
                // 简化实现：只读取版本
                // Table Directory 中的 offset 是绝对偏移
                let pos = entry.offset
                let version = readUInt32(pos)
            case None =>
                throw PdfException("maxp table not found")
        }
    }

    /**
     * 读取 cmap 表（字符到字形映射）
     * 这是正确显示 Unicode 字符的关键
     */
    private func readCmapTable(): Unit {
        match (tables.get("cmap")) {
            case Some(entry) =>
                // Table Directory 中的 offset 是绝对偏移（相对于文件开始）
                let tableStart = entry.offset
                var pos = tableStart

                // 版本（通常为 0）
                let version = readUInt16(pos)
                pos += 2

                // 子表数量
                let numTables = readUInt16(pos)
                pos += 2

                // 寻找最佳的 Unicode 子表
                // 优先级：format 12 (UCS-4) > format 4 (BMP)
                var bestSubtableOffset: Int64 = -1
                var bestFormat: Int32 = -1

                for (i in 0..Int64(numTables)) {
                    let platformID = readUInt16(pos)
                    pos += 2
                    let encodingID = readUInt16(pos)
                    pos += 2
                    let subtableOffset = Int64(readUInt32(pos))
                    pos += 4

                    // 检查是否为 Unicode 编码
                    // Platform 0 = Unicode, Platform 3 = Windows
                    let isUnicode = (platformID == 0) ||
                                    (platformID == 3 && (encodingID == 1 || encodingID == 10))

                    if (isUnicode) {
                        let subtablePos = tableStart + subtableOffset
                        let format = Int32(readUInt16(subtablePos))

                        // 优先使用 format 12（支持完整 Unicode）
                        if (format == 12 && bestFormat != 12) {
                            bestSubtableOffset = subtableOffset
                            bestFormat = 12
                        } else if (format == 4 && bestFormat < 4) {
                            bestSubtableOffset = subtableOffset
                            bestFormat = 4
                        }
                    }
                }

                // 解析找到的子表
                if (bestSubtableOffset >= 0) {
                    let subtablePos = tableStart + bestSubtableOffset
                    if (bestFormat == 12) {
                        readCmapFormat12(subtablePos)
                    } else if (bestFormat == 4) {
                        readCmapFormat4(subtablePos)
                    }
                }
            case None =>
                // cmap 表是必需的，但某些字体可能没有
                // 不抛出异常，使用空映射
                ()
        }
    }

    /**
     * 读取 cmap format 4 子表（BMP 字符）
     * 这是最常见的格式，支持 Unicode BMP (U+0000 to U+FFFF)
     */
    private func readCmapFormat4(subtablePos: Int64): Unit {
        var pos = subtablePos

        // format (已知为 4)
        pos += 2

        // length
        let length = readUInt16(pos)
        pos += 2

        // language
        pos += 2

        // segCountX2
        let segCountX2 = Int64(readUInt16(pos))
        let segCount = segCountX2 / 2
        pos += 2

        // searchRange, entrySelector, rangeShift
        pos += 6

        // 读取 endCode 数组
        let endCodes = ArrayList<UInt16>()
        for (i in 0..segCount) {
            endCodes.add(readUInt16(pos))
            pos += 2
        }

        // reservedPad
        pos += 2

        // 读取 startCode 数组
        let startCodes = ArrayList<UInt16>()
        for (i in 0..segCount) {
            startCodes.add(readUInt16(pos))
            pos += 2
        }

        // 读取 idDelta 数组
        let idDeltas = ArrayList<Int32>()
        for (i in 0..segCount) {
            idDeltas.add(readInt16(pos))
            pos += 2
        }

        // 保存 idRangeOffset 位置
        let idRangeOffsetPos = pos

        // 读取 idRangeOffset 数组
        let idRangeOffsets = ArrayList<UInt16>()
        for (i in 0..segCount) {
            idRangeOffsets.add(readUInt16(pos))
            pos += 2
        }

        // 构建 Unicode 到 Glyph ID 的映射
        for (segIndex in 0..segCount) {
            let startCode = startCodes[segIndex]
            let endCode = endCodes[segIndex]
            let idDelta = idDeltas[segIndex]
            let idRangeOffset = idRangeOffsets[segIndex]

            // 跳过结束段标记
            if (startCode == 0xFFFF) {
                continue
            }

            for (charCode in UInt32(startCode)..UInt32(endCode) + 1) {
                var glyphId: UInt16 = 0

                if (idRangeOffset == 0) {
                    // 直接使用 delta
                    let gid = (Int32(charCode) + idDelta) & 0xFFFF
                    glyphId = UInt16(gid)
                } else {
                    // 使用 idRangeOffset 数组查找
                    let offsetPos = idRangeOffsetPos + (segIndex * 2)
                    let glyphIdPos = offsetPos + Int64(idRangeOffset) + Int64((charCode - UInt32(startCode)) * 2)

                    if (glyphIdPos + 2 <= fontData.size) {
                        glyphId = readUInt16(glyphIdPos)
                        if (glyphId != 0) {
                            glyphId = UInt16((Int32(glyphId) + idDelta) & 0xFFFF)
                        }
                    }
                }

                if (glyphId != 0) {
                    cmapTable[charCode] = glyphId
                }
            }
        }
    }

    /**
     * 读取 cmap format 12 子表（完整 Unicode）
     * 支持 Unicode 补充平面（U+10000 及以上）
     */
    private func readCmapFormat12(subtablePos: Int64): Unit {
        var pos = subtablePos

        // format (已知为 12)
        pos += 2

        // reserved
        pos += 2

        // length (32-bit)
        let length = readUInt32(pos)
        pos += 4

        // language
        pos += 4

        // numGroups
        let numGroups = readUInt32(pos)
        pos += 4

        // 读取每个组
        for (i in 0..Int64(numGroups)) {
            let startCharCode = readUInt32(pos)
            pos += 4
            let endCharCode = readUInt32(pos)
            pos += 4
            let startGlyphId = readUInt32(pos)
            pos += 4

            // 构建映射
            for (charCode in startCharCode..endCharCode + 1) {
                let glyphId = startGlyphId + (charCode - startCharCode)
                if (glyphId <= 0xFFFF) {
                    cmapTable[charCode] = UInt16(glyphId)
                }
            }
        }
    }

    // ===== 字节读取辅助方法 =====

    /**
     * 读取 4 字节标签
     */
    private func readTag(pos: Int64): String {
        let b0 = fontData[pos]
        let b1 = fontData[pos + 1]
        let b2 = fontData[pos + 2]
        let b3 = fontData[pos + 3]
        "${Rune(b0)}${Rune(b1)}${Rune(b2)}${Rune(b3)}"
    }

    /**
     * 读取 UInt32 (Big Endian)
     */
    private func readUInt32(pos: Int64): UInt32 {
        let b0 = UInt32(fontData[pos])
        let b1 = UInt32(fontData[pos + 1])
        let b2 = UInt32(fontData[pos + 2])
        let b3 = UInt32(fontData[pos + 3])
        (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    }

    /**
     * 读取 UInt16 (Big Endian)
     */
    private func readUInt16(pos: Int64): UInt16 {
        let b0 = UInt16(fontData[pos])
        let b1 = UInt16(fontData[pos + 1])
        (b0 << 8) | b1
    }

    /**
     * 读取 Int16 (Big Endian)
     */
    private func readInt16(pos: Int64): Int32 {
        let value = Int32(readUInt16(pos))
        if (value >= 32768) {
            value - 65536
        } else {
            value
        }
    }

    // ===== 公共方法 =====

    /**
     * 获取字体数据
     * 返回已加载的字体数据
     */
    public func getFontData(): Array<UInt8> {
        fontData
    }

    /**
     * 获取 unitsPerEm
     */
    public func getUnitsPerEm(): Int32 {
        unitsPerEm
    }

    /**
     * 获取 ascent
     */
    public func getAscent(): Int32 {
        ascent
    }

    /**
     * 获取 descent
     */
    public func getDescent(): Int32 {
        descent
    }

    /**
     * 获取 capHeight
     */
    public func getCapHeight(): Int32 {
        capHeight
    }

    /**
     * 获取文件名
     */
    public func getFileName(): String {
        fileName
    }

    /**
     * 获取 Unicode 字符对应的 Glyph ID
     * 这是正确显示 Unicode 字符的关键方法
     * @param unicode Unicode 码点
     * @return Glyph ID，如果未找到返回 0（.notdef）
     */
    public func getGlyphId(unicode: UInt32): UInt16 {
        match (cmapTable.get(unicode)) {
            case Some(gid) => gid
            case None => UInt16(0)  // .notdef glyph
        }
    }

    /**
     * 检查字体是否包含指定 Unicode 字符
     */
    public func hasGlyph(unicode: UInt32): Bool {
        cmapTable.contains(unicode)
    }

    /**
     * 获取 cmap 表中的字符数量
     */
    public func getGlyphCount(): Int64 {
        cmapTable.size
    }

    /**
     * 读取 hmtx 表（Horizontal Metrics）
     * 包含每个字形的宽度信息
     */
    private func readHmtxTable(): Unit {
        match (tables.get("hmtx")) {
            case Some(entry) =>
                var pos = entry.offset

                // hmtx 表结构：
                // - numberOfHMetrics 个 longHorMetric 记录（每个 4 字节：advanceWidth + lsb）
                // - 剩余字形只有 lsb（每个 2 字节），宽度沿用最后一个 advanceWidth

                // 初始化字形宽度数组（使用最大可能数量）
                let maxGlyphs = numberOfHMetrics + 1000  // 预留空间
                glyphWidths = Array<Int32>(Int64(maxGlyphs), repeat: Int32(0))

                // 读取前 numberOfHMetrics 个字形的宽度
                var lastAdvanceWidth: Int32 = 0
                for (i in 0..numberOfHMetrics) {
                    let advanceWidth = Int32(readUInt16(pos))
                    pos += 2
                    let lsb = readInt16(pos)  // Left Side Bearing (暂不使用)
                    pos += 2

                    glyphWidths[Int64(i)] = advanceWidth
                    lastAdvanceWidth = advanceWidth
                }

                // 剩余字形使用最后一个 advanceWidth
                // 从表的长度推断总字形数
                let remainingBytes = entry.length - (Int64(numberOfHMetrics) * 4)
                let remainingGlyphs = remainingBytes / 2

                for (i in 0..remainingGlyphs) {
                    let glyphIndex = Int64(numberOfHMetrics) + i
                    if (glyphIndex < glyphWidths.size) {
                        glyphWidths[glyphIndex] = lastAdvanceWidth
                    }
                }
            case None =>
                // hmtx 表对于显示字体宽度非常重要，但某些字体可能没有
                // 使用默认宽度
                ()
        }
    }

    /**
     * 获取字形宽度（字体单位）
     * @param glyphId 字形 ID
     * @return 字形宽度（以 unitsPerEm 为单位），如果未找到返回 0
     */
    public func getGlyphWidth(glyphId: UInt16): Int32 {
        let index = Int64(glyphId)
        if (index >= 0 && index < glyphWidths.size) {
            glyphWidths[index]
        } else {
            0
        }
    }

    /**
     * 获取字符宽度（字体单位）
     * @param unicode Unicode 码点
     * @return 字符宽度（以 unitsPerEm 为单位），如果未找到返回 0
     */
    public func getCharWidth(unicode: UInt32): Int32 {
        let glyphId = getGlyphId(unicode)
        getGlyphWidth(glyphId)
    }

    /**
     * 获取字符串宽度（点 points）
     * @param text 文本字符串
     * @param fontSize 字体大小（点）
     * @return 字符串宽度（点）
     */
    public func getStringWidth(text: String, fontSize: Float32): Float32 {
        var totalWidth: Int64 = 0
        var lastGlyphId: UInt16 = 0

        for (ch in text) {
            // Rune 可以直接转换为 Int64，然后转为 UInt32
            let unicode = UInt32(Int64(ch))
            let glyphId = getGlyphId(unicode)
            let width = getGlyphWidth(glyphId)
            totalWidth += Int64(width)

            // 应用 kerning
            if (lastGlyphId != 0) {
                let kern = getKerning(lastGlyphId, glyphId)
                totalWidth += Int64(kern)
            }

            lastGlyphId = glyphId
        }

        // 转换为点：(totalWidth / unitsPerEm) * fontSize
        if (unitsPerEm > 0) {
            Float32(totalWidth) * fontSize / Float32(unitsPerEm)
        } else {
            0.0
        }
    }

    /**
     * 读取 kern 表（字距调整）
     * 包含字符对之间的距离调整信息
     */
    private func readKernTable(): Unit {
        match (tables.get("kern")) {
            case Some(entry) =>
                var pos = entry.offset

                // kern 表版本（通常为 0）
                let version = readUInt16(pos)
                pos += 2

                // 子表数量
                let nTables = readUInt16(pos)
                pos += 2

                // 读取每个子表
                for (tableIndex in 0..Int64(nTables)) {
                    // 子表版本
                    let subtableVersion = readUInt16(pos)
                    pos += 2

                    // 子表长度
                    let length = readUInt16(pos)
                    pos += 2

                    // 覆盖标志（coverage）
                    let coverage = readUInt16(pos)
                    pos += 2

                    // 检查是否为水平方向的 kerning (bit 0 = 1) 和 format 0
                    let horizontal = (coverage & 0x0001) != 0
                    let format = (coverage >> 8) & 0xFF

                    if (horizontal && format == 0) {
                        // Format 0: 排序的 kerning 对列表
                        let nPairs = readUInt16(pos)
                        pos += 2

                        // 跳过 searchRange, entrySelector, rangeShift
                        pos += 6

                        // 读取每个 kerning 对
                        for (pairIndex in 0..Int64(nPairs)) {
                            let left = readUInt16(pos)
                            pos += 2
                            let right = readUInt16(pos)
                            pos += 2
                            let value = readInt16(pos)
                            pos += 2

                            // 使用组合键存储
                            let key = (UInt32(left) << 16) | UInt32(right)
                            kernPairs[key] = value
                        }
                    } else {
                        // 跳过不支持的格式
                        pos += Int64(length) - 6  // 减去已读取的 6 字节
                    }
                }
            case None =>
                // kern 表是可选的，没有也不影响基本功能
                ()
        }
    }

    /**
     * 获取两个字形之间的 kerning 调整值
     * @param leftGlyphId 左侧字形 ID
     * @param rightGlyphId 右侧字形 ID
     * @return Kerning 调整值（字体单位），如果无调整返回 0
     */
    public func getKerning(leftGlyphId: UInt16, rightGlyphId: UInt16): Int32 {
        let key = (UInt32(leftGlyphId) << 16) | UInt32(rightGlyphId)
        match (kernPairs.get(key)) {
            case Some(value) => value
            case None => 0
        }
    }

    /**
     * 获取两个 Unicode 字符之间的 kerning 调整值
     * @param leftChar 左侧字符
     * @param rightChar 右侧字符
     * @return Kerning 调整值（字体单位），如果无调整返回 0
     */
    public func getCharKerning(leftChar: UInt32, rightChar: UInt32): Int32 {
        let leftGlyphId = getGlyphId(leftChar)
        let rightGlyphId = getGlyphId(rightChar)
        getKerning(leftGlyphId, rightGlyphId)
    }
}

/**
 * 字体表条目
 */
class TableEntry {
    public let tag: String
    public let checksum: UInt32
    public let offset: Int64
    public let length: Int64

    public init(tag: String, checksum: UInt32, offset: Int64, length: Int64) {
        this.tag = tag
        this.checksum = checksum
        this.offset = offset
        this.length = length
    }
}
