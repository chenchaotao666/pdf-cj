/**
 * PDF-CJ: FontFactory - 字体工厂
 * 管理字体创建和缓存
 */
package pdf_cj.text

import std.collection.{HashMap, ArrayList}
import std.fs.{Directory, exists, canonicalize, Path}
import std.runtime.gc

/**
 * 字体工厂类
 * 提供字体创建和管理功能
 */
public class FontFactory {
    // 字体缓存
    private static var fontCache: HashMap<String, BaseFont> = HashMap<String, BaseFont>()

    // 按名注册表：字体名（小写）→ 字体文件路径。由 register*/registerDirectories 填充，
    // 供 getFont(name) 与 BaseFont.createFont(name) 按名解析为实际文件。
    private static var _registry: HashMap<String, String> = HashMap<String, String>()

    // 扫描时已访问的目录（规范化真实路径），用于跟进符号链接的同时防止环
    private static var _visitedDirs: HashMap<String, Bool> = HashMap<String, Bool>()

    // registerDirectories 默认扫描的系统字体目录（Linux / macOS / Windows）
    private static let _SYSTEM_FONT_DIRS: Array<String> = [
        "/usr/share/fonts",
        "/usr/local/share/fonts",
        "/Library/Fonts",
        "/System/Library/Fonts",
        "C:\\Windows\\Fonts"
    ]

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
            // 已注册（按名）→ 用其文件路径并嵌入；否则按标准/系统字体名处理
            let bf = match (getRegisteredPath(actualFontName)) {
                case Some(path) => BaseFont.createFont(path, encoding, BaseFont.EMBEDDED)
                case None => BaseFont.createFont(actualFontName, encoding)
            }
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
     * 注册单个字体文件：读取其内部 family/full/postscript 名并建立「名→路径」索引。
     * @param path 字体文件路径（.ttf/.ttc/.otf）
     */
    public static func register(path: String): Unit {
        // 1) 字体内部名（family / full / postscript）；TTC 子字体用 "path,N"
        for ((name, idx) in FontNameReader.readNames(path)) {
            let value = if (idx == 0) { path } else { "${path},${idx}" }
            _registry[name.toAsciiLower()] = value
        }
        // 2) 文件名形式（带/不带扩展名）→ 整文件，便于按文件名加载（与 OpenPDF 一致）
        let fname = match (path.lastIndexOf("/")) {
            case Some(si) => path[(si + 1)..]
            case None => path
        }
        if (fname.size > 0) {
            _registry[fname.toAsciiLower()] = path
            match (fname.lastIndexOf(".")) {
                case Some(di) where di > 0 => _registry[fname[0..di].toAsciiLower()] = path
                case _ => ()
            }
        }
    }

    /**
     * 用显式别名注册字体文件（不依赖 name 表）。
     * @param path 字体文件路径
     * @param alias 字体别名
     */
    public static func register(path: String, alias: String): Unit {
        _registry[alias.toAsciiLower()] = path
        // 同时尝试索引文件内真实名称
        register(path)
    }

    /**
     * 扫描目录，注册其中所有字体文件（.ttf/.ttc/.otf），递归子目录。
     * @param directory 字体目录
     */
    public static func registerDirectory(directory: String): Unit {
        registerDirectoryDepth(directory, 0)
    }

    // 扫描期间已注册的字体文件计数，用于周期性触发 GC 回收名表解析的临时垃圾。
    private static var _scanRegCount: Int64 = 0

    // 限深递归扫描；规范化真实路径以跟进符号链接，并用已访问集合防止环。
    private static func registerDirectoryDepth(directory: String, depth: Int64): Unit {
        if (depth > 8 || !exists(directory)) { return }
        // 规范化（跟进符号链接到真实目录）
        let canon = try { canonicalize(Path(directory)).toString() } catch (_: Exception) { directory }
        if (_visitedDirs.contains(canon)) { return }  // 防环
        _visitedDirs[canon] = true
        try {
            for (entry in Directory.readFrom(canon)) {
                let p = entry.path.toString()
                let lower = p.toAsciiLower()
                if (lower.endsWith(".ttf") || lower.endsWith(".ttc") || lower.endsWith(".otf")) {
                    register(p)
                    // 每注册若干字体回收一次：name 表解析会产生大量短命缓冲，
                    // 不及时回收会让托管堆持续增长（CJK 字体目录下尤甚），故主动 GC。
                    _scanRegCount += 1
                    if (_scanRegCount % 24 == 0) { gc() }
                } else if (!lower.endsWith(".") && isLikelyDir(p)) {
                    registerDirectoryDepth(p, depth + 1)  // 递归子目录
                }
            }
        } catch (_: Exception) {}
    }

    /**
     * 扫描常见系统字体目录，注册全部字体（对标 OpenPDF registerDirectories）。
     * 之后即可用 getFont(字体名) / BaseFont.createFont(字体名, ...) 按名取字体，无需路径。
     */
    public static func registerDirectories(): Unit {
        registerStandardFonts()
        _visitedDirs = HashMap<String, Bool>()  // 重置已访问集合
        _scanRegCount = 0
        for (dir in _SYSTEM_FONT_DIRS) {
            if (exists(dir)) { registerDirectory(dir) }
        }
        // 扫描结束后做一次彻底回收，释放名表解析期间累积的临时内存，
        // 避免与后续 createFont（加载大字体）叠加而触顶 OOM。
        gc(heavy: true)
    }

    // 注册标准 14 字体名（与 OpenPDF 一致；值即字体名本身，createFont 按标准字体处理）
    private static func registerStandardFonts(): Unit {
        let std = [
            COURIER, COURIER_BOLD, COURIER_OBLIQUE, COURIER_BOLDOBLIQUE,
            HELVETICA, HELVETICA_BOLD, HELVETICA_OBLIQUE, HELVETICA_BOLDOBLIQUE,
            TIMES_ROMAN, TIMES_BOLD, TIMES_ITALIC, TIMES_BOLDITALIC,
            SYMBOL, ZAPFDINGBATS
        ]
        for (s in std) { _registry[s.toAsciiLower()] = s }
    }

    /**
     * 查询某字体名是否已注册，返回其文件路径。
     */
    public static func getRegisteredPath(fontName: String): ?String {
        _registry.get(fontName.toAsciiLower())
    }

    /**
     * 已注册字体名数量
     */
    public static func getRegisteredFontCount(): Int64 {
        _registry.size
    }

    /**
     * 列举所有已注册的字体名（对标 OpenPDF FontFactory.getRegisteredFonts）。
     */
    public static func getRegisteredFonts(): ArrayList<String> {
        let names = ArrayList<String>()
        for ((name, _) in _registry) { names.add(name) }
        names
    }

    private static func isLikelyDir(path: String): Bool {
        // 无扩展名的条目按目录尝试（readFrom 失败会被忽略）
        let lower = path.toAsciiLower()
        !(lower.endsWith(".ttf") || lower.endsWith(".ttc") || lower.endsWith(".otf") ||
          lower.endsWith(".pfb") || lower.endsWith(".afm") || lower.endsWith(".txt"))
    }

    /**
     * 清除字体缓存
     */
    public static func clearCache(): Unit {
        fontCache.clear()
    }

    /**
     * 检查字体是否已注册（按名）
     */
    public static func isRegistered(fontName: String): Bool {
        _registry.contains(fontName.toAsciiLower())
    }
}
