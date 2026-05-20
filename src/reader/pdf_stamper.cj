/**
 * PDF-CJ: PdfStamper - PDF 修改器
 * 以增量更新方式在现有 PDF 上叠加内容
 */
package pdf_cj.reader

import std.collection.{HashMap, ArrayList}
import pdf_cj.base.*
import pdf_cj.core.PdfContentByte
import pdf_cj.util.{Rectangle, PdfException}

/**
 * PDF 修改器
 * 支持在页面上下层叠加内容、修改元数据，以增量更新写入输出流
 */
public class PdfStamper {
    private var reader: PdfReader
    private var outputStream: PdfOutputStream
    private var closed: Bool = false

    // 页面内容层（懒初始化）
    private var overContents: HashMap<Int32, PdfContentByte> = HashMap<Int32, PdfContentByte>()
    private var underContents: HashMap<Int32, PdfContentByte> = HashMap<Int32, PdfContentByte>()

    // 额外文档元数据
    private var moreInfo: HashMap<String, String> = HashMap<String, String>()

    // 加密参数（仅存储，简化实现不实际加密）
    private var encryptionSet: Bool = false
    private var encUserPassword: Array<UInt8> = Array<UInt8>(0, repeat: 0)
    private var encOwnerPassword: Array<UInt8> = Array<UInt8>(0, repeat: 0)
    private var encPermissions: Int32 = 0
    private var encType: Int32 = 0

    // AcroFields 缓存
    private var acroFieldsInstance: ?AcroFields = None

    // 下一个可用对象编号
    private var nextObjectNumber: Int32

    public init(reader: PdfReader, os: PdfOutputStream) {
        this.reader = reader
        this.outputStream = os
        this.nextObjectNumber = reader.getMaxObjectNumber() + 1
    }

    /**
     * 获取页面上层内容（在原始内容之上绘制）
     */
    public func getOverContent(pageNum: Int32): PdfContentByte {
        match (overContents.get(pageNum)) {
            case Some(cb) => cb
            case None =>
                let cb = PdfContentByte()
                overContents[pageNum] = cb
                cb
        }
    }

    /**
     * 获取页面下层内容（在原始内容之下绘制）
     */
    public func getUnderContent(pageNum: Int32): PdfContentByte {
        match (underContents.get(pageNum)) {
            case Some(cb) => cb
            case None =>
                let cb = PdfContentByte()
                underContents[pageNum] = cb
                cb
        }
    }

    /**
     * 获取表单字段访问器（委托给 PdfReader）
     */
    public func getAcroFields(): AcroFields {
        match (acroFieldsInstance) {
            case Some(af) => af
            case None =>
                let af = reader.getAcroFields()
                acroFieldsInstance = Some(af)
                af
        }
    }

    /**
     * 设置加密参数（简化实现：仅存储参数）
     */
    public func setEncryption(
        userPassword: Array<UInt8>,
        ownerPassword: Array<UInt8>,
        permissions: Int32,
        encryptionType: Int32
    ): Unit {
        encryptionSet = true
        encUserPassword = userPassword
        encOwnerPassword = ownerPassword
        encPermissions = permissions
        encType = encryptionType
    }

    /**
     * 追加/更新文档信息字典
     */
    public func setMoreInfo(info: HashMap<String, String>): Unit {
        for ((k, v) in info) {
            moreInfo[k] = v
        }
    }

    /**
     * 获取 PdfReader
     */
    public func getReader(): PdfReader {
        reader
    }

    /**
     * 获取页面总数
     */
    public func getNumberOfPages(): Int32 {
        reader.getNumberOfPages()
    }

    /**
     * 获取页面尺寸
     */
    public func getPageSize(pageNum: Int32): Rectangle {
        reader.getPageSize(pageNum)
    }

    /**
     * 是否已关闭
     */
    public func isClosed(): Bool {
        closed
    }

    /**
     * 完成所有修改并以增量更新写入输出流，然后关闭
     */
    public func close(): Unit {
        if (closed) { return }
        closed = true

        // 1. 写原始 PDF 字节
        outputStream.writeBytes(reader.fileData)

        // 2. 收集所有修改过的页面
        let modifiedPages = collectModifiedPages()

        // xref 条目：(对象号, 偏移)
        var xrefEntries: ArrayList<(Int32, Int64)> = ArrayList<(Int32, Int64)>()

        // 3. 为每个修改页面写新的内容流对象并更新页面字典
        for (i in 0..modifiedPages.size) {
            let pageNum = modifiedPages[i]
            let pageObjNum = reader.getPageObjectNumber(pageNum)
            if (pageObjNum <= 0) { continue }

            // 写下层内容流
            var underRef: ?Int32 = None
            match (underContents.get(pageNum)) {
                case Some(cb) =>
                    if (cb.size > 0) {
                        let objNum = allocateObjectNumber()
                        let offset = outputStream.position
                        writeStreamObj(outputStream, objNum, cb.toByteArray())
                        xrefEntries.add((objNum, offset))
                        underRef = Some(objNum)
                    }
                case None => ()
            }

            // 写上层内容流
            var overRef: ?Int32 = None
            match (overContents.get(pageNum)) {
                case Some(cb) =>
                    if (cb.size > 0) {
                        let objNum = allocateObjectNumber()
                        let offset = outputStream.position
                        writeStreamObj(outputStream, objNum, cb.toByteArray())
                        xrefEntries.add((objNum, offset))
                        overRef = Some(objNum)
                    }
                case None => ()
            }

            // 写更新后的页面字典
            let pageDictObjNum = pageObjNum
            let pageOffset = outputStream.position
            writeUpdatedPageDict(outputStream, pageNum, pageDictObjNum, underRef, overRef)
            xrefEntries.add((pageDictObjNum, pageOffset))
        }

        // 4. 若有 moreInfo，写 Info 对象
        var infoObjNum: ?Int32 = None
        if (moreInfo.size > 0) {
            let objNum = allocateObjectNumber()
            let offset = outputStream.position
            let infoDict = PdfDictionary()
            for ((k, v) in moreInfo) {
                infoDict.put(PdfName(k), PdfString(v))
            }
            PdfIndirectObject(objNum, infoDict).writeTo(outputStream)
            xrefEntries.add((objNum, offset))
            infoObjNum = Some(objNum)
        }

        // 5. 写 xref 段（每个对象单独一段）
        let xrefStart = outputStream.position
        for (i in 0..xrefEntries.size) {
            let (objNum, offset) = xrefEntries[i]
            outputStream.writeString("${objNum} 1\n")
            outputStream.writeString(formatXRefEntry(offset, 0))
        }

        // 6. 写 trailer
        let prevXRef = reader.getStartXRefOffset()
        let rootObjNum = reader.getRootObjectNumber()
        let totalObjs = nextObjectNumber

        outputStream.writeString("trailer\n")
        outputStream.writeString("<< /Size ${totalObjs} /Root ${rootObjNum} 0 R /Prev ${prevXRef}")
        match (infoObjNum) {
            case Some(n) => outputStream.writeString(" /Info ${n} 0 R")
            case None => ()
        }
        outputStream.writeString(" >>\n")

        // 7. startxref + %%EOF
        outputStream.writeString("startxref\n${xrefStart}\n%%EOF\n")

        reader.close()
    }

    // ─── Private helpers ───────────────────────────────────────────────────────

    private func allocateObjectNumber(): Int32 {
        let n = nextObjectNumber
        nextObjectNumber += 1
        n
    }

    private func collectModifiedPages(): ArrayList<Int32> {
        let result = ArrayList<Int32>()
        // 收集 overContents 中有内容的页面
        for ((pageNum, cb) in overContents) {
            if (cb.size > 0) { result.add(pageNum) }
        }
        // 收集 underContents 中有内容但尚未加入的页面
        for ((pageNum, cb) in underContents) {
            if (cb.size > 0) {
                var found = false
                for (i in 0..result.size) {
                    if (result[i] == pageNum) { found = true; break }
                }
                if (!found) { result.add(pageNum) }
            }
        }
        result
    }

    /**
     * 写一个 stream 对象：N 0 obj\n<< /Length M >>\nstream\n<bytes>\nendstream\nendobj\n
     */
    private func writeStreamObj(os: PdfOutputStream, objNum: Int32, bytes: Array<UInt8>): Unit {
        os.writeString("${objNum} 0 obj\n")
        os.writeString("<< /Length ${bytes.size} >>\n")
        os.writeString("stream\n")
        os.writeBytes(bytes)
        os.writeString("\nendstream\nendobj\n")
    }

    /**
     * 写更新后的页面字典，将 underRef/overRef 插入 /Contents 数组
     */
    private func writeUpdatedPageDict(
        os: PdfOutputStream,
        pageNum: Int32,
        pageDictObjNum: Int32,
        underRef: ?Int32,
        overRef: ?Int32
    ): Unit {
        let idx = Int64(pageNum - 1)
        if (idx < 0 || idx >= reader.pageObjectNumbers.size) { return }

        // 获取原始 /Contents
        let originalContents = getOriginalContentsRefs(pageNum)

        // 构建新 Contents 数组
        let contentsArray = PdfArray()
        match (underRef) {
            case Some(n) => contentsArray.add(PdfIndirectReference(n))
            case None => ()
        }
        for (i in 0..originalContents.size) {
            contentsArray.add(PdfIndirectReference(originalContents[i]))
        }
        match (overRef) {
            case Some(n) => contentsArray.add(PdfIndirectReference(n))
            case None => ()
        }

        // 写页面字典对象
        os.writeString("${pageDictObjNum} 0 obj\n")
        os.writeString("<< /Type /Page")

        // 复制原始页面字典中的其他条目
        let pageDict = getPageDict(pageNum)
        match (pageDict) {
            case Some(d) =>
                let ks = d.keys()
                for (i in 0..ks.size) {
                    let k = ks[i]
                    if (k == "Type" || k == "Contents") { continue }
                    match (d.get(PdfName(k))) {
                        case Some(v) =>
                            os.writeString(" /${k} ")
                            v.writeTo(os)
                        case None => ()
                    }
                }
            case None => ()
        }

        os.writeString(" /Contents ")
        contentsArray.writeTo(os)
        os.writeString(" >>\nendobj\n")
    }

    /**
     * 获取页面原始 /Contents 中的对象号列表
     */
    private func getOriginalContentsRefs(pageNum: Int32): ArrayList<Int32> {
        let result = ArrayList<Int32>()
        let pageDict = getPageDict(pageNum)
        match (pageDict) {
            case Some(d) =>
                match (d.get(PdfName("Contents"))) {
                    case Some(ref: PdfIndirectReference) =>
                        result.add(ref.objectNumber)
                    case Some(arr: PdfArray) =>
                        for (i in 0..arr.size) {
                            match (arr.get(i)) {
                                case ref: PdfIndirectReference => result.add(ref.objectNumber)
                                case _ => ()
                            }
                        }
                    case _ => ()
                }
            case None => ()
        }
        result
    }

    private func getPageDict(pageNum: Int32): ?PdfDictionary {
        let idx = Int64(pageNum - 1)
        if (idx >= 0 && idx < reader.pageObjectNumbers.size) {
            let objNum = reader.pageObjectNumbers[idx]
            match (reader.getObject(PdfIndirectReference(objNum))) {
                case Some(d: PdfDictionary) => Some(d)
                case _ => None
            }
        } else {
            None
        }
    }

    /**
     * 格式化 20 字节 xref 条目：NNNNNNNNNN GGGGG n \r\n
     */
    private func formatXRefEntry(offset: Int64, gen: Int32): String {
        padLeft10(offset) + " " + padLeft5(gen) + " n \r\n"
    }

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
}

/**
 * PdfStamper 工厂类
 */
public class PdfStamperFactory {
    public static func create(inputPath: String, outputStream: PdfOutputStream): PdfStamper {
        PdfStamper(PdfReader(inputPath), outputStream)
    }

    public static func createFromReader(reader: PdfReader, outputStream: PdfOutputStream): PdfStamper {
        PdfStamper(reader, outputStream)
    }
}
