/**
 * PDF-CJ: FontSubsetting - 字体子集化
 * 只嵌入实际使用的字形，减小 PDF 文件体积
 */
package pdf_cj.text

import std.collection.{HashMap, ArrayList}

/**
 * 字体子集化类
 * 跟踪使用的字形并生成子集字体
 */
public class FontSubsetting {
    private var ttfFont: TrueTypeFont
    private var usedGlyphs: HashMap<UInt16, Bool> = HashMap<UInt16, Bool>()  // 使用 HashMap 模拟 Set
    private var glyphMapping: HashMap<UInt16, UInt16> = HashMap<UInt16, UInt16>()  // 旧 GID -> 新 GID

    /**
     * 构造函数
     * @param font TrueType 字体对象
     */
    public init(font: TrueTypeFont) {
        this.ttfFont = font
        // Glyph 0 (.notdef) 必须包含
        usedGlyphs[UInt16(0)] = true
    }

    /**
     * 标记字形为已使用
     * @param glyphId 字形 ID
     */
    public func markGlyphUsed(glyphId: UInt16): Unit {
        usedGlyphs[glyphId] = true
    }

    /**
     * 标记 Unicode 字符为已使用
     * @param unicode Unicode 码点
     */
    public func markCharUsed(unicode: UInt32): Unit {
        let glyphId = ttfFont.getGlyphId(unicode)
        if (glyphId != 0) {
            usedGlyphs[glyphId] = true
        }
    }

    /**
     * 标记字符串中所有字符为已使用
     * @param text 文本字符串
     */
    public func markStringUsed(text: String): Unit {
        for (ch in text) {
            let unicode = UInt32(Int64(ch))
            markCharUsed(unicode)
        }
    }

    /**
     * 获取使用的字形数量
     */
    public func getUsedGlyphCount(): Int64 {
        usedGlyphs.size
    }

    /**
     * 检查字形是否被使用
     */
    public func isGlyphUsed(glyphId: UInt16): Bool {
        match (usedGlyphs.get(glyphId)) {
            case Some(_) => true
            case None => false
        }
    }

    /**
     * 构建字形映射（旧 GID -> 新 GID）
     * 将使用的字形按顺序重新编号
     */
    public func buildGlyphMapping(): Unit {
        glyphMapping.clear()

        // 将使用的字形 ID 排序
        var sortedGlyphs = ArrayList<UInt16>()
        for ((gid, _) in usedGlyphs) {
            sortedGlyphs.add(gid)
        }

        // 简单排序（冒泡排序）
        for (i in 0..sortedGlyphs.size) {
            for (j in 0..(sortedGlyphs.size - i - 1)) {
                if (sortedGlyphs[j] > sortedGlyphs[j + 1]) {
                    let temp = sortedGlyphs[j]
                    sortedGlyphs[j] = sortedGlyphs[j + 1]
                    sortedGlyphs[j + 1] = temp
                }
            }
        }

        // 建立映射
        for (newGid in 0..sortedGlyphs.size) {
            let oldGid = sortedGlyphs[newGid]
            glyphMapping[oldGid] = UInt16(newGid)
        }
    }

    /**
     * 获取新的字形 ID
     * @param oldGlyphId 原字形 ID
     * @return 新字形 ID，如果未使用返回 0
     */
    public func getNewGlyphId(oldGlyphId: UInt16): UInt16 {
        match (glyphMapping.get(oldGlyphId)) {
            case Some(newGid) => newGid
            case None => UInt16(0)
        }
    }

    /**
     * 生成子集字体数据
     * 这是一个简化版本，只生成必要的表
     * 完整实现需要处理：head, hhea, hmtx, maxp, name, cmap, loca, glyf, post 等表
     *
     * @return 子集字体的字节数据
     */
    public func generateSubsetFont(): Array<UInt8> {
        // 构建字形映射
        buildGlyphMapping()

        // 简化实现：返回空数组
        // 实际实现需要：
        // 1. 创建新的 TrueType 表头
        // 2. 重建 cmap 表（只包含使用的字符）
        // 3. 重建 glyf 表（只包含使用的字形）
        // 4. 重建 loca 表（字形偏移表）
        // 5. 重建 hmtx 表（字形宽度表）
        // 6. 更新 head, hhea, maxp 表
        // 7. 计算校验和
        // 8. 写入所有表

        // TODO: 完整实现字体子集化算法
        Array<UInt8>(0, repeat: UInt8(0))
    }

    /**
     * 生成子集化的 cmap 表
     * @return cmap 表数据
     */
    private func generateCmapTable(): Array<UInt8> {
        // 简化实现：生成 format 4 cmap 子表
        // 实际需要遍历使用的字形，构建 Unicode -> 新 GID 的映射

        // TODO: 实现 cmap format 4 生成
        Array<UInt8>(0, repeat: UInt8(0))
    }

    /**
     * 生成子集化的 glyf 表
     * @return glyf 表数据
     */
    private func generateGlyfTable(): Array<UInt8> {
        // 简化实现：提取使用的字形轮廓数据
        // 需要处理复合字形（引用其他字形）

        // TODO: 实现 glyf 表提取
        Array<UInt8>(0, repeat: UInt8(0))
    }

    /**
     * 生成子集化的 loca 表
     * @param glyfData glyf 表数据
     * @return loca 表数据
     */
    private func generateLocaTable(glyfData: Array<UInt8>): Array<UInt8> {
        // loca 表记录每个字形在 glyf 表中的偏移
        // 有两种格式：short (16-bit) 和 long (32-bit)

        // TODO: 实现 loca 表生成
        Array<UInt8>(0, repeat: UInt8(0))
    }

    /**
     * 生成子集化的 hmtx 表
     * @return hmtx 表数据
     */
    private func generateHmtxTable(): Array<UInt8> {
        // hmtx 表包含每个字形的宽度和左边距

        // TODO: 实现 hmtx 表生成
        Array<UInt8>(0, repeat: UInt8(0))
    }

    /**
     * 更新 head 表
     * @return 更新后的 head 表数据
     */
    private func updateHeadTable(): Array<UInt8> {
        // 需要更新字形数量等信息

        // TODO: 实现 head 表更新
        Array<UInt8>(0, repeat: UInt8(0))
    }

    /**
     * 更新 hhea 表
     * @param numberOfHMetrics 水平度量数量
     * @return 更新后的 hhea 表数据
     */
    private func updateHheaTable(numberOfHMetrics: Int32): Array<UInt8> {
        // 需要更新 numberOfHMetrics 字段

        // TODO: 实现 hhea 表更新
        Array<UInt8>(0, repeat: UInt8(0))
    }

    /**
     * 更新 maxp 表
     * @param numGlyphs 字形数量
     * @return 更新后的 maxp 表数据
     */
    private func updateMaxpTable(numGlyphs: Int32): Array<UInt8> {
        // 需要更新字形数量

        // TODO: 实现 maxp 表更新
        Array<UInt8>(0, repeat: UInt8(0))
    }

    /**
     * 计算表的校验和
     * @param data 表数据
     * @return 校验和
     */
    private func calculateChecksum(data: Array<UInt8>): UInt32 {
        var sum: UInt32 = 0
        var i: Int64 = 0

        // 每 4 字节作为一个 UInt32 累加
        while (i + 3 < data.size) {
            let val = (UInt32(data[i]) << 24) |
                     (UInt32(data[i + 1]) << 16) |
                     (UInt32(data[i + 2]) << 8) |
                     UInt32(data[i + 3])
            sum += val
            i += 4
        }

        // 处理剩余字节
        if (i < data.size) {
            var val: UInt32 = 0
            for (j in i..data.size) {
                val = (val << 8) | UInt32(data[j])
            }
            // 填充到 4 字节
            let shift = Int32(4 - (data.size - i)) * 8
            val = val << UInt32(shift)
            sum += val
        }

        sum
    }

    /**
     * 写入 UInt32 (Big Endian)
     */
    private func writeUInt32(value: UInt32, buffer: Array<UInt8>, offset: Int64): Unit {
        buffer[offset] = UInt8((value >> 24) & 0xFF)
        buffer[offset + 1] = UInt8((value >> 16) & 0xFF)
        buffer[offset + 2] = UInt8((value >> 8) & 0xFF)
        buffer[offset + 3] = UInt8(value & 0xFF)
    }

    /**
     * 写入 UInt16 (Big Endian)
     */
    private func writeUInt16(value: UInt16, buffer: Array<UInt8>, offset: Int64): Unit {
        buffer[offset] = UInt8((UInt32(value) >> 8) & 0xFF)
        buffer[offset + 1] = UInt8(UInt32(value) & 0xFF)
    }

    /**
     * 获取字体子集化信息（用于调试）
     */
    public func getSubsetInfo(): String {
        var info = "Font Subsetting Information:\n"
        info = "${info}Used glyphs: ${usedGlyphs.size}\n"
        info = "${info}Glyph IDs: "

        for ((gid, _) in usedGlyphs) {
            info = "${info}${gid} "
        }

        info
    }
}

/**
 * 字体子集化工具类
 * 提供静态方法处理字体子集化
 */
public class FontSubsettingUtil {
    /**
     * 检查字形 ID 是否有效
     */
    public static func isValidGlyphId(glyphId: UInt16, maxGlyphs: Int32): Bool {
        Int32(glyphId) >= 0 && Int32(glyphId) < maxGlyphs
    }

    /**
     * 生成子集字体的 PostScript 名称
     * @param originalName 原字体名称
     * @param subset 子集标识符（6 个大写字母）
     * @return 子集字体名称
     */
    public static func generateSubsetName(originalName: String, subset: String): String {
        "${subset}+${originalName}"
    }

    /**
     * 生成随机子集标识符（6 个大写字母）
     * 简化实现：使用固定前缀
     */
    public static func generateSubsetPrefix(): String {
        "SUBSET"  // 实际应该生成随机的 6 个大写字母
    }
}
