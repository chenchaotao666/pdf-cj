/**
 * PDF-CJ: ColumnText - 文本定位工具
 * 用于在指定区域内排列文本
 */
package pdf_cj.core

import std.collection.ArrayList
import pdf_cj.api.{Element, Paragraph, Phrase, Chunk}
import pdf_cj.text.{Alignment, Font}
import pdf_cj.util.Rectangle

/**
 * 列文本类
 * 用于在指定矩形区域内排版文本
 */
public class ColumnText {
    private var _canvas: PdfContentByte
    private var _simpleColumn: Bool = true

    // 列边界
    private var _llx: Float32 = 0.0
    private var _lly: Float32 = 0.0
    private var _urx: Float32 = 0.0
    private var _ury: Float32 = 0.0

    // 当前位置
    private var _currentY: Float32 = 0.0

    // 文本属性
    private var _alignment: Alignment = Alignment.Left
    private var _leading: Float32 = 0.0
    private var _fixedLeading: Float32 = 0.0
    private var _multipliedLeading: Float32 = 1.0
    private var _indent: Float32 = 0.0
    private var _followingIndent: Float32 = 0.0
    private var _rightIndent: Float32 = 0.0
    private var _extraParagraphSpace: Float32 = 0.0
    private var _spaceCharRatio: Float32 = 1.0

    // 待排版内容
    private var _compositeElements: ArrayList<Element> = ArrayList<Element>()

    // 状态常量
    public static let NO_MORE_TEXT: Int32 = 0
    public static let NO_MORE_COLUMN: Int32 = 1
    private static let CONTINUE_PROCESSING: Int32 = 2

    public init(canvas: PdfContentByte) {
        this._canvas = canvas
    }

    /**
     * 设置简单列模式的边界
     */
    public func setSimpleColumn(llx: Float32, lly: Float32, urx: Float32, ury: Float32): Unit {
        _llx = llx
        _lly = lly
        _urx = urx
        _ury = ury
        _currentY = ury
        _simpleColumn = true
    }

    /**
     * 设置简单列模式的边界（使用矩形）
     */
    public func setSimpleColumn(rect: Rectangle): Unit {
        setSimpleColumn(rect.left, rect.bottom, rect.right, rect.top)
    }

    /**
     * 设置简单列模式的边界（带对齐和行距）
     */
    public func setSimpleColumn(llx: Float32, lly: Float32, urx: Float32, ury: Float32,
                                 leading: Float32, alignment: Alignment): Unit {
        setSimpleColumn(llx, lly, urx, ury)
        _leading = leading
        _alignment = alignment
    }

    /**
     * 添加元素
     */
    public func addElement(element: Element): Unit {
        _compositeElements.add(element)
    }

    /**
     * 添加文本
     */
    public func addText(phrase: Phrase): Unit {
        _compositeElements.add(phrase)
    }

    /**
     * 设置文本
     */
    public func setText(phrase: Phrase): Unit {
        _compositeElements.clear()
        _compositeElements.add(phrase)
    }

    /**
     * 执行排版
     * @return NO_MORE_TEXT 或 NO_MORE_COLUMN
     */
    public func go(): Int32 {
        goComposite(false)
    }

    /**
     * 模拟排版（不实际绘制）
     * @return NO_MORE_TEXT 或 NO_MORE_COLUMN
     */
    public func goSimulate(): Int32 {
        goComposite(true)
    }

    /**
     * 执行复合元素排版
     */
    private func goComposite(simulate: Bool): Int32 {
        if (_compositeElements.isEmpty()) {
            return NO_MORE_TEXT
        }

        let width = _urx - _llx - _indent - _followingIndent - _rightIndent

        while (!_compositeElements.isEmpty()) {
            let element = _compositeElements[0]

            let status = match (element.getType()) {
                case Paragraph => handleParagraphElement(element, simulate)
                case Phrase => handlePhraseElement(element, simulate)
                case _ => handleUnknownElement(element)
            }

            if (status != CONTINUE_PROCESSING) {
                return status
            }
        }

        NO_MORE_TEXT
    }

    /**
     * 处理段落元素
     */
    private func handleParagraphElement(element: Element, simulate: Bool): Int32 {
        match (element) {
            case para: Paragraph => processParagraph(para, simulate)
            case _ => removeAndContinue()
        }
    }

    /**
     * 处理短语元素
     */
    private func handlePhraseElement(element: Element, simulate: Bool): Int32 {
        match (element) {
            case phrase: Phrase => processPhrase(phrase, simulate)
            case _ => removeAndContinue()
        }
    }

    /**
     * 处理未知元素
     */
    private func handleUnknownElement(element: Element): Int32 {
        removeAndContinue()
    }

    /**
     * 处理段落
     */
    private func processParagraph(para: Paragraph, simulate: Bool): Int32 {
        let lineHeight = if (_leading > 0.0) {
            _leading
        } else {
            para.leading
        }

        // 检查是否有足够空间
        if (_currentY - lineHeight < _lly) {
            return NO_MORE_COLUMN
        }

        // 排版段落
        if (!simulate) {
            drawParagraph(para)
        }

        _currentY -= lineHeight
        _compositeElements.remove(0..1)
        CONTINUE_PROCESSING
    }

    /**
     * 处理短语
     */
    private func processPhrase(phrase: Phrase, simulate: Bool): Int32 {
        let lineHeight = if (_leading > 0.0) {
            _leading
        } else {
            phrase.leading
        }

        if (_currentY - lineHeight < _lly) {
            return NO_MORE_COLUMN
        }

        if (!simulate) {
            drawPhrase(phrase)
        }

        _currentY -= lineHeight
        _compositeElements.remove(0..1)
        CONTINUE_PROCESSING
    }

    /**
     * 移除当前元素并继续处理
     */
    private func removeAndContinue(): Int32 {
        _compositeElements.remove(0..1)
        CONTINUE_PROCESSING
    }

    /**
     * 绘制段落
     */
    private func drawParagraph(para: Paragraph): Unit {
        let x = _llx + _indent + para.firstLineIndent
        _canvas.beginText()
        _canvas.setTextMatrix(x, _currentY)

        for (chunk in para.getChunks()) {
            let font = chunk.font
            let baseFont = font.getCalculatedBaseFont()

            // 应用颜色（如果有）
            match (chunk.color) {
                case Some(color) => _canvas.setColorFill(color)
                case None => ()
            }

            // 获取并使用正确的字体名称
            let fontName = _canvas.getWriter().addFont(baseFont)
            _canvas.setFontAndSize(fontName, font.size)
            _canvas.showText(chunk.content)
        }

        _canvas.endText()
    }

    /**
     * 绘制短语
     */
    private func drawPhrase(phrase: Phrase): Unit {
        let x = _llx + _indent
        _canvas.beginText()
        _canvas.setTextMatrix(x, _currentY)

        for (chunk in phrase.getChunks()) {
            let font = chunk.font
            let baseFont = font.getCalculatedBaseFont()

            // 应用颜色（如果有）
            match (chunk.color) {
                case Some(color) => _canvas.setColorFill(color)
                case None => ()
            }

            // 获取并使用正确的字体名称
            let fontName = _canvas.getWriter().addFont(baseFont)
            _canvas.setFontAndSize(fontName, font.size)
            _canvas.showText(chunk.content)
        }

        _canvas.endText()
    }

    // ===== 属性访问器 =====

    /**
     * 获取/设置对齐方式
     */
    public prop alignment: Alignment {
        get() { _alignment }
    }

    public func setAlignment(alignment: Alignment): Unit {
        _alignment = alignment
    }

    /**
     * 获取/设置行距
     */
    public prop leading: Float32 {
        get() { _leading }
    }

    public func setLeading(leading: Float32): Unit {
        _leading = leading
    }

    public func setLeading(fixedLeading: Float32, multipliedLeading: Float32): Unit {
        _fixedLeading = fixedLeading
        _multipliedLeading = multipliedLeading
    }

    /**
     * 获取/设置缩进
     */
    public prop indent: Float32 {
        get() { _indent }
    }

    public func setIndent(indent: Float32): Unit {
        _indent = indent
    }

    public prop followingIndent: Float32 {
        get() { _followingIndent }
    }

    public func setFollowingIndent(indent: Float32): Unit {
        _followingIndent = indent
    }

    public prop rightIndent: Float32 {
        get() { _rightIndent }
    }

    public func setRightIndent(indent: Float32): Unit {
        _rightIndent = indent
    }

    /**
     * 获取当前 Y 位置
     */
    public prop yLine: Float32 {
        get() { _currentY }
    }

    public func setYLine(y: Float32): Unit {
        _currentY = y
    }

    /**
     * 检查是否还有更多文本
     */
    public func hasMoreText(): Bool {
        !_compositeElements.isEmpty()
    }

    /**
     * 获取剩余文本的估计高度
     */
    public func getFilledHeight(): Float32 {
        _ury - _currentY
    }
}
