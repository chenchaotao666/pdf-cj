/**
 * PDF-CJ: FontSelector - 字体选择器
 * 对标 OpenPDF FontSelector：addFont(Font) + process(String): Phrase
 * 自动根据字符的字形覆盖情况选择合适字体，实现 CJK/Latin 混排
 */
package pdf_cj.api

import std.collection.ArrayList
import pdf_cj.text.{BaseFont, Font}

public class FontSelector {
    private var fonts: ArrayList<Font> = ArrayList<Font>()

    public func addFont(font: Font): Unit {
        fonts.add(font)
    }

    // 与 OpenPDF 一致：直接返回 Phrase，无需手动遍历 segments
    public func process(text: String): Phrase {
        let phrase = Phrase()
        if (text.isEmpty() || fonts.size == 0) {
            return phrase
        }

        var curFont: ?Font = None
        var curText = ""

        for (ch in text.runes()) {
            let selected = selectFont(UInt32(ch))

            let sameFont: Bool = match (curFont) {
                case Some(cf) => match (selected) {
                    case Some(sf) =>
                        cf.getCalculatedBaseFont().name == sf.getCalculatedBaseFont().name
                    case None => false
                }
                case None => selected.isNone()
            }

            if (!sameFont && !curText.isEmpty()) {
                _ = phrase.add(buildChunk(curText, curFont))
                curText = ""
            }

            curFont = selected
            curText = curText + String([ch])
        }

        if (!curText.isEmpty()) {
            _ = phrase.add(buildChunk(curText, curFont))
        }

        phrase
    }

    private func selectFont(unicode: UInt32): ?Font {
        for (i in 0..fonts.size) {
            let f = fonts[i]
            if (f.getCalculatedBaseFont().hasGlyph(unicode)) {
                return Some(f)
            }
        }
        None
    }

    private func buildChunk(text: String, font: ?Font): Chunk {
        match (font) {
            case Some(f) => Chunk(text, f)
            case None => Chunk(text)
        }
    }
}
