/**
 * PDF-CJ: GlyphList - 字形列表管理
 * 标准字形名称到 Unicode 的映射（Adobe Glyph List）
 */
package pdf_cj.text

import std.collection.{HashMap, ArrayList}

/**
 * 字形列表类
 * 提供字形名称到 Unicode 码点的映射
 */
public class GlyphList {
    private static var glyphToUnicode: HashMap<String, UInt32> = HashMap<String, UInt32>()
    private static var unicodeToGlyph: HashMap<UInt32, String> = HashMap<UInt32, String>()
    private static var initialized: Bool = false

    /**
     * 初始化字形列表
     * 实现 Adobe Glyph List (AGL) 标准映射
     */
    private static func initialize(): Unit {
        if (initialized) {
            return
        }

        // 常见字形映射（完整列表约有 4000+ 项，这里列举常用的）

        // 基本拉丁字符
        addMapping("A", 0x0041)
        addMapping("B", 0x0042)
        addMapping("C", 0x0043)
        addMapping("D", 0x0044)
        addMapping("E", 0x0045)
        addMapping("F", 0x0046)
        addMapping("G", 0x0047)
        addMapping("H", 0x0048)
        addMapping("I", 0x0049)
        addMapping("J", 0x004A)
        addMapping("K", 0x004B)
        addMapping("L", 0x004C)
        addMapping("M", 0x004D)
        addMapping("N", 0x004E)
        addMapping("O", 0x004F)
        addMapping("P", 0x0050)
        addMapping("Q", 0x0051)
        addMapping("R", 0x0052)
        addMapping("S", 0x0053)
        addMapping("T", 0x0054)
        addMapping("U", 0x0055)
        addMapping("V", 0x0056)
        addMapping("W", 0x0057)
        addMapping("X", 0x0058)
        addMapping("Y", 0x0059)
        addMapping("Z", 0x005A)

        addMapping("a", 0x0061)
        addMapping("b", 0x0062)
        addMapping("c", 0x0063)
        addMapping("d", 0x0064)
        addMapping("e", 0x0065)
        addMapping("f", 0x0066)
        addMapping("g", 0x0067)
        addMapping("h", 0x0068)
        addMapping("i", 0x0069)
        addMapping("j", 0x006A)
        addMapping("k", 0x006B)
        addMapping("l", 0x006C)
        addMapping("m", 0x006D)
        addMapping("n", 0x006E)
        addMapping("o", 0x006F)
        addMapping("p", 0x0070)
        addMapping("q", 0x0071)
        addMapping("r", 0x0072)
        addMapping("s", 0x0073)
        addMapping("t", 0x0074)
        addMapping("u", 0x0075)
        addMapping("v", 0x0076)
        addMapping("w", 0x0077)
        addMapping("x", 0x0078)
        addMapping("y", 0x0079)
        addMapping("z", 0x007A)

        // 数字
        addMapping("zero", 0x0030)
        addMapping("one", 0x0031)
        addMapping("two", 0x0032)
        addMapping("three", 0x0033)
        addMapping("four", 0x0034)
        addMapping("five", 0x0035)
        addMapping("six", 0x0036)
        addMapping("seven", 0x0037)
        addMapping("eight", 0x0038)
        addMapping("nine", 0x0039)

        // 标点符号
        addMapping("space", 0x0020)
        addMapping("exclam", 0x0021)
        addMapping("quotedbl", 0x0022)
        addMapping("numbersign", 0x0023)
        addMapping("dollar", 0x0024)
        addMapping("percent", 0x0025)
        addMapping("ampersand", 0x0026)
        addMapping("quotesingle", 0x0027)
        addMapping("parenleft", 0x0028)
        addMapping("parenright", 0x0029)
        addMapping("asterisk", 0x002A)
        addMapping("plus", 0x002B)
        addMapping("comma", 0x002C)
        addMapping("hyphen", 0x002D)
        addMapping("period", 0x002E)
        addMapping("slash", 0x002F)
        addMapping("colon", 0x003A)
        addMapping("semicolon", 0x003B)
        addMapping("less", 0x003C)
        addMapping("equal", 0x003D)
        addMapping("greater", 0x003E)
        addMapping("question", 0x003F)
        addMapping("at", 0x0040)
        addMapping("bracketleft", 0x005B)
        addMapping("backslash", 0x005C)
        addMapping("bracketright", 0x005D)
        addMapping("asciicircum", 0x005E)
        addMapping("underscore", 0x005F)
        addMapping("grave", 0x0060)
        addMapping("braceleft", 0x007B)
        addMapping("bar", 0x007C)
        addMapping("braceright", 0x007D)
        addMapping("asciitilde", 0x007E)

        // 扩展拉丁字符（部分）
        addMapping("Aacute", 0x00C1)
        addMapping("Acircumflex", 0x00C2)
        addMapping("Adieresis", 0x00C4)
        addMapping("Agrave", 0x00C0)
        addMapping("Aring", 0x00C5)
        addMapping("Atilde", 0x00C3)
        addMapping("Ccedilla", 0x00C7)
        addMapping("Eacute", 0x00C9)
        addMapping("Ecircumflex", 0x00CA)
        addMapping("Edieresis", 0x00CB)
        addMapping("Egrave", 0x00C8)
        addMapping("Ntilde", 0x00D1)
        addMapping("Oacute", 0x00D3)
        addMapping("Ocircumflex", 0x00D4)
        addMapping("Odieresis", 0x00D6)
        addMapping("Ograve", 0x00D2)
        addMapping("Otilde", 0x00D5)
        addMapping("Uacute", 0x00DA)
        addMapping("Ucircumflex", 0x00DB)
        addMapping("Udieresis", 0x00DC)
        addMapping("Ugrave", 0x00D9)

        // 小写扩展拉丁字符
        addMapping("aacute", 0x00E1)
        addMapping("acircumflex", 0x00E2)
        addMapping("adieresis", 0x00E4)
        addMapping("agrave", 0x00E0)
        addMapping("aring", 0x00E5)
        addMapping("atilde", 0x00E3)
        addMapping("ccedilla", 0x00E7)
        addMapping("eacute", 0x00E9)
        addMapping("ecircumflex", 0x00EA)
        addMapping("edieresis", 0x00EB)
        addMapping("egrave", 0x00E8)
        addMapping("ntilde", 0x00F1)
        addMapping("oacute", 0x00F3)
        addMapping("ocircumflex", 0x00F4)
        addMapping("odieresis", 0x00F6)
        addMapping("ograve", 0x00F2)
        addMapping("otilde", 0x00F5)
        addMapping("uacute", 0x00FA)
        addMapping("ucircumflex", 0x00FB)
        addMapping("udieresis", 0x00FC)
        addMapping("ugrave", 0x00F9)

        // 常见符号
        addMapping("bullet", 0x2022)
        addMapping("dagger", 0x2020)
        addMapping("daggerdbl", 0x2021)
        addMapping("ellipsis", 0x2026)
        addMapping("endash", 0x2013)
        addMapping("emdash", 0x2014)
        addMapping("euro", 0x20AC)
        addMapping("guillemotleft", 0x00AB)
        addMapping("guillemotright", 0x00BB)
        addMapping("trademark", 0x2122)

        // .notdef 特殊字形
        addMapping(".notdef", 0x0000)

        initialized = true
    }

    /**
     * 添加字形映射
     */
    private static func addMapping(glyphName: String, unicode: UInt32): Unit {
        glyphToUnicode[glyphName] = unicode
        unicodeToGlyph[unicode] = glyphName
    }

    /**
     * 根据字形名称获取 Unicode 码点
     * @param glyphName 字形名称
     * @return Unicode 码点，未找到返回 0
     */
    public static func nameToUnicode(glyphName: String): UInt32 {
        initialize()

        match (glyphToUnicode.get(glyphName)) {
            case Some(unicode) => unicode
            case None =>
                // 尝试解析 uniXXXX 格式
                if (glyphName.startsWith("uni") && glyphName.size == 7) {
                    return parseUnicodeName(glyphName)
                }
                // 未找到，返回 0
                0
        }
    }

    /**
     * 根据 Unicode 码点获取字形名称
     * @param unicode Unicode 码点
     * @return 字形名称，未找到返回空字符串
     */
    public static func unicodeToName(unicode: UInt32): String {
        initialize()

        match (unicodeToGlyph.get(unicode)) {
            case Some(name) => name
            case None =>
                // 生成 uniXXXX 格式名称
                if (unicode > 0 && unicode <= 0xFFFF) {
                    return generateUnicodeName(unicode)
                }
                ""
        }
    }

    /**
     * 解析 uniXXXX 格式的字形名称
     * @param name 字形名称（如 "uni4E00"）
     * @return Unicode 码点
     */
    private static func parseUnicodeName(name: String): UInt32 {
        // 提取十六进制部分（跳过 "uni" 前缀）
        let hexPart = name[3..]

        // 简单的十六进制解析
        var result: UInt32 = 0
        for (ch in hexPart) {
            result = result * 16
            let code = Int64(ch)
            if (code >= 0x30 && code <= 0x39) {  // '0'-'9'
                result = result + UInt32(code - 0x30)
            } else if (code >= 0x41 && code <= 0x46) {  // 'A'-'F'
                result = result + UInt32(code - 0x41 + 10)
            } else if (code >= 0x61 && code <= 0x66) {  // 'a'-'f'
                result = result + UInt32(code - 0x61 + 10)
            }
        }

        result
    }

    /**
     * 生成 uniXXXX 格式的字形名称
     * @param unicode Unicode 码点
     * @return 字形名称
     */
    private static func generateUnicodeName(unicode: UInt32): String {
        let hexDigits = "0123456789ABCDEF"
        var result = "uni"

        // 生成 4 位十六进制
        let d3 = (unicode >> 12) & 0xF
        let d2 = (unicode >> 8) & 0xF
        let d1 = (unicode >> 4) & 0xF
        let d0 = unicode & 0xF

        result = "${result}${hexDigits[Int64(d3)]}"
        result = "${result}${hexDigits[Int64(d2)]}"
        result = "${result}${hexDigits[Int64(d1)]}"
        result = "${result}${hexDigits[Int64(d0)]}"

        result
    }

    /**
     * 检查字形名称是否存在
     * @param glyphName 字形名称
     * @return 是否存在
     */
    public static func hasGlyph(glyphName: String): Bool {
        initialize()
        glyphToUnicode.contains(glyphName)
    }

    /**
     * 获取所有字形名称的数量
     */
    public static func getGlyphCount(): Int64 {
        initialize()
        glyphToUnicode.size
    }
}

/**
 * Type1 字体字形工具
 * 提供 Type1 字体特有的字形名称支持
 */
public class Type1GlyphUtil {
    /**
     * 检查是否为标准 Type1 字形名称
     * @param glyphName 字形名称
     * @return 是否为标准名称
     */
    public static func isStandardName(glyphName: String): Bool {
        GlyphList.hasGlyph(glyphName)
    }

    /**
     * Type1 字符串编码到字形名称
     * @param text 文本
     * @return 字形名称列表
     */
    public static func textToGlyphNames(text: String): Array<String> {
        let result = ArrayList<String>()

        for (ch in text) {
            let unicode = UInt32(Int64(ch))
            let glyphName = GlyphList.unicodeToName(unicode)
            if (glyphName.size > 0) {
                result.add(glyphName)
            }
        }

        // 转换为数组
        let arr = Array<String>(result.size, repeat: "")
        for (i in 0..result.size) {
            arr[i] = result[i]
        }
        arr
    }
}
