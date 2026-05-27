/**
 * PDF-CJ: PdfWriter - PDF 写入器
 * 核心写入器，实现 DocListener 接口
 */
package pdf_cj.core

import std.io.OutputStream
import std.collection.ArrayList
import pdf_cj.base.{
    PdfObject, PdfDictionary, PdfName, PdfNumber, PdfString, PdfArray,
    PdfStream, PdfIndirectReference, PdfOutputStream, PdfFileOutputStream, PdfBoolean
}
import pdf_cj.api.{Document, DocListener, Element, ElementType, Paragraph, Phrase, Chunk, HeaderFooter}
import pdf_cj.util.{Rectangle, PageSize, PdfException}
import pdf_cj.text.{Font, BaseFont, Alignment, VerticalAlignment, TrueTypeFont, Color, Border}
import pdf_cj.table.{PdfPTable, PdfPCell, PdfPRow}
import pdf_cj.image.{Image, ImageType, PngParser, PngInfo, GifParser, BmpParser, Jp2Parser}
import pdf_cj.form.{PdfAnnotation, PdfFormField, PdfOutlineTree, PdfOutline, PdfDestination}
import pdf_cj.codec.FlateEncoder
import pdf_cj.security.PdfEncryption
import zlib4cj.{Zlib, ZlibType}

/**
 * PDF 写入器
 * 将文档内容写入 PDF 文件
 */
public class PdfWriter <: DocListener {
    // 输出流
    private var _outputStream: PdfOutputStream
    private var _document: ?Document = None

    // PDF 结构
    private var _body: PdfBody
    private var _catalog: PdfCatalog = PdfCatalog()
    private var _pages: PdfPages = PdfPages()
    private var _info: PdfInfo = PdfInfo()

    // 当前页面状态
    private var _currentPage: ?PdfPage = None
    private var _currentContent: ?PdfContentByte = None
    private var _resources: PdfResources = PdfResources()

    // 页面设置
    private var _pageSize: Rectangle = PageSize.A4
    private var _marginLeft: Float32 = 36.0
    private var _marginRight: Float32 = 36.0
    private var _marginTop: Float32 = 36.0
    private var _marginBottom: Float32 = 36.0

    // 当前绘图位置
    private var _currentY: Float32 = 0.0
    private var _pageNumber: Int32 = 0

    // 页眉页脚
    private var _header: ?HeaderFooter = None
    private var _footer: ?HeaderFooter = None

    // 字体缓存
    private var _fontReferences: ArrayList<FontRefEntry> = ArrayList<FontRefEntry>()

    // 预留的 Pages 对象编号（在 open() 时分配，供 completePage() 使用）
    private var _pagesObjNum: Int32 = 0

    // 延迟写入的字体文件（在 close() 时写入，确保所有字形都已标记）
    private var _pendingFontFiles: ArrayList<PendingFontFile> = ArrayList<PendingFontFile>()

    // 延迟写入的 CIDToGIDMap 流（在字体文件写入后，glyphMapping 就绪后写入）
    private var _pendingCIDToGIDMaps: ArrayList<PendingCIDToGIDMap> = ArrayList<PendingCIDToGIDMap>()

    // 延迟写入的 W 数组（字形宽度，在所有文字渲染后写入以确保 usedGlyphs 完整）
    private var _pendingWArrays: ArrayList<PendingWArray> = ArrayList<PendingWArray>()

    // 当前页面预留对象编号（在 newPage() 时分配，供 completePage() 和书签引用使用）
    private var _currentPageObjNum: Int32 = 0

    // 已写入页面的引用列表（按页码顺序，从 1 开始）
    private var _pageRefs: ArrayList<PdfIndirectReference> = ArrayList<PdfIndirectReference>()

    // 当前页面待写入注释
    private var _currentPageAnnots: ArrayList<PdfAnnotation> = ArrayList<PdfAnnotation>()

    // 当前页面待写入表单字段
    private var _currentPageFormFields: ArrayList<PdfFormField> = ArrayList<PdfFormField>()

    // 所有表单字段引用（按写入顺序，在 completePage 中收集，close() 时写入 AcroForm）
    private var _allFieldRefs: ArrayList<PdfIndirectReference> = ArrayList<PdfIndirectReference>()

    // 书签树
    private var _outlineTree: ?PdfOutlineTree = None

    // 页面事件监听器
    private var _pageEvent: ?PdfPageEvent = None

    // 加密
    private var _encryption: ?PdfEncryption = None

    // 两端对齐渲染时当前行的词间距（TJ kern 方式，因为 Tw 对 CID 字体无效）
    private var _justifyWordSpacing: Float32 = 0.0
    // 上一行生效的两端对齐参数（用于最后短行复用，与 OpenPDF 行为一致）
    private var _prevJustifyTc: Float32 = 0.0
    private var _prevJustifyTw: Float32 = 0.0
    // 上一段落使用的 leading（用于空段落行高，与 OpenPDF 行为一致）
    private var _lastLeading: Float32 = 0.0
    // 等待放置的图片（与 OpenPDF imageWait 机制一致：当图片放不下时先缓存，下次换页时再放置）
    private var _imageWait: ?Image = None

    // PDF 版本
    public static let PDF_VERSION_1_4 = "1.4"
    public static let PDF_VERSION_1_5 = "1.5"
    public static let PDF_VERSION_1_6 = "1.6"
    public static let PDF_VERSION_1_7 = "1.7"

    private var _pdfVersion: String = PDF_VERSION_1_4

    /**
     * 私有构造函数
     */
    private init(os: OutputStream) {
        this._outputStream = PdfFileOutputStream(os)
        this._body = PdfBody(_outputStream)
        // _currentContent will be initialized when first needed
    }

    /**
     * 获取 PdfWriter 实例并关联到文档
     */
    public static func getInstance(document: Document, os: OutputStream): PdfWriter {
        let writer = PdfWriter(os)
        writer._document = Some(document)
        writer._currentContent = Some(PdfContentByte(writer))
        document.addDocListener(writer)
        writer
    }

    // ===== DocListener 实现 =====

    /**
     * 打开文档
     */
    public func open(): Unit {
        // 写入 PDF 头
        writeHeader()

        // 预留 Pages 对象编号，确保 completePage() 能正确设置 /Parent 引用
        _pagesObjNum = _body.reserveObjectNumber()

        // 初始化页面设置
        match (_document) {
            case Some(doc) => initializePageSettings(doc)
            case None => ()
        }

        // 通知文档打开
        fireOnOpenDocument()

        // 开始第一页
        newPage()
    }

    /**
     * 初始化页面设置
     */
    private func initializePageSettings(doc: Document): Unit {
        _pageSize = doc.pageSize
        _marginLeft = doc.leftMargin
        _marginRight = doc.rightMargin
        _marginTop = doc.topMargin
        _marginBottom = doc.bottomMargin

        // 初始化文档信息
        _info = PdfInfo(doc)
    }

    /**
     * 获取当前内容字节流（安全访问）
     */
    private func getContent(): PdfContentByte {
        match (_currentContent) {
            case Some(content) => content
            case None => throw PdfException("PdfWriter not properly initialized")
        }
    }

    /**
     * 关闭文档
     */
    public func close(): Unit {
        // 完成当前页面
        finishCurrentPage()

        // 通知文档关闭
        fireOnCloseDocument()

        // 写入延迟的字体文件（此时所有字形已经标记完毕，generateSubsetFont 会填充 glyphMapping）
        for (pending in _pendingFontFiles) {
            let fontStream = createFontFileStream(pending.ttf, pending.baseFont)
            encryptStream(fontStream, pending.objNum)
            _body.add(fontStream, pending.objNum)
        }

        // 写入 W 数组（各字形实际宽度，使 PDF 渲染与换行测量一致）
        for (pending in _pendingWArrays) {
            let wArray = buildWArray(pending.baseFont)
            _body.add(wArray, pending.objNum)
        }

        // 写入 CIDToGIDMap 流（依赖上方 generateSubsetFont 已填充的 glyphMapping）
        for (pending in _pendingCIDToGIDMaps) {
            match (pending.baseFont.getFontSubset()) {
                case Some(subset) =>
                    let cidToGIDData = subset.buildCIDToGIDMapData()
                    let stream = PdfStream()
                    stream.setContent(cidToGIDData)
                    encryptStream(stream, pending.objNum)
                    _body.add(stream, pending.objNum)
                case None => ()
            }
        }

        // 写入 AcroForm（如果有表单字段）
        if (_allFieldRefs.size > 0) {
            let fieldsArray = PdfArray()
            for (i in 0.._allFieldRefs.size) {
                fieldsArray.add(_allFieldRefs[i])
            }
            let acroForm = PdfDictionary()
            acroForm.put(PdfName("Fields"), fieldsArray)
            acroForm.put(PdfName("NeedAppearances"), PdfBoolean(true))
            _catalog.setAcroForm(acroForm)
        }

        // 写入书签树（如果有）
        match (_outlineTree) {
            case Some(tree) =>
                // 递归收集所有节点（包括在 addOutline 之后添加的子节点）
                let allOutlines = ArrayList<PdfOutline>()
                collectAllOutlines(tree.getRoot(), allOutlines)
                if (allOutlines.size > 1) {
                    // 为每个节点预留对象编号
                    for (i in 0..allOutlines.size) {
                        let objNum = _body.reserveObjectNumber()
                        allOutlines[i].setReference(PdfIndirectReference(objNum))
                    }
                    // 构建所有书签字典（填充 Parent/First/Last/Prev/Next）
                    for (i in 0..allOutlines.size) {
                        allOutlines[i].buildDictionary()
                    }
                    // 写入所有书签对象
                    for (i in 0..allOutlines.size) {
                        let outline = allOutlines[i]
                        match (outline.getReference()) {
                            case Some(ref) =>
                                _body.add(outline.getDictionary(), ref.objectNumber)
                            case None => ()
                        }
                    }
                    match (allOutlines[0].getReference()) {
                        case Some(rootRef) =>
                            _catalog.setOutlines(rootRef)
                            _catalog.dictionary.put(PdfName("PageMode"), PdfName("UseOutlines"))
                        case None => ()
                    }
                }
            case None => ()
        }

        // 预留对象编号
        let catalogObjNum = _body.reserveObjectNumber()
        let infoObjNum = _body.reserveObjectNumber()

        // 写入页面树
        let pagesRef = PdfIndirectReference(_pagesObjNum)
        _body.add(_pages.dictionary, _pagesObjNum)

        // 写入 Catalog
        _catalog.setPages(pagesRef)
        let catalogRef = _body.add(_catalog.dictionary, catalogObjNum)

        // 写入文档信息
        let infoRef = _body.add(_info.dictionary, infoObjNum)

        // 写入加密字典（必须在 writeXref() 之前，才能进入 xref 表）
        let encryptRef: ?PdfIndirectReference = match (_encryption) {
            case Some(enc) =>
                let encObjNum = _body.reserveObjectNumber()
                Some(_body.add(enc.getEncryptionDictionary(), encObjNum))
            case None => None
        }

        // 写入交叉引用表
        let xrefPos = _body.writeXref()

        // 写入 Trailer
        writeTrailer(catalogRef, infoRef, xrefPos, encryptRef)

        // 刷新并关闭
        _outputStream.flush()
    }

    /**
     * 新页面
     */
    public func newPage(): Bool {
        // 完成当前页面
        if (_currentPage.isSome()) {
            finishCurrentPage()
        }

        _pageNumber += 1

        // 预留页面对象编号（供书签 Destination 引用和 completePage 写入使用）
        _currentPageObjNum = _body.reserveObjectNumber()

        // 创建新页面
        _currentPage = Some(PdfPage(_pageSize))
        _currentContent = PdfContentByte(this)
        _resources = PdfResources()

        // 重置绘图位置
        _currentY = _pageSize.height - _marginTop

        // 与 OpenPDF 一致：新页时若有缓存的 imageWait 则立即放置
        match (_imageWait) {
            case Some(img) =>
                _imageWait = None
                _ = processImage(img)
            case None => ()
        }

        // 绘制页眉
        match (_header) {
            case Some(header) => drawHeaderFooter(header, true)
            case None => ()
        }

        // 重置当前页面注释和表单字段列表
        _currentPageAnnots = ArrayList<PdfAnnotation>()
        _currentPageFormFields = ArrayList<PdfFormField>()

        // 通知新页面开始
        fireOnStartPage()

        true
    }

    /**
     * 添加注释到当前页面
     */
    public func addAnnotation(annot: PdfAnnotation): Unit {
        _currentPageAnnots.add(annot)
    }

    /**
     * 添加表单字段到当前页面（同时写入 AcroForm 和页面 Annots）
     */
    public func addFormField(field: PdfFormField): Unit {
        _currentPageFormFields.add(field)
    }

    /**
     * 注册页面事件监听器
     */
    public func setPageEvent(event: PdfPageEvent): Unit {
        this._pageEvent = Some(event)
    }

    // ===== 页面事件 fire helpers =====

    private func fireOnOpenDocument(): Unit {
        match (_pageEvent) {
            case Some(ev) => match (_document) {
                case Some(doc) => ev.onOpenDocument(this, doc)
                case None => ()
            }
            case None => ()
        }
    }

    private func fireOnCloseDocument(): Unit {
        match (_pageEvent) {
            case Some(ev) => match (_document) {
                case Some(doc) => ev.onCloseDocument(this, doc)
                case None => ()
            }
            case None => ()
        }
    }

    private func fireOnStartPage(): Unit {
        match (_pageEvent) {
            case Some(ev) => match (_document) {
                case Some(doc) => ev.onStartPage(this, doc)
                case None => ()
            }
            case None => ()
        }
    }

    private func fireOnEndPage(): Unit {
        match (_pageEvent) {
            case Some(ev) => match (_document) {
                case Some(doc) => ev.onEndPage(this, doc)
                case None => ()
            }
            case None => ()
        }
    }

    private func fireOnParagraph(y: Float32): Unit {
        match (_pageEvent) {
            case Some(ev) => match (_document) {
                case Some(doc) => ev.onParagraph(this, doc, y)
                case None => ()
            }
            case None => ()
        }
    }

    private func fireOnParagraphEnd(y: Float32): Unit {
        match (_pageEvent) {
            case Some(ev) => match (_document) {
                case Some(doc) => ev.onParagraphEnd(this, doc, y)
                case None => ()
            }
            case None => ()
        }
    }

    /**
     * 设置书签树（在 close() 时写入）
     */
    public func setOutlineTree(tree: PdfOutlineTree): Unit {
        _outlineTree = Some(tree)
    }

    /**
     * 获取书签树（不存在则自动创建），用于逐步添加书签
     */
    public func getOutlineTree(): PdfOutlineTree {
        match (_outlineTree) {
            case Some(tree) => tree
            case None =>
                let tree = PdfOutlineTree()
                _outlineTree = Some(tree)
                tree
        }
    }

    /**
     * 添加根级书签（快捷方式）
     * @param title 书签标题
     * @param dest  目标位置（用 getCurrentPageReference() 构造）
     * @return 新建的 PdfOutline，可继续添加子书签
     */
    public func addOutline(title: String, dest: PdfDestination): PdfOutline {
        let outline = PdfOutline(title, dest)
        getOutlineTree().addOutline(outline)
        outline
    }

    /**
     * 获取当前页面引用（用于创建书签 Destination）
     * 必须在 newPage()/open() 之后调用
     */
    public func getCurrentPageReference(): PdfIndirectReference {
        PdfIndirectReference(_currentPageObjNum)
    }

    /**
     * 设置页面大小
     */
    public func setPageSize(size: Rectangle): Bool {
        this._pageSize = size
        true
    }

    /**
     * 设置边距
     */
    public func setMargins(left: Float32, right: Float32, top: Float32, bottom: Float32): Bool {
        this._marginLeft = left
        this._marginRight = right
        this._marginTop = top
        this._marginBottom = bottom
        true
    }

    /**
     * 设置页眉
     */
    public func setHeader(header: HeaderFooter): Unit {
        this._header = Some(header)
    }

    /**
     * 设置页脚
     */
    public func setFooter(footer: HeaderFooter): Unit {
        this._footer = Some(footer)
    }

    /**
     * 重置页眉
     */
    public func resetHeader(): Unit {
        this._header = None
    }

    /**
     * 重置页脚
     */
    public func resetFooter(): Unit {
        this._footer = None
    }

    /**
     * 添加元素
     */
    public func add(element: Element): Bool {
        match (element.getType()) {
            case Paragraph => addParagraph(element)
            case Phrase => addPhrase(element)
            case Chunk => addChunk(element)
            case Table => addTable(element)
            case Image => addImage(element)
            case _ => false
        }
    }

    // ===== 内部方法 =====

    /**
     * 写入 PDF 头
     */
    private func writeHeader(): Unit {
        _outputStream.writeString("%PDF-")
        _outputStream.writeString(_pdfVersion)
        _outputStream.writeNewLine()

        // 二进制标记（确保文件被识别为二进制）
        _outputStream.write(UInt8(0x25))  // %
        _outputStream.write(UInt8(0xE2))
        _outputStream.write(UInt8(0xE3))
        _outputStream.write(UInt8(0xCF))
        _outputStream.write(UInt8(0xD3))
        _outputStream.writeNewLine()
    }

    /**
     * 写入 Trailer
     */
    private func writeTrailer(catalogRef: PdfIndirectReference, infoRef: PdfIndirectReference,
                              xrefPos: Int64, encryptRef: ?PdfIndirectReference): Unit {
        _outputStream.writeString("trailer")
        _outputStream.writeNewLine()

        let trailer = PdfDictionary()
        trailer.put(PdfName.SIZE, PdfNumber(Int32(_body.objectCount + 1)))
        trailer.put(PdfName.ROOT, catalogRef)
        trailer.put(PdfName.INFO, infoRef)

        // 加密字典引用 + 文件 ID（加密字典对象已在 xref 之前写入）
        match (encryptRef) {
            case Some(ref) =>
                trailer.put(PdfName("Encrypt"), ref)
                match (_encryption) {
                    case Some(enc) =>
                        let fileId = enc.getFileID()
                        let idArr  = PdfArray()
                        idArr.add(PdfString(fileId))
                        idArr.add(PdfString(fileId))
                        trailer.put(PdfName("ID"), idArr)
                    case None => ()
                }
            case None => ()
        }

        trailer.writeTo(_outputStream)
        _outputStream.writeNewLine()

        // startxref
        _outputStream.writeString("startxref")
        _outputStream.writeNewLine()
        _outputStream.writeInt(xrefPos)
        _outputStream.writeNewLine()

        // EOF
        _outputStream.writeString("%%EOF")
        _outputStream.writeNewLine()
    }

    /**
     * 完成当前页面
     */
    private func finishCurrentPage(): Unit {
        match (_currentPage) {
            case Some(page) => completePage(page)
            case None => ()
        }
    }

    private func completePage(page: PdfPage): Unit {
        // 通知页面结束（在内容流写入前，事件处理器仍可绘制）
        fireOnEndPage()

        // 绘制页脚
        match (_footer) {
            case Some(footer) => drawHeaderFooter(footer, false)
            case None => ()
        }

        // 写入内容流
        let contentStream = getContent().toStream()
        let contentObjNum = _body.reserveObjectNumber()
        encryptStream(contentStream, contentObjNum)
        let contentRef = _body.add(contentStream, contentObjNum)
        page.setContents(contentRef)

        // 设置资源
        page.setResources(_resources.toDictionary())

        // 设置父节点引用
        page.setParent(PdfIndirectReference(_pagesObjNum))

        // 写入注释和表单字段到页面 Annots 数组
        let annotsArray = PdfArray()
        var hasAnnots = false

        // 普通注释
        for (i in 0.._currentPageAnnots.size) {
            let annotRef = _body.add(_currentPageAnnots[i].getDictionary())
            annotsArray.add(annotRef)
            hasAnnots = true
        }

        // 表单字段（合并的字段+Widget 对象）
        for (i in 0.._currentPageFormFields.size) {
            let field = _currentPageFormFields[i]
            let mergedDict = buildMergedFieldDict(field, _currentPageObjNum)
            let fieldRef = _body.add(mergedDict)
            annotsArray.add(fieldRef)
            _allFieldRefs.add(fieldRef)
            hasAnnots = true
        }

        if (hasAnnots) {
            page.dictionary.put(PdfName("Annots"), annotsArray)
        }

        // 写入页面（使用预留的对象编号）
        let pageRef = _body.add(page.dictionary, _currentPageObjNum)
        _pageRefs.add(pageRef)
        _pages.addPage(pageRef)
    }

    /**
     * 递归收集书签树中的所有节点（深度优先）
     */
    private func collectAllOutlines(outline: PdfOutline, result: ArrayList<PdfOutline>): Unit {
        result.add(outline)
        let children = outline.getChildren()
        for (i in 0..children.size) {
            collectAllOutlines(children[i], result)
        }
    }

    /**
     * 将表单字段字典与其 Widget 注释属性合并为单个 PDF 对象
     */
    private func buildMergedFieldDict(field: PdfFormField, pageObjNum: Int32): PdfDictionary {
        let dict = field.getDictionary()
        // 设置 Annot 类型标记
        dict.put(PdfName("Type"), PdfName("Annot"))
        dict.put(PdfName("Subtype"), PdfName("Widget"))
        // 设置页面引用
        dict.put(PdfName("P"), PdfIndirectReference(pageObjNum))
        // 从第一个 widget 复制 Rect（如果字段字典本身没有 Rect）
        match (dict.get(PdfName("Rect"))) {
            case None =>
                let widgets = field.getWidgets()
                if (widgets.size > 0) {
                    let widgetDict = widgets[0].getDictionary()
                    match (widgetDict.get(PdfName("Rect"))) {
                        case Some(rect) => dict.put(PdfName("Rect"), rect)
                        case None => ()
                    }
                }
            case Some(_) => ()
        }
        dict
    }

    /**
     * 添加段落
     */
    private func addParagraph(element: Element): Bool {
        match (element) {
            case para: Paragraph => processParagraph(para)
            case _ => false
        }
    }

    private func processParagraph(para: Paragraph): Bool {
        // 重置两端对齐的跨行复用参数（每个新段落独立计算）
        _prevJustifyTc = 0.0
        _prevJustifyTw = 0.0

        // 段前间距
        _currentY -= para.spacingBefore

        // 若连一行都放不下则换页
        if (_currentY - para.leading < _marginBottom) {
            newPage()
        }

        // 通知段落开始
        fireOnParagraph(_currentY)

        // 计算段落可用宽度（首行有额外缩进）
        let leftX = _marginLeft + para.indentationLeft
        let firstLineLeftX = leftX + para.firstLineIndent
        let rightX = _pageSize.width - _marginRight - para.indentationRight

        // ── Pass 1: 构建所有行，每行是一个 Chunk 列表 ──
        let allLines = ArrayList<ArrayList<Chunk>>()
        var currentLine = ArrayList<Chunk>()
        var lineWidth: Float32 = 0.0
        var isFirstLine = true

        for (chunk in para.getChunks()) {
            let font = chunk.font
            let baseFont = font.getCalculatedBaseFont()
            var segText = ""
            var segWidth: Float32 = 0.0

            for (r in chunk.content.runes()) {
                let charStr = String([r])
                let charWidth = baseFont.getWidthPoint(charStr, font.size)
                let availWidth: Float32 = if (isFirstLine) {
                    rightX - firstLineLeftX
                } else {
                    rightX - leftX
                }

                if (lineWidth + segWidth + charWidth > availWidth && lineWidth + segWidth > 0.0) {
                    // 当前段落片段非空，加入本行
                    if (!segText.isEmpty()) {
                        let seg = Chunk(segText, font)
                        match (chunk.color) {
                            case Some(c) => _ = seg.setColor(c)
                            case None => ()
                        }
                        if (chunk.underline) { _ = seg.setUnderline() }
                        if (chunk.strikethrough) { _ = seg.setStrikethrough() }
                        match (chunk.background) {
                            case Some(bg) => _ = seg.setBackground(bg)
                            case None => ()
                        }
                        currentLine.add(seg)
                    }
                    // 保存本行，开启新行
                    allLines.add(currentLine)
                    currentLine = ArrayList<Chunk>()
                    lineWidth = 0.0
                    isFirstLine = false
                    segText = charStr
                    segWidth = charWidth
                } else {
                    segText += charStr
                    segWidth += charWidth
                }
            }

            // chunk 遍历完，将剩余段落片段加入当前行
            if (!segText.isEmpty()) {
                let seg = Chunk(segText, font)
                match (chunk.color) {
                    case Some(c) => _ = seg.setColor(c)
                    case None => ()
                }
                if (chunk.underline) { _ = seg.setUnderline() }
                if (chunk.strikethrough) { _ = seg.setStrikethrough() }
                match (chunk.background) {
                    case Some(bg) => _ = seg.setBackground(bg)
                    case None => ()
                }
                currentLine.add(seg)
                lineWidth += segWidth
            }
        }

        // 最后一行（若非空）
        if (!currentLine.isEmpty()) {
            allLines.add(currentLine)
        }

        // 空段落：没有任何行，仍需下移一行高度
        // 与 OpenPDF 一致：空段落复用上一段落的 leading，而不是自身默认 leading
        if (allLines.isEmpty()) {
            let effectiveLeading = if (_lastLeading > 0.0) { _lastLeading } else { para.leading }
            _currentY -= effectiveLeading
            _currentY -= para.spacingAfter
            fireOnParagraphEnd(_currentY)
            return true
        }

        // ── Pass 2: 渲染每行，按对齐方式计算 x 起点 ──
        // 与 OpenPDF 对齐：先减 leading（下移一行高度），再绘制 baseline
        for (i in 0..allLines.size) {
            _currentY -= para.leading
            if (_currentY < _marginBottom) {
                newPage()
            }

            let line = allLines[i]
            let lineLeftX: Float32 = if (i == 0) { firstLineLeftX } else { leftX }

            // 计算本行总宽度
            var totalWidth: Float32 = 0.0
            for (seg in line) {
                totalWidth += seg.getWidthPoint()
            }

            // 根据对齐计算起始 x
            let startX: Float32 = match (para.alignment) {
                case Alignment.Center => lineLeftX + (rightX - lineLeftX - totalWidth) / 2.0
                case Alignment.Right => rightX - totalWidth
                case _ => lineLeftX
            }

            // 两端对齐：计算 Tc（字符间距）和词间距（TJ kern）
            // 与 OpenPDF 行为一致：对满行按公式计算，对明显偏短的最后一行复用上一行的 Tc/Tw
            // 公式：ratio=2.5, baseFactor=extraSpace/(ratio*spaces+chars-1)
            var appliedTc: Float32 = 0.0
            var appliedTw: Float32 = 0.0
            let isJustified = match (para.alignment) { case Alignment.Justified => true; case _ => false }
            if (isJustified) {
                let lineWidth = rightX - lineLeftX
                let extraSpace = lineWidth - totalWidth
                var charCount: Int32 = 0
                var spaceCount: Int32 = 0
                for (seg in line) {
                    for (r in seg.content.runes()) {
                        charCount += 1
                        if (r == r' ') { spaceCount += 1 }
                    }
                }
                // 行是否充分填满（extraSpace < 15% lineWidth）
                let isFull = lineWidth > 0.0 && extraSpace > 0.0 && (extraSpace / lineWidth) < 0.15
                if (charCount > 1 && isFull) {
                    // 满行：按本行 extraSpace 计算 Tc/Tw
                    let ratio: Float32 = 2.5
                    let baseFactor = extraSpace / (ratio * Float32(spaceCount) + Float32(charCount) - 1.0)
                    appliedTc = baseFactor
                    appliedTw = ratio * baseFactor
                } else if (charCount > 1 && _prevJustifyTc > 0.0) {
                    // 明显偏短的最后一行：与 OpenPDF 一致，复用上一行的 Tc/Tw
                    appliedTc = _prevJustifyTc
                    appliedTw = _prevJustifyTw
                }
                if (appliedTc > 0.0) {
                    // Tc 有效；Tw 对 CID 字体无效（空格 GID ≠ 0x20），词间距改由 drawChunk 内 TJ kern 实现
                    getContent().setCharacterSpacing(appliedTc)
                    _justifyWordSpacing = appliedTw
                }
            }

            // 逐 chunk 渲染
            var cx = startX
            for (seg in line) {
                drawChunk(seg, cx, _currentY, para.alignment)
                cx += seg.getWidthPoint()
            }

            // 重置字符间距（词间距通过 _justifyWordSpacing 在 drawChunk 内处理）
            if (appliedTc != 0.0 || appliedTw != 0.0) {
                getContent().setCharacterSpacing(0.0)
                _justifyWordSpacing = 0.0
                // 保存本行参数供下一行（最后短行）复用
                _prevJustifyTc = appliedTc
                _prevJustifyTw = appliedTw
            }
        }

        // 段后间距
        _currentY -= para.spacingAfter

        // 记录本段落 leading，供后续空段落复用（与 OpenPDF 行为一致）
        _lastLeading = para.leading

        // 通知段落结束
        fireOnParagraphEnd(_currentY)

        true
    }

    /**
     * 添加短语
     */
    private func addPhrase(element: Element): Bool {
        match (element) {
            case phrase: Phrase => processPhrase(phrase)
            case _ => false
        }
    }

    private func processPhrase(phrase: Phrase): Bool {
        let leftX = _marginLeft
        for (chunk in phrase.getChunks()) {
            drawChunk(chunk, leftX, _currentY, Alignment.Left)
        }
        _currentY -= phrase.leading
        true
    }

    /**
     * 添加 Chunk
     */
    private func addChunk(element: Element): Bool {
        match (element) {
            case chunk: Chunk => processChunk(chunk)
            case _ => false
        }
    }

    private func processChunk(chunk: Chunk): Bool {
        if (chunk.content == "\n") {
            // Chunk.NEWLINE: 与 OpenPDF 一致，相当于 16pt 行距的空行
            processParagraph(Paragraph(16.0))
        } else {
            drawChunk(chunk, _marginLeft, _currentY, Alignment.Left)
        }
        true
    }

    /**
     * 添加表格
     */
    private func addTable(element: Element): Bool {
        match (element) {
            case table: PdfPTable => processTable(table)
            case _ => false
        }
    }

    /**
     * 添加图片
     */
    private func addImage(element: Element): Bool {
        match (element) {
            case image: Image => processImage(image)
            case _ => false
        }
    }

    /**
     * 处理图片
     */
    private func processImage(image: Image): Bool {
        // 获取图片数据
        let rawData = match (image.rawData) {
            case Some(data) => data
            case None => return false
        }

        let imageWidth = image.scaledWidth
        let imageHeight = image.scaledHeight

        // 若设置了绝对坐标，直接放置，不影响文档流
        if (image.hasAbsolutePosition) {
            let iccRef = embedIccProfile(image)
            let imageXObject = createImageXObject(image, rawData, iccRef)
            let imageObjNum = _body.reserveObjectNumber()
            encryptStream(imageXObject, imageObjNum)
            let imageRef = _body.add(imageXObject, imageObjNum)
            let imageName = _resources.addXObject(imageRef)
            drawImage(imageName, image.absoluteX, image.absoluteY, imageWidth, imageHeight)
            return true
        }

        // 与 OpenPDF 一致：图片与上方文本的间距 = lastLeading / 2
        let f = _lastLeading / 2.0
        _currentY -= f

        // 与 OpenPDF imageWait 机制一致：
        // - 第一次放不下：缓存图片（imageWait），恢复 _currentY，继续处理后续元素
        // - 第二次放不下（imageWait 已有值）：强制换页（换页时 imageWait 会被放置），再处理本图片
        if (_currentY - imageHeight < _marginBottom) {
            match (_imageWait) {
                case None =>
                    // 第一次：缓存，恢复游标，延迟到下一页放置
                    _currentY += f
                    _imageWait = Some(image)
                    return true
                case Some(_) =>
                    // 第二次：强制换页（newPage 内会放置 imageWait），恢复后重新应用 f
                    _currentY += f
                    newPage()
                    _currentY -= f
            }
        }

        // 嵌入 ICC Profile（若 JPEG 有内嵌 ICC Profile）
        let iccRef = embedIccProfile(image)

        // 创建图片 XObject
        let imageXObject = createImageXObject(image, rawData, iccRef)

        // 添加到资源并获取名称
        let imageObjNum = _body.reserveObjectNumber()
        encryptStream(imageXObject, imageObjNum)
        let imageRef = _body.add(imageXObject, imageObjNum)
        let imageName = _resources.addXObject(imageRef)

        // 计算图片位置
        let pageWidth = _pageSize.width - _marginLeft - _marginRight

        let imageX = match (image.alignment) {
            case Alignment.Left => _marginLeft
            case Alignment.Center => _marginLeft + (pageWidth - imageWidth) / 2.0
            case Alignment.Right => _marginLeft + pageWidth - imageWidth
            case _ => _marginLeft
        }

        // 计算 Y 位置（PDF 坐标系从下往上）
        let imageY = _currentY - imageHeight

        // 绘制图片
        drawImage(imageName, imageX, imageY, imageWidth, imageHeight)

        // 更新 Y 位置
        _currentY -= imageHeight

        true
    }

    /**
     * 嵌入 ICC Profile 对象（若 JPEG 有内嵌 ICC Profile），返回其引用
     */
    private func embedIccProfile(image: Image): ?PdfIndirectReference {
        match (image.iccProfile) {
            case Some(iccData) =>
                let iccStream = PdfStream()
                iccStream.setContent(iccData)
                // ICC Profile 需要注明颜色分量数（RGB = 3）
                iccStream.put(PdfName("N"), PdfNumber(3))
                let iccObjNum = _body.reserveObjectNumber()
                let iccRef = _body.add(iccStream, iccObjNum)
                Some(iccRef)
            case None => None
        }
    }

    /**
     * 创建图片 XObject
     */
    private func createImageXObject(image: Image, rawData: Array<UInt8>,
                                    iccRef: ?PdfIndirectReference): PdfStream {
        let stream = PdfStream()
        stream.put(PdfName.TYPE, PdfName.XOBJECT)
        stream.put(PdfName("Subtype"), PdfName("Image"))
        stream.put(PdfName("Width"), PdfNumber(Int32(image.plainWidth)))
        stream.put(PdfName("Height"), PdfNumber(Int32(image.plainHeight)))

        // 根据图片类型设置过滤器和颜色空间
        match (image.imageType) {
            case ImageType.Jpeg =>
                // JPEG 使用 DCTDecode 过滤器，可直接嵌入原始JPEG数据
                stream.put(PdfName.FILTER, PdfName.DCTDECODE)
                // 优先使用内嵌 ICC Profile，否则回退到 DeviceRGB
                match (iccRef) {
                    case Some(ref) =>
                        let csArray = PdfArray()
                        csArray.add(PdfName("ICCBased"))
                        csArray.add(ref)
                        stream.put(PdfName("ColorSpace"), csArray)
                    case None =>
                        stream.put(PdfName("ColorSpace"), PdfName("DeviceRGB"))
                }
                stream.put(PdfName("BitsPerComponent"), PdfNumber(8))
                stream.setContent(rawData)
            case ImageType.Png =>
                // PNG：提取IDAT数据并使用FlateDecode
                createPngXObject(stream, rawData)
            case ImageType.Gif =>
                // GIF：转换为 RGB 数据
                createGifXObject(stream, rawData)
            case ImageType.Bmp =>
                // BMP：转换为 RGB 数据
                createBmpXObject(stream, rawData)
            case ImageType.Jpeg2000 =>
                // JPEG2000 使用 JPXDecode，直接嵌入原始数据
                // ColorSpace 和 BitsPerComponent 可选（JPEG2000 流内含），但显式写出
                let jp2cs = match (Jp2Parser.parse(rawData)) {
                    case Some(info) => info.colorSpace
                    case None => "DeviceRGB"
                }
                let jp2bpc = match (Jp2Parser.parse(rawData)) {
                    case Some(info) => info.bitsPerComponent
                    case None => Int32(8)
                }
                stream.put(PdfName.FILTER, PdfName.JPXDECODE)
                stream.put(PdfName.COLORSPACE, PdfName(jp2cs))
                stream.put(PdfName("BitsPerComponent"), PdfNumber(jp2bpc))
                stream.setContent(rawData)
            case _ =>
                // 默认处理：尝试作为RGB数据
                stream.put(PdfName("ColorSpace"), PdfName("DeviceRGB"))
                stream.put(PdfName("BitsPerComponent"), PdfNumber(8))
                stream.setContent(rawData)
        }

        stream
    }

    /**
     * 创建PNG XObject
     * 使用 zlib4cj 解压 PNG 的 IDAT 数据
     */
    private func createPngXObject(stream: PdfStream, rawData: Array<UInt8>): Unit {
        match (PngParser.parse(rawData)) {
            case Some(pngInfo) =>
                try {
                    // 解压 IDAT 数据（PNG 使用 ZLIB 格式，不是纯 DEFLATE）
                    let decompressedData = Zlib.uncompress(pngInfo.idatData, wrap: ZlibType.ZLIB)

                    // 应用PNG滤波器还原
                    var imageData = applyPngFilters(decompressedData, pngInfo)

                    // 如果是索引色，转换为 RGB
                    if (pngInfo.colorType == UInt8(3) && pngInfo.palette.size > 0) {
                        imageData = convertIndexedToRGB(imageData, pngInfo.palette)
                    }

                    // 设置颜色空间
                    let colorSpace = match (pngInfo.colorType) {
                        case 0 => "DeviceGray"  // 灰度
                        case 2 => "DeviceRGB"   // RGB
                        case 3 => "DeviceRGB"   // 索引色（已转换为RGB）
                        case 4 => "DeviceGray"  // 灰度+Alpha（简化为灰度）
                        case 6 => "DeviceRGB"   // RGBA（简化为RGB）
                        case _ => "DeviceRGB"
                    }
                    stream.put(PdfName("ColorSpace"), PdfName(colorSpace))
                    stream.put(PdfName("BitsPerComponent"), PdfNumber(8))  // 转换后都是8位

                    // 添加 Decode 数组（明确指定颜色值范围）
                    // DeviceRGB: [0 1 0 1 0 1] 表示 R、G、B 都是从 0 到 1
                    let decodeArray = PdfArray()
                    decodeArray.add(PdfNumber(0))
                    decodeArray.add(PdfNumber(1))
                    decodeArray.add(PdfNumber(0))
                    decodeArray.add(PdfNumber(1))
                    decodeArray.add(PdfNumber(0))
                    decodeArray.add(PdfNumber(1))
                    stream.put(PdfName("Decode"), decodeArray)

                    // 重新压缩数据用于 PDF
                    let compressedData = FlateEncoder.encode(imageData)

                    stream.put(PdfName.FILTER, PdfName.FLATEDECODE)
                    stream.setContent(compressedData)
                } catch (e: Exception) {
                    // 如果处理失败，回退到简化处理（创建占位图片）
                    stream.put(PdfName("ColorSpace"), PdfName("DeviceRGB"))
                    stream.put(PdfName("BitsPerComponent"), PdfNumber(8))
                    let placeholderData = Array<UInt8>(100, repeat: UInt8(128))
                    stream.setContent(placeholderData)
                }
            case None =>
                // 解析失败，创建空白图片
                stream.put(PdfName("ColorSpace"), PdfName("DeviceRGB"))
                stream.put(PdfName("BitsPerComponent"), PdfNumber(8))
                let blankData = Array<UInt8>(100, repeat: UInt8(255))
                stream.setContent(blankData)
        }
    }

    /**
     * 创建 GIF XObject
     * 将 GIF 转换为 RGB 数据
     */
    private func createGifXObject(stream: PdfStream, rawData: Array<UInt8>): Unit {
        match (GifParser.parse(rawData)) {
            case Some(gifInfo) =>
                try {
                    // 将索引色转换为 RGB
                    let imageData = GifParser.convertToRGB(gifInfo)

                    stream.put(PdfName("ColorSpace"), PdfName("DeviceRGB"))
                    stream.put(PdfName("BitsPerComponent"), PdfNumber(8))

                    // 压缩数据用于 PDF
                    let compressedData = FlateEncoder.encode(imageData)

                    stream.put(PdfName.FILTER, PdfName.FLATEDECODE)
                    stream.setContent(compressedData)
                } catch (e: Exception) {
                    // 如果处理失败，回退到简化处理
                    stream.put(PdfName("ColorSpace"), PdfName("DeviceRGB"))
                    stream.put(PdfName("BitsPerComponent"), PdfNumber(8))
                    let placeholderData = Array<UInt8>(100, repeat: UInt8(128))
                    stream.setContent(placeholderData)
                }
            case None =>
                // 解析失败，创建空白图片
                stream.put(PdfName("ColorSpace"), PdfName("DeviceRGB"))
                stream.put(PdfName("BitsPerComponent"), PdfNumber(8))
                let blankData = Array<UInt8>(100, repeat: UInt8(255))
                stream.setContent(blankData)
        }
    }

    /**
     * 创建 BMP XObject
     * 将 BMP 转换为 RGB 数据
     */
    private func createBmpXObject(stream: PdfStream, rawData: Array<UInt8>): Unit {
        match (BmpParser.parse(rawData)) {
            case Some(bmpInfo) =>
                try {
                    // 将 BMP 转换为 RGB（处理上下翻转和调色板）
                    let imageData = BmpParser.convertToRGB(bmpInfo)

                    stream.put(PdfName("ColorSpace"), PdfName("DeviceRGB"))
                    stream.put(PdfName("BitsPerComponent"), PdfNumber(8))

                    // 压缩数据用于 PDF
                    let compressedData = FlateEncoder.encode(imageData)

                    stream.put(PdfName.FILTER, PdfName.FLATEDECODE)
                    stream.setContent(compressedData)
                } catch (e: Exception) {
                    // 如果处理失败，回退到简化处理
                    stream.put(PdfName("ColorSpace"), PdfName("DeviceRGB"))
                    stream.put(PdfName("BitsPerComponent"), PdfNumber(8))
                    let placeholderData = Array<UInt8>(100, repeat: UInt8(128))
                    stream.setContent(placeholderData)
                }
            case None =>
                // 解析失败，创建空白图片
                stream.put(PdfName("ColorSpace"), PdfName("DeviceRGB"))
                stream.put(PdfName("BitsPerComponent"), PdfNumber(8))
                let blankData = Array<UInt8>(100, repeat: UInt8(255))
                stream.setContent(blankData)
        }
    }

    /**
     * 应用 PNG 滤波器还原原始图像数据
     * 完整实现：支持所有 PNG 滤波器类型
     */
    private func applyPngFilters(data: Array<UInt8>, pngInfo: PngInfo): Array<UInt8> {
        let componentsPerPixel = Int64(PngParser.getColorComponents(pngInfo.colorType))
        let bytesPerPixel = componentsPerPixel * Int64(pngInfo.bitDepth) / 8
        let bytesPerRow = (Int64(pngInfo.width) * componentsPerPixel * Int64(pngInfo.bitDepth) + 7) / 8
        let stride = bytesPerRow + 1  // +1 for filter type byte

        let height = Int64(pngInfo.height)
        let width = Int64(pngInfo.width)

        // 对于 RGBA，输出 RGB（去掉 Alpha 通道）
        let isRGBA = pngInfo.colorType == UInt8(6)
        let outputBytesPerRow = if (isRGBA) { width * 3 } else { bytesPerRow }
        let resultSize = outputBytesPerRow * height
        let result = Array<UInt8>(resultSize, repeat: UInt8(0))

        // 临时缓冲区用于存储当前行和上一行
        var currentRow = Array<UInt8>(bytesPerRow, repeat: UInt8(0))
        var prevRow = Array<UInt8>(bytesPerRow, repeat: UInt8(0))

        var y: Int64 = 0
        while (y < height) {
            let filterType = data[y * stride]
            let rowStart = y * stride + 1

            // 应用滤波器还原
            var x: Int64 = 0
            while (x < bytesPerRow) {
                let raw = data[rowStart + x]
                var restored: UInt8 = raw

                match (filterType) {
                    case 0 =>  // None
                        restored = raw
                    case 1 =>  // Sub
                        let left = if (x >= bytesPerPixel) { currentRow[x - bytesPerPixel] } else { UInt8(0) }
                        restored = UInt8((Int32(raw) + Int32(left)) % 256)
                    case 2 =>  // Up
                        let up = prevRow[x]
                        restored = UInt8((Int32(raw) + Int32(up)) % 256)
                    case 3 =>  // Average
                        let left = if (x >= bytesPerPixel) { currentRow[x - bytesPerPixel] } else { UInt8(0) }
                        let up = prevRow[x]
                        let avg = (Int32(left) + Int32(up)) / 2
                        restored = UInt8((Int32(raw) + avg) % 256)
                    case 4 =>  // Paeth
                        let left = if (x >= bytesPerPixel) { currentRow[x - bytesPerPixel] } else { UInt8(0) }
                        let up = prevRow[x]
                        let upLeft = if (x >= bytesPerPixel) { prevRow[x - bytesPerPixel] } else { UInt8(0) }
                        let pr = paethPredictor(left, up, upLeft)
                        restored = UInt8((Int32(raw) + Int32(pr)) % 256)
                    case _ =>
                        restored = raw
                }

                currentRow[x] = restored
                x += 1
            }

            // 将当前行复制到结果，如果是 RGBA 则转换为 RGB
            if (isRGBA) {
                // RGBA → RGB: 进行 alpha 混合（假设白色背景）
                var srcIdx: Int64 = 0
                var dstIdx: Int64 = y * outputBytesPerRow
                while (srcIdx < bytesPerRow) {
                    let r = currentRow[srcIdx]
                    let g = currentRow[srcIdx + 1]
                    let b = currentRow[srcIdx + 2]
                    let alpha = currentRow[srcIdx + 3]

                    // Alpha 混合公式：output = color + (255 - color) * (255 - alpha) / 255
                    // 这会将透明区域与白色背景混合
                    if (alpha == UInt8(255)) {
                        // 完全不透明，直接使用原色
                        result[dstIdx] = r
                        result[dstIdx + 1] = g
                        result[dstIdx + 2] = b
                    } else if (alpha == UInt8(0)) {
                        // 完全透明，使用白色
                        result[dstIdx] = UInt8(255)
                        result[dstIdx + 1] = UInt8(255)
                        result[dstIdx + 2] = UInt8(255)
                    } else {
                        // 半透明，进行混合
                        let alphaFloat = Int32(alpha)
                        let invAlpha = 255 - alphaFloat
                        result[dstIdx] = UInt8((Int32(r) * alphaFloat + 255 * invAlpha) / 255)
                        result[dstIdx + 1] = UInt8((Int32(g) * alphaFloat + 255 * invAlpha) / 255)
                        result[dstIdx + 2] = UInt8((Int32(b) * alphaFloat + 255 * invAlpha) / 255)
                    }

                    srcIdx += 4
                    dstIdx += 3
                }
            } else {
                // 直接复制
                var x2: Int64 = 0
                while (x2 < bytesPerRow) {
                    result[y * outputBytesPerRow + x2] = currentRow[x2]
                    x2 += 1
                }
            }

            // 交换缓冲区
            let temp = prevRow
            prevRow = currentRow
            currentRow = temp

            y += 1
        }

        result
    }

    /**
     * Paeth 预测器（用于 PNG Filter Type 4）
     */
    private func paethPredictor(a: UInt8, b: UInt8, c: UInt8): UInt8 {
        let p = Int32(a) + Int32(b) - Int32(c)
        let pa = if (p > Int32(a)) { p - Int32(a) } else { Int32(a) - p }
        let pb = if (p > Int32(b)) { p - Int32(b) } else { Int32(b) - p }
        let pc = if (p > Int32(c)) { p - Int32(c) } else { Int32(c) - p }

        if (pa <= pb && pa <= pc) {
            return a
        } else if (pb <= pc) {
            return b
        } else {
            return c
        }
    }

    /**
     * 将索引色数据转换为 RGB
     * @param indexedData 索引值数组
     * @param palette 调色板数据（RGB格式，每个颜色3字节）
     * @return RGB数据数组
     */
    private func convertIndexedToRGB(indexedData: Array<UInt8>, palette: Array<UInt8>): Array<UInt8> {
        let pixelCount = indexedData.size
        let rgbData = Array<UInt8>(pixelCount * 3, repeat: UInt8(0))

        var i: Int64 = 0
        while (i < pixelCount) {
            let index = Int64(indexedData[i])
            let paletteOffset = index * 3

            // 检查调色板索引是否有效
            if (paletteOffset + 2 < palette.size) {
                rgbData[i * 3] = palette[paletteOffset]          // R
                rgbData[i * 3 + 1] = palette[paletteOffset + 1]  // G
                rgbData[i * 3 + 2] = palette[paletteOffset + 2]  // B
            } else {
                // 如果索引超出调色板范围，使用黑色
                rgbData[i * 3] = UInt8(0)
                rgbData[i * 3 + 1] = UInt8(0)
                rgbData[i * 3 + 2] = UInt8(0)
            }

            i += 1
        }

        rgbData
    }

    /**
     * 绘制图片到内容流
     */
    private func drawImage(imageName: String, x: Float32, y: Float32, width: Float32, height: Float32): Unit {
        // 保存图形状态
        getContent().saveState()

        // 设置变换矩阵：缩放并平移图片
        // PDF 的图片默认是 1x1 单位，需要缩放到实际大小
        getContent().concatCTM(width, 0.0, 0.0, height, x, y)

        // 绘制 XObject
        getContent().addXObject(imageName)

        // 恢复图形状态
        getContent().restoreState()
    }

    /**
     * 处理表格
     */
    private func processTable(table: PdfPTable): Bool {
        table.completeRow()

        _currentY -= table.spacingBefore

        let pageWidth = _pageSize.width - _marginLeft - _marginRight
        let tableWidth = if (table.lockedWidth) {
            table.totalWidth
        } else {
            pageWidth * (table.widthPercentage / 100.0)
        }

        let tableX = match (table.horizontalAlignment) {
            case Left => _marginLeft
            case Center => _marginLeft + (pageWidth - tableWidth) / 2.0
            case Right => _marginLeft + pageWidth - tableWidth
            case _ => _marginLeft
        }

        let columnWidths = calculateColumnWidths(table, tableWidth)
        let rowCount = table.rowCount

        // 预计算所有行高（rowspan 单元格渲染时需要累加多行高度）
        let rowHeights = Array<Float32>(Int64(rowCount), {_ => 0.0})
        var ri: Int32 = 0
        while (ri < rowCount) {
            let rowOpt = table.getRow(ri)
            if (rowOpt.isSome()) {
                rowHeights[Int64(ri)] = calculateRowHeight(rowOpt.getOrThrow(), columnWidths)
            }
            ri += 1
        }

        // 绘制所有行
        var rowIdx: Int32 = 0
        while (rowIdx < rowCount) {
            let rowH = rowHeights[Int64(rowIdx)]
            if (_currentY - rowH < _marginBottom) {
                newPage()
            }
            let rowOpt2 = table.getRow(rowIdx)
            if (rowOpt2.isSome()) {
                drawRowWithRowspan(rowOpt2.getOrThrow(), tableX, _currentY, columnWidths, rowH,
                                   rowHeights, rowIdx, rowCount)
            }
            _currentY -= rowH
            rowIdx += 1
        }

        _currentY -= table.spacingAfter
        true
    }

    /**
     * 在指定坐标绘制表格的指定行范围，返回绘制后的 Y 坐标
     * @param table 目标表格（已调用 completeRow）
     * @param firstRow 起始行（含），0-based
     * @param lastRow 结束行（不含），-1 表示到最后一行
     * @param x 左边 X 坐标
     * @param y 顶部 Y 坐标
     * @return 绘制后的 Y 坐标（最后一行底部）
     */
    public func writeSelectedRows(table: PdfPTable, firstRow: Int32, lastRow: Int32,
                                  x: Float32, y: Float32): Float32 {
        let rowCount = table.rowCount
        let actualLast = if (lastRow < 0 || lastRow > rowCount) { rowCount } else { lastRow }

        let columnWidths = if (table.lockedWidth) {
            table.getAbsoluteColumnWidths(table.totalWidth)
        } else {
            let pageWidth = _pageSize.width - _marginLeft - _marginRight
            table.getAbsoluteColumnWidths(pageWidth * (table.widthPercentage / 100.0))
        }

        // 预计算所有行高
        let rowHeights = Array<Float32>(Int64(rowCount), {_ => 0.0})
        var ri: Int32 = 0
        while (ri < rowCount) {
            let rowOpt = table.getRow(ri)
            if (rowOpt.isSome()) {
                rowHeights[Int64(ri)] = calculateRowHeight(rowOpt.getOrThrow(), columnWidths)
            }
            ri += 1
        }

        var currentY = y
        var rowIdx = firstRow
        while (rowIdx < actualLast) {
            let rowH = rowHeights[Int64(rowIdx)]
            let rowOpt2 = table.getRow(rowIdx)
            if (rowOpt2.isSome()) {
                drawRowWithRowspan(rowOpt2.getOrThrow(), x, currentY, columnWidths, rowH,
                                   rowHeights, rowIdx, rowCount)
            }
            currentY -= rowH
            rowIdx += 1
        }
        currentY
    }

    /**
     * 计算列宽
     */
    private func calculateColumnWidths(table: PdfPTable, totalWidth: Float32): Array<Float32> {
        table.getAbsoluteColumnWidths(totalWidth)
    }

    /**
     * 计算行高（colspan 感知，使用 cell.calculateHeight 精确换行估算）
     */
    private func calculateRowHeight(row: PdfPRow, columnWidths: Array<Float32>): Float32 {
        var maxHeight: Float32 = 0.0
        var cellIdx: Int32 = 0
        while (cellIdx < row.cellCount) {
            let cellOpt = row.getCell(cellIdx)
            if (cellOpt.isSome()) {
                let cell = cellOpt.getOrThrow()
                // rowspan > 1 的单元格不参与本行高度计算（其高度由跨行累计决定）
                if (cell.rowspan == 1) {
                    let colStart = row.getColumnPosition(cellIdx)
                    var cellWidth: Float32 = 0.0
                    var s: Int32 = 0
                    while (s < cell.colspan && (colStart + s) < Int32(columnWidths.size)) {
                        cellWidth += columnWidths[Int64(colStart + s)]
                        s += 1
                    }
                    let h = cell.calculateHeight(cellWidth)
                    if (h > maxHeight) {
                        maxHeight = h
                    }
                }
            }
            cellIdx += 1
        }
        if (maxHeight < 14.0) {
            maxHeight = 14.0
        }
        maxHeight
    }

    /**
     * 绘制单元格内的元素，返回新的 Y 坐标
     */
    private func drawCellElement(elem: Element, x: Float32, y: Float32): Float32 {
        match (elem) {
            case para: Paragraph => drawParagraphInCell(para, x, y)
            case _ => y
        }
    }

    /**
     * 在单元格中绘制段落
     */
    private func drawParagraphInCell(para: Paragraph, x: Float32, y: Float32): Float32 {
        // 与 OpenPDF 一致：先下移 spacingBefore，再下移 leading 到 baseline，最后返回 baseline - spacingAfter
        let newY = y - para.spacingBefore - para.leading
        let paraChunks = para.getChunks()
        var idx: Int64 = 0
        var currentX = x
        while (idx < paraChunks.size) {
            drawChunk(paraChunks[idx], currentX, newY, para.alignment)
            currentX += paraChunks[idx].getWidthPoint()
            idx += 1
        }
        newY - para.spacingAfter
    }

    /**
     * 绘制行（支持 colspan 和 rowspan）
     * rowspan > 1 的单元格高度 = 所跨各行高度之和
     */
    private func drawRowWithRowspan(row: PdfPRow, startX: Float32, startY: Float32,
                                    columnWidths: Array<Float32>, rowHeight: Float32,
                                    rowHeights: Array<Float32>, rowIdx: Int32, totalRows: Int32): Unit {
        var cellIdx: Int32 = 0
        while (cellIdx < row.cellCount) {
            let cellOpt = row.getCell(cellIdx)
            if (cellOpt.isSome()) {
                let cell = cellOpt.getOrThrow()
                let colStart = row.getColumnPosition(cellIdx)

                // 计算该单元格跨列总宽度
                var cellWidth: Float32 = 0.0
                var s: Int32 = 0
                while (s < cell.colspan && (colStart + s) < Int32(columnWidths.size)) {
                    cellWidth += columnWidths[Int64(colStart + s)]
                    s += 1
                }

                // 计算该单元格的 X 起始坐标
                var cellX: Float32 = startX
                var c: Int32 = 0
                while (c < colStart && c < Int32(columnWidths.size)) {
                    cellX += columnWidths[Int64(c)]
                    c += 1
                }

                // rowspan > 1：高度为所跨各行高度之和
                var cellHeight: Float32 = rowHeight
                if (cell.rowspan > 1) {
                    cellHeight = 0.0
                    var r: Int32 = rowIdx
                    while (r < rowIdx + cell.rowspan && r < totalRows) {
                        cellHeight += rowHeights[Int64(r)]
                        r += 1
                    }
                }

                drawCell(cell, cellX, startY, cellWidth, cellHeight)
            }
            cellIdx += 1
        }
    }

    /**
     * 绘制单元格
     */
    private func drawCell(cell: PdfPCell, x: Float32, y: Float32, width: Float32, height: Float32): Unit {
        // 绘制背景
        if (cell.backgroundColor.isSome()) {
            let bgColor = cell.backgroundColor.getOrThrow()
            getContent().setColorFill(bgColor)
            getContent().rectangle(x, y - height, width, height)
            getContent().fill()
            // 重置填充色为黑色，避免文本使用背景色
            getContent().setColorFill(Color(0, 0, 0))
        }

        // 绘制边框
        drawCellBorder(cell, x, y, width, height)

        // 绘制内容
        drawCellContent(cell, x, y, width, height)
    }

    /**
     * 绘制单元格边框
     */
    private func drawCellBorder(cell: PdfPCell, x: Float32, y: Float32, width: Float32, height: Float32): Unit {
        let border = cell.border

        if (border == 0) {
            return
        }

        // 设置边框颜色
        if (cell.borderColor.isSome()) {
            getContent().setColorStroke(cell.borderColor.getOrThrow())
        } else {
            getContent().setColorStroke(Color(0, 0, 0))
        }

        getContent().setLineWidth(cell.borderWidth)

        // 绘制上边框
        if ((border & Border.TOP) != 0) {
            getContent().moveTo(x, y)
            getContent().lineTo(x + width, y)
            getContent().stroke()
        }

        // 绘制下边框
        if ((border & Border.BOTTOM) != 0) {
            getContent().moveTo(x, y - height)
            getContent().lineTo(x + width, y - height)
            getContent().stroke()
        }

        // 绘制左边框
        if ((border & Border.LEFT) != 0) {
            getContent().moveTo(x, y)
            getContent().lineTo(x, y - height)
            getContent().stroke()
        }

        // 绘制右边框
        if ((border & Border.RIGHT) != 0) {
            getContent().moveTo(x + width, y)
            getContent().lineTo(x + width, y - height)
            getContent().stroke()
        }
    }

    /**
     * 绘制单元格内容
     */
    private func drawCellContent(cell: PdfPCell, x: Float32, y: Float32, width: Float32, height: Float32): Unit {
        // 计算内容区域
        let contentX = x + cell.paddingLeft
        let contentY = y - cell.paddingTop
        let contentWidth = width - cell.paddingLeft - cell.paddingRight
        let contentHeight = height - cell.paddingTop - cell.paddingBottom

        // 绘制 Phrase
        if (cell.phrase.isSome()) {
            let phrase = cell.phrase.getOrThrow()
            let font = phrase.font
            let fontSize = font.size

            // 垂直对齐：与 OpenPDF 一致，单行用 fontSize 作为行高
            let textY = match (cell.verticalAlignment) {
                case Top => contentY - fontSize
                case Middle => contentY - (contentHeight + fontSize) / 2.0
                case Bottom | Baseline => contentY - contentHeight + fontSize
            }

            // 水平对齐：计算总文字宽度后按对齐方式确定起始 x
            let chunks = phrase.getChunks()
            var totalTextWidth: Float32 = 0.0
            var chunkIdx: Int64 = 0
            while (chunkIdx < chunks.size) {
                totalTextWidth += chunks[chunkIdx].getWidthPoint()
                chunkIdx += 1
            }
            let startX: Float32 = match (cell.horizontalAlignment) {
                case Alignment.Center => contentX + (contentWidth - totalTextWidth) / 2.0
                case Alignment.Right => contentX + contentWidth - totalTextWidth
                case _ => contentX
            }

            // 逐 chunk 渲染（各 chunk 顺序排列）
            var cx = startX
            chunkIdx = 0
            while (chunkIdx < chunks.size) {
                drawChunk(chunks[chunkIdx], cx, textY, cell.horizontalAlignment)
                cx += chunks[chunkIdx].getWidthPoint()
                chunkIdx += 1
            }
        }

        // 绘制内容元素（Paragraph 等）
        var elementY = contentY
        var i: Int64 = 0
        while (i < cell.contentSize) {
            let elem = cell.getContentElement(i)
            elementY = drawCellElement(elem, contentX, elementY)
            i += 1
        }
    }

    /**
     * 绘制 Chunk
     */
    private func drawChunk(chunk: Chunk, x: Float32, y: Float32, alignment: Alignment): Unit {
        let font = chunk.font
        let baseFont = font.getCalculatedBaseFont()

        // 获取或创建字体资源
        let fontName = getOrCreateFont(baseFont)

        // ── 背景高亮：在文本 BT..ET 之前绘制填充矩形 ──
        match (chunk.background) {
            case Some(bgColor) =>
                let textWidth = baseFont.getWidthPoint(chunk.content, font.size)
                // OpenPDF: rectangle(x-1, y-size*0.2, width+2, size+2)
                let bgY = y - font.size * 0.2
                let bgH = font.size + 2.0
                getContent().saveState()
                getContent().setColorFill(bgColor)
                getContent().rectangle(x - 1.0, bgY, textWidth + 2.0, bgH)
                getContent().fill()
                getContent().restoreState()
            case None => ()
        }

        // ── 绘制文本 ──
        getContent().beginText()
        getContent().setFontAndSize(fontName, font.size)

        // 检查是否需要设置颜色
        let hasCustomColor = chunk.color.isSome() || font.color.isSome()

        // 设置颜色（优先使用 chunk 的颜色，其次使用 font 的颜色）
        if (hasCustomColor) {
            match (chunk.color) {
                case Some(color) => getContent().setColorFill(color)
                case None =>
                    match (font.color) {
                        case Some(color) => getContent().setColorFill(color)
                        case None => ()
                    }
            }
        } else {
            // 没有自定义颜色时，重置为黑色（避免继承之前的颜色）
            getContent().setColorFill(Color.BLACK)
        }

        // 粗体：使用 PDF 文本渲染模式 2（fill+stroke）模拟，与 OpenPDF 行为一致
        if (font.isBold()) {
            // 描边颜色与填充色保持一致
            match (chunk.color) {
                case Some(color) => getContent().setColorStroke(color)
                case None => match (font.color) {
                    case Some(color) => getContent().setColorStroke(color)
                    case None => getContent().setColorStroke(Color.BLACK)
                }
            }
            getContent().setTextRenderingMode(2)
            getContent().setLineWidth(font.size / 30.0)
        }

        // 设置文本矩阵，如果是斜体则应用倾斜变换
        if (font.isItalic()) {
            // tan(12°) ≈ 0.21256，与 OpenPDF PdfWriter.ITALIC_ANGLE 一致
            getContent().setTextMatrix(1.0, 0.0, 0.21256, 1.0, x, y)
        } else {
            getContent().setTextMatrix(x, y)
        }

        // 根据字体编码选择输出方式
        let useUnicode = baseFont.isUnicodeEncoding()
        baseFont.markStringUsed(chunk.content)
        // 两端对齐时，词间距通过 TJ kern 实现（因 Tw 对 CID 字体的空格 GID 无效）
        if (_justifyWordSpacing > 0.0 && useUnicode) {
            getContent().showTextWithWordSpacing(chunk.content, _justifyWordSpacing, font.size, Some(baseFont))
        } else {
            getContent().showText(chunk.content, useUnicode, Some(baseFont))
        }

        // 粗体渲染模式重置
        if (font.isBold()) {
            getContent().setTextRenderingMode(0)
            getContent().setLineWidth(1.0)
        }

        getContent().endText()

        // ── 下划线 / 删除线：在文本之后绘制线条 ──
        if (chunk.underline || chunk.strikethrough) {
            let textWidth = baseFont.getWidthPoint(chunk.content, font.size)
            var lineThickness = font.size * 0.05
            if (lineThickness < 0.5) {
                lineThickness = 0.5
            }
            // 线条颜色：优先 chunk 颜色，然后 font 颜色，最后黑色
            let lineColor = match (chunk.color) {
                case Some(c) => c
                case None => match (font.color) {
                    case Some(c) => c
                    case None => Color.BLACK
                }
            }
            getContent().saveState()
            getContent().setColorStroke(lineColor)
            getContent().setLineWidth(lineThickness)
            if (chunk.underline) {
                // OpenPDF: fixed −2pt below baseline
                let lineY = y - 2.0
                getContent().moveTo(x, lineY)
                getContent().lineTo(x + textWidth, lineY)
                getContent().stroke()
            }
            if (chunk.strikethrough) {
                // OpenPDF: fontSize/3 above baseline
                let lineY = y + font.size / 3.0
                getContent().moveTo(x, lineY)
                getContent().lineTo(x + textWidth, lineY)
                getContent().stroke()
            }
            getContent().restoreState()
        }
    }

    /**
     * 添加字体到文档
     * 返回字体在 PDF 资源中的名称（如 "F1", "F2" 等）
     */
    public func addFont(baseFont: BaseFont): String {
        getOrCreateFont(baseFont)
    }

    /**
     * 获取或创建字体资源
     */
    private func getOrCreateFont(baseFont: BaseFont): String {
        // 检查缓存
        for (entry in _fontReferences) {
            if (entry.fontName == baseFont.name) {
                return _resources.addFont(baseFont, entry.reference)
            }
        }

        let fontRef = if (baseFont.isUnicodeEncoding()) {
            // Unicode 字体 - 创建 Type0 + CIDFont 结构
            createCIDFont(baseFont)
        } else {
            // 标准字体 - 创建 Type1 字体
            createType1Font(baseFont)
        }

        // 缓存
        _fontReferences.add(FontRefEntry(baseFont.name, fontRef))

        // 添加到资源
        _resources.addFont(baseFont, fontRef)
    }

    /**
     * 创建标准 Type1 字体
     */
    private func createType1Font(baseFont: BaseFont): PdfIndirectReference {
        let fontDict = PdfDictionary()
        fontDict.put(PdfName.TYPE, PdfName.FONT)
        fontDict.put(PdfName.SUBTYPE, PdfName.TYPE1)
        fontDict.put(PdfName.BASEFONT, PdfName(baseFont.name))
        fontDict.put(PdfName.ENCODING, PdfName.WINANSIENCODING)

        _body.add(fontDict)
    }

    /**
     * 创建 CIDFont（用于 Unicode 字体）
     */
    private func createCIDFont(baseFont: BaseFont): PdfIndirectReference {
        // 创建 CIDSystemInfo 字典
        let cidSystemInfo = PdfDictionary()
        cidSystemInfo.put(PdfName("Registry"), PdfString("Adobe"))
        cidSystemInfo.put(PdfName("Ordering"), PdfString("Identity"))
        cidSystemInfo.put(PdfName("Supplement"), PdfNumber(0))

        // 判断是否为 CFF（OpenType）字体
        let isCFF = match (baseFont.getTrueTypeFont()) {
            case Some(ttf) => ttf.isCFF()
            case None => false
        }

        // 创建 CIDFont 字典（DescendantFonts）
        // CFF 字体用 CIDFontType0，TrueType 字体用 CIDFontType2
        let cidFont = PdfDictionary()
        cidFont.put(PdfName.TYPE, PdfName.FONT)
        cidFont.put(PdfName("Subtype"), PdfName(if (isCFF) { "CIDFontType0" } else { "CIDFontType2" }))
        cidFont.put(PdfName.BASEFONT, PdfName(baseFont.getPdfFontName()))
        cidFont.put(PdfName("CIDSystemInfo"), cidSystemInfo)

        // 添加默认宽度（CJK 全角字符通常为 1000 单位）
        cidFont.put(PdfName("DW"), PdfNumber(1000))

        // 预留 W 数组对象编号（在 close() 时根据实际使用的字形写入实际宽度）
        let wArrayObjNum = _body.reserveObjectNumber()
        cidFont.put(PdfName("W"), PdfIndirectReference(wArrayObjNum))
        _pendingWArrays.add(PendingWArray(wArrayObjNum, baseFont))

        // CIDToGIDMap：仅 TrueType（CIDFontType2）需要
        // 嵌入字体使用流式 CIDToGIDMap（旧 GID → 紧凑新 GID），未嵌入字体用 Identity
        if (!isCFF) {
            if (baseFont.isEmbedded && baseFont.getFontSubset().isSome()) {
                let cidToGIDObjNum = _body.reserveObjectNumber()
                cidFont.put(PdfName("CIDToGIDMap"), PdfIndirectReference(cidToGIDObjNum))
                _pendingCIDToGIDMaps.add(PendingCIDToGIDMap(cidToGIDObjNum, baseFont))
            } else {
                cidFont.put(PdfName("CIDToGIDMap"), PdfName("Identity"))
            }
        }

        // 只有在嵌入字体时才创建 FontDescriptor
        if (baseFont.isEmbedded && baseFont.path.isSome()) {
            let fontDescriptor = createFontDescriptor(baseFont)
            let descriptorRef = _body.add(fontDescriptor)
            cidFont.put(PdfName("FontDescriptor"), descriptorRef)
        }

        // 将 CIDFont 添加到文档
        let cidFontRef = _body.add(cidFont)

        // 创建 Type0 字体字典
        let fontDict = PdfDictionary()
        fontDict.put(PdfName.TYPE, PdfName.FONT)
        fontDict.put(PdfName.SUBTYPE, PdfName("Type0"))
        fontDict.put(PdfName.BASEFONT, PdfName(baseFont.getPdfFontName()))
        fontDict.put(PdfName.ENCODING, PdfName("Identity-H"))

        // 设置 DescendantFonts
        let descendantFonts = PdfArray()
        descendantFonts.add(cidFontRef)
        fontDict.put(PdfName("DescendantFonts"), descendantFonts)

        // 添加 ToUnicode CMap（可选，用于文本提取）
        // 这里暂时省略，因为需要创建完整的 CMap

        _body.add(fontDict)
    }

    /**
     * 构建 CIDFont W 数组（仅包含与 DW 不同的字形宽度）
     * W 数组格式：[glyphId [width] glyphId [width] ...]
     */
    private func buildWArray(baseFont: BaseFont): PdfArray {
        let wArray = PdfArray()
        match (baseFont.getTrueTypeFont()) {
            case Some(ttf) =>
                let unitsPerEm = ttf.getUnitsPerEm()
                if (unitsPerEm <= 0) {
                    return wArray
                }
                let dwUnits: Int32 = 1000  // 对应 DW=1000

                // 收集所有已用字形 ID（嵌入字体通过 FontSubsetting 跟踪）
                let glyphIds: ArrayList<UInt16> = match (baseFont.getFontSubset()) {
                    case Some(subset) => subset.getUsedGlyphIds()
                    case None => ArrayList<UInt16>()
                }

                for (gid in glyphIds) {
                    let widthInFontUnits = ttf.getGlyphWidth(gid)
                    // 转换为 PDF 字体单位（以 1000 为基准）
                    let widthIn1000: Int32 = (widthInFontUnits * 1000) / unitsPerEm
                    if (widthIn1000 != dwUnits) {
                        wArray.add(PdfNumber(Int32(gid)))
                        let entry = PdfArray()
                        entry.add(PdfNumber(widthIn1000))
                        wArray.add(entry)
                    }
                }
            case None => ()
        }
        wArray
    }

    /**
     * 创建字体描述符（FontDescriptor）
     */
    private func createFontDescriptor(baseFont: BaseFont): PdfDictionary {
        let descriptor = PdfDictionary()
        descriptor.put(PdfName.TYPE, PdfName("FontDescriptor"))
        descriptor.put(PdfName("FontName"), PdfName(baseFont.getPdfFontName()))

        // 从 TrueType 字体获取度量（如果有）
        match (baseFont.getTrueTypeFont()) {
            case Some(ttf) =>
                // 使用实际的字体度量
                descriptor.put(PdfName("Flags"), PdfNumber(4))  // Symbolic for CJK
                descriptor.put(PdfName("FontBBox"), createFontBBox())
                descriptor.put(PdfName("ItalicAngle"), PdfNumber(0))

                // 将字体单位转换为 PDF 单位
                let scale = 1000.0 / Float32(ttf.getUnitsPerEm())
                let ascent = Int32(Float32(ttf.getAscent()) * scale)
                let descent = Int32(Float32(ttf.getDescent()) * scale)

                descriptor.put(PdfName("Ascent"), PdfNumber(ascent))
                descriptor.put(PdfName("Descent"), PdfNumber(descent))
                descriptor.put(PdfName("CapHeight"), PdfNumber(ascent))
                descriptor.put(PdfName("StemV"), PdfNumber(80))

                // 嵌入字体文件：预留对象编号，延迟到 close() 写入
                // CFF 字体用 FontFile3，TrueType 字体用 FontFile2
                if (baseFont.isEmbedded) {
                    let fontFileObjNum = _body.reserveObjectNumber()
                    let fontFileRef = PdfIndirectReference(fontFileObjNum)
                    if (ttf.isCFF()) {
                        descriptor.put(PdfName("FontFile3"), fontFileRef)
                    } else {
                        descriptor.put(PdfName("FontFile2"), fontFileRef)
                    }
                    _pendingFontFiles.add(PendingFontFile(fontFileObjNum, ttf, baseFont))
                }
            case None =>
                // 使用默认值
                descriptor.put(PdfName("Flags"), PdfNumber(32))
                descriptor.put(PdfName("FontBBox"), createFontBBox())
                descriptor.put(PdfName("ItalicAngle"), PdfNumber(0))
                descriptor.put(PdfName("Ascent"), PdfNumber(880))
                descriptor.put(PdfName("Descent"), PdfNumber(-120))
                descriptor.put(PdfName("CapHeight"), PdfNumber(880))
                descriptor.put(PdfName("StemV"), PdfNumber(80))
        }

        descriptor
    }

    /**
     * 创建字体文件流
     * CFF 字体：提取原始 CFF 表数据，用 FontFile3/CIDFontType0C 嵌入（不子集化）
     * TrueType 字体：生成子集 TTF，用 FontFile2 嵌入
     */
    private func createFontFileStream(ttf: TrueTypeFont, baseFont: BaseFont): PdfStream {
        let stream = PdfStream()

        if (ttf.isCFF()) {
            // OpenType/CFF 字体：子集化后嵌入 CFF 表数据，压缩写入
            let rawCFF: Array<UInt8> = match (ttf.getRawTable("CFF ")) {
                case Some(d) => d
                case None => Array<UInt8>(0, repeat: UInt8(0))
            }
            let cffData: Array<UInt8> = match (baseFont.getFontSubset()) {
                case Some(subset) =>
                    let sub = subset.generateCFFSubset(rawCFF)
                    if (sub.size > 0 && sub.size < rawCFF.size) { sub } else { rawCFF }
                case None => rawCFF
            }
            stream.put(PdfName("Subtype"), PdfName("CIDFontType0C"))
            let compressedCFF = FlateEncoder.encode(cffData)
            stream.put(PdfName.FILTER, PdfName.FLATEDECODE)
            stream.setContent(compressedCFF)
        } else {
            // TrueType 字体：使用子集数据，压缩写入
            let fontData: Array<UInt8> = match (baseFont.getFontSubset()) {
                case Some(subset) =>
                    let subsetData = subset.generateSubsetFont()
                    if (subsetData.size > 0) { subsetData } else { ttf.getFontData() }
                case None => ttf.getFontData()
            }
            // Length1 = 未压缩字体数据大小（FontFile2 规范要求）
            stream.put(PdfName("Length1"), PdfNumber(Int32(fontData.size)))
            let compressedFont = FlateEncoder.encode(fontData)
            stream.put(PdfName.FILTER, PdfName.FLATEDECODE)
            stream.setContent(compressedFont)
        }

        stream
    }

    /**
     * 创建字体边界框
     */
    private func createFontBBox(): PdfArray {
        let bbox = PdfArray()
        bbox.add(PdfNumber(-100))
        bbox.add(PdfNumber(-100))
        bbox.add(PdfNumber(1000))
        bbox.add(PdfNumber(900))
        bbox
    }

    /**
     * 绘制页眉页脚
     */
    private func drawHeaderFooter(hf: HeaderFooter, isHeader: Bool): Unit {
        let y = if (isHeader) {
            _pageSize.height - _marginTop / 2.0
        } else {
            _marginBottom / 2.0
        }

        // 获取字体：优先使用 before 的字体，否则使用 after 的字体，最后使用默认字体
        let font = match (hf.before) {
            case Some(p) => p.font
            case None =>
                match (hf.after) {
                    case Some(p) => p.font
                    case None => Font.DEFAULT
                }
        }

        let beforeContent = match (hf.before) {
            case Some(p) => p.getContent()
            case None => ""
        }

        let afterContent = match (hf.after) {
            case Some(p) => p.getContent()
            case None => ""
        }

        let phrase = if (hf.isNumbered) {
            beforeContent + _pageNumber.toString() + afterContent
        } else {
            beforeContent + afterContent
        }

        // 创建临时 Chunk，使用原始 Phrase 的字体
        let chunk = Chunk(phrase, font)
        drawChunk(chunk, _marginLeft, y, hf.alignment)
    }

    // ===== 公共属性 =====

    /**
     * 获取当前页码
     */
    public prop pageNumber: Int32 {
        get() { _pageNumber }
    }

    /**
     * 获取页面大小
     */
    public prop pageSize: Rectangle {
        get() { _pageSize }
    }

    /**
     * 设置 PDF 版本
     */
    public func setPdfVersion(version: String): Unit {
        this._pdfVersion = version
    }

    /**
     * 设置 PDF 加密
     * 调用 document.open() 之前设置，确保 /Encrypt 写入 trailer。
     */
    public func setEncryption(enc: PdfEncryption): Unit {
        this._encryption = Some(enc)
    }

    // 在把流加入 body 之前，用 per-object 密钥加密其内容
    private func encryptStream(stream: PdfStream, objNum: Int32): Unit {
        match (_encryption) {
            case Some(enc) =>
                let content = stream.getContent()
                if (content.size > 0) {
                    let encrypted = enc.encryptBytes(content, objNum, 0i32)
                    stream.setContent(encrypted)
                }
            case None => ()
        }
    }

    /**
     * 获取直接内容（用于高级绘图）
     */
    public func getDirectContent(): PdfContentByte {
        getContent()
    }

    /**
     * 获取文档
     */
    public prop document: ?Document {
        get() { _document }
    }

    /**
     * 获取 Body（用于添加对象）
     */
    public prop body: PdfBody {
        get() { _body }
    }

    /**
     * 获取资源
     */
    public prop resources: PdfResources {
        get() { _resources }
    }

    /**
     * 获取当前文档流 Y 坐标（PDF 坐标系，从页面底部算起，向上为正）
     * 可在 document.add() 前后读取，用于精确定位表单字段
     */
    public prop currentY: Float32 {
        get() { _currentY }
    }

    /**
     * 获取左边距
     */
    public prop marginLeft: Float32 {
        get() { _marginLeft }
    }

    // ── 透明度与渐变 API ────────────────────────────────────────────────────

    /**
     * 注册扩展图形状态（透明度/混合模式）
     * @return ExtGState 资源名称，供 cb.setExtGState(name) 使用
     */
    public func addGState(gstate: PdfGState): String {
        let dict = gstate.toDictionary()
        let ref = _body.add(dict)
        _resources.addExtGState(ref)
    }

    /**
     * 注册渐变填充图案（ShadingPattern）
     * @return Pattern 资源名称，供 cb.setColorFillPattern(name) 使用
     */
    public func addShadingPattern(pattern: PdfShadingPattern): String {
        let dict = pattern.toDictionary()
        let ref = _body.add(dict)
        _resources.addPattern(ref)
    }

    /**
     * 注册渐变对象供 sh 操作符直接使用
     * @return Shading 资源名称，供 cb.paintShading(name) 使用
     */
    public func addShading(shading: PdfShading): String {
        let dict = shading.toDictionary()
        let ref = _body.add(dict)
        _resources.addShading(ref)
    }
}

/**
 * 字体引用缓存条目
 */
class FontRefEntry {
    public let fontName: String
    public let reference: PdfIndirectReference

    public init(fontName: String, reference: PdfIndirectReference) {
        this.fontName = fontName
        this.reference = reference
    }
}

/**
 * 延迟写入的字体文件条目
 */
class PendingFontFile {
    public let objNum: Int32
    public let ttf: TrueTypeFont
    public let baseFont: BaseFont

    public init(objNum: Int32, ttf: TrueTypeFont, baseFont: BaseFont) {
        this.objNum = objNum
        this.ttf = ttf
        this.baseFont = baseFont
    }
}

/**
 * 延迟写入的 CIDToGIDMap 流条目
 * 在字体文件写入（generateSubsetFont 填充 glyphMapping）之后写入
 */
class PendingCIDToGIDMap {
    public let objNum: Int32
    public let baseFont: BaseFont

    public init(objNum: Int32, baseFont: BaseFont) {
        this.objNum = objNum
        this.baseFont = baseFont
    }
}

class PendingWArray {
    public let objNum: Int32
    public let baseFont: BaseFont

    public init(objNum: Int32, baseFont: BaseFont) {
        this.objNum = objNum
        this.baseFont = baseFont
    }
}
