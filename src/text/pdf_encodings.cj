/**
 * PDF-CJ: PdfEncodings - PDF 编码转换工具
 * 统一的 PDF 编码转换工具类
 */
package pdf_cj.text

import std.collection.{HashMap, ArrayList}

/**
 * PDF 编码转换工具类
 * 提供常见编码的转换函数
 */
public class PdfEncodings {
    // 编码名称常量
    public static let CP1252 = "Cp1252"
    public static let WINANSI = "WinAnsi"
    public static let MACROMAN = "MacRoman"
    public static let SYMBOL = "Symbol"
    public static let ZAPFDINGBATS = "ZapfDingbats"
    public static let UTF8 = "UTF-8"
    public static let UTF16BE = "UTF-16BE"
    public static let IDENTITY_H = "Identity-H"
    public static let IDENTITY_V = "Identity-V"

    private static var encodingTables: HashMap<String, Array<UInt32>> = HashMap<String, Array<UInt32>>()

    /**
     * 初始化编码表
     */
    private static func initEncodingTables(): Unit {
        if (encodingTables.size > 0) {
            return  // 已初始化
        }

        // 初始化 CP1252 (Windows Latin-1)
        encodingTables[CP1252] = createCP1252Table()
        encodingTables[WINANSI] = createCP1252Table()

        // 初始化 MacRoman
        encodingTables[MACROMAN] = createMacRomanTable()
    }

    /**
     * 创建 CP1252 编码表
     * CP1252 是 Windows 西欧编码
     */
    private static func createCP1252Table(): Array<UInt32> {
        let table = Array<UInt32>(256, repeat: UInt32(0))

        // 0-127 与 ASCII 相同
        for (i in 0..128) {
            table[Int64(i)] = UInt32(i)
        }

        // 128-255 的特殊映射
        table[128] = 0x20AC  // Euro sign
        table[130] = 0x201A  // Single low-9 quotation mark
        table[131] = 0x0192  // Latin small letter f with hook
        table[132] = 0x201E  // Double low-9 quotation mark
        table[133] = 0x2026  // Horizontal ellipsis
        table[134] = 0x2020  // Dagger
        table[135] = 0x2021  // Double dagger
        table[136] = 0x02C6  // Modifier letter circumflex accent
        table[137] = 0x2030  // Per mille sign
        table[138] = 0x0160  // Latin capital letter S with caron
        table[139] = 0x2039  // Single left-pointing angle quotation mark
        table[140] = 0x0152  // Latin capital ligature OE
        table[142] = 0x017D  // Latin capital letter Z with caron
        table[145] = 0x2018  // Left single quotation mark
        table[146] = 0x2019  // Right single quotation mark
        table[147] = 0x201C  // Left double quotation mark
        table[148] = 0x201D  // Right double quotation mark
        table[149] = 0x2022  // Bullet
        table[150] = 0x2013  // En dash
        table[151] = 0x2014  // Em dash
        table[152] = 0x02DC  // Small tilde
        table[153] = 0x2122  // Trade mark sign
        table[154] = 0x0161  // Latin small letter s with caron
        table[155] = 0x203A  // Single right-pointing angle quotation mark
        table[156] = 0x0153  // Latin small ligature oe
        table[158] = 0x017E  // Latin small letter z with caron
        table[159] = 0x0178  // Latin capital letter Y with diaeresis

        // 160-255 与 ISO-8859-1 相同
        for (i in 160..256) {
            table[Int64(i)] = UInt32(i)
        }

        table
    }

    /**
     * 创建 MacRoman 编码表
     */
    private static func createMacRomanTable(): Array<UInt32> {
        let table = Array<UInt32>(256, repeat: UInt32(0))

        // 0-127 与 ASCII 相同
        for (i in 0..128) {
            table[Int64(i)] = UInt32(i)
        }

        // 128-255 的 MacRoman 特殊映射（部分）
        table[128] = 0x00C4  // A umlaut
        table[129] = 0x00C5  // A ring
        table[130] = 0x00C7  // C cedilla
        table[131] = 0x00C9  // E acute
        table[132] = 0x00D1  // N tilde
        table[133] = 0x00D6  // O umlaut
        table[134] = 0x00DC  // U umlaut
        table[135] = 0x00E1  // a acute
        table[136] = 0x00E0  // a grave
        table[137] = 0x00E2  // a circumflex
        table[138] = 0x00E4  // a umlaut
        table[139] = 0x00E3  // a tilde
        table[140] = 0x00E5  // a ring
        table[141] = 0x00E7  // c cedilla
        table[142] = 0x00E9  // e acute
        table[143] = 0x00E8  // e grave

        // 简化：其余使用 ISO-8859-1
        for (i in 144..256) {
            table[Int64(i)] = UInt32(i)
        }

        table
    }

    /**
     * 将字节数组按指定编码转换为 Unicode 字符串
     * @param bytes 字节数组
     * @param encoding 编码名称
     * @return Unicode 字符串
     */
    public static func convertToUnicode(bytes: Array<UInt8>, encoding: String): String {
        initEncodingTables()

        // UTF-16BE 特殊处理
        if (encoding == UTF16BE) {
            return decodeUTF16BE(bytes)
        }

        // 获取编码表
        match (encodingTables.get(encoding)) {
            case Some(table) =>
                var result = ""
                for (i in 0..bytes.size) {
                    let byteVal = Int64(bytes[i])
                    if (byteVal >= 0 && byteVal < table.size) {
                        let unicode = table[byteVal]
                        result = "${result}${Rune(Int64(unicode))}"
                    }
                }
                return result
            case None =>
                // 未知编码，假设为 ISO-8859-1
                var result = ""
                for (i in 0..bytes.size) {
                    result = "${result}${Rune(Int64(bytes[i]))}"
                }
                return result
        }
    }

    /**
     * 将 Unicode 字符串按指定编码转换为字节数组
     * @param text Unicode 字符串
     * @param encoding 编码名称
     * @return 字节数组
     */
    public static func convertFromUnicode(text: String, encoding: String): Array<UInt8> {
        initEncodingTables()

        // UTF-16BE 特殊处理
        if (encoding == UTF16BE) {
            return encodeUTF16BE(text)
        }

        // Identity-H/V 使用 UTF-16BE
        if (encoding == IDENTITY_H || encoding == IDENTITY_V) {
            return encodeUTF16BE(text)
        }

        // 获取编码表
        match (encodingTables.get(encoding)) {
            case Some(table) =>
                // 创建反向映射
                let reverseMap = HashMap<UInt32, UInt8>()
                for (i in 0..table.size) {
                    let unicode = table[i]
                    reverseMap[unicode] = UInt8(i)
                }

                var result = ArrayList<UInt8>()
                for (ch in text) {
                    let unicode = UInt32(Int64(ch))
                    match (reverseMap.get(unicode)) {
                        case Some(byteVal) => result.add(byteVal)
                        case None => result.add(UInt8(0x3F))  // '?' 作为替代
                    }
                }

                // 转换为数组
                let arr = Array<UInt8>(result.size, repeat: UInt8(0))
                for (i in 0..result.size) {
                    arr[i] = result[i]
                }
                return arr
            case None =>
                // 未知编码，使用简单转换
                let arr = Array<UInt8>(text.size, repeat: UInt8(0))
                var idx: Int64 = 0
                for (ch in text) {
                    let unicode = Int64(ch)
                    if (unicode < 256) {
                        arr[idx] = UInt8(unicode)
                    } else {
                        arr[idx] = UInt8(0x3F)  // '?'
                    }
                    idx += 1
                }
                return arr
        }
    }

    /**
     * 解码 UTF-16BE 字节数组为字符串
     * @param bytes 字节数组
     * @return 字符串
     */
    private static func decodeUTF16BE(bytes: Array<UInt8>): String {
        var result = ""
        var i: Int64 = 0

        // 跳过 BOM
        if (bytes.size >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
            i = 2
        }

        while (i + 1 < bytes.size) {
            let high = UInt32(bytes[i])
            let low = UInt32(bytes[i + 1])
            let codePoint = (high << 8) | low

            // 检查是否为代理对
            if (codePoint >= 0xD800 && codePoint <= 0xDBFF && i + 3 < bytes.size) {
                // 高代理
                let highSurrogate = codePoint
                let lowHigh = UInt32(bytes[i + 2])
                let lowLow = UInt32(bytes[i + 3])
                let lowSurrogate = (lowHigh << 8) | lowLow

                if (lowSurrogate >= 0xDC00 && lowSurrogate <= 0xDFFF) {
                    // 计算实际码点
                    let actual = ((highSurrogate - 0xD800) << 10) + (lowSurrogate - 0xDC00) + 0x10000
                    result = "${result}${Rune(Int64(actual))}"
                    i += 4
                    continue
                }
            }

            result = "${result}${Rune(Int64(codePoint))}"
            i += 2
        }

        result
    }

    /**
     * 编码字符串为 UTF-16BE 字节数组
     * @param text 字符串
     * @return 字节数组
     */
    private static func encodeUTF16BE(text: String): Array<UInt8> {
        var result = ArrayList<UInt8>()

        // 添加 BOM
        result.add(UInt8(0xFE))
        result.add(UInt8(0xFF))

        for (ch in text) {
            let codePoint = UInt32(Int64(ch))

            if (codePoint <= 0xFFFF) {
                // BMP 字符
                result.add(UInt8((codePoint >> 8) & 0xFF))
                result.add(UInt8(codePoint & 0xFF))
            } else {
                // 补充平面，使用代理对
                let adjusted = codePoint - 0x10000
                let high = 0xD800 + ((adjusted >> 10) & 0x3FF)
                let low = 0xDC00 + (adjusted & 0x3FF)

                result.add(UInt8((high >> 8) & 0xFF))
                result.add(UInt8(high & 0xFF))
                result.add(UInt8((low >> 8) & 0xFF))
                result.add(UInt8(low & 0xFF))
            }
        }

        // 转换为数组
        let arr = Array<UInt8>(result.size, repeat: UInt8(0))
        for (i in 0..result.size) {
            arr[i] = result[i]
        }
        arr
    }

    /**
     * 检查字符是否在指定编码中可用
     * @param unicode Unicode 码点
     * @param encoding 编码名称
     * @return 是否可用
     */
    public static func isCharAvailable(unicode: UInt32, encoding: String): Bool {

        // UTF-16BE 和 Identity-H/V 支持所有 Unicode
        if (encoding == UTF16BE || encoding == IDENTITY_H || encoding == IDENTITY_V) {
            return true
        }

        initEncodingTables()

        match (encodingTables.get(encoding)) {
            case Some(table) =>
                // 检查表中是否有此 Unicode
                for (i in 0..table.size) {
                    if (table[i] == unicode) {
                        return true
                    }
                }
                return false
            case None =>
                // 未知编码，只支持 ASCII
                return unicode < 128
        }
    }

    /**
     * 转义 PDF 字符串中的特殊字符
     * @param text 原始文本
     * @return 转义后的文本
     */
    public static func escapePdfString(text: String): String {
        var result = ""

        for (ch in text) {
            let code = UInt32(Int64(ch))
            if (code == 0x5C) {  // '\\'
                result = "${result}\\\\"
            } else if (code == 0x28) {  // '('
                result = "${result}\\("
            } else if (code == 0x29) {  // ')'
                result = "${result}\\)"
            } else if (code == 0x0D) {  // '\r'
                result = "${result}\\r"
            } else if (code == 0x0A) {  // '\n'
                result = "${result}\\n"
            } else if (code == 0x09) {  // '\t'
                result = "${result}\\t"
            } else {
                result = "${result}${ch}"
            }
        }

        result
    }
}
