/**
 * PDF-CJ: TrueTypeFontUnicode - Unicode 字体专用处理
 * 优化 Unicode 字体（特别是 CJK 字体）的处理
 */
package pdf_cj.text

import std.collection.{HashMap, ArrayList}
import pdf_cj.util.PdfException

/**
 * Unicode TrueType 字体增强类
 * 提供对 Unicode 字体的优化支持，特别是 CJK 字体
 */
public class TrueTypeFontUnicode {
    private var baseFont: TrueTypeFont
    private var verticalSubstitutions: HashMap<UInt16, UInt16> = HashMap<UInt16, UInt16>()  // 水平 GID -> 垂直 GID
    private var isVertical: Bool = false

    /**
     * 构造函数
     * @param font 基础 TrueType 字体
     * @param vertical 是否为垂直书写模式
     */
    public init(font: TrueTypeFont, vertical: Bool) {
        this.baseFont = font
        this.isVertical = vertical

        if (vertical) {
            // 如果是垂直模式，尝试加载垂直替换表
            loadVerticalSubstitutions()
        }
    }

    /**
     * 创建水平书写的 Unicode 字体
     */
    public static func createHorizontal(font: TrueTypeFont): TrueTypeFontUnicode {
        TrueTypeFontUnicode(font, false)
    }

    /**
     * 创建垂直书写的 Unicode 字体
     */
    public static func createVertical(font: TrueTypeFont): TrueTypeFontUnicode {
        TrueTypeFontUnicode(font, true)
    }

    /**
     * 加载垂直书写的字形替换
     * 从 GSUB 表或 vhea/vmtx 表加载
     */
    private func loadVerticalSubstitutions(): Unit {
        // 简化实现：暂不加载
        // 实际应该：
        // 1. 检查 GSUB 表中的 'vert' 特性
        // 2. 或检查 vhea/vmtx 表
        // 3. 建立水平字形到垂直字形的映射
    }

    /**
     * 获取字形 ID（考虑垂直模式）
     * @param unicode Unicode 码点
     * @return 字形 ID
     */
    public func getGlyphId(unicode: UInt32): UInt16 {
        let gid = baseFont.getGlyphId(unicode)

        if (isVertical) {
            // 如果是垂直模式，尝试获取垂直替换字形
            match (verticalSubstitutions.get(gid)) {
                case Some(vertGid) => return vertGid
                case None => return gid
            }
        }

        gid
    }

    /**
     * 获取字形宽度
     * @param glyphId 字形 ID
     * @return 字形宽度（字体单位）
     */
    public func getGlyphWidth(glyphId: UInt16): Int32 {
        baseFont.getGlyphWidth(glyphId)
    }

    /**
     * 获取字符宽度
     * @param unicode Unicode 码点
     * @return 字符宽度（字体单位）
     */
    public func getCharWidth(unicode: UInt32): Int32 {
        let gid = getGlyphId(unicode)
        getGlyphWidth(gid)
    }

    /**
     * 获取基础字体
     */
    public func getBaseFont(): TrueTypeFont {
        baseFont
    }

    /**
     * 是否为垂直书写模式
     */
    public func isVerticalWriting(): Bool {
        isVertical
    }

    /**
     * 检查 Unicode 字符是否为 CJK 字符
     * @param unicode Unicode 码点
     * @return 是否为 CJK 字符
     */
    public static func isCJKChar(unicode: UInt32): Bool {
        // CJK 统一表意文字基本区：U+4E00 - U+9FFF
        if (unicode >= 0x4E00 && unicode <= 0x9FFF) {
            return true
        }

        // CJK 统一表意文字扩展 A：U+3400 - U+4DBF
        if (unicode >= 0x3400 && unicode <= 0x4DBF) {
            return true
        }

        // CJK 统一表意文字扩展 B：U+20000 - U+2A6DF
        if (unicode >= 0x20000 && unicode <= 0x2A6DF) {
            return true
        }

        // CJK 统一表意文字扩展 C：U+2A700 - U+2B73F
        if (unicode >= 0x2A700 && unicode <= 0x2B73F) {
            return true
        }

        // CJK 统一表意文字扩展 D：U+2B740 - U+2B81F
        if (unicode >= 0x2B740 && unicode <= 0x2B81F) {
            return true
        }

        // CJK 统一表意文字扩展 E：U+2B820 - U+2CEAF
        if (unicode >= 0x2B820 && unicode <= 0x2CEAF) {
            return true
        }

        // CJK 兼容表意文字：U+F900 - U+FAFF
        if (unicode >= 0xF900 && unicode <= 0xFAFF) {
            return true
        }

        // CJK 兼容表意文字补充：U+2F800 - U+2FA1F
        if (unicode >= 0x2F800 && unicode <= 0x2FA1F) {
            return true
        }

        false
    }

    /**
     * 检查 Unicode 字符是否为假名（日文）
     * @param unicode Unicode 码点
     * @return 是否为假名
     */
    public static func isKanaChar(unicode: UInt32): Bool {
        // 平假名：U+3040 - U+309F
        if (unicode >= 0x3040 && unicode <= 0x309F) {
            return true
        }

        // 片假名：U+30A0 - U+30FF
        if (unicode >= 0x30A0 && unicode <= 0x30FF) {
            return true
        }

        // 片假名拼音扩展：U+31F0 - U+31FF
        if (unicode >= 0x31F0 && unicode <= 0x31FF) {
            return true
        }

        false
    }

    /**
     * 检查 Unicode 字符是否为韩文
     * @param unicode Unicode 码点
     * @return 是否为韩文
     */
    public static func isHangulChar(unicode: UInt32): Bool {
        // 韩文音节：U+AC00 - U+D7AF
        if (unicode >= 0xAC00 && unicode <= 0xD7AF) {
            return true
        }

        // 韩文字母：U+1100 - U+11FF
        if (unicode >= 0x1100 && unicode <= 0x11FF) {
            return true
        }

        // 韩文兼容字母：U+3130 - U+318F
        if (unicode >= 0x3130 && unicode <= 0x318F) {
            return true
        }

        // 韩文扩展 A：U+A960 - U+A97F
        if (unicode >= 0xA960 && unicode <= 0xA97F) {
            return true
        }

        // 韩文扩展 B：U+D7B0 - U+D7FF
        if (unicode >= 0xD7B0 && unicode <= 0xD7FF) {
            return true
        }

        false
    }

    /**
     * 检查 Unicode 字符是否为全角标点
     * @param unicode Unicode 码点
     * @return 是否为全角标点
     */
    public static func isFullwidthPunctuation(unicode: UInt32): Bool {
        // CJK 符号和标点：U+3000 - U+303F
        if (unicode >= 0x3000 && unicode <= 0x303F) {
            return true
        }

        // 全角 ASCII 变体：U+FF00 - U+FFEF
        if (unicode >= 0xFF00 && unicode <= 0xFFEF) {
            return true
        }

        false
    }

    /**
     * 获取字符的脚本类型
     */
    public static func getCharScript(unicode: UInt32): CharScript {
        if (isCJKChar(unicode)) {
            return CharScript.CJK
        } else if (isKanaChar(unicode)) {
            return CharScript.Kana
        } else if (isHangulChar(unicode)) {
            return CharScript.Hangul
        } else if (isFullwidthPunctuation(unicode)) {
            return CharScript.FullwidthPunctuation
        } else if (unicode < 0x80) {
            return CharScript.Latin
        } else {
            return CharScript.Other
        }
    }
}

/**
 * 字符脚本类型枚举
 */
public enum CharScript {
    | Latin                // 拉丁字符
    | CJK                  // CJK 统一表意文字
    | Kana                 // 日文假名
    | Hangul               // 韩文
    | FullwidthPunctuation // 全角标点
    | Other                // 其他
}

/**
 * Unicode 字体工具类
 */
public class UnicodeFontUtil {
    /**
     * 检查字符串是否主要包含 CJK 字符
     * @param text 文本
     * @return 如果 CJK 字符占比超过 50% 返回 true
     */
    public static func isCJKText(text: String): Bool {
        var cjkCount: Int64 = 0
        var totalCount: Int64 = 0

        for (ch in text) {
            let unicode = UInt32(Int64(ch))
            totalCount += 1

            if (TrueTypeFontUnicode.isCJKChar(unicode)) {
                cjkCount += 1
            }
        }

        if (totalCount == 0) {
            return false
        }

        // CJK 字符占比超过 50%
        (cjkCount * 2) > totalCount
    }

    /**
     * 获取推荐的文本方向
     * @param text 文本
     * @return 推荐的方向（水平或垂直）
     */
    public static func getRecommendedDirection(text: String): TextDirection {
        // 简化实现：默认水平
        // 实际应该根据文本内容和语言判断
        TextDirection.Horizontal
    }

    /**
     * 将 Unicode 字符串转换为 UTF-16BE 字节数组（PDF 常用）
     * @param text Unicode 字符串
     * @return UTF-16BE 字节数组
     */
    public static func toUTF16BE(text: String): Array<UInt8> {
        var result = ArrayList<UInt8>()

        // 添加 BOM (Byte Order Mark)
        result.add(UInt8(0xFE))
        result.add(UInt8(0xFF))

        for (ch in text) {
            let codePoint = UInt32(Int64(ch))

            if (codePoint <= 0xFFFF) {
                // BMP 字符，直接编码为 16 位
                result.add(UInt8((codePoint >> 8) & 0xFF))
                result.add(UInt8(codePoint & 0xFF))
            } else {
                // 补充平面字符，编码为代理对
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
}

/**
 * 文本方向枚举
 */
public enum TextDirection {
    | Horizontal  // 水平
    | Vertical    // 垂直
}
