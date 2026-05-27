/**
 * PDF-CJ: FontFactory - 字体工厂
 * 管理字体创建和缓存
 */
package pdf_cj.text

import std.collection.HashMap

/**
 * 字体工厂类
 * 提供字体创建和管理功能
 */
public class FontFactory {
    // 字体缓存
    private static var fontCache: HashMap<String, BaseFont> = HashMap<String, BaseFont>()

    // 字体名称常量（与 BaseFont 对应）
    public static let COURIER = BaseFont.COURIER
    public static let COURIER_BOLD = BaseFont.COURIER_BOLD
    public static let COURIER_OBLIQUE = BaseFont.COURIER_OBLIQUE
    public static let COURIER_BOLDOBLIQUE = BaseFont.COURIER_BOLDOBLIQUE

    public static let HELVETICA = BaseFont.HELVETICA
    public static let HELVETICA_BOLD = BaseFont.HELVETICA_BOLD
    public static let HELVETICA_OBLIQUE = BaseFont.HELVETICA_OBLIQUE
    public static let HELVETICA_BOLDOBLIQUE = BaseFont.HELVETICA_BOLDOBLIQUE

    public static let TIMES = BaseFont.TIMES_ROMAN
    public static let TIMES_ROMAN = BaseFont.TIMES_ROMAN
    public static let TIMES_BOLD = BaseFont.TIMES_BOLD
    public static let TIMES_ITALIC = BaseFont.TIMES_ITALIC
    public static let TIMES_BOLDITALIC = BaseFont.TIMES_BOLDITALIC

    public static let SYMBOL = BaseFont.SYMBOL
    public static let ZAPFDINGBATS = BaseFont.ZAPFDINGBATS

    /**
     * 获取字体
     * @param fontName 字体名称
     */
    public static func getFont(fontName: String): Font {
        getFont(fontName, BaseFont.WINANSI, Font.DEFAULTSIZE, FontStyle.Normal, None)
    }

    /**
     * 获取字体
     * @param fontName 字体名称
     * @param size 字体大小
     */
    public static func getFont(fontName: String, size: Float32): Font {
        getFont(fontName, BaseFont.WINANSI, size, FontStyle.Normal, None)
    }

    /**
     * 获取字体
     * @param fontName 字体名称
     * @param size 字体大小
     * @param style 字体样式
     */
    public static func getFont(fontName: String, size: Float32, style: FontStyle): Font {
        getFont(fontName, BaseFont.WINANSI, size, style, None)
    }

    /**
     * 获取字体
     * @param fontName 字体名称
     * @param size 字体大小
     * @param style 字体样式
     * @param color 字体颜色
     */
    public static func getFont(fontName: String, size: Float32,
                                style: FontStyle, color: Color): Font {
        getFont(fontName, BaseFont.WINANSI, size, style, Some(color))
    }

    /**
     * 获取字体（完整参数）
     */
    public static func getFont(fontName: String, encoding: String, size: Float32,
                                style: FontStyle, color: ?Color): Font {
        // 根据样式确定实际字体名称
        let actualFontName = resolveFont(fontName, style)

        // 从缓存获取或创建 BaseFont
        let cacheKey = "${actualFontName}|${encoding}"
        let cached = fontCache.get(cacheKey)
        let baseFont = if (cached.isSome()) {
            cached.getOrThrow()
        } else {
            let bf = BaseFont.createFont(actualFontName, encoding)
            fontCache[cacheKey] = bf
            bf
        }

        // 创建 Font 对象
        match (color) {
            case Some(c) => Font(baseFont, size, style, c)
            case None => Font(baseFont, size, style)
        }
    }

    /**
     * 根据基础字体名和样式解析实际字体名
     */
    private static func resolveFont(fontName: String, style: FontStyle): String {
        match (fontName) {
            case "Helvetica" => match (style) {
                case Bold => HELVETICA_BOLD
                case Italic => HELVETICA_OBLIQUE
                case BoldItalic => HELVETICA_BOLDOBLIQUE
                case _ => HELVETICA
            }
            case "Courier" => match (style) {
                case Bold => COURIER_BOLD
                case Italic => COURIER_OBLIQUE
                case BoldItalic => COURIER_BOLDOBLIQUE
                case _ => COURIER
            }
            case "Times-Roman" | "Times" => match (style) {
                case Bold => TIMES_BOLD
                case Italic => TIMES_ITALIC
                case BoldItalic => TIMES_BOLDITALIC
                case _ => TIMES_ROMAN
            }
            case _ => fontName
        }
    }

    /**
     * 注册字体
     * @param path 字体文件路径
     * @param alias 字体别名
     */
    public static func register(path: String, alias: String): Unit {
        // TODO: 实现自定义字体注册
    }

    /**
     * 注册目录下所有字体
     * @param directory 字体目录
     */
    public static func registerDirectory(directory: String): Unit {
        // TODO: 实现目录字体注册
    }

    /**
     * 清除字体缓存
     */
    public static func clearCache(): Unit {
        fontCache.clear()
    }

    /**
     * 检查字体是否已注册
     */
    public static func isRegistered(fontName: String): Bool {
        fontCache.contains(fontName)
    }
}
