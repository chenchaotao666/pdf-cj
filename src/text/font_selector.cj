/**
 * PDF-CJ: FontSelector - 字体选择器
 * 自动选择合适的字体显示文本
 */
package pdf_cj.text

import std.collection.ArrayList

/**
 * 字体段落
 * 表示使用同一字体的连续文本段
 */
public class FontSegment {
    public let font: ?BaseFont
    public let text: String

    public init(font: ?BaseFont, text: String) {
        this.font = font
        this.text = text
    }

    public func getFont(): ?BaseFont {
        font
    }

    public func getText(): String {
        text
    }

    public func getLength(): Int64 {
        text.size
    }

    public func hasFont(): Bool {
        font.isSome()
    }
}

/**
 * 字体选择器类
 * 维护字体列表，自动选择合适的字体来显示文本
 */
public class FontSelector {
    private var fonts: ArrayList<BaseFont> = ArrayList<BaseFont>()
    private var currentFont: ?BaseFont = None

    public func addFont(font: BaseFont): Unit {
        fonts.add(font)

        if (currentFont.isNone() && fonts.size > 0) {
            currentFont = Some(font)
        }
    }

    public func selectFont(unicode: UInt32): ?BaseFont {
        for (i in 0..fonts.size) {
            let font = fonts[i]
            if (font.hasGlyph(unicode)) {
                return Some(font)
            }
        }
        None
    }

    public func selectFonts(text: String): Array<FontSegment> {
        let segments = ArrayList<FontSegment>()

        if (text.size == 0 || fonts.size == 0) {
            return Array<FontSegment>(0, repeat: FontSegment(None, ""))
        }

        var currentSegmentFont: ?BaseFont = None
        var currentSegmentText = ""

        for (ch in text) {
            let unicode = UInt32(Int64(ch))
            let selectedFont = selectFont(unicode)

            // 检查是否需要开始新段落
            var needNewSegment = false
            match (currentSegmentFont) {
                case Some(cf) =>
                    match (selectedFont) {
                        case Some(sf) => needNewSegment = !areSameFont(cf, sf)
                        case None => needNewSegment = true
                    }
                case None =>
                    needNewSegment = selectedFont.isSome()
            }

            if (needNewSegment && currentSegmentText.size > 0) {
                segments.add(FontSegment(currentSegmentFont, currentSegmentText))
                currentSegmentText = ""
            }

            currentSegmentFont = selectedFont
            currentSegmentText = "${currentSegmentText}${ch}"
        }

        if (currentSegmentText.size > 0) {
            segments.add(FontSegment(currentSegmentFont, currentSegmentText))
        }

        let arr = Array<FontSegment>(segments.size, repeat: FontSegment(None, ""))
        for (i in 0..segments.size) {
            arr[i] = segments[i]
        }
        arr
    }

    private func areSameFont(font1: BaseFont, font2: BaseFont): Bool {
        font1.name == font2.name
    }

    public func getFontCount(): Int64 {
        fonts.size
    }

    public func getFonts(): Array<BaseFont> {
        if (fonts.size == 0) {
            return Array<BaseFont>(0, repeat: BaseFont.createFont())
        }
        let arr = Array<BaseFont>(fonts.size, repeat: fonts[0])
        for (i in 0..fonts.size) {
            arr[i] = fonts[i]
        }
        arr
    }

    public func clearFonts(): Unit {
        fonts.clear()
        currentFont = None
    }

    public func getCurrentFont(): ?BaseFont {
        currentFont
    }

    public func setCurrentFont(font: BaseFont): Unit {
        currentFont = Some(font)
    }
}

/**
 * 字体选择策略
 */
public enum FontSelectionStrategy {
    | FirstMatch
    | BestMatch
    | PreferCJK
    | PreferLatin
}

/**
 * 字体选择器工具类
 */
public class FontSelectorUtil {
    public static func createDefault(): FontSelector {
        let selector = FontSelector()
        selector.addFont(BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI))
        selector
    }
}
