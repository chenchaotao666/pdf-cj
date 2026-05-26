/**
 * PDF-CJ: PdfPCell - PDF 表格单元格
 * 表格的单元格，支持内容、边框、背景色等属性
 */
package pdf_cj.table

import std.collection.ArrayList
import pdf_cj.api.{Element, ElementType, ElementListener, Chunk, Phrase, Paragraph}
import pdf_cj.text.{Color, Alignment, Border, VerticalAlignment}

/**
 * PdfPCell 类 - PDF 表格单元格
 * 支持文本、边框、背景色、对齐方式等
 */
public class PdfPCell <: Element {
    // 内容
    private var _content: ArrayList<Element> = ArrayList<Element>()
    private var _phrase: ?Phrase = None

    // 边框属性
    private var _border: Int32 = Border.BOX
    private var _borderWidth: Float32 = 0.5
    private var _borderColor: ?Color = None

    // 背景
    private var _backgroundColor: ?Color = None

    // 对齐方式
    private var _horizontalAlignment: Alignment = Alignment.Left
    private var _verticalAlignment: VerticalAlignment = VerticalAlignment.Top

    // 内边距
    private var _padding: Float32 = 2.0
    private var _paddingLeft: Float32 = 2.0
    private var _paddingRight: Float32 = 2.0
    private var _paddingTop: Float32 = 2.0
    private var _paddingBottom: Float32 = 2.0
    private var _useBorderPadding: Bool = false

    // 跨行跨列
    private var _colspan: Int32 = 1
    private var _rowspan: Int32 = 1

    // 尺寸
    private var _fixedHeight: Float32 = 0.0
    private var _minimumHeight: Float32 = 0.0
    private var _noWrap: Bool = false

    /**
     * 创建空单元格
     */
    public init() {}

    /**
     * 使用 Phrase 创建单元格
     */
    public init(phrase: Phrase) {
        this._phrase = Some(phrase)
    }

    /**
     * 使用 Paragraph 创建单元格
     * 与 OpenPDF 一致：构造器传入的单个 Paragraph 走 simple mode（高度=font.size）
     * 通过 addElement() 添加的多段落走 composite mode（高度=leading）
     */
    public init(paragraph: Paragraph) {
        this._phrase = Some(paragraph)
    }

    /**
     * 使用文本创建单元格
     */
    public init(text: String) {
        this._phrase = Some(Phrase(text))
    }

    // ===== 内容管理 =====

    /**
     * 添加元素到单元格
     */
    public func addElement(element: Element): Unit {
        _content.add(element)
    }

    /**
     * 设置 Phrase
     */
    public func setPhrase(phrase: Phrase): Unit {
        this._phrase = Some(phrase)
    }

    /**
     * 获取 Phrase
     */
    public prop phrase: ?Phrase {
        get() { _phrase }
    }

    // ===== 边框设置 =====

    /**
     * 设置边框
     */
    public func setBorder(border: Int32): Unit {
        this._border = border
    }

    /**
     * 获取边框
     */
    public prop border: Int32 {
        get() { _border }
    }

    /**
     * 设置边框宽度
     */
    public func setBorderWidth(width: Float32): Unit {
        this._borderWidth = width
    }

    /**
     * 获取边框宽度
     */
    public prop borderWidth: Float32 {
        get() { _borderWidth }
    }

    /**
     * 设置边框颜色
     */
    public func setBorderColor(color: Color): Unit {
        this._borderColor = Some(color)
    }

    /**
     * 获取边框颜色
     */
    public prop borderColor: ?Color {
        get() { _borderColor }
    }

    /**
     * 禁用指定边
     */
    public func disableBorderSide(side: Int32): Unit {
        this._border = this._border & (this._border ^ side)
    }

    /**
     * 启用指定边
     */
    public func enableBorderSide(side: Int32): Unit {
        this._border = this._border | side
    }

    // ===== 背景设置 =====

    /**
     * 设置背景色
     */
    public func setBackgroundColor(color: Color): Unit {
        this._backgroundColor = Some(color)
    }

    /**
     * 获取背景色
     */
    public prop backgroundColor: ?Color {
        get() { _backgroundColor }
    }

    // ===== 对齐方式 =====

    /**
     * 设置水平对齐
     */
    public func setHorizontalAlignment(alignment: Alignment): Unit {
        this._horizontalAlignment = alignment
    }

    /**
     * 设置水平对齐（整数）
     */
    public func setHorizontalAlignment(alignment: Int32): Unit {
        this._horizontalAlignment = Alignment.fromInt(alignment)
    }

    /**
     * 获取水平对齐
     */
    public prop horizontalAlignment: Alignment {
        get() { _horizontalAlignment }
    }

    /**
     * 设置垂直对齐
     */
    public func setVerticalAlignment(alignment: VerticalAlignment): Unit {
        this._verticalAlignment = alignment
    }

    /**
     * 设置垂直对齐（整数）
     */
    public func setVerticalAlignment(alignment: Int32): Unit {
        this._verticalAlignment = VerticalAlignment.fromInt(alignment)
    }

    /**
     * 获取垂直对齐
     */
    public prop verticalAlignment: VerticalAlignment {
        get() { _verticalAlignment }
    }

    // ===== 内边距设置 =====

    /**
     * 设置统一内边距
     */
    public func setPadding(padding: Float32): Unit {
        this._padding = padding
        this._paddingLeft = padding
        this._paddingRight = padding
        this._paddingTop = padding
        this._paddingBottom = padding
    }

    /**
     * 获取内边距
     */
    public prop padding: Float32 {
        get() { _padding }
    }

    /**
     * 设置左内边距
     */
    public func setPaddingLeft(padding: Float32): Unit {
        this._paddingLeft = padding
    }

    /**
     * 设置右内边距
     */
    public func setPaddingRight(padding: Float32): Unit {
        this._paddingRight = padding
    }

    /**
     * 设置上内边距
     */
    public func setPaddingTop(padding: Float32): Unit {
        this._paddingTop = padding
    }

    /**
     * 设置下内边距
     */
    public func setPaddingBottom(padding: Float32): Unit {
        this._paddingBottom = padding
    }

    /**
     * 获取左内边距
     */
    public prop paddingLeft: Float32 {
        get() { _paddingLeft }
    }

    /**
     * 获取右内边距
     */
    public prop paddingRight: Float32 {
        get() { _paddingRight }
    }

    /**
     * 获取上内边距
     */
    public prop paddingTop: Float32 {
        get() { _paddingTop }
    }

    /**
     * 获取下内边距
     */
    public prop paddingBottom: Float32 {
        get() { _paddingBottom }
    }

    /**
     * 设置是否使用边框内边距
     */
    public func setUseBorderPadding(use: Bool): Unit {
        this._useBorderPadding = use
    }

    /**
     * 获取是否使用边框内边距
     */
    public prop useBorderPadding: Bool {
        get() { _useBorderPadding }
    }

    // ===== 跨行跨列 =====

    /**
     * 设置列跨度
     */
    public func setColspan(colspan: Int32): Unit {
        this._colspan = colspan
    }

    /**
     * 获取列跨度
     */
    public prop colspan: Int32 {
        get() { _colspan }
    }

    /**
     * 设置行跨度
     */
    public func setRowspan(rowspan: Int32): Unit {
        this._rowspan = rowspan
    }

    /**
     * 获取行跨度
     */
    public prop rowspan: Int32 {
        get() { _rowspan }
    }

    // ===== 高度设置 =====

    /**
     * 设置固定高度
     */
    public func setFixedHeight(height: Float32): Unit {
        this._fixedHeight = height
    }

    /**
     * 获取固定高度
     */
    public prop fixedHeight: Float32 {
        get() { _fixedHeight }
    }

    /**
     * 设置最小高度
     */
    public func setMinimumHeight(height: Float32): Unit {
        this._minimumHeight = height
    }

    /**
     * 获取最小高度
     */
    public prop minimumHeight: Float32 {
        get() { _minimumHeight }
    }

    /**
     * 设置是否禁止换行
     */
    public func setNoWrap(noWrap: Bool): Unit {
        this._noWrap = noWrap
    }

    /**
     * 获取是否禁止换行
     */
    public prop noWrap: Bool {
        get() { _noWrap }
    }

    /**
     * 计算单元格高度（考虑文本换行）
     */
    public func calculateHeight(cellWidth: Float32): Float32 {
        if (_fixedHeight > 0.0) {
            return _fixedHeight
        }

        let availW = cellWidth - _paddingLeft - _paddingRight
        var height: Float32 = _paddingTop + _paddingBottom

        match (_phrase) {
            case Some(p) =>
                // 与 OpenPDF 一致：单行高度 = font.size，多行高度 = lines * leading
                let fontSize = p.font.size
                height += estimateWrappedHeight(p.getWidth(), fontSize, p.leading, availW)
            case None => ()
        }

        // composite mode（via addElement）：每个段落用 leading 计算高度，与 OpenPDF 一致
        var i: Int64 = 0
        while (i < _content.size) {
            match (_content[i]) {
                case para: Paragraph =>
                    height += para.spacingBefore
                    height += estimateWrappedHeight(para.getWidth(), para.leading, para.leading, availW)
                    height += para.spacingAfter
                case _ =>
                    height += 14.0
            }
            i += 1
        }

        if (height < _minimumHeight) {
            height = _minimumHeight
        }
        if (height < 14.0) {
            height = 14.0
        }
        height
    }

    // 单行高度 = fontSize，多行高度 = lines * leading（与 OpenPDF 一致）
    private func estimateWrappedHeight(textWidth: Float32, fontSize: Float32, leading: Float32, availWidth: Float32): Float32 {
        if (availWidth <= 0.0 || textWidth <= 0.0) {
            return fontSize
        }
        if (textWidth <= availWidth) {
            return fontSize
        }
        let lines = Float32(Int64(textWidth / availWidth)) + 1.0
        // 首行用 fontSize，后续行用 leading
        fontSize + (lines - 1.0) * leading
    }

    // ===== Element 接口实现 =====

    public func getType(): ElementType {
        ElementType.Cell
    }

    public func getChunks(): ArrayList<Chunk> {
        let result = ArrayList<Chunk>()

        // 添加 Phrase 的 Chunks
        match (_phrase) {
            case Some(p) => addPhraseChunks(p, result)
            case None => ()
        }

        // 添加内容元素的 Chunks
        for (elem in _content) {
            addElementChunks(elem, result)
        }

        result
    }

    private func addPhraseChunks(phrase: Phrase, result: ArrayList<Chunk>): Unit {
        for (chunk in phrase.getChunks()) {
            result.add(chunk)
        }
    }

    private func addElementChunks(element: Element, result: ArrayList<Chunk>): Unit {
        for (chunk in element.getChunks()) {
            result.add(chunk)
        }
    }

    public func isContent(): Bool {
        true
    }

    public func isNestable(): Bool {
        false
    }

    public func process(listener: ElementListener): Bool {
        listener.add(this)
    }

    /**
     * 获取内容元素数量
     */
    public prop contentSize: Int64 {
        get() { _content.size }
    }

    /**
     * 获取指定索引的内容元素
     */
    public func getContentElement(index: Int64): Element {
        _content[index]
    }
}
