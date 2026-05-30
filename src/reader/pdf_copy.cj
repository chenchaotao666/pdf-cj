/**
 * PDF-CJ: PdfCopy / PdfSmartCopy - PDF 合并器
 * 将多个 PDF 的页面合并为一个新的 PDF 文档
 */
package pdf_cj.reader

import std.collection.{HashMap, ArrayList}
import pdf_cj.base.*
import pdf_cj.api.{Document, DocListener, Element, HeaderFooter}
import pdf_cj.util.Rectangle

// ─── 存储对象（资源收集器使用） ────────────────────────────────────────────────

class StoredStreamObj {
    var objNum: Int32
    var streamDict: PdfDictionary
    var bytes: Array<UInt8>

    init(n: Int32, d: PdfDictionary, b: Array<UInt8>) {
        objNum = n
        streamDict = d
        bytes = b
    }
}

class StoredRegularObj {
    var objNum: Int32
    var obj: PdfObject

    init(n: Int32, o: PdfObject) {
        objNum = n
        obj = o
    }
}

// ─── 资源收集器 ────────────────────────────────────────────────────────────────

class ResourceCollector {
    var nextObjNum: Int32 = 3
    var objMapping: HashMap<String, Int32> = HashMap<String, Int32>()
    var streamObjs: ArrayList<StoredStreamObj> = ArrayList<StoredStreamObj>()
    var regularObjs: ArrayList<StoredRegularObj> = ArrayList<StoredRegularObj>()

    init() {}

    func readerObjKey(reader: PdfReader, srcObjNum: Int32): String {
        reader.getFileName() + ":" + "${srcObjNum}"
    }

    func remapObject(obj: PdfObject, reader: PdfReader): PdfObject {
        match (obj) {
            case ref: PdfIndirectReference =>
                let newNum = getOrAllocate(ref.objectNumber, reader)
                PdfIndirectReference(newNum, 0)
            case d: PdfDictionary =>
                let newDict = PdfDictionary()
                for (key in d.keys()) {
                    match (d.get(PdfName(key))) {
                        case Some(v) => newDict.put(PdfName(key), remapObject(v, reader))
                        case None => ()
                    }
                }
                newDict
            case arr: PdfArray =>
                let newArr = PdfArray()
                for (i in 0..arr.size) {
                    newArr.add(remapObject(arr.get(i), reader))
                }
                newArr
            case _ => obj
        }
    }

    func getOrAllocate(srcObjNum: Int32, reader: PdfReader): Int32 {
        let key = readerObjKey(reader, srcObjNum)
        match (objMapping.get(key)) {
            case Some(n) => return n
            case None => ()
        }
        let newNum = nextObjNum
        nextObjNum += 1
        objMapping[key] = newNum

        match (reader.getObjectByNumber(srcObjNum)) {
            case None => ()
            case Some(obj) =>
                if (reader.isStreamObject(srcObjNum)) {
                    let streamDict = match (obj) {
                        case d: PdfDictionary => d
                        case _ => PdfDictionary()
                    }
                    let remappedDict = match (remapObject(streamDict, reader)) {
                        case d: PdfDictionary => d
                        case _ => PdfDictionary()
                    }
                    let rawBytes = reader.getRawStreamByObjNum(srcObjNum)
                    remappedDict.put(PdfName("Length"), PdfNumber(Int64(rawBytes.size)))
                    streamObjs.add(StoredStreamObj(newNum, remappedDict, rawBytes))
                } else {
                    let remapped = remapObject(obj, reader)
                    regularObjs.add(StoredRegularObj(newNum, remapped))
                }
        }
        newNum
    }

    func getRemappedResources(pageDict: PdfDictionary, reader: PdfReader): PdfObject {
        match (pageDict.get(PdfName("Resources"))) {
            case Some(ref: PdfIndirectReference) =>
                remapObject(ref, reader)
            case Some(d: PdfDictionary) =>
                remapObject(d, reader)
            case _ =>
                let minimal = PdfDictionary()
                let procSet = PdfArray()
                procSet.add(PdfName("PDF"))
                procSet.add(PdfName("Text"))
                procSet.add(PdfName("ImageB"))
                procSet.add(PdfName("ImageC"))
                procSet.add(PdfName("ImageI"))
                minimal.put(PdfName("ProcSet"), procSet)
                minimal
        }
    }
}

// ─── 内部：收集到的页面记录 ────────────────────────────────────────────────────

class PageEntry {
    var contentBytes: Array<UInt8>
    var mediaBox: Rectangle
    var remappedResources: PdfObject
    var fingerprint: String

    init(content: Array<UInt8>, box: Rectangle, resources: PdfObject, fp: String) {
        contentBytes = content
        mediaBox = box
        remappedResources = resources
        fingerprint = fp
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

private func sortAscending(list: ArrayList<Int32>): Unit {
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

/**
 * 将收集到的页面和资源写出为完整的新 PDF
 *
 * 对象布局：
 *   obj 1           : Catalog
 *   obj 2           : Pages root
 *   obj 3..(2+R)    : 资源对象（流对象和普通对象，由 collector 分配）
 *   obj (3+R)..     : 内容流（每页一个，SmartCopy 时去重）
 *   obj (3+R+C)..   : 页面字典（每页一个）
 */
private func writePdfNew(os: PdfOutputStream, pages_: ArrayList<PageEntry>,
                          collector_: ResourceCollector,
                          contentObjNums: ArrayList<Int32>,
                          firstPageDict: Int32): Unit {
    let n = pages_.size
    let offsets = HashMap<Int32, Int64>()

    os.writeString("%PDF-1.4\n")

    // obj 1: Catalog
    offsets[1] = os.position
    os.writeString("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n")

    // Build Kids array
    var kidsStr = "["
    for (i in 0..n) {
        let pdNum = firstPageDict + Int32(i)
        if (i > 0) { kidsStr += " " }
        kidsStr += "${pdNum} 0 R"
    }
    kidsStr += "]"

    // obj 2: Pages root
    offsets[2] = os.position
    os.writeString("2 0 obj\n<< /Type /Pages /Kids ${kidsStr} /Count ${n} >>\nendobj\n")

    // Write stream resource objects
    for (i in 0..collector_.streamObjs.size) {
        let so = collector_.streamObjs[i]
        offsets[so.objNum] = os.position
        os.writeString("${so.objNum} 0 obj\n")
        so.streamDict.writeTo(os)
        os.writeString("\nstream\n")
        os.writeBytes(so.bytes)
        os.writeString("\nendstream\nendobj\n")
    }

    // Write regular resource objects
    for (i in 0..collector_.regularObjs.size) {
        let ro = collector_.regularObjs[i]
        offsets[ro.objNum] = os.position
        os.writeString("${ro.objNum} 0 obj\n")
        ro.obj.writeTo(os)
        os.writeString("\nendobj\n")
    }

    // Write content streams (deduped by content obj num)
    let writtenContent = HashMap<Int32, Bool>()
    for (i in 0..n) {
        let cnum = contentObjNums[i]
        if (!writtenContent.contains(cnum)) {
            writtenContent[cnum] = true
            offsets[cnum] = os.position
            let bytes = pages_[i].contentBytes
            os.writeString("${cnum} 0 obj\n<< /Length ${bytes.size} >>\nstream\n")
            os.writeBytes(bytes)
            os.writeString("\nendstream\nendobj\n")
        }
    }

    // Write page dicts
    for (i in 0..n) {
        let pdNum = firstPageDict + Int32(i)
        let cnum = contentObjNums[i]
        let box = pages_[i].mediaBox
        offsets[pdNum] = os.position
        os.writeString("${pdNum} 0 obj\n")
        os.writeString("<< /Type /Page /Parent 2 0 R /MediaBox [")
        os.writeFloat32(box.left)
        os.writeString(" ")
        os.writeFloat32(box.bottom)
        os.writeString(" ")
        os.writeFloat32(box.right)
        os.writeString(" ")
        os.writeFloat32(box.top)
        os.writeString("] /Resources ")
        pages_[i].remappedResources.writeTo(os)
        os.writeString(" /Contents ${cnum} 0 R >>\nendobj\n")
    }

    // Write xref table
    let allObjNums = ArrayList<Int32>()
    for ((objNum, _) in offsets) {
        allObjNums.add(objNum)
    }
    sortAscending(allObjNums)

    let xrefStart = os.position
    os.writeString("xref\n0 1\n")
    os.writeString(xrefEntry(0, 65535, "f"))
    for (i in 0..allObjNums.size) {
        let objNum = allObjNums[i]
        let off = match (offsets.get(objNum)) {
            case Some(o) => o
            case None => Int64(0)
        }
        os.writeString("${objNum} 1\n")
        os.writeString(xrefEntry(off, 0, "n"))
    }

    let totalObjs = allObjNums.size + 1
    os.writeString("trailer\n<< /Size ${totalObjs} /Root 1 0 R >>\nstartxref\n${xrefStart}\n%%EOF\n")
}

// ─── PdfCopy ──────────────────────────────────────────────────────────────────

/**
 * PDF 合并器
 * 将多个源 PDF 的页面合并写入一个新 PDF，同时复制字体、图像等资源对象
 */
public class PdfCopy <: DocListener {
    private var document: Document
    var outputStream: PdfOutputStream
    private var addedPages: ArrayList<PageEntry> = ArrayList<PageEntry>()
    private var closed: Bool = false
    private var collector: ResourceCollector = ResourceCollector()

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

    public func addPage(page: PdfImportedPage): Unit {
        let content = page.getContent()
        let box = match (page.getMediaBox()) {
            case Some(b) => b
            case None => Rectangle(0.0, 0.0, 595.0, 842.0)
        }
        let reader = page.getReader()
        let pageNum = page.getPageNumber()
        let pageDict = match (reader.getPageDictionary(pageNum)) {
            case Some(d) => d
            case None => PdfDictionary()
        }
        let resources = collector.getRemappedResources(pageDict, reader)
        let fp = contentFingerprint(content)
        addedPages.add(PageEntry(content, box, resources, fp))
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

    public static func parseRanges(ranges: String): ArrayList<Int32> {
        parsePageRanges(ranges, 0)
    }

    public func getPageCount(): Int64 { addedPages.size }

    public func close(): Unit {
        if (closed) { return }
        closed = true
        let n = addedPages.size
        let firstContent = collector.nextObjNum
        let contentObjNums = ArrayList<Int32>()
        for (i in 0..n) {
            contentObjNums.add(firstContent + Int32(i))
        }
        let firstPageDict = firstContent + Int32(n)
        writePdfNew(outputStream, addedPages, collector, contentObjNums, firstPageDict)
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
    private var collector: ResourceCollector = ResourceCollector()
    private var fingerprintSet: HashMap<String, Bool> = HashMap<String, Bool>()
    private var uniqueFingerprintCount: Int32 = 0

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

    public func addPage(page: PdfImportedPage): Unit {
        let content = page.getContent()
        let box = match (page.getMediaBox()) {
            case Some(b) => b
            case None => Rectangle(0.0, 0.0, 595.0, 842.0)
        }
        let reader = page.getReader()
        let pageNum = page.getPageNumber()
        let pageDict = match (reader.getPageDictionary(pageNum)) {
            case Some(d) => d
            case None => PdfDictionary()
        }
        let resources = collector.getRemappedResources(pageDict, reader)
        let fp = contentFingerprint(content)
        if (!fingerprintSet.contains(fp)) {
            fingerprintSet[fp] = true
            uniqueFingerprintCount += 1
        }
        addedPages.add(PageEntry(content, box, resources, fp))
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

    public func getDedupedContentCount(): Int64 { Int64(uniqueFingerprintCount) }

    public func close(): Unit {
        if (closed) { return }
        closed = true
        let n = addedPages.size
        let firstContent = collector.nextObjNum
        let fpToObjNum = HashMap<String, Int32>()
        var nextContentNum = firstContent
        let contentObjNums = ArrayList<Int32>()
        for (i in 0..n) {
            let fp = addedPages[i].fingerprint
            let objNum = match (fpToObjNum.get(fp)) {
                case Some(existing) => existing
                case None =>
                    let newN = nextContentNum
                    nextContentNum += 1
                    fpToObjNum[fp] = newN
                    newN
            }
            contentObjNums.add(objNum)
        }
        let firstPageDict = nextContentNum
        writePdfNew(outputStream, addedPages, collector, contentObjNums, firstPageDict)
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
