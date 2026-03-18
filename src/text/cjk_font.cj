/**
 * PDF-CJ: CJKFont - CJK 字体优化
 * 专门优化 CJK 字体的处理性能
 */
package pdf_cj.text

/**
 * CJK 字体类型枚举
 */
public enum CJKFontType {
    | SimplifiedChinese   // 简体中文
    | TraditionalChinese  // 繁体中文
    | Japanese            // 日文
    | Korean              // 韩文
}

/**
 * CJK 字体类
 * 提供 CJK 字符集的快速映射和优化处理
 */
public class CJKFont {
    private var baseFont: BaseFont
    private var fontType: CJKFontType
    private var isMonospace: Bool = true  // CJK 字体通常是等宽的

    /**
     * 构造函数
     * @param font 基础字体
     * @param fontType CJK 字体类型
     */
    public init(font: BaseFont, fontType: CJKFontType) {
        this.baseFont = font
        this.fontType = fontType
    }

    /**
     * 创建 CJK 字体
     * @param fontPath 字体文件路径
     * @param fontType CJK 字体类型
     * @param embedded 是否嵌入
     */
    public static func createCJKFont(fontPath: String, fontType: CJKFontType, embedded: Bool): CJKFont {
        let encoding = BaseFont.IDENTITY_H  // CJK 字体使用 Identity-H 编码
        let baseFont = BaseFont.createFont(fontPath, encoding, embedded)
        CJKFont(baseFont, fontType)
    }

    /**
     * 创建简体中文字体
     * @param fontPath 字体文件路径
     * @param embedded 是否嵌入
     */
    public static func createSimplifiedChineseFont(fontPath: String, embedded: Bool): CJKFont {
        createCJKFont(fontPath, CJKFontType.SimplifiedChinese, embedded)
    }

    /**
     * 创建繁体中文字体
     * @param fontPath 字体文件路径
     * @param embedded 是否嵌入
     */
    public static func createTraditionalChineseFont(fontPath: String, embedded: Bool): CJKFont {
        createCJKFont(fontPath, CJKFontType.TraditionalChinese, embedded)
    }

    /**
     * 创建日文字体
     * @param fontPath 字体文件路径
     * @param embedded 是否嵌入
     */
    public static func createJapaneseFont(fontPath: String, embedded: Bool): CJKFont {
        createCJKFont(fontPath, CJKFontType.Japanese, embedded)
    }

    /**
     * 创建韩文字体
     * @param fontPath 字体文件路径
     * @param embedded 是否嵌入
     */
    public static func createKoreanFont(fontPath: String, embedded: Bool): CJKFont {
        createCJKFont(fontPath, CJKFontType.Korean, embedded)
    }

    /**
     * 获取基础字体
     */
    public func getBaseFont(): BaseFont {
        baseFont
    }

    /**
     * 获取字体类型
     */
    public func getFontType(): CJKFontType {
        fontType
    }

    /**
     * 获取字符宽度（优化的 CJK 实现）
     * @param unicode Unicode 码点
     * @return 字符宽度（千分之一单位）
     */
    public func getCharWidth(unicode: UInt32): Int32 {
        // 对于 CJK 字符，如果是等宽字体，可以使用缓存的宽度值
        if (isMonospace && TrueTypeFontUnicode.isCJKChar(unicode)) {
            return getDefaultCJKWidth()
        }

        // 否则使用基础字体的宽度查询
        baseFont.getCharWidth(unicode)
    }

    /**
     * 获取默认 CJK 字符宽度
     * 对于等宽 CJK 字体，通常为 1000（千分之一单位）
     */
    private func getDefaultCJKWidth(): Int32 {
        1000
    }

    /**
     * 获取字符串宽度
     * @param text 文本
     * @param fontSize 字体大小
     * @return 字符串宽度（点）
     */
    public func getStringWidth(text: String, fontSize: Float32): Float32 {
        baseFont.getWidthPoint(text, fontSize)
    }

    /**
     * 检查字符是否在字体支持的范围内
     * @param unicode Unicode 码点
     * @return 是否支持
     */
    public func supportsChar(unicode: UInt32): Bool {
        match (fontType) {
            case CJKFontType.SimplifiedChinese =>
                TrueTypeFontUnicode.isCJKChar(unicode) ||
                unicode < 0x80  // 基本拉丁字符
            case CJKFontType.TraditionalChinese =>
                TrueTypeFontUnicode.isCJKChar(unicode) ||
                unicode < 0x80
            case CJKFontType.Japanese =>
                TrueTypeFontUnicode.isCJKChar(unicode) ||
                TrueTypeFontUnicode.isKanaChar(unicode) ||
                unicode < 0x80
            case CJKFontType.Korean =>
                TrueTypeFontUnicode.isCJKChar(unicode) ||
                TrueTypeFontUnicode.isHangulChar(unicode) ||
                unicode < 0x80
        }
    }

    /**
     * 设置是否为等宽字体
     */
    public func setMonospace(mono: Bool): Unit {
        this.isMonospace = mono
    }

    /**
     * 是否为等宽字体
     */
    public func isMonospaceFont(): Bool {
        isMonospace
    }
}

/**
 * 常见 CJK 字体预设
 */
public class CJKFontPresets {
    /**
     * 获取字体名称对应的字体类型
     * @param fontName 字体名称
     * @return 字体类型
     */
    public static func getFontType(fontName: String): CJKFontType {
        // 简体中文字体
        if (fontName.contains("SimSun") || fontName.contains("宋体") ||
            fontName.contains("SimHei") || fontName.contains("黑体") ||
            fontName.contains("Microsoft YaHei") || fontName.contains("微软雅黑") ||
            fontName.contains("NotoSansSC") || fontName.contains("NotoSerifSC")) {
            return CJKFontType.SimplifiedChinese
        }

        // 繁体中文字体
        if (fontName.contains("MingLiU") || fontName.contains("新細明體") ||
            fontName.contains("PMingLiU") ||
            fontName.contains("NotoSansTC") || fontName.contains("NotoSerifTC")) {
            return CJKFontType.TraditionalChinese
        }

        // 日文字体
        if (fontName.contains("MS Gothic") || fontName.contains("MS Mincho") ||
            fontName.contains("Meiryo") || fontName.contains("メイリオ") ||
            fontName.contains("NotoSansJP") || fontName.contains("NotoSerifJP") ||
            fontName.contains("Hiragino")) {
            return CJKFontType.Japanese
        }

        // 韩文字体
        if (fontName.contains("Gulim") || fontName.contains("굴림") ||
            fontName.contains("Batang") || fontName.contains("바탕") ||
            fontName.contains("Malgun Gothic") ||
            fontName.contains("NotoSansKR") || fontName.contains("NotoSerifKR")) {
            return CJKFontType.Korean
        }

        // 默认简体中文
        CJKFontType.SimplifiedChinese
    }
}
