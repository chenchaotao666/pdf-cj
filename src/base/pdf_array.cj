/**
 * PDF-CJ: PdfArray - PDF 数组对象
 */
package pdf_cj.base

import std.collection.ArrayList

/**
 * PDF 数组对象
 */
public class PdfArray <: PdfObjectBase {
    private var elements: ArrayList<PdfObject> = ArrayList<PdfObject>()

    /**
     * 创建空数组
     */
    public init() {}

    /**
     * 从单个元素创建
     */
    public init(element: PdfObject) {
        elements.add(element)
    }

    /**
     * 从数字数组创建
     */
    public init(values: Array<Float32>) {
        for (v in values) {
            elements.add(PdfNumber(v))
        }
    }

    /**
     * 从整数数组创建
     */
    public init(values: Array<Int32>) {
        for (v in values) {
            elements.add(PdfNumber(v))
        }
    }

    /**
     * 添加元素
     */
    public func add(obj: PdfObject): PdfArray {
        elements.add(obj)
        this
    }

    /**
     * 添加数字
     */
    public func add(value: Float32): PdfArray {
        elements.add(PdfNumber(value))
        this
    }

    /**
     * 添加整数
     */
    public func add(value: Int32): PdfArray {
        elements.add(PdfNumber(value))
        this
    }

    /**
     * 添加字符串
     */
    public func add(value: String): PdfArray {
        elements.add(PdfString(value))
        this
    }

    /**
     * 获取元素
     */
    public func get(index: Int64): PdfObject {
        elements[index]
    }

    /**
     * 获取数组大小
     */
    public prop size: Int64 {
        get() { elements.size }
    }

    /**
     * 是否为空
     */
    public func isEmpty(): Bool {
        elements.isEmpty()
    }

    /**
     * 获取数字值
     */
    public func getAsNumber(index: Int64): ?PdfNumber {
        let obj = elements[index]
        match (obj) {
            case num: PdfNumber => Some(num)
            case _ => None
        }
    }

    /**
     * 获取字符串值
     */
    public func getAsString(index: Int64): ?PdfString {
        let obj = elements[index]
        match (obj) {
            case str: PdfString => Some(str)
            case _ => None
        }
    }

    /**
     * 获取名称值
     */
    public func getAsName(index: Int64): ?PdfName {
        let obj = elements[index]
        match (obj) {
            case name: PdfName => Some(name)
            case _ => None
        }
    }

    /**
     * 获取数组值
     */
    public func getAsArray(index: Int64): ?PdfArray {
        let obj = elements[index]
        match (obj) {
            case arr: PdfArray => Some(arr)
            case _ => None
        }
    }

    /**
     * 获取字典值
     */
    public func getAsDictionary(index: Int64): ?PdfDictionary {
        let obj = elements[index]
        match (obj) {
            case dict: PdfDictionary => Some(dict)
            case _ => None
        }
    }

    public override func getType(): PdfObjectType {
        PdfObjectType.Array
    }

    public override func writeTo(os: PdfOutputStream): Unit {
        os.write(UInt8(0x5B))  // [
        var first = true
        for (element in elements) {
            if (!first) {
                os.writeSpace()
            }
            element.writeTo(os)
            first = false
        }
        os.write(UInt8(0x5D))  // ]
    }

    /**
     * 迭代数组元素
     */
    public func iterator(): Iterator<PdfObject> {
        elements.iterator()
    }
}
