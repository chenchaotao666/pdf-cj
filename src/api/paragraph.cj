/**
 * PDF-CJ: Paragraph - 段落
 * 表示文档中的段落，支持对齐、缩进等格式
 */
package pdf_cj.api

import std.collection.ArrayList
import pdf_cj.text.{Font, Alignment}

/**
 * Paragraph 类 - 段落
 * 继承自 Phrase，增加段落特有的格式属性
 */
public class Paragraph <: Phrase {
    private var _alignment: Alignment = Alignment.Left
    private var _indentationLeft: Float32 = 0.0
    private var _indentationRight: Float32 = 0.0
    private var _firstLineIndent: Float32 = 0.0
    private var _spacingBefore: Float32 = 0.0
    private var _spacingAfter: Float32 = 0.0
    private var _keepTogether: Bool = false
    private var _extraParagraphSpace: Float32 = 0.0

    /**
     * 创建空段落
     */
    public init() {
        super()
    }

    /**
     * 使用文本创建段落
     */
    public init(text: String) {
        super(text)
    }

    /**
     * 使用文本和字体创建段落
     */
    public init(text: String, font: Font) {
        super(text, font)
    }

    /**
     * 使用行距创建段落
     */
    public init(leading: Float32) {
        super(leading)
    }

    /**
     * 使用行距和文本创建段落
     */
    public init(leading: Float32, text: String) {
        super(leading, text)
    }

    /**
     * 使用行距、文本和字体创建段落
     */
    public init(leading: Float32, text: String, font: Font) {
        super(leading, text, font)
    }

    /**
     * 使用 Chunk 创建段落
     */
    public init(chunk: Chunk) {
        super()
        this._leading = chunk.font.size * DEFAULT_LEADING_MULTIPLIER
        add(chunk)
    }

    /**
     * 使用 Phrase 创建段落
     */
    public init(phrase: Phrase) {
        super()
        this._leading = phrase.leading
        this._font = phrase.font
        for (chunk in phrase.getChunks()) {
            add(chunk)
        }
    }

    // ===== 对齐设置 =====

    /**
     * 获取对齐方式
     */
    public prop alignment: Alignment {
        get() { _alignment }
    }

    /**
     * 设置对齐方式
     */
    public func setAlignment(alignment: Alignment): Unit {
        this._alignment = alignment
    }

    /**
     * 设置对齐方式（整数值，兼容 OpenPDF）
     */
    public func setAlignment(alignment: Int32): Unit {
        this._alignment = Alignment.fromInt(alignment)
    }

    // ===== 缩进设置 =====

    /**
     * 获取左缩进
     */
    public prop indentationLeft: Float32 {
        get() { _indentationLeft }
    }

    /**
     * 设置左缩进
     */
    public func setIndentationLeft(indentation: Float32): Unit {
        this._indentationLeft = indentation
    }

    /**
     * 获取右缩进
     */
    public prop indentationRight: Float32 {
        get() { _indentationRight }
    }

    /**
     * 设置右缩进
     */
    public func setIndentationRight(indentation: Float32): Unit {
        this._indentationRight = indentation
    }

    /**
     * 获取首行缩进
     */
    public prop firstLineIndent: Float32 {
        get() { _firstLineIndent }
    }

    /**
     * 设置首行缩进
     */
    public func setFirstLineIndent(indent: Float32): Unit {
        this._firstLineIndent = indent
    }

    // ===== 间距设置 =====

    /**
     * 获取段前间距
     */
    public prop spacingBefore: Float32 {
        get() { _spacingBefore }
    }

    /**
     * 设置段前间距
     */
    public func setSpacingBefore(spacing: Float32): Unit {
        this._spacingBefore = spacing
    }

    /**
     * 获取段后间距
     */
    public prop spacingAfter: Float32 {
        get() { _spacingAfter }
    }

    /**
     * 设置段后间距
     */
    public func setSpacingAfter(spacing: Float32): Unit {
        this._spacingAfter = spacing
    }

    /**
     * 设置段落间距（同时设置段前和段后）
     */
    public func setSpacing(spacing: Float32): Unit {
        this._spacingBefore = spacing
        this._spacingAfter = spacing
    }

    // ===== 其他设置 =====

    /**
     * 是否保持段落在同一页
     */
    public prop keepTogether: Bool {
        get() { _keepTogether }
    }

    /**
     * 设置是否保持段落在同一页
     */
    public func setKeepTogether(keep: Bool): Unit {
        this._keepTogether = keep
    }

    /**
     * 获取额外段落间距
     */
    public prop extraParagraphSpace: Float32 {
        get() { _extraParagraphSpace }
    }

    /**
     * 设置额外段落间距
     */
    public func setExtraParagraphSpace(space: Float32): Unit {
        this._extraParagraphSpace = space
    }

    // ===== Element 接口实现 =====

    public override func getType(): ElementType {
        ElementType.Paragraph
    }

    /**
     * 设置固定行距 + 倍数行距（对标 OpenPDF Paragraph.setLeading(fixedLeading, multipliedLeading)）
     */
    public func setLeading(fixedLeading: Float32, multiplier: Float32): Unit {
        this._leading = fixedLeading + _font.size * multiplier
    }

    /**
     * 设置倍数行距
     */
    public func setMultipliedLeading(multiplier: Float32): Unit {
        this._leading = _font.size * multiplier
    }

    /**
     * 获取段落总高度（估算）
     */
    public func getTotalHeight(): Float32 {
        // 简化计算：行数 * 行高 + 段前间距 + 段后间距
        let lineCount = estimateLineCount()
        lineCount * _leading + _spacingBefore + _spacingAfter
    }

    /**
     * 估算行数
     */
    private func estimateLineCount(): Float32 {
        // 简化实现：假设平均每行50个字符
        let content = getContent()
        let charCount = content.size
        if (charCount == 0) {
            1.0
        } else {
            Float32(charCount) / 50.0 + 1.0
        }
    }
}
