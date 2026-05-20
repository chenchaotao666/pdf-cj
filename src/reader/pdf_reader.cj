/**
 * PDF-CJ: PdfReader - PDF 读取器核心
 * PDF 文档读取的主入口
 */
package pdf_cj.reader

import std.fs.{File, Path, OpenMode}
import std.collection.{ArrayList, HashMap}
import pdf_cj.base.*
import pdf_cj.util.{Rectangle, PdfException}

/**
 * PDF 读取器
 * 负责打开和读取 PDF 文件，提供页面信息、内容和表单字段访问
 */
public class PdfReader {
    private var fileName: String
    var fileData: Array<UInt8> = Array<UInt8>(0, repeat: 0)
    private var xrefTable: ?XRefTable = None
    private var catalog: ?PdfDictionary = None
    private var pages: ?PdfDictionary = None
    private var numberOfPages: Int32 = 0

    private var pageList: ArrayList<PdfDictionary> = ArrayList<PdfDictionary>()
    private var pageSizes: ArrayList<Rectangle> = ArrayList<Rectangle>()
    private var pageContentsCache: HashMap<Int32, Array<UInt8>> = HashMap<Int32, Array<UInt8>>()
    private var infoDict: ?HashMap<String, String> = None
    private var acroFieldsInstance: ?AcroFields = None
    var pageObjectNumbers: ArrayList<Int32> = ArrayList<Int32>()

    /**
     * 从文件路径构造
     */
    public init(filename: String) {
        this.fileName = filename
        readFile()
        parseDocument()
    }

    /**
     * 从内存字节数组构造（用于测试）
     */
    public init(data: Array<UInt8>) {
        this.fileName = ""
        this.fileData = data
        parseDocument()
    }

    /**
     * 读取文件到内存
     */
    private func readFile(): Unit {
        try {
            let file = File(Path(fileName), OpenMode.Read)
            let bufferSize: Int64 = 65536
            let buffer = Array<UInt8>(bufferSize, repeat: UInt8(0))
            var chunks = ArrayList<Array<UInt8>>()
            var totalRead: Int64 = 0

            while (true) {
                let bytesRead = file.read(buffer)
                if (bytesRead <= 0) { break }
                let chunk = Array<UInt8>(bytesRead, repeat: UInt8(0))
                for (i in 0..bytesRead) { chunk[i] = buffer[i] }
                chunks.add(chunk)
                totalRead += bytesRead
            }
            file.close()

            fileData = Array<UInt8>(totalRead, repeat: UInt8(0))
            var offset: Int64 = 0
            for (i in 0..chunks.size) {
                let chunk = chunks[i]
                for (j in 0..chunk.size) { fileData[offset + j] = chunk[j] }
                offset += chunk.size
            }
        } catch (e: Exception) {
            throw PdfException("Failed to read PDF file: ${fileName}, error: ${e.message}")
        }
    }

    /**
     * 解析 PDF 文档结构：xref → catalog → pages → info
     */
    private func parseDocument(): Unit {
        let startxref = XRefParser.findStartXRef(fileData)
        if (startxref < 0) {
            throw PdfException("Could not find startxref in PDF")
        }

        let xref = XRefParser(fileData, startxref).parse()
        this.xrefTable = Some(xref)

        try {
            parseCatalogAndPages(xref)
            parseInfoDict(xref)
        } catch (e: Exception) {
            // 解析失败时保留默认值（numberOfPages=0，空列表）
        }
    }

    /**
     * 从 trailer 解析 Catalog 并遍历 Pages 树
     */
    private func parseCatalogAndPages(xref: XRefTable): Unit {
        let trailerOpt = xref.getTrailer()
        let rootRef = match (trailerOpt) {
            case Some(t) => match (t.get("Root")) {
                case Some(r) => r
                case None => return
            }
            case None => return
        }

        let catalogObjNum = parseObjNumFromRef(rootRef)
        if (catalogObjNum <= 0) { return }

        let catalogDict = match (resolveRef(catalogObjNum)) {
            case Some(obj) => match (resolveToDict(obj)) {
                case Some(d) => d
                case None => return
            }
            case None => return
        }
        this.catalog = Some(catalogDict)

        let pagesRef = match (catalogDict.get(PdfName("Pages"))) {
            case Some(ref: PdfIndirectReference) => ref.objectNumber
            case _ => return
        }

        let pagesObj = match (resolveRef(pagesRef)) {
            case Some(obj) => obj
            case None => return
        }

        match (resolveToDict(pagesObj)) {
            case Some(d) =>
                this.pages = Some(d)
                collectPages(d, pagesRef)
                this.numberOfPages = Int32(pageList.size)
            case None => ()
        }
    }

    /**
     * 从 trailer 解析文档信息字典 /Info
     */
    private func parseInfoDict(xref: XRefTable): Unit {
        let infoRefStr = match (xref.getTrailer()) {
            case Some(t) => match (t.get("Info")) {
                case Some(v) => v
                case None => return
            }
            case None => return
        }

        let infoObjNum = parseObjNumFromRef(infoRefStr)
        if (infoObjNum <= 0) { return }

        match (resolveRef(infoObjNum)) {
            case Some(obj) =>
                match (obj) {
                    case d: PdfDictionary =>
                        this.infoDict = Some(dictToStringMap(d))
                    case _ => ()
                }
            case None => ()
        }
    }

    /**
     * 递归遍历 Pages 树，收集叶子 Page 字典和对应的页面尺寸
     */
    private func collectPages(dict: PdfDictionary, objNum: Int32): Unit {
        let typeStr = match (dict.getAsName(PdfName("Type"))) {
            case Some(n) => n.name
            case None => "Page"
        }

        if (typeStr == "Pages") {
            match (dict.getAsArray(PdfName("Kids"))) {
                case Some(kids) =>
                    for (i in 0..kids.size) {
                        let kidObj = kids.get(i)
                        match (kidObj) {
                            case ref: PdfIndirectReference =>
                                match (resolveRef(ref.objectNumber)) {
                                    case Some(resolved) =>
                                        match (resolved) {
                                            case d: PdfDictionary => collectPages(d, ref.objectNumber)
                                            case _ => ()
                                        }
                                    case None => ()
                                }
                            case d: PdfDictionary => collectPages(d, 0)
                            case _ => ()
                        }
                    }
                case None => ()
            }
        } else {
            // 叶子 Page 节点
            let mediaBox = extractMediaBox(dict)
            pageList.add(dict)
            pageSizes.add(mediaBox)
            pageObjectNumbers.add(objNum)
        }
    }

    /**
     * 从页面字典提取 MediaBox，缺省返回 A4
     */
    private func extractMediaBox(dict: PdfDictionary): Rectangle {
        match (dict.getAsArray(PdfName("MediaBox"))) {
            case Some(arr) =>
                if (arr.size >= 4) {
                    let llx = extractFloat(arr.get(0))
                    let lly = extractFloat(arr.get(1))
                    let urx = extractFloat(arr.get(2))
                    let ury = extractFloat(arr.get(3))
                    return Rectangle(llx, lly, urx, ury)
                }
                Rectangle(0.0, 0.0, 595.0, 842.0)
            case None => Rectangle(0.0, 0.0, 595.0, 842.0)
        }
    }

    /**
     * 安全地从 PdfObject 提取 Float32 值
     */
    private func extractFloat(obj: PdfObject): Float32 {
        match (obj) {
            case num: PdfNumber => Float32(num.floatVal())
            case _ => 0.0
        }
    }

    /**
     * 解析 "n g R" 格式的字符串，返回对象号（失败返回 0）
     */
    private func parseObjNumFromRef(s: String): Int32 {
        var result: Int32 = 0
        for (r in s.runes()) {
            let code = UInt32(r)
            if (code >= 0x30 && code <= 0x39) {
                result = result * 10 + Int32(code - 0x30)
            } else if (result > 0) {
                break
            }
        }
        result
    }

    /**
     * 通过对象号从 xref 表解析对象
     */
    private func resolveRef(objNum: Int32): ?PdfObject {
        match (xrefTable) {
            case Some(xref) =>
                let offset = xref.getOffset(objNum)
                if (offset >= 0) { readObjectAt(offset) } else { None }
            case None => None
        }
    }

    /**
     * 将 PdfObject 解析为字典（自动跟随间接引用）
     */
    private func resolveToDict(obj: PdfObject): ?PdfDictionary {
        match (obj) {
            case d: PdfDictionary => Some(d)
            case ref: PdfIndirectReference =>
                match (resolveRef(ref.objectNumber)) {
                    case Some(resolved) => resolveToDict(resolved)
                    case None => None
                }
            case _ => None
        }
    }

    /**
     * 将 PdfDictionary 的键值对转换为 HashMap<String, String>
     */
    private func dictToStringMap(dict: PdfDictionary): HashMap<String, String> {
        let result = HashMap<String, String>()
        for (key in dict.keys()) {
            match (dict.get(PdfName(key))) {
                case Some(obj) =>
                    let strVal = match (obj) {
                        case s: PdfString => s.value
                        case n: PdfName => n.name
                        case num: PdfNumber => "${num.floatVal()}"
                        case _ => ""
                    }
                    if (strVal.size > 0) { result[key] = strVal }
                case None => ()
            }
        }
        result
    }

    /**
     * 在指定字节偏移处解析一个 PDF 对象（跳过 "num gen obj" 头）
     */
    private func readObjectAt(offset: Int64): ?PdfObject {
        let tokenizer = PdfTokenizer(fileData)
        tokenizer.setPosition(offset)
        tokenizer.nextToken()  // num
        tokenizer.nextToken()  // gen
        tokenizer.nextToken()  // "obj"
        PdfParser(tokenizer).parseObject()
    }

    /**
     * 在指定字节偏移处读取 stream 对象的原始字节内容
     * 跳过 "num gen obj" 头和字典，读取 stream 关键字后的内容
     */
    private func readRawStreamAt(offset: Int64): Array<UInt8> {
        let tok = PdfTokenizer(fileData)
        tok.setPosition(offset)
        tok.nextToken()  // num
        tok.nextToken()  // gen
        tok.nextToken()  // "obj"
        PdfParser(tok).parseObject()  // consume the stream dict
        match (tok.peekToken()) {
            case Some(t) =>
                if (t.getValue() == "stream") {
                    tok.nextToken()  // consume "stream"
                    tok.readStreamContent()
                } else {
                    Array<UInt8>(0, repeat: 0)
                }
            case None => Array<UInt8>(0, repeat: 0)
        }
    }

    // ─── Public API ────────────────────────────────────────────────────────────

    /**
     * 获取总页数
     */
    public func getNumberOfPages(): Int32 {
        numberOfPages
    }

    /**
     * 获取指定页（从 1 开始）的页面尺寸
     * 若解析失败或页码越界，返回 A4 默认尺寸
     */
    public func getPageSize(pageNum: Int32): Rectangle {
        let idx = Int64(pageNum - 1)
        if (idx >= 0 && idx < pageSizes.size) {
            return pageSizes[idx]
        }
        Rectangle(0.0, 0.0, 595.0, 842.0)
    }

    /**
     * 获取指定页的内容流原始字节
     * 优先返回 setPageContent 写入的内容；若无则从文件解析 /Contents 流
     */
    public func getPageContent(pageNum: Int32): Array<UInt8> {
        // 优先返回缓存（由 setPageContent 写入）
        match (pageContentsCache.get(pageNum)) {
            case Some(cached) => return cached
            case None => ()
        }

        let idx = Int64(pageNum - 1)
        if (idx < 0 || idx >= pageList.size) {
            return Array<UInt8>(0, repeat: 0)
        }
        let pageDict = pageList[idx]

        // /Contents 可以是单个间接引用，也可以是间接引用数组
        match (pageDict.get(PdfName("Contents"))) {
            case Some(ref: PdfIndirectReference) =>
                match (xrefTable) {
                    case Some(xref) =>
                        let off = xref.getOffset(ref.objectNumber)
                        if (off >= 0) { readRawStreamAt(off) } else { Array<UInt8>(0, repeat: 0) }
                    case None => Array<UInt8>(0, repeat: 0)
                }
            case Some(arr: PdfArray) =>
                // 合并多个内容流
                var combined = ArrayList<UInt8>()
                for (i in 0..arr.size) {
                    match (arr.get(i)) {
                        case ref: PdfIndirectReference =>
                            match (xrefTable) {
                                case Some(xref) =>
                                    let off = xref.getOffset(ref.objectNumber)
                                    if (off >= 0) {
                                        let bytes = readRawStreamAt(off)
                                        for (j in 0..bytes.size) { combined.add(bytes[j]) }
                                        combined.add(0x20)  // space separator
                                    }
                                case None => ()
                            }
                        case _ => ()
                    }
                }
                let result = Array<UInt8>(combined.size, repeat: 0)
                for (i in 0..combined.size) { result[i] = combined[i] }
                result
            case _ => Array<UInt8>(0, repeat: 0)
        }
    }

    /**
     * 替换指定页的内容（在内存中，不写回文件；配合 PdfStamper 使用）
     */
    public func setPageContent(pageNum: Int32, content: Array<UInt8>): Unit {
        pageContentsCache[pageNum] = content
    }

    /**
     * 获取文档信息字典（/Info）
     * 返回标题、作者、创建时间等元数据
     */
    public func getInfo(): HashMap<String, String> {
        match (infoDict) {
            case Some(d) => d
            case None => HashMap<String, String>()
        }
    }

    /**
     * 获取 AcroFields 实例，用于读取和填写 PDF 表单字段
     */
    public func getAcroFields(): AcroFields {
        match (acroFieldsInstance) {
            case Some(af) => af
            case None =>
                let af = AcroFields(this)
                acroFieldsInstance = Some(af)
                af
        }
    }

    /**
     * 关闭读取器，释放内存
     */
    public func close(): Unit {
        fileData = Array<UInt8>(0, repeat: 0)
        xrefTable = None
        catalog = None
        pages = None
        numberOfPages = 0
        pageList = ArrayList<PdfDictionary>()
        pageSizes = ArrayList<Rectangle>()
        pageObjectNumbers = ArrayList<Int32>()
        pageContentsCache = HashMap<Int32, Array<UInt8>>()
        infoDict = None
        acroFieldsInstance = None
    }

    /**
     * 获取指定页（从 1 开始）的对象编号
     */
    public func getPageObjectNumber(pageNum: Int32): Int32 {
        let idx = Int64(pageNum - 1)
        if (idx >= 0 && idx < pageObjectNumbers.size) {
            return pageObjectNumbers[idx]
        }
        0
    }

    /**
     * 获取 xref 表中最大的对象编号
     */
    public func getMaxObjectNumber(): Int32 {
        match (xrefTable) {
            case Some(xref) =>
                let nums = xref.getAllObjectNumbers()
                var maxNum: Int32 = 0
                for (i in 0..nums.size) {
                    if (nums[i] > maxNum) { maxNum = nums[i] }
                }
                maxNum
            case None => 0
        }
    }

    /**
     * 获取 startxref 偏移
     */
    public func getStartXRefOffset(): Int64 {
        XRefParser.findStartXRef(fileData)
    }

    /**
     * 获取根对象（/Root）编号
     */
    public func getRootObjectNumber(): Int32 {
        match (xrefTable) {
            case Some(xref) =>
                match (xref.getTrailer()) {
                    case Some(t) =>
                        match (t.get("Root")) {
                            case Some(ref) => parseObjNumFromRef(ref)
                            case None => 1
                        }
                    case None => 1
                }
            case None => 1
        }
    }

    // ─── Legacy / Utility ──────────────────────────────────────────────────────

    /**
     * 获取文件名
     */
    public func getFileName(): String {
        fileName
    }

    /**
     * 获取 PDF 版本字符串（从文件头读取）
     */
    public func getPdfVersion(): String {
        // %PDF-1.x 在文件开头，格式固定
        if (fileData.size < 9) { return "1.4" }
        // bytes 5-7: "1.x"
        var ver = ""
        for (i in 5..9) {
            if (i < fileData.size) {
                ver += String(Rune(Int64(fileData[i])))
            }
        }
        if (ver.size > 0) { ver } else { "1.4" }
    }

    /**
     * 检查文件是否加密
     */
    public func isEncrypted(): Bool {
        match (xrefTable) {
            case Some(xref) =>
                match (xref.getTrailer()) {
                    case Some(t) => t.contains("Encrypt")
                    case None => false
                }
            case None => false
        }
    }

    /**
     * 根据引用获取对象
     */
    public func getObject(ref: PdfIndirectReference): ?PdfObject {
        resolveRef(ref.objectNumber)
    }
}

/**
 * PDF 页面信息
 */
public class PageInfo {
    public let pageNumber: Int32
    public let mediaBox: Rectangle
    public let rotation: Int32

    public init(pageNumber: Int32, mediaBox: Rectangle, rotation: Int32) {
        this.pageNumber = pageNumber
        this.mediaBox = mediaBox
        this.rotation = rotation
    }

    public func getPageNumber(): Int32 { pageNumber }
    public func getMediaBox(): Rectangle { mediaBox }
    public func getRotation(): Int32 { rotation }
}
