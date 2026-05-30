/**
 * PDF-CJ: PdfCopy / PdfSmartCopy - PDF 合并器
 * 将多个 PDF 的页面合并为一个新的 PDF 文档
 */
package pdf_cj.reader

import std.collection.{HashMap, ArrayList}
import pdf_cj.base.*
import pdf_cj.api.{Document, DocListener, Element, HeaderFooter}
import pdf_cj.util.Rectangle

// ─── 内部：收集到的页面记录 ────────────────────────────────────────────────────

class PageEntry {
    var contentBytes: Array<UInt8>
    var mediaBox: Rectangle

    init(content: Array<UInt8>, box: Rectangle) {
        contentBytes = content
        mediaBox = box
    }
}

// ─── 页面范围解析工具 ──────────────────────────────────────────────────────────

/**
 * 将 "1-3,5,7-9" 格式的字符串解析为页码列表（已去重、已排序）
 * @param ranges 范围字符串
 * @param maxPage 文档最大页码（越界页码被忽略，0 表示不限）
 */
func parsePageRanges(ranges: String, maxPage: Int32): ArrayList<Int32> {
    let result = ArrayList<Int32>()
    let parts = splitString(ranges, 44)  // ','
    for (i in 0..parts.size) {
        let part = trimString(parts[i])
        if (part.size == 0) { continue }
        let dashIdx = indexOfByteCode(part, 45)  // '-'
        if (dashIdx >= 0) {
            let startStr = trimString(substringOf(part, 0, dashIdx))
            let endStr = trimString(substringOf(part, dashIdx + 1, Int64(part.size)))
            let start = parsePositiveInt(startStr)
            let end = parsePositiveInt(endStr)
            if (start > 0 && end >= start) {
                var p = start
                while (p <= end) {
                    if (maxPage <= 0 || p <= maxPage) {
                        addIfAbsent(result, p)
                    }
                    p += 1
                }
            }
        } else {
            let n = parsePositiveInt(part)
            if (n > 0 && (maxPage <= 0 || n <= maxPage)) {
                addIfAbsent(result, n)
            }
        }
    }
    result
}

// sep is ASCII code (e.g. 44 for ',')
private func splitString(s: String, sepCode: Int64): ArrayList<String> {
    let result = ArrayList<String>()
    var cur = ""
    for (c in s) {
        if (Int64(c) == sepCode) {
            result.add(cur)
            cur = ""
        } else {
            cur += String(Rune(Int64(c)))
        }
    }
    result.add(cur)
    result
}

private func trimString(s: String): String {
    var arr = ArrayList<Int64>()
    for (c in s) { arr.add(Int64(c)) }
    var start: Int64 = 0
    var end: Int64 = arr.size
    while (start < end) {
        let b = arr[start]
        if (b == 32 || b == 9 || b == 13 || b == 10) { start += 1 } else { break }
    }
    while (end > start) {
        let b = arr[end - 1]
        if (b == 32 || b == 9 || b == 13 || b == 10) { end -= 1 } else { break }
    }
    var result = ""
    for (i in start..end) {
        result += String(Rune(arr[i]))
    }
    result
}

// Returns index of first occurrence of byte with ASCII code targetCode, or -1
private func indexOfByteCode(s: String, targetCode: Int64): Int64 {
    var i: Int64 = 0
    for (c in s) {
        if (Int64(c) == targetCode) { return i }
        i += 1
    }
    -1
}

private func substringOf(s: String, from: Int64, to: Int64): String {
    var result = ""
    var i: Int64 = 0
    for (c in s) {
        if (i >= from && i < to) {
            result += String(Rune(Int64(c)))
        }
        i += 1
    }
    result
}

private func parsePositiveInt(s: String): Int32 {
    var result: Int32 = 0
    var hasDigit = false
    for (c in s) {
        let code = Int64(c)
        if (code >= 48 && code <= 57) {
            result = result * 10 + Int32(code - 48)
            hasDigit = true
        } else {
            return 0
        }
    }
    if (hasDigit) { result } else { 0 }
}

private func addIfAbsent(list: ArrayList<Int32>, val_: Int32): Unit {
    for (i in 0..list.size) {
        if (list[i] == val_) { return }
    }
    list.add(val_)
}

// ─── PDF 序列化工具 ────────────────────────────────────────────────────────────

private func padLeft10(n: Int64): String {
    var s = "${n}"
    while (s.size < 10) { s = "0" + s }
    s
}

private func padLeft5(n: Int32): String {
    var s = "${n}"
    while (s.size < 5) { s = "0" + s }
    s
}

private func xrefEntry(offset: Int64, gen: Int32, flag: String): String {
    padLeft10(offset) + " " + padLeft5(gen) + " ${flag} \r\n"
}

/**
 * 将收集到的页面写出为完整的新 PDF
 *
 * 对象布局（共 2+N*2 个对象）：
 *   obj 1          : Catalog
 *   obj 2          : Pages root
 *   obj 3+i*2      : 第 i+1 页的内容流（或去重后复用的对象号）
 *   obj 4+i*2      : 第 i+1 页的页面字典
 */
private func writePdfFromPages(os: PdfOutputStream, pages: ArrayList<PageEntry>,
                               contentObjNums: ArrayList<Int32>): Unit {
    let n = pages.size
    // 对象总数：1(Catalog) + 1(Pages) + n(content streams, 可能有去重) + n(page dicts)
    // 但 xref 需要覆盖所有对象号，所以用最大对象号+1作为 /Size
    // 计算最大对象号
    var maxObjNum: Int32 = 2
    for (i in 0..contentObjNums.size) {
        let cn = contentObjNums[i]
        if (cn > maxObjNum) { maxObjNum = cn }
        let pn = 3 + Int32(i) * 2  // 等价的页面字典编号
        if (pn > maxObjNum) { maxObjNum = pn }
    }
    // 页面字典对象号为偶数：4, 6, 8, ... = 4+i*2
    // 内容流对象号由调用方通过 contentObjNums[i] 传入
    // 页面字典: 对于第 i 页 (0-indexed), objNum = 3 + i*2 + 1 = 4 + i*2

    // 跟踪每个对象号的写入偏移
    // 最大对象号 = 2 + n*2（无去重时）
    // 用 HashMap 记录 objNum -> offset
    let offsets = HashMap<Int32, Int64>()

    os.writeString("%PDF-1.4\n")

    // obj 1: Catalog
    offsets[1] = os.position
    os.writeString("1 0 obj\n")
    os.writeString("<< /Type /Catalog /Pages 2 0 R >>\n")
    os.writeString("endobj\n")

    // 先构建 Kids 数组字符串
    var kidsStr = "["
    for (i in 0..n) {
        let pageDictObjNum = 4 + Int32(i) * 2
        if (i > 0) { kidsStr += " " }
        kidsStr += "${pageDictObjNum} 0 R"
    }
    kidsStr += "]"

    // obj 2: Pages root
    offsets[2] = os.position
    os.writeString("2 0 obj\n")
    os.writeString("<< /Type /Pages /Kids ${kidsStr} /Count ${n} >>\n")
    os.writeString("endobj\n")

    // 写内容流（去重：相同 objNum 只写一次）
    let writtenContentObjs = HashMap<Int32, Bool>()

    for (i in 0..n) {
        let contentObjNum = contentObjNums[i]
        if (!writtenContentObjs.contains(contentObjNum)) {
            writtenContentObjs[contentObjNum] = true
            offsets[contentObjNum] = os.position
            let bytes = pages[i].contentBytes
            os.writeString("${contentObjNum} 0 obj\n")
            os.writeString("<< /Length ${bytes.size} >>\n")
            os.writeString("stream\n")
            os.writeBytes(bytes)
            os.writeString("\nendstream\nendobj\n")
        }
    }

    // 写页面字典
    for (i in 0..n) {
        let pageDictObjNum = 4 + Int32(i) * 2
        let contentObjNum = contentObjNums[i]
        let box = pages[i].mediaBox
        offsets[pageDictObjNum] = os.position
        os.writeString("${pageDictObjNum} 0 obj\n")
        os.writeString("<< /Type /Page /Parent 2 0 R")
        os.writeString(" /MediaBox [")
        os.writeFloat32(box.left)
        os.writeString(" ")
        os.writeFloat32(box.bottom)
        os.writeString(" ")
        os.writeFloat32(box.right)
        os.writeString(" ")
        os.writeFloat32(box.top)
        os.writeString("]")
        os.writeString(" /Resources << /ProcSet [/PDF /Text /ImageB /ImageC /ImageI] >>")
        os.writeString(" /Contents ${contentObjNum} 0 R")
        os.writeString(" >>\n")
        os.writeString("endobj\n")
    }

    // 收集所有对象号，排序后写 xref
    let allObjNums = ArrayList<Int32>()
    for ((objNum, _) in offsets) {
        allObjNums.add(objNum)
    }
    sortAscending(allObjNums)

    let xrefStart = os.position
    os.writeString("xref\n")
    // free entry for obj 0
    os.writeString("0 1\n")
    os.writeString(xrefEntry(0, 65535, "f"))
    // one subsection per object
    for (i in 0..allObjNums.size) {
        let objNum = allObjNums[i]
        let offset = match (offsets.get(objNum)) {
            case Some(o) => o
            case None => Int64(0)
        }
        os.writeString("${objNum} 1\n")
        os.writeString(xrefEntry(offset, 0, "n"))
    }

    let totalObjs = allObjNums.size + 1  // +1 for obj 0
    let rootRef = 1

    os.writeString("trailer\n")
    os.writeString("<< /Size ${totalObjs} /Root ${rootRef} 0 R >>\n")
    os.writeString("startxref\n${xrefStart}\n%%EOF\n")
}

private func sortAscending(list: ArrayList<Int32>): Unit {
    // Insertion sort (page counts are small)
    let n = list.size
    var i: Int64 = 1
    while (i < n) {
        let key = list[i]
        var j = i - 1
        while (j >= 0 && list[j] > key) {
            list[j + 1] = list[j]
            j -= 1
        }
        list[j + 1] = key
        i += 1
    }
}

private func contentFingerprint(bytes: Array<UInt8>): String {
    if (bytes.size == 0) { return "empty" }
    var sum: Int64 = 0
    for (i in 0..bytes.size) {
        sum = (sum + Int64(bytes[i])) % 65536
    }
    "${bytes.size}_${sum}"
}

// ─── PdfCopy ──────────────────────────────────────────────────────────────────

/**
 * PDF 合并器
 * 将多个源 PDF 的页面合并写入一个新 PDF
 */
public class PdfCopy <: DocListener {
    private var document: Document
    var outputStream: PdfOutputStream
    private var addedPages: ArrayList<PageEntry> = ArrayList<PageEntry>()
    private var closed: Bool = false

    public init(document: Document, os: PdfOutputStream) {
        this.document = document
        this.outputStream = os
        document.addDocListener(this)
    }

    public func add(element: Element): Bool { true }
    public func open(): Unit {}
    public func newPage(): Bool { true }
    public func setPageSize(size: Rectangle): Bool { true }
    public func setMargins(left: Float32, right: Float32, top: Float32, bottom: Float32): Bool { true }
    public func setHeader(header: HeaderFooter): Unit {}
    public func setFooter(footer: HeaderFooter): Unit {}
    public func resetHeader(): Unit {}
    public func resetFooter(): Unit {}

    /**
     * 从源文档取得导入页面句柄
     */
    public func getImportedPage(reader: PdfReader, pageNum: Int32): PdfImportedPage {
        PdfImportedPage(reader, pageNum)
    }

    /**
     * 将导入页面加入合并列表
     */
    public func addPage(page: PdfImportedPage): Unit {
        let content = page.getContent()
        let box = match (page.getMediaBox()) {
            case Some(b) => b
            case None => Rectangle(0.0, 0.0, 595.0, 842.0)
        }
        addedPages.add(PageEntry(content, box))
    }

    /**
     * 将整个源文档的所有页面加入合并列表
     */
    public func addDocument(reader: PdfReader): Unit {
        let n = reader.getNumberOfPages()
        for (i in 1..(n + 1)) {
            addPage(getImportedPage(reader, Int32(i)))
        }
    }

    /**
     * 按页面范围字符串从源文档选取页面加入合并列表
     * @param reader 源文档
     * @param ranges 页面范围，如 "1-3,5,7-9"
     */
    public func selectPages(reader: PdfReader, ranges: String): Unit {
        let pageNums = parsePageRanges(ranges, reader.getNumberOfPages())
        for (i in 0..pageNums.size) {
            addPage(getImportedPage(reader, pageNums[i]))
        }
    }

    /**
     * 解析页面范围字符串，返回页码列表（不限最大页码）
     */
    public static func parseRanges(ranges: String): ArrayList<Int32> {
        parsePageRanges(ranges, 0)
    }

    /**
     * 已加入的页面总数
     */
    public func getPageCount(): Int64 {
        addedPages.size
    }

    /**
     * 完成合并，将结果写入输出流
     * 内容流不去重（相同内容会写两份），使用 PdfSmartCopy 可以去重
     */
    public func close(): Unit {
        if (closed) { return }
        closed = true

        // 每页分配独立的内容流对象号：3, 5, 7, ...
        let contentObjNums = ArrayList<Int32>()
        for (i in 0..addedPages.size) {
            contentObjNums.add(3 + Int32(i) * 2)
        }

        writePdfFromPages(outputStream, addedPages, contentObjNums)
    }

    public func isClosed(): Bool { closed }
}

// ─── PdfImportedPage ──────────────────────────────────────────────────────────

/**
 * 从源 PDF 导入的页面句柄
 */
public class PdfImportedPage {
    private var reader: PdfReader
    private var pageNumber: Int32
    private var mediaBox: ?Rectangle = None

    public init(reader: PdfReader, pageNum: Int32) {
        this.reader = reader
        this.pageNumber = pageNum
        this.mediaBox = Some(reader.getPageSize(pageNum))
    }

    public func getReader(): PdfReader { reader }
    public func getPageNumber(): Int32 { pageNumber }
    public func getMediaBox(): ?Rectangle { mediaBox }

    public func getWidth(): Float32 {
        match (mediaBox) {
            case Some(box) => box.right - box.left
            case None => 0.0
        }
    }

    public func getHeight(): Float32 {
        match (mediaBox) {
            case Some(box) => box.top - box.bottom
            case None => 0.0
        }
    }

    public func getContent(): Array<UInt8> {
        reader.getPageContent(pageNumber)
    }
}

// ─── PdfSmartCopy ─────────────────────────────────────────────────────────────

/**
 * 智能合并器
 * 与 PdfCopy 相同，但相同内容的页面只写一份内容流对象（去重）
 */
public class PdfSmartCopy <: DocListener {
    var outputStream: PdfOutputStream
    private var document: Document
    private var addedPages: ArrayList<PageEntry> = ArrayList<PageEntry>()
    private var closed: Bool = false

    // 内容指纹 → 已分配的内容流对象号
    private var contentObjMap: HashMap<String, Int32> = HashMap<String, Int32>()
    // 每页实际使用的内容流对象号（可能被多页共享）
    private var pageContentObjNums: ArrayList<Int32> = ArrayList<Int32>()
    // 下一个可分配的对象号（从3开始，步长2，给内容流用）
    private var nextContentObjNum: Int32 = 3

    public init(document: Document, os: PdfOutputStream) {
        this.document = document
        this.outputStream = os
        document.addDocListener(this)
    }

    public func add(element: Element): Bool { true }
    public func open(): Unit {}
    public func newPage(): Bool { true }
    public func setPageSize(size: Rectangle): Bool { true }
    public func setMargins(left: Float32, right: Float32, top: Float32, bottom: Float32): Bool { true }
    public func setHeader(header: HeaderFooter): Unit {}
    public func setFooter(footer: HeaderFooter): Unit {}
    public func resetHeader(): Unit {}
    public func resetFooter(): Unit {}

    public func getImportedPage(reader: PdfReader, pageNum: Int32): PdfImportedPage {
        PdfImportedPage(reader, pageNum)
    }

    /**
     * 添加页面，自动去重相同内容流
     */
    public func addPage(page: PdfImportedPage): Unit {
        let content = page.getContent()
        let box = match (page.getMediaBox()) {
            case Some(b) => b
            case None => Rectangle(0.0, 0.0, 595.0, 842.0)
        }
        let fingerprint = contentFingerprint(content)

        let contentObjNum = match (contentObjMap.get(fingerprint)) {
            case Some(existing) => existing
            case None =>
                let newNum = nextContentObjNum
                // 内容流对象号：3,5,7,...；页面字典：4,6,8,...
                // 去重时跳过已用号码：我们只分配奇数给内容流
                nextContentObjNum += 2
                contentObjMap[fingerprint] = newNum
                newNum
        }

        addedPages.add(PageEntry(content, box))
        pageContentObjNums.add(contentObjNum)
    }

    public func addDocument(reader: PdfReader): Unit {
        let n = reader.getNumberOfPages()
        for (i in 1..(n + 1)) {
            addPage(getImportedPage(reader, Int32(i)))
        }
    }

    public func selectPages(reader: PdfReader, ranges: String): Unit {
        let pageNums = parsePageRanges(ranges, reader.getNumberOfPages())
        for (i in 0..pageNums.size) {
            addPage(getImportedPage(reader, pageNums[i]))
        }
    }

    public func getPageCount(): Int64 { addedPages.size }

    public func getDedupedContentCount(): Int64 { Int64(contentObjMap.size) }

    public func close(): Unit {
        if (closed) { return }
        closed = true

        // 页面字典对象号需要与 writePdfFromPages 内的计算保持一致：
        // writePdfFromPages 中 pageDictObjNum = 4 + i*2
        // 内容流对象号由调用方通过 pageContentObjNums 传入
        // 但 writePdfFromPages 用固定公式 4+i*2 计算页面字典对象号
        // 需要确保内容流对象号不与 4+i*2 冲突
        // 当前内容流号从 3 开始步长 2 → 3,5,7,... 不会与 4,6,8,... 冲突 ✓

        writePdfFromPages(outputStream, addedPages, pageContentObjNums)
    }

    public func isClosed(): Bool { closed }
}

// ─── PdfCopyFactory ───────────────────────────────────────────────────────────

public class PdfCopyFactory {
    public static func createCopy(document: Document, os: PdfOutputStream): PdfCopy {
        PdfCopy(document, os)
    }

    public static func createSmartCopy(document: Document, os: PdfOutputStream): PdfSmartCopy {
        PdfSmartCopy(document, os)
    }
}
