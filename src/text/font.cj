/**
 * PDF-CJ: Font - 字体类
 * 高层字体封装，包含字体、大小、样式和颜色
 */
package pdf_cj.text

/**
 * 字体类
 * 封装字体的所有属性
 */
public class Font {
    private let _baseFont: ?BaseFont
    private let _size: Float32
    private let _style: FontStyle
    private let _color: ?Color
    private let _family: FontFamily

    // 默认字体
    public static let DEFAULT = Font(None, 12.0, FontStyle.Normal, None, FontFamily.Undefined)

    // 默认字体大小
    public static let DEFAULTSIZE: Float32 = 12.0

    /**
     * 完整构造函数
     */
    public init(baseFont: ?BaseFont, size: Float32, style: FontStyle,
                color: ?Color, family: FontFamily) {
        this._baseFont = baseFont
        this._size = size
        this._style = style
        this._color = color
        this._family = family
    }

    /**
     * 使用 BaseFont 创建字体
     */
    public init(baseFont: BaseFont, size: Float32) {
        this(Some(baseFont), size, FontStyle.Normal, None, FontFamily.Undefined)
    }

    /**
     * 使用 BaseFont 和样式创建字体
     */
    public init(baseFont: BaseFont, size: Float32, style: FontStyle) {
        this(Some(baseFont), size, style, None, FontFamily.Undefined)
    }

    /**
     * 使用 BaseFont、样式和颜色创建字体
     */
    public init(baseFont: BaseFont, size: Float32, style: FontStyle, color: Color) {
        this(Some(baseFont), size, style, Some(color), FontFamily.Undefined)
    }

    /**
     * 使用字体家族创建字体
     */
    public init(family: FontFamily, size: Float32) {
        this(None, size, FontStyle.Normal, None, family)
    }

    /**
     * 使用字体家族和样式创建字体
     */
    public init(family: FontFamily, size: Float32, style: FontStyle) {
        this(None, size, style, None, family)
    }

    /**
     * 使用字体家族、样式和颜色创建字体
     */
    public init(family: FontFamily, size: Float32, style: FontStyle, color: Color) {
        this(None, size, style, Some(color), family)
    }

    /**
     * 获取字体大小
     */
    public prop size: Float32 {
        get() { _size }
    }

    /**
     * 获取字体样式
     */
    public prop style: FontStyle {
        get() { _style }
    }

    /**
     * 获取字体颜色
     */
    public prop color: ?Color {
        get() { _color }
    }

    /**
     * 获取字体家族
     */
    public prop family: FontFamily {
        get() { _family }
    }

    /**
     * 获取 BaseFont
     */
    public prop baseFont: ?BaseFont {
        get() { _baseFont }
    }

    /**
     * 获取已计算的 BaseFont（考虑家族和样式）
     */
    public func getCalculatedBaseFont(): BaseFont {
        if (_baseFont.isSome()) {
            return _baseFont.getOrThrow()
        }

        // 根据家族和样式选择标准字体
        let fontName = match (_family) {
            case Courier => match (_style) {
                case Bold => BaseFont.COURIER_BOLD
                case Italic => BaseFont.COURIER_OBLIQUE
                case BoldItalic => BaseFont.COURIER_BOLDOBLIQUE
                case _ => BaseFont.COURIER
            }
            case TimesRoman => match (_style) {
                case Bold => BaseFont.TIMES_BOLD
                case Italic => BaseFont.TIMES_ITALIC
                case BoldItalic => BaseFont.TIMES_BOLDITALIC
                case _ => BaseFont.TIMES_ROMAN
            }
            case Symbol => BaseFont.SYMBOL
            case ZapfDingbats => BaseFont.ZAPFDINGBATS
            case _ => match (_style) {
                case Bold => BaseFont.HELVETICA_BOLD
                case Italic => BaseFont.HELVETICA_OBLIQUE
                case BoldItalic => BaseFont.HELVETICA_BOLDOBLIQUE
                case _ => BaseFont.HELVETICA
            }
        }
        BaseFont.createFont(fontName, BaseFont.WINANSI)
    }

    /**
     * 是否为粗体
     */
    public func isBold(): Bool {
        _style.isBold()
    }

    /**
     * 是否为斜体
     */
    public func isItalic(): Bool {
        _style.isItalic()
    }

    /**
     * 是否有下划线
     */
    public func isUnderlined(): Bool {
        _style == FontStyle.Underline
    }

    /**
     * 是否有删除线
     */
    public func isStrikethru(): Bool {
        _style == FontStyle.Strikethrough
    }

    /**
     * 创建相同字体但不同大小
     */
    public func withSize(newSize: Float32): Font {
        Font(_baseFont, newSize, _style, _color, _family)
    }

    /**
     * 创建相同字体但不同样式
     */
    public func withStyle(newStyle: FontStyle): Font {
        Font(_baseFont, _size, newStyle, _color, _family)
    }

    /**
     * 创建相同字体但不同颜色
     */
    public func withColor(newColor: Color): Font {
        Font(_baseFont, _size, _style, Some(newColor), _family)
    }

    /**
     * 获取字符串宽度
     */
    public func getWidthPoint(text: String): Float32 {
        getCalculatedBaseFont().getWidthPoint(text, _size)
    }
}
