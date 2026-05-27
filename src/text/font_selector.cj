/**
 * PDF-CJ: FontSegment - 字体分段
 * 表示使用同一字体的连续文本段，由 FontSelector 生成
 */
package pdf_cj.text

public class FontSegment {
    public let font: ?BaseFont
    public let text: String

    public init(font: ?BaseFont, text: String) {
        this.font = font
        this.text = text
    }

    public func getFont(): ?BaseFont { font }
    public func getText(): String { text }
    public func hasFont(): Bool { font.isSome() }
}
