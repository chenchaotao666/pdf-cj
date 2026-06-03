/**
 * PDF-CJ: ColumnText - 文本定位工具
 * 用于在指定区域内排列文本
 */
package pdf_cj.core

import std.collection.ArrayList
import pdf_cj.api.{Element, Paragraph, Phrase, Chunk}
import pdf_cj.text.{Alignment, Font, Color, BaseFont}
import pdf_cj.util.Rectangle

/**
 * 行内文本段（同一字体/颜色的连续文字）
 */
class TextSegment {
    let text: String
    let font: Font
    let color: ?Color

    init(text: String, font: Font, color: ?Color) {
        this.text = text
        this.font = font
        this.color = color
    }
}

/**
 * 列文本类
 * 用于在指定矩形区域内排版文本，支持多行换行和列溢出处理。
 */
public class ColumnText {
    private var _canvas: PdfContentByte
    private var _simpleColumn: Bool = true

    // 列边界
    private var _llx: Float32 = 0.0
    private var _lly: Float32 = 0.0
    private var _urx: Float32 = 0.0
    private var _ury: Float32 = 0.0

    // 当前排版 Y 位置
    private var _currentY: Float32 = 0.0

    // 文本属性
    private var _alignment: Alignment = Alignment.Left
    private var _leading: Float32 = 0.0
    private var _fixedLeading: Float32 = 0.0
    private var _multipliedLeading: Float32 = 1.0
    private var _indent: Float32 = 0.0
    private var _followingIndent: Float32 = 0.0
    private var _rightIndent: Float32 = 0.0
    private var _spaceCharRatio: Float32 = 1.0

    // 待排版内容队列
    private var _compositeElements: ArrayList<Element> = ArrayList<Element>()

    // go() 返回值
    public static let NO_MORE_TEXT: Int32 = 0
    public static let NO_MORE_COLUMN: Int32 = 1
    private static let CONTINUE_PROCESSING: Int32 = 2

    public init(canvas: PdfContentByte) {
        this._canvas = canvas
    }

    // ───────────────────────────────────────────
    // 列边界设置
    // ───────────────────────────────────────────

    /**
     * 设置列边界（llx/lly 为左下角，urx/ury 为右上角）
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
     * 设置列边界（Rectangle 版本）
     */
    public func setSimpleColumn(rect: Rectangle): Unit {
        setSimpleColumn(rect.left, rect.bottom, rect.right, rect.top)
    }

    /**
     * 设置列边界（带行距和对齐方式）
     */
    public func setSimpleColumn(llx: Float32, lly: Float32, urx: Float32, ury: Float32,
                                 leading: Float32, alignment: Alignment): Unit {
        setSimpleColumn(llx, lly, urx, ury)
        _leading = leading
        _alignment = alignment
    }

    /**
     * 设置列边界（OpenPDF 兼容接口，参数顺序：left, right, bottom, top）
     */
    public func addSimpleColumn(left: Float32, right: Float32, bottom: Float32, top: Float32): Unit {
        setSimpleColumn(left, bottom, right, top)
    }

    // ───────────────────────────────────────────
    // 内容管理
    // ───────────────────────────────────────────

    /**
     * 追加元素到排版队列
     */
    public func addElement(element: Element): Unit {
        _compositeElements.add(element)
    }

    /**
     * 追加 Phrase 到排版队列
     */
    public func addText(phrase: Phrase): Unit {
        _compositeElements.add(phrase)
    }

    /**
     * 清空队列并设置单个 Phrase
     */
    public func setText(phrase: Phrase): Unit {
        _compositeElements.clear()
        _compositeElements.add(phrase)
    }

    // ───────────────────────────────────────────
    // 排版执行
    // ───────────────────────────────────────────

    /**
     * 执行排版并绘制
     * @return NO_MORE_TEXT（所有内容已排完）或 NO_MORE_COLUMN（列空间已满）
     */
    public func go(): Int32 {
        goComposite(false)
    }

    /**
     * 模拟排版（仅推进 Y 位置，不绘制）
     * @return NO_MORE_TEXT 或 NO_MORE_COLUMN
     */
    public func goSimulate(): Int32 {
        goComposite(true)
    }

    private func goComposite(simulate: Bool): Int32 {
        if (_compositeElements.isEmpty()) {
            return NO_MORE_TEXT
        }

        while (!_compositeElements.isEmpty()) {
            let element = _compositeElements[0]
            let status = match (element.getType()) {
                case Paragraph => handleParagraphElement(element, simulate)
                case Phrase => handlePhraseElement(element, simulate)
                case _ => skipUnknownElement()
            }
            if (status != CONTINUE_PROCESSING) {
                return status
            }
        }

        NO_MORE_TEXT
    }

    private func handleParagraphElement(element: Element, simulate: Bool): Int32 {
        match (element) {
            case para: Paragraph => processParagraph(para, simulate)
            case _ => skipUnknownElement()
        }
    }

    private func handlePhraseElement(element: Element, simulate: Bool): Int32 {
        match (element) {
            case phrase: Phrase => processPhrase(phrase, simulate)
            case _ => skipUnknownElement()
        }
    }

    private func skipUnknownElement(): Int32 {
        _compositeElements.remove(0..1)
        CONTINUE_PROCESSING
    }

    // ───────────────────────────────────────────
    // 行构建（字符级换行）
    // ───────────────────────────────────────────

    /**
     * 将段落的所有 Chunk 按列宽分割成行。
     * 每行是一个 ArrayList<TextSegment>，代表该行内来自不同 Chunk 的文本段。
     */
    private func buildLines(para: Paragraph): ArrayList<ArrayList<TextSegment>> {
        let allLines = ArrayList<ArrayList<TextSegment>>()
        var currentLine = ArrayList<TextSegment>()
        var lineWidth: Float32 = 0.0
        var isFirstLine = true

        let leftX  = _llx + _indent + para.indentationLeft
        let rightX = _urx - _rightIndent - para.indentationRight

        for (chunk in para.getChunks()) {
            let font      = chunk.font
            let baseFont  = font.getCalculatedBaseFont()
            let color     = chunk.color
            var segText   = ""
            var segWidth: Float32 = 0.0

            for (r in chunk.content.runes()) {
                let charStr   = String([r])
                let charWidth = baseFont.getWidthPoint(charStr, font.size)
                let availWidth = if (isFirstLine) {
                    rightX - leftX - para.firstLineIndent
                } else {
                    rightX - leftX
                }

                if (lineWidth + segWidth + charWidth > availWidth && lineWidth + segWidth > 0.0) {
                    if (!segText.isEmpty()) {
                        currentLine.add(TextSegment(segText, font, color))
                    }
                    allLines.add(currentLine)
                    currentLine = ArrayList<TextSegment>()
                    lineWidth = 0.0
                    isFirstLine = false
                    segText = charStr
                    segWidth = charWidth
                } else {
                    segText += charStr
                    segWidth += charWidth
                }
            }

            if (!segText.isEmpty()) {
                currentLine.add(TextSegment(segText, font, color))
                lineWidth += segWidth
            }
        }

        if (!currentLine.isEmpty()) {
            allLines.add(currentLine)
        }

        allLines
    }

    // ───────────────────────────────────────────
    // 段落排版（支持溢出截断）
    // ───────────────────────────────────────────

    private func processParagraph(para: Paragraph, simulate: Bool): Int32 {
        let lineHeight = if (_leading > 0.0) { _leading } else { para.leading }
        let leftX      = _llx + _indent + para.indentationLeft

        let allLines = buildLines(para)
        if (allLines.isEmpty()) {
            _compositeElements.remove(0..1)
            return CONTINUE_PROCESSING
        }

        var linesDrawn: Int64 = 0

        for (i in 0..allLines.size) {
            _currentY -= lineHeight
            if (_currentY < _lly) {
                _currentY += lineHeight
                break
            }
            let lineX = if (i == 0) { leftX + para.firstLineIndent } else { leftX }
            if (!simulate) {
                drawLine(allLines[i], lineX, _currentY)
            }
            linesDrawn += 1
        }

        if (linesDrawn == 0) {
            return NO_MORE_COLUMN
        }

        if (linesDrawn == allLines.size) {
            _currentY -= para.spacingAfter
            _compositeElements.remove(0..1)
            return CONTINUE_PROCESSING
        }

        // 部分绘制：把剩余行重建为新 Paragraph，放回队列头部
        let remainPara = Paragraph(lineHeight)
        remainPara.setAlignment(para.alignment)
        remainPara.setIndentationLeft(para.indentationLeft)
        remainPara.setIndentationRight(para.indentationRight)
        remainPara.setSpacingAfter(para.spacingAfter)

        for (i in linesDrawn..allLines.size) {
            let line = allLines[i]
            for (seg in line) {
                let chunk = Chunk(seg.text, seg.font)
                match (seg.color) {
                    case Some(c) => _ = chunk.setColor(c)
                    case None => ()
                }
                remainPara.add(chunk)
            }
        }

        _compositeElements.remove(0..1)
        let newList = ArrayList<Element>()
        newList.add(remainPara)
        for (i in 0.._compositeElements.size) {
            newList.add(_compositeElements[i])
        }
        _compositeElements = newList

        NO_MORE_COLUMN
    }

    // ───────────────────────────────────────────
    // 绘制
    // ───────────────────────────────────────────

    /**
     * 绘制一行（由多个 TextSegment 组成）
     */
    private func drawLine(segments: ArrayList<TextSegment>, lineX: Float32, lineY: Float32): Unit {
        var x = lineX
        let writer = _canvas.getWriter()

        for (seg in segments) {
            let baseFont = seg.font.getCalculatedBaseFont()
            let fontName = writer.addFont(baseFont)
            let useUnicode = baseFont.isUnicodeEncoding()
            writer.markFontGlyphs(baseFont, seg.text)

            _canvas.beginText()
            _canvas.setFontAndSize(fontName, seg.font.size)
            let fillColor = match (seg.color) {
                case Some(c) => c
                case None => Color.BLACK
            }
            _canvas.setColorFill(fillColor)

            let bfName = baseFont.name
            let needsBoldSim = seg.font.isBold() && (baseFont.isTrueType() || !bfName.contains("Bold"))
            if (needsBoldSim) {
                _canvas.setColorStroke(fillColor)
                _canvas.setTextRenderingMode(2)
                _canvas.setLineWidth(seg.font.size / 30.0)
            }

            _canvas.setTextMatrix(x, lineY)
            _canvas.showText(seg.text, useUnicode, Some(baseFont))

            if (needsBoldSim) {
                _canvas.setTextRenderingMode(0)
                _canvas.setLineWidth(1.0)
            }

            _canvas.endText()

            x += baseFont.getWidthPoint(seg.text, seg.font.size)
        }
    }

    /**
     * 处理短语（单行，不换行）
     */
    private func processPhrase(phrase: Phrase, simulate: Bool): Int32 {
        let lineHeight = if (_leading > 0.0) { _leading } else { phrase.leading }

        _currentY -= lineHeight
        if (_currentY < _lly) {
            _currentY += lineHeight
            return NO_MORE_COLUMN
        }

        if (!simulate) {
            drawPhrase(phrase)
        }

        _compositeElements.remove(0..1)
        CONTINUE_PROCESSING
    }

    /**
     * 绘制短语（按顺序绘制各 Chunk，不换行）
     */
    private func drawPhrase(phrase: Phrase): Unit {
        let writer = _canvas.getWriter()
        var x = _llx + _indent

        for (chunk in phrase.getChunks()) {
            let font      = chunk.font
            let baseFont  = font.getCalculatedBaseFont()
            let fontName  = writer.addFont(baseFont)
            let useUnicode = baseFont.isUnicodeEncoding()
            writer.markFontGlyphs(baseFont, chunk.content)

            _canvas.beginText()
            _canvas.setFontAndSize(fontName, font.size)
            let fillColor = match (chunk.color) {
                case Some(c) => c
                case None => Color.BLACK
            }
            _canvas.setColorFill(fillColor)

            let bfName = baseFont.name
            let needsBoldSim = font.isBold() && (baseFont.isTrueType() || !bfName.contains("Bold"))
            if (needsBoldSim) {
                _canvas.setColorStroke(fillColor)
                _canvas.setTextRenderingMode(2)
                _canvas.setLineWidth(font.size / 30.0)
            }

            _canvas.setTextMatrix(x, _currentY)
            _canvas.showText(chunk.content, useUnicode, Some(baseFont))

            if (needsBoldSim) {
                _canvas.setTextRenderingMode(0)
                _canvas.setLineWidth(1.0)
            }

            _canvas.endText()

            x += baseFont.getWidthPoint(chunk.content, font.size)
        }
    }

    // ───────────────────────────────────────────
    // 属性访问器
    // ───────────────────────────────────────────

    public prop alignment: Alignment {
        get() { _alignment }
    }

    public func setAlignment(alignment: Alignment): Unit {
        _alignment = alignment
    }

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

    public prop yLine: Float32 {
        get() { _currentY }
    }

    public func setYLine(y: Float32): Unit {
        _currentY = y
    }

    public func hasMoreText(): Bool {
        !_compositeElements.isEmpty()
    }

    public func getFilledHeight(): Float32 {
        _ury - _currentY
    }
}
