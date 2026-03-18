/**
 * PDF-CJ: PdfWriter - PDF 写入器
 * 核心写入器，实现 DocListener 接口
 */
package pdf_cj.core

import std.io.OutputStream
import std.collection.ArrayList
import pdf_cj.base.{
    PdfObject, PdfDictionary, PdfName, PdfNumber, PdfString, PdfArray,
    PdfStream, PdfIndirectReference, PdfOutputStream, PdfFileOutputStream
}
import pdf_cj.api.{Document, DocListener, Element, ElementType, Paragraph, Phrase, Chunk, HeaderFooter}
import pdf_cj.util.{Rectangle, PageSize, PdfException}
import pdf_cj.text.{Font, BaseFont, Alignment, TrueTypeFont, Color, Border}
import pdf_cj.table.{PdfPTable, PdfPCell, PdfPRow, VerticalAlignment}
import pdf_cj.image.{Image, ImageType, PngParser, PngInfo}
import pdf_cj.codec.FlateEncoder
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

        // 初始化页面设置
        match (_document) {
            case Some(doc) => initializePageSettings(doc)
            case None => ()
        }

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

        // 预留对象编号
        let catalogObjNum = _body.reserveObjectNumber()
        let pagesObjNum = _body.reserveObjectNumber()
        let infoObjNum = _body.reserveObjectNumber()

        // 写入页面树
        let pagesRef = PdfIndirectReference(pagesObjNum)
        _body.add(_pages.dictionary, pagesObjNum)

        // 写入 Catalog
        _catalog.setPages(pagesRef)
        let catalogRef = _body.add(_catalog.dictionary, catalogObjNum)

        // 写入文档信息
        let infoRef = _body.add(_info.dictionary, infoObjNum)

        // 写入交叉引用表
        let xrefPos = _body.writeXref()

        // 写入 Trailer
        writeTrailer(catalogRef, infoRef, xrefPos)

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

        // 创建新页面
        _currentPage = Some(PdfPage(_pageSize))
        _currentContent = PdfContentByte(this)
        _resources = PdfResources()

        // 重置绘图位置
        _currentY = _pageSize.height - _marginTop

        // 绘制页眉
        match (_header) {
            case Some(header) => drawHeaderFooter(header, true)
            case None => ()
        }

        true
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
    private func writeTrailer(catalogRef: PdfIndirectReference, infoRef: PdfIndirectReference, xrefPos: Int64): Unit {
        _outputStream.writeString("trailer")
        _outputStream.writeNewLine()

        let trailer = PdfDictionary()
        trailer.put(PdfName.SIZE, PdfNumber(Int32(_body.objectCount + 1)))
        trailer.put(PdfName.ROOT, catalogRef)
        trailer.put(PdfName.INFO, infoRef)

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
        // 绘制页脚
        match (_footer) {
            case Some(footer) => drawHeaderFooter(footer, false)
            case None => ()
        }

        // 写入内容流
        let contentStream = getContent().toStream()
        let contentRef = _body.add(contentStream)
        page.setContents(contentRef)

        // 设置资源
        page.setResources(_resources.toDictionary())

        // 获取页面树引用
        let pagesObjNum = _body.objectCount + 2  // 预估
        page.setParent(PdfIndirectReference(pagesObjNum))

        // 写入页面
        let pageRef = _body.add(page.dictionary)
        _pages.addPage(pageRef)
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
        // 段前间距
        _currentY -= para.spacingBefore

        // 检查是否需要分页
        let estimatedHeight = para.getTotalHeight()
        if (_currentY - estimatedHeight < _marginBottom) {
            newPage()
        }

        // 计算段落位置
        let leftX = _marginLeft + para.indentationLeft + para.firstLineIndent
        let rightX = _pageSize.width - _marginRight - para.indentationRight
        let width = rightX - leftX

        // 绘制段落内容
        var currentX = leftX
        for (chunk in para.getChunks()) {
            drawChunk(chunk, currentX, _currentY, para.alignment)
            // 累加当前 chunk 的宽度，以便下一个 chunk 能正确排列
            currentX += chunk.getWidthPoint()
        }

        // 更新 Y 位置
        _currentY -= para.leading

        // 段后间距
        _currentY -= para.spacingAfter

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
        drawChunk(chunk, _marginLeft, _currentY, Alignment.Left)
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

        // 检查是否需要分页
        let imageHeight = image.scaledHeight
        if (_currentY - imageHeight < _marginBottom) {
            newPage()
        }

        // 创建图片 XObject
        let imageXObject = createImageXObject(image, rawData)

        // 添加到资源并获取名称
        let imageRef = _body.add(imageXObject)
        let imageName = _resources.addXObject(imageRef)

        // 计算图片位置
        let imageWidth = image.scaledWidth
        let pageWidth = _pageSize.width - _marginLeft - _marginRight

        println("[PDF Writer] Drawing image: ${imageWidth} x ${imageHeight}")

        let imageX = match (image.alignment) {
            case Alignment.Left => _marginLeft
            case Alignment.Center => _marginLeft + (pageWidth - imageWidth) / 2.0
            case Alignment.Right => _marginLeft + pageWidth - imageWidth
            case _ => _marginLeft
        }

        // 计算 Y 位置（PDF 坐标系从下往上）
        let imageY = _currentY - imageHeight

        println("[PDF Writer] Position: (${imageX}, ${imageY})")

        // 绘制图片
        drawImage(imageName, imageX, imageY, imageWidth, imageHeight)

        // 更新 Y 位置
        _currentY -= imageHeight

        true
    }

    /**
     * 创建图片 XObject
     */
    private func createImageXObject(image: Image, rawData: Array<UInt8>): PdfStream {
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
                stream.put(PdfName("ColorSpace"), PdfName("DeviceRGB"))
                stream.put(PdfName("BitsPerComponent"), PdfNumber(8))
                stream.setContent(rawData)
            case ImageType.Png =>
                // PNG：提取IDAT数据并使用FlateDecode
                createPngXObject(stream, rawData)
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
                    println("[PNG] ✓ Decompressed: ${decompressedData.size} bytes")

                    // 应用PNG滤波器还原
                    let imageData = applyPngFilters(decompressedData, pngInfo)
                    println("[PNG] ✓ After filters: ${imageData.size} bytes")

                    // 统计颜色
                    var redCount: Int64 = 0
                    var i: Int64 = 0
                    while (i < imageData.size) {
                        if (imageData[i] > UInt8(100)) {
                            redCount += 1
                        }
                        i += 3
                    }
                    println("[PNG] ✓ Red pixels: ${redCount}")

                    // 设置颜色空间
                    let colorSpace = match (pngInfo.colorType) {
                        case 0 => "DeviceGray"  // 灰度
                        case 2 => "DeviceRGB"   // RGB
                        case 3 => "DeviceRGB"   // 索引色（简化为RGB）
                        case 4 => "DeviceGray"  // 灰度+Alpha（简化为灰度）
                        case 6 => "DeviceRGB"   // RGBA（简化为RGB）
                        case _ => "DeviceRGB"
                    }
                    println("[PNG] ✓ ColorSpace: ${colorSpace}")
                    stream.put(PdfName("ColorSpace"), PdfName(colorSpace))
                    stream.put(PdfName("BitsPerComponent"), PdfNumber(Int32(pngInfo.bitDepth)))

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
                    println("[PNG] ✓ Added Decode array: [0 1 0 1 0 1]")

                    // 重新压缩数据用于 PDF
                    let compressedData = FlateEncoder.encode(imageData)
                    println("[PNG] ✓ Compressed for PDF: ${compressedData.size} bytes")

                    // 验证压缩数据：尝试解压看看是否正确
                    let testDecompressed = FlateEncoder.decode(compressedData)
                    println("[PNG] ✓ Test decompress: ${testDecompressed.size} bytes")
                    if (testDecompressed.size != imageData.size) {
                        println("[PNG] ⚠ WARNING: Size mismatch! Original: ${imageData.size}, Decompressed: ${testDecompressed.size}")
                    }
                    // 比较前几个字节
                    var dataMatches = true
                    var checkCount: Int64 = 0
                    while (checkCount < 100 && checkCount < imageData.size) {
                        if (imageData[checkCount] != testDecompressed[checkCount]) {
                            dataMatches = false
                            break
                        }
                        checkCount += 1
                    }
                    if (dataMatches) {
                        println("[PNG] ✓ Compression verification passed")
                    } else {
                        println("[PNG] ❌ WARNING: Compression verification failed!")
                    }

                    stream.put(PdfName.FILTER, PdfName.FLATEDECODE)
                    stream.setContent(compressedData)
                    println("[PNG] ✓ PNG processing completed successfully")
                } catch (e: Exception) {
                    // 如果处理失败，回退到简化处理（创建占位图片）
                    println("[PNG] ❌ ERROR: ${e}")
                    println("[PNG] Creating placeholder image")
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
        // 确保最后一行已完成
        table.completeRow()

        // 表前间距
        _currentY -= table.spacingBefore

        // 计算表格宽度
        let pageWidth = _pageSize.width - _marginLeft - _marginRight
        let tableWidth = if (table.lockedWidth) {
            table.totalWidth
        } else {
            pageWidth * (table.widthPercentage / 100.0)
        }

        // 计算表格起始 X 坐标（根据对齐方式）
        let tableX = match (table.horizontalAlignment) {
            case Left => _marginLeft
            case Center => _marginLeft + (pageWidth - tableWidth) / 2.0
            case Right => _marginLeft + pageWidth - tableWidth
            case _ => _marginLeft
        }

        // 计算列宽
        let columnWidths = calculateColumnWidths(table, tableWidth)

        // 绘制所有行
        var rowIndex: Int32 = 0
        while (rowIndex < table.rowCount) {
            let rowOpt = table.getRow(rowIndex)
            if (rowOpt.isSome()) {
                let row = rowOpt.getOrThrow()

                // 计算行高
                let rowHeight = calculateRowHeight(row, columnWidths)

                // 检查是否需要分页
                if (_currentY - rowHeight < _marginBottom) {
                    newPage()
                }

                // 绘制行
                drawRow(row, tableX, _currentY, columnWidths, rowHeight, table.columns)

                // 更新 Y 位置
                _currentY -= rowHeight
            }
            rowIndex += 1
        }

        // 表后间距
        _currentY -= table.spacingAfter

        true
    }

    /**
     * 计算列宽
     */
    private func calculateColumnWidths(table: PdfPTable, totalWidth: Float32): Array<Float32> {
        let numColumns = table.columns
        Array<Float32>(Int64(numColumns), {_ => totalWidth / Float32(numColumns)})
    }

    /**
     * 计算行高
     */
    private func calculateRowHeight(row: PdfPRow, columnWidths: Array<Float32>): Float32 {
        var maxHeight: Float32 = 0.0

        var cellIndex: Int32 = 0
        while (cellIndex < row.cellCount) {
            let cellOpt = row.getCell(cellIndex)
            if (cellOpt.isSome()) {
                let cell = cellOpt.getOrThrow()
                let height = calculateCellHeight(cell, columnWidths[Int64(cellIndex)])
                if (height > maxHeight) {
                    maxHeight = height
                }
            }
            cellIndex += 1
        }

        if (maxHeight < 20.0) {
            maxHeight = 20.0  // 最小行高
        }

        maxHeight
    }

    /**
     * 计算单元格高度
     */
    private func calculateCellHeight(cell: PdfPCell, width: Float32): Float32 {
        // 固定高度
        if (cell.fixedHeight > 0.0) {
            return cell.fixedHeight
        }

        // 估算内容高度
        var contentHeight: Float32 = 0.0

        // 处理 Phrase
        if (cell.phrase.isSome()) {
            let phrase = cell.phrase.getOrThrow()
            contentHeight = phrase.leading + 5.0
        }

        // 处理内容元素
        var i: Int64 = 0
        while (i < cell.contentSize) {
            contentHeight += getElementHeight(cell.getContentElement(i))
            i += 1
        }

        // 添加内边距
        contentHeight += cell.paddingTop + cell.paddingBottom

        // 应用最小高度
        if (contentHeight < cell.minimumHeight) {
            contentHeight = cell.minimumHeight
        }

        contentHeight
    }

    /**
     * 获取元素高度
     */
    private func getElementHeight(elem: Element): Float32 {
        match (elem) {
            case para: Paragraph => para.leading + 5.0
            case _ => 15.0
        }
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
        let newY = y - para.leading
        let paraChunks = para.getChunks()
        var idx: Int64 = 0
        var currentX = x
        while (idx < paraChunks.size) {
            drawChunk(paraChunks[idx], currentX, newY, para.alignment)
            // 累加 chunk 宽度
            currentX += paraChunks[idx].getWidthPoint()
            idx += 1
        }
        newY
    }

    /**
     * 绘制行
     */
    private func drawRow(row: PdfPRow, startX: Float32, startY: Float32,
                         columnWidths: Array<Float32>, rowHeight: Float32, numColumns: Int32): Unit {
        var currentX = startX
        var columnPos: Int32 = 0  // 当前列位置
        var cellArrayIndex: Int32 = 0  // 单元格数组索引

        while (columnPos < numColumns && cellArrayIndex < row.cellCount) {
            let cellOpt = row.getCell(cellArrayIndex)

            if (cellOpt.isSome()) {
                let cell = cellOpt.getOrThrow()
                let colspan = cell.colspan

                // 计算跨列单元格的总宽度
                var cellWidth: Float32 = 0.0
                var spanIdx: Int32 = 0
                while (spanIdx < colspan && (columnPos + spanIdx) < numColumns) {
                    cellWidth += columnWidths[Int64(columnPos + spanIdx)]
                    spanIdx += 1
                }

                drawCell(cell, currentX, startY, cellWidth, rowHeight)

                // 更新位置
                currentX += cellWidth
                columnPos += colspan
                cellArrayIndex += 1
            } else {
                // 空单元格（不应该发生，但作为安全检查）
                currentX += columnWidths[Int64(columnPos)]
                columnPos += 1
                cellArrayIndex += 1
            }
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

            // 计算垂直对齐
            let textY = match (cell.verticalAlignment) {
                case Top => contentY - phrase.leading
                case Middle => contentY - (contentHeight - phrase.leading) / 2.0
                case Bottom => contentY - contentHeight + phrase.leading
            }

            // 绘制文本
            let chunks = phrase.getChunks()
            var chunkIdx: Int64 = 0
            while (chunkIdx < chunks.size) {
                drawChunk(chunks[chunkIdx], contentX, textY, cell.horizontalAlignment)
                chunkIdx += 1
            }
        }

        // 绘制内容元素
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

        // 绘制文本
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

        // 设置文本矩阵，如果是斜体则应用倾斜变换
        if (font.isItalic()) {
            // 斜体倾斜变换矩阵：[1, 0, 0.21, 1, x, y]
            // 0.21 是标准的斜体倾斜系数（约相当于 12 度）
            getContent().setTextMatrix(1.0, 0.0, 0.21, 1.0, x, y)
        } else {
            getContent().setTextMatrix(x, y)
        }

        // 根据字体编码选择输出方式
        let useUnicode = baseFont.isUnicodeEncoding()
        // 传递 BaseFont 以支持 Unicode 到 Glyph ID 的转换
        getContent().showText(chunk.content, useUnicode, Some(baseFont))

        // 如果是粗体且没有真正的粗体字体，通过重复绘制模拟粗体效果
        if (font.isBold()) {
            // 模拟粗体：略微偏移后再次绘制（fake bold）
            let offset: Float32 = font.size / 30.0  // 偏移量约为字号的 1/30
            getContent().setTextMatrix(x + offset, y)
            getContent().showText(chunk.content, useUnicode, Some(baseFont))
        }

        getContent().endText()
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

        // 创建 CIDFont 字典（DescendantFonts）
        let cidFont = PdfDictionary()
        cidFont.put(PdfName.TYPE, PdfName.FONT)
        cidFont.put(PdfName("Subtype"), PdfName("CIDFontType2"))
        cidFont.put(PdfName.BASEFONT, PdfName(baseFont.name))
        cidFont.put(PdfName("CIDSystemInfo"), cidSystemInfo)

        // 添加默认宽度
        cidFont.put(PdfName("DW"), PdfNumber(1000))

        // 设置 CIDToGIDMap 为 Identity
        // 这表示 CID（我们输出的 Glyph ID）直接对应字体中的 Glyph ID
        cidFont.put(PdfName("CIDToGIDMap"), PdfName("Identity"))

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
        fontDict.put(PdfName.BASEFONT, PdfName(baseFont.name))
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
     * 创建字体描述符（FontDescriptor）
     */
    private func createFontDescriptor(baseFont: BaseFont): PdfDictionary {
        let descriptor = PdfDictionary()
        descriptor.put(PdfName.TYPE, PdfName("FontDescriptor"))
        descriptor.put(PdfName("FontName"), PdfName(baseFont.name))

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

                // 嵌入字体文件
                if (baseFont.isEmbedded) {
                    let fontStream = createFontFileStream(ttf)
                    let fontFileRef = _body.add(fontStream)
                    descriptor.put(PdfName("FontFile2"), fontFileRef)  // TrueType
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
     */
    private func createFontFileStream(ttf: TrueTypeFont): PdfStream {
        let fontData = ttf.getFontData()

        let stream = PdfStream()
        stream.setContent(fontData)

        // 添加字体文件长度
        stream.put(PdfName("Length1"), PdfNumber(Int32(fontData.size)))

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
