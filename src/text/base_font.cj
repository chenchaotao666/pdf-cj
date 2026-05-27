/**
 * PDF-CJ: BaseFont - 基础字体类
 * PDF 底层字体对象，处理字体加载和编码
 */
package pdf_cj.text

import pdf_cj.util.PdfException

/**
 * 基础字体类
 * 表示 PDF 文档中的字体资源
 */
public class BaseFont {
    private let fontName: String
    private let encoding: String
    private let embedded: Bool
    private let fontPath: ?String  // TrueType 字体文件路径
    private var ttfFont: ?TrueTypeFont = None  // TrueType 字体对象
    private var fontSubset: ?FontSubsetting = None  // 字体子集化对象（用于嵌入字体）
    private var _subsetFontName: ?String = None  // 子集字体名称（6字符前缀+字体名）

    // 标准 14 字体名称
    public static let COURIER = "Courier"
    public static let COURIER_BOLD = "Courier-Bold"
    public static let COURIER_OBLIQUE = "Courier-Oblique"
    public static let COURIER_BOLDOBLIQUE = "Courier-BoldOblique"

    public static let HELVETICA = "Helvetica"
    public static let HELVETICA_BOLD = "Helvetica-Bold"
    public static let HELVETICA_OBLIQUE = "Helvetica-Oblique"
    public static let HELVETICA_BOLDOBLIQUE = "Helvetica-BoldOblique"

    public static let TIMES_ROMAN = "Times-Roman"
    public static let TIMES_BOLD = "Times-Bold"
    public static let TIMES_ITALIC = "Times-Italic"
    public static let TIMES_BOLDITALIC = "Times-BoldItalic"

    public static let SYMBOL = "Symbol"
    public static let ZAPFDINGBATS = "ZapfDingbats"

    // 编码常量
    public static let CP1252 = "Cp1252"           // Windows 西欧编码
    public static let WINANSI = CP1252            // 别名
    public static let MACROMAN = "MacRoman"       // Mac 罗马编码
    public static let IDENTITY_H = "Identity-H"   // Unicode 水平书写
    public static let IDENTITY_V = "Identity-V"   // Unicode 垂直书写

    // 字体嵌入模式
    public static let NOT_EMBEDDED = false
    public static let EMBEDDED = true
    public static let CACHED = true
    public static let NOT_CACHED = false

    /**
     * 私有构造函数
     */
    private init(fontName: String, encoding: String, embedded: Bool, fontPath: ?String) {
        this.fontName = fontName
        this.encoding = encoding
        this.embedded = embedded
        this.fontPath = fontPath
    }

    /**
     * 创建字体
     * @param name 字体名称或字体文件路径
     * @param encoding 编码方式
     * @param embedded 是否嵌入字体
     */
    public static func createFont(name: String, encoding: String, embedded: Bool): BaseFont {
        // 检查是否为标准 14 字体
        if (isStandardFont(name)) {
            return BaseFont(name, encoding, false, None)  // 标准字体不需要嵌入
        }

        // 检查是否为 TrueType 字体文件
        if (name.endsWith(".ttf") || name.endsWith(".TTF") ||
            name.endsWith(".ttc") || name.endsWith(".TTC") ||
            name.endsWith(".otf") || name.endsWith(".OTF")) {
            // TrueType/OpenType 字体 - 加载字体文件
            let fontBaseName = extractFontName(name)
            let baseFont = BaseFont(fontBaseName, encoding, embedded, Some(name))

            // 对于 Unicode 编码，需要加载字体以获取 cmap 表（用于 Unicode 到 GID 转换）
            // 对于嵌入字体，也需要加载字体数据
            if (encoding == IDENTITY_H || encoding == IDENTITY_V || embedded) {
                baseFont.loadTrueTypeFont(name)
            }

            return baseFont
        }

        // 尝试作为系统字体名称
        // 对于中文字体，允许直接使用字体名称
        return BaseFont(name, encoding, embedded, None)
    }

    /**
     * 创建字体（简化版本）
     */
    public static func createFont(name: String, encoding: String): BaseFont {
        createFont(name, encoding, NOT_EMBEDDED)
    }

    /**
     * 创建默认字体
     */
    public static func createFont(): BaseFont {
        createFont(HELVETICA, WINANSI, NOT_EMBEDDED)
    }

    /**
     * 检查是否为标准 14 字体
     */
    private static func isStandardFont(name: String): Bool {
        let standardFonts = [
            COURIER, COURIER_BOLD, COURIER_OBLIQUE, COURIER_BOLDOBLIQUE,
            HELVETICA, HELVETICA_BOLD, HELVETICA_OBLIQUE, HELVETICA_BOLDOBLIQUE,
            TIMES_ROMAN, TIMES_BOLD, TIMES_ITALIC, TIMES_BOLDITALIC,
            SYMBOL, ZAPFDINGBATS
        ]
        for (font in standardFonts) {
            if (font == name) {
                return true
            }
        }
        false
    }

    /**
     * 从文件路径提取字体名称
     */
    private static func extractFontName(path: String): String {
        // 特殊处理 Noto CJK 字体
        if (path.contains("NotoSansCJK")) {
            return "NotoSansCJKsc-Regular"  // 简体中文变体
        }
        if (path.contains("NotoSerifCJK")) {
            return "NotoSerifCJKsc-Regular"  // 简体中文变体
        }

        // 获取最后一个斜杠后的文件名
        var name = path
        match (path.lastIndexOf("/")) {
            case Some(index) =>
                if (index < path.size - 1) {
                    name = path[(index + 1)..]
                }
            case None => ()
        }

        match (name.lastIndexOf("\\")) {
            case Some(index) =>
                if (index < name.size - 1) {
                    name = name[(index + 1)..]
                }
            case None => ()
        }

        // 移除扩展名
        match (name.lastIndexOf(".")) {
            case Some(index) =>
                if (index > 0) {
                    name = name[0..index]
                }
            case None => ()
        }

        name
    }

    /**
     * 检查是否使用 Unicode 编码
     */
    public func isUnicodeEncoding(): Bool {
        encoding == IDENTITY_H || encoding == IDENTITY_V
    }

    /**
     * 检查是否为 TrueType 字体
     */
    public func isTrueType(): Bool {
        fontPath.isSome()
    }

    /**
     * 加载 TrueType 字体
     */
    private func loadTrueTypeFont(path: String): Unit {
        try {
            let font = TrueTypeFont(path)
            ttfFont = Some(font)

            // 如果需要嵌入字体，创建子集化对象并生成子集前缀
            if (embedded) {
                fontSubset = Some(FontSubsetting(font))
                let prefix = generateSubsetPrefix(path)
                _subsetFontName = Some("${prefix}+${fontName}")
            }
        } catch (e: Exception) {
            throw PdfException("Failed to load TrueType font: ${path}, error: ${e.message}")
        }
    }

    /**
     * 获取 TrueType 字体对象
     */
    public func getTrueTypeFont(): ?TrueTypeFont {
        ttfFont
    }

    /**
     * 获取字符串宽度（单位：点）
     * @param text 文本
     * @param fontSize 字体大小
     */
    public func getWidthPoint(text: String, fontSize: Float32): Float32 {
        // 标记字符串中的字形为已使用（用于子集化）
        markStringUsed(text)

        // 如果是 TrueType 字体，使用精确的字形宽度
        match (ttfFont) {
            case Some(ttf) =>
                return ttf.getStringWidth(text, fontSize)
            case None =>
                // 简化实现：使用平均字符宽度
                let avgCharWidth = getAverageCharWidth()
                return Float32(text.size) * fontSize * avgCharWidth / 1000.0
        }
    }

    /**
     * 获取单个字符的宽度（字体单位）
     * @param unicode Unicode 码点
     * @return 字符宽度（以千分之一单位），如果未找到返回 0
     */
    public func getCharWidth(unicode: UInt32): Int32 {
        match (ttfFont) {
            case Some(ttf) =>
                // 从 TrueType 字体获取精确宽度，转换为千分之一单位
                let widthInFontUnits = ttf.getCharWidth(unicode)
                let unitsPerEm = ttf.getUnitsPerEm()
                if (unitsPerEm > 0) {
                    return (widthInFontUnits * 1000) / unitsPerEm
                } else {
                    return 0
                }
            case None =>
                // 对于标准字体，返回估算值
                return Int32(getAverageCharWidth())
        }
    }

    /**
     * 获取字形宽度（字体单位）
     * @param glyphId 字形 ID
     * @return 字形宽度（以千分之一单位），如果未找到返回 0
     */
    public func getGlyphWidth(glyphId: UInt16): Int32 {
        match (ttfFont) {
            case Some(ttf) =>
                // 从 TrueType 字体获取精确宽度，转换为千分之一单位
                let widthInFontUnits = ttf.getGlyphWidth(glyphId)
                let unitsPerEm = ttf.getUnitsPerEm()
                if (unitsPerEm > 0) {
                    return (widthInFontUnits * 1000) / unitsPerEm
                } else {
                    return 0
                }
            case None =>
                // 对于标准字体，返回估算值
                return Int32(getAverageCharWidth())
        }
    }

    /**
     * 获取平均字符宽度（千分之一单位）
     */
    private func getAverageCharWidth(): Float32 {
        // 不同字体有不同的平均宽度
        match (fontName) {
            case "Courier" | "Courier-Bold" | "Courier-Oblique" | "Courier-BoldOblique" =>
                600.0  // 等宽字体
            case "Helvetica" | "Helvetica-Bold" | "Helvetica-Oblique" | "Helvetica-BoldOblique" =>
                500.0
            case "Times-Roman" | "Times-Bold" | "Times-Italic" | "Times-BoldItalic" =>
                450.0
            case _ =>
                500.0
        }
    }

    /**
     * 获取字体上升高度
     */
    public func getAscent(fontSize: Float32): Float32 {
        fontSize * 0.8  // 简化：80% 的字体大小
    }

    /**
     * 获取字体下降高度
     */
    public func getDescent(fontSize: Float32): Float32 {
        fontSize * 0.2  // 简化：20% 的字体大小
    }

    /**
     * 计算文本实际 descender（与 OpenPDF 一致：取所有字形 yMin 的最小值转换为点数）
     * 返回正值（下沉量），0 表示文本不含 descender 字形
     *
     * 对于 glyf-based TrueType 字体：读取实际字形 yMin
     * 对于 CFF-based OpenType 字体（如 NotoSansCJK）：检测深 descender 字符 (j/p/q/y) 并使用 hhea descent
     */
    public func getTextDescentPt(text: String, fontSize: Float32): Float32 {
        match (ttfFont) {
            case Some(ttf) =>
                if (!ttf.isCFF()) {
                    // glyf-based TrueType: 用实际字形 yMin
                    var minY: Int32 = 0
                    for (r in text.runes()) {
                        let gid = ttf.getGlyphId(UInt32(r))
                        let yMin = ttf.getGlyphYMin(gid)
                        if (yMin < minY) { minY = yMin }
                    }
                    if (minY >= 0) { return 0.0 }
                    Float32(-minY) * fontSize / Float32(ttf.getUnitsPerEm())
                } else {
                    // CFF-based OpenType (如 NotoSansCJK): 检测深 descender 字符
                    // j/p/q/y 在大多数拉丁字体中具有深 descender；CJK 字符无 descender
                    var hasDeepDescender = false
                    for (r in text.runes()) {
                        if (r == r'j' || r == r'p' || r == r'q' || r == r'y') {
                            hasDeepDescender = true
                        }
                    }
                    if (!hasDeepDescender) { return 0.0 }
                    let d = ttf.getDescent()  // hhea descent, 负值如 -288
                    if (d >= 0) { return 0.0 }
                    Float32(-d) * fontSize / Float32(ttf.getUnitsPerEm())
                }
            case None =>
                0.0
        }
    }

    /**
     * 获取行高
     */
    public func getLineHeight(fontSize: Float32): Float32 {
        fontSize * 1.2  // 简化：120% 的字体大小
    }

    // 属性访问器
    public prop name: String {
        get() { fontName }
    }

    public prop fontEncoding: String {
        get() { encoding }
    }

    public prop isEmbedded: Bool {
        get() { embedded }
    }

    public prop path: ?String {
        get() { fontPath }
    }

    /**
     * 获取 PDF 字体名称（嵌入子集字体时带6字符前缀，如 "ABCDEF+FontName"）
     */
    public func getPdfFontName(): String {
        match (_subsetFontName) {
            case Some(name) => name
            case None => fontName
        }
    }

    /**
     * 生成子集字体名称前缀（6个大写字母，基于字体路径的哈希）
     */
    private static func generateSubsetPrefix(fontPath: String): String {
        var h: Int64 = 5381
        for (c in fontPath.runes()) {
            h = ((h << 5) + h + Int64(UInt32(c))) & 0x7FFFFFFF
        }
        var prefix = ""
        for (i in 0..6) {
            let idx = h % 26
            prefix = "${prefix}${Rune(UInt8(65 + idx))}"
            h = h / 26
        }
        prefix
    }

    /**
     * 是否为等宽字体
     */
    public func isMonospace(): Bool {
        fontName.startsWith("Courier")
    }

    /**
     * 获取 Unicode 字符对应的 Glyph ID
     * 仅对 TrueType 字体有效
     * @param unicode Unicode 码点
     * @return Glyph ID，如果字体不支持返回 0
     */
    public func getGlyphId(unicode: UInt32): UInt16 {
        match (ttfFont) {
            case Some(ttf) => ttf.getGlyphId(unicode)
            case None => UInt16(0)
        }
    }

    /**
     * 检查字体是否包含指定 Unicode 字符
     */
    public func hasGlyph(unicode: UInt32): Bool {
        match (ttfFont) {
            case Some(ttf) => ttf.hasGlyph(unicode)
            case None => false
        }
    }

    /**
     * 获取两个字形之间的 kerning 调整值
     * @param leftGlyphId 左侧字形 ID
     * @param rightGlyphId 右侧字形 ID
     * @return Kerning 调整值（以千分之一单位），如果无调整返回 0
     */
    public func getKerning(leftGlyphId: UInt16, rightGlyphId: UInt16): Int32 {
        match (ttfFont) {
            case Some(ttf) =>
                // 从 TrueType 字体获取 kerning，转换为千分之一单位
                let kernInFontUnits = ttf.getKerning(leftGlyphId, rightGlyphId)
                let unitsPerEm = ttf.getUnitsPerEm()
                if (unitsPerEm > 0) {
                    return (kernInFontUnits * 1000) / unitsPerEm
                } else {
                    return 0
                }
            case None =>
                // 标准字体没有 kerning 数据
                return 0
        }
    }

    /**
     * 获取两个 Unicode 字符之间的 kerning 调整值
     * @param leftChar 左侧字符
     * @param rightChar 右侧字符
     * @return Kerning 调整值（以千分之一单位），如果无调整返回 0
     */
    public func getCharKerning(leftChar: UInt32, rightChar: UInt32): Int32 {
        match (ttfFont) {
            case Some(ttf) =>
                // 从 TrueType 字体获取 kerning，转换为千分之一单位
                let kernInFontUnits = ttf.getCharKerning(leftChar, rightChar)
                let unitsPerEm = ttf.getUnitsPerEm()
                if (unitsPerEm > 0) {
                    return (kernInFontUnits * 1000) / unitsPerEm
                } else {
                    return 0
                }
            case None =>
                // 标准字体没有 kerning 数据
                return 0
        }
    }

    /**
     * 标记字形为已使用（用于子集化）
     * @param glyphId 字形 ID
     */
    public func markGlyphUsed(glyphId: UInt16): Unit {
        match (fontSubset) {
            case Some(subset) => subset.markGlyphUsed(glyphId)
            case None => ()
        }
    }

    /**
     * 标记 Unicode 字符为已使用（用于子集化）
     * @param unicode Unicode 码点
     */
    public func markCharUsed(unicode: UInt32): Unit {
        match (fontSubset) {
            case Some(subset) => subset.markCharUsed(unicode)
            case None => ()
        }
    }

    /**
     * 标记字符串中所有字符为已使用（用于子集化）
     * @param text 文本字符串
     */
    public func markStringUsed(text: String): Unit {
        match (fontSubset) {
            case Some(subset) => subset.markStringUsed(text)
            case None => ()
        }
    }

    /**
     * 获取字体子集化对象
     */
    public func getFontSubset(): ?FontSubsetting {
        fontSubset
    }

    /**
     * 获取使用的字形数量
     */
    public func getUsedGlyphCount(): Int64 {
        match (fontSubset) {
            case Some(subset) => subset.getUsedGlyphCount()
            case None => 0
        }
    }
}
