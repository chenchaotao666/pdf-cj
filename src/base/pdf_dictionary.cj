/**
 * PDF-CJ: PdfDictionary - PDF 字典对象
 */
package pdf_cj.base

import std.collection.HashMap
import std.collection.ArrayList

/**
 * PDF 字典对象
 */
public class PdfDictionary <: PdfObjectBase {
    protected var entries: HashMap<String, PdfObject> = HashMap<String, PdfObject>()
    protected var keyOrder: ArrayList<String> = ArrayList<String>()

    /**
     * 创建空字典
     */
    public init() {}

    /**
     * 创建带类型的字典
     */
    public init(dictType: PdfName) {
        put(PdfName.TYPE, dictType)
    }

    /**
     * 设置键值对
     */
    public func put(key: PdfName, value: PdfObject): Unit {
        let keyStr = key.name
        if (!entries.contains(keyStr)) {
            keyOrder.add(keyStr)
        }
        entries[keyStr] = value
    }

    /**
     * 设置数字值
     */
    public func put(key: PdfName, value: Int64): Unit {
        put(key, PdfNumber(value))
    }

    /**
     * 设置浮点数值
     */
    public func put(key: PdfName, value: Float32): Unit {
        put(key, PdfNumber(value))
    }

    /**
     * 设置字符串值
     */
    public func put(key: PdfName, value: String): Unit {
        put(key, PdfString(value))
    }

    /**
     * 设置布尔值
     */
    public func put(key: PdfName, value: Bool): Unit {
        put(key, PdfBoolean.getInstance(value))
    }

    /**
     * 获取值
     */
    public func get(key: PdfName): ?PdfObject {
        entries.get(key.name)
    }

    /**
     * 获取数字值
     */
    public func getAsNumber(key: PdfName): ?PdfNumber {
        match (get(key)) {
            case Some(num: PdfNumber) => Option<PdfNumber>.Some(num)
            case _ => Option<PdfNumber>.None
        }
    }

    /**
     * 获取字符串值
     */
    public func getAsString(key: PdfName): ?PdfString {
        match (get(key)) {
            case Some(str: PdfString) => Option<PdfString>.Some(str)
            case _ => Option<PdfString>.None
        }
    }

    /**
     * 获取名称值
     */
    public func getAsName(key: PdfName): ?PdfName {
        match (get(key)) {
            case Some(name: PdfName) => Option<PdfName>.Some(name)
            case _ => Option<PdfName>.None
        }
    }

    /**
     * 获取数组值
     */
    public func getAsArray(key: PdfName): ?PdfArray {
        match (get(key)) {
            case Some(arr: PdfArray) => Option<PdfArray>.Some(arr)
            case _ => Option<PdfArray>.None
        }
    }

    /**
     * 获取字典值
     */
    public func getAsDictionary(key: PdfName): ?PdfDictionary {
        match (get(key)) {
            case Some(dict: PdfDictionary) => Option<PdfDictionary>.Some(dict)
            case _ => Option<PdfDictionary>.None
        }
    }

    /**
     * 移除键值对
     */
    public func remove(key: PdfName): Unit {
        entries.remove(key.name)
        // 从keyOrder中移除
        var newOrder = ArrayList<String>()
        for (k in keyOrder) {
            if (k != key.name) {
                newOrder.add(k)
            }
        }
        keyOrder = newOrder
    }

    /**
     * 检查是否包含键
     */
    public func contains(key: PdfName): Bool {
        entries.contains(key.name)
    }

    /**
     * 获取键数量
     */
    public prop size: Int64 {
        get() { entries.size }
    }

    /**
     * 是否为空
     */
    public func isEmpty(): Bool {
        entries.isEmpty()
    }

    /**
     * 合并另一个字典
     */
    public func merge(other: PdfDictionary): Unit {
        for (key in other.keyOrder) {
            let value = other.entries.get(key)
            if (value.isSome()) {
                let v = value.getOrThrow()
                if (!entries.contains(key)) {
                    keyOrder.add(key)
                }
                entries[key] = v
            }
        }
    }

    public override func getType(): PdfObjectType {
        PdfObjectType.Dictionary
    }

    public override func writeTo(os: PdfOutputStream): Unit {
        os.writeString("<<")
        for (key in keyOrder) {
            let value = entries.get(key)
            if (value.isSome()) {
                let v = value.getOrThrow()
                let nameObj = PdfName(key)
                nameObj.writeTo(os)
                os.writeSpace()
                v.writeTo(os)
            }
        }
        os.writeString(">>")
    }

    /**
     * 获取所有键
     */
    public func keys(): ArrayList<String> {
        keyOrder
    }
}
