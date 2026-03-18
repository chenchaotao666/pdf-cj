/**
 * PDF-CJ: HeaderFooter - 页眉页脚
 * 用于设置文档的页眉和页脚
 */
package pdf_cj.api

import pdf_cj.text.{Font, Alignment, Border}

/**
 * HeaderFooter 类 - 页眉页脚
 */
public class HeaderFooter {
    private var _before: ?Phrase = None
    private var _after: ?Phrase = None
    private var _numbered: Bool = false
    private var _alignment: Alignment = Alignment.Center
    private var _border: Int32 = Border.TOP + Border.BOTTOM
    private var _borderWidth: Float32 = 1.0

    /**
     * 创建不带页码的页眉/页脚
     */
    public init(phrase: Phrase) {
        this._before = Some(phrase)
        this._numbered = false
    }

    /**
     * 创建带页码的页眉/页脚
     * @param before 页码前的文本
     * @param numbered 是否显示页码
     */
    public init(before: Phrase, numbered: Bool) {
        this._before = Some(before)
        this._numbered = numbered
    }

    /**
     * 创建带页码和后缀的页眉/页脚
     * @param numbered 是否显示页码
     * @param after 页码后的文本
     */
    public init(numbered: Bool, after: Phrase) {
        this._numbered = numbered
        this._after = Some(after)
    }

    /**
     * 创建带前缀和后缀的页眉/页脚
     * @param before 页码前的文本
     * @param numbered 是否显示页码
     * @param after 页码后的文本
     */
    public init(before: Phrase, numbered: Bool, after: Phrase) {
        this._before = Some(before)
        this._numbered = numbered
        this._after = Some(after)
    }

    /**
     * 获取前缀短语
     */
    public prop before: ?Phrase {
        get() { _before }
    }

    /**
     * 获取后缀短语
     */
    public prop after: ?Phrase {
        get() { _after }
    }

    /**
     * 是否显示页码
     */
    public prop isNumbered: Bool {
        get() { _numbered }
    }

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
     * 设置对齐方式（整数值）
     */
    public func setAlignment(alignment: Int32): Unit {
        this._alignment = Alignment.fromInt(alignment)
    }

    /**
     * 获取边框
     */
    public prop border: Int32 {
        get() { _border }
    }

    /**
     * 设置边框
     */
    public func setBorder(border: Int32): Unit {
        this._border = border
    }

    /**
     * 禁用边框
     */
    public func disableBorderSide(side: Int32): Unit {
        // 使用 XOR 和 AND 来清除指定位
        this._border = this._border & (this._border ^ side)
    }

    /**
     * 获取边框宽度
     */
    public prop borderWidth: Float32 {
        get() { _borderWidth }
    }

    /**
     * 设置边框宽度
     */
    public func setBorderWidth(width: Float32): Unit {
        this._borderWidth = width
    }

    /**
     * 生成带页码的完整短语
     * @param pageNumber 当前页码
     */
    public func getCompletePhrase(pageNumber: Int32): Phrase {
        let result = Phrase()

        // 添加前缀
        match (_before) {
            case Some(b) => addPhraseChunks(b, result)
            case None => ()
        }

        // 添加页码
        if (_numbered) {
            result.add("${pageNumber}")
        }

        // 添加后缀
        match (_after) {
            case Some(a) => addPhraseChunks(a, result)
            case None => ()
        }

        result
    }

    private func addPhraseChunks(phrase: Phrase, target: Phrase): Unit {
        for (chunk in phrase.getChunks()) {
            target.addChunk(chunk)
        }
    }
}
