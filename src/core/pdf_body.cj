/**
 * PDF-CJ: PdfBody - PDF Body 管理
 * 管理 PDF 对象编号分配和对象写入
 */
package pdf_cj.core

import std.collection.ArrayList
import pdf_cj.base.{PdfObject, PdfIndirectObject, PdfIndirectReference, PdfOutputStream}

/**
 * 对象位置记录
 */
public class ObjectOffset {
    public let objectNumber: Int32
    public let generation: Int32
    public let offset: Int64

    public init(objectNumber: Int32, generation: Int32, offset: Int64) {
        this.objectNumber = objectNumber
        this.generation = generation
        this.offset = offset
    }
}

/**
 * PDF Body 管理器
 * 负责分配对象编号和记录对象偏移量
 */
public class PdfBody {
    private var currentObjectNumber: Int32 = 0
    private var objects: ArrayList<ObjectOffset> = ArrayList<ObjectOffset>()
    private let outputStream: PdfOutputStream

    public init(os: PdfOutputStream) {
        this.outputStream = os
    }

    /**
     * 分配新的对象编号
     */
    public func allocateObjectNumber(): Int32 {
        currentObjectNumber += 1
        currentObjectNumber
    }

    /**
     * 添加对象到 body
     * @return 间接引用
     */
    public func add(obj: PdfObject): PdfIndirectReference {
        let objNum = allocateObjectNumber()
        let offset = outputStream.position

        // 记录偏移量
        objects.add(ObjectOffset(objNum, 0, offset))

        // 写入对象
        let indirectObj = PdfIndirectObject(objNum, obj)
        indirectObj.writeTo(outputStream)

        PdfIndirectReference(objNum)
    }

    /**
     * 添加对象到 body（指定对象编号）
     * @return 间接引用
     */
    public func add(obj: PdfObject, objNum: Int32): PdfIndirectReference {
        let offset = outputStream.position

        // 记录偏移量
        objects.add(ObjectOffset(objNum, 0, offset))

        // 写入对象
        let indirectObj = PdfIndirectObject(objNum, obj)
        indirectObj.writeTo(outputStream)

        PdfIndirectReference(objNum)
    }

    /**
     * 获取当前对象数量
     */
    public prop objectCount: Int32 {
        get() { currentObjectNumber }
    }

    /**
     * 获取所有对象偏移量
     */
    public func getOffsets(): ArrayList<ObjectOffset> {
        objects
    }

    /**
     * 写入交叉引用表
     * @return xref 表的起始位置
     */
    public func writeXref(): Int64 {
        let xrefPos = outputStream.position

        outputStream.writeString("xref")
        outputStream.writeNewLine()

        // 写入对象数量 (包括对象0)
        outputStream.writeString("0 ")
        outputStream.writeInt(Int64(currentObjectNumber) + 1)
        outputStream.writeNewLine()

        // 写入对象0（永久空闲对象）
        outputStream.writeString("0000000000 65535 f ")
        outputStream.writeNewLine()

        // 按对象编号排序写入
        for (i in 1..=currentObjectNumber) {
            var found = false
            for (obj in objects) {
                if (obj.objectNumber == i) {
                    writeXrefEntry(obj.offset, obj.generation, true)
                    found = true
                    break
                }
            }
            if (!found) {
                // 对象不存在，写入空闲条目
                writeXrefEntry(0, 65535, false)
            }
        }

        xrefPos
    }

    /**
     * 写入单个 xref 条目
     */
    private func writeXrefEntry(offset: Int64, generation: Int32, inUse: Bool): Unit {
        // 10位偏移量
        let offsetStr = padLeft(offset.toString(), 10, Rune(48))
        outputStream.writeString(offsetStr)
        outputStream.writeSpace()

        // 5位世代号
        let genStr = padLeft(generation.toString(), 5, Rune(48))
        outputStream.writeString(genStr)
        outputStream.writeSpace()

        // 标记
        if (inUse) {
            outputStream.write(UInt8(0x6E))  // 'n'
        } else {
            outputStream.write(UInt8(0x66))  // 'f'
        }
        outputStream.writeSpace()
        outputStream.writeNewLine()
    }

    /**
     * 左填充字符串
     */
    private func padLeft(s: String, length: Int64, padChar: Rune): String {
        var result = s
        while (result.size < length) {
            result = String([padChar]) + result
        }
        result
    }

    /**
     * 预留对象编号
     */
    public func reserveObjectNumber(): Int32 {
        allocateObjectNumber()
    }
}
