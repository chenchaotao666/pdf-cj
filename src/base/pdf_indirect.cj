/**
 * PDF-CJ: PdfIndirectReference - PDF 间接引用
 */
package pdf_cj.base

/**
 * PDF 间接引用
 * 格式: objNum genNum R
 */
public class PdfIndirectReference <: PdfObjectBase {
    private let _objectNumber: Int32
    private let _generation: Int32

    /**
     * 创建间接引用
     */
    public init(objectNumber: Int32, generation: Int32) {
        this._objectNumber = objectNumber
        this._generation = generation
    }

    /**
     * 创建间接引用（generation = 0）
     */
    public init(objectNumber: Int32) {
        this._objectNumber = objectNumber
        this._generation = 0
    }

    /**
     * 获取对象编号
     */
    public prop objectNumber: Int32 {
        get() { _objectNumber }
    }

    /**
     * 获取世代号
     */
    public prop generation: Int32 {
        get() { _generation }
    }

    public override func getType(): PdfObjectType {
        PdfObjectType.Indirect
    }

    public override func writeTo(os: PdfOutputStream): Unit {
        os.writeInt(Int64(_objectNumber))
        os.writeSpace()
        os.writeInt(Int64(_generation))
        os.writeString(" R")
    }
}

/**
 * PDF 间接对象
 * 包含对象编号、世代号和实际对象
 */
public class PdfIndirectObject {
    private let _objectNumber: Int32
    private let _generation: Int32
    private let _object: PdfObject

    /**
     * 创建间接对象
     */
    public init(objectNumber: Int32, generation: Int32, obj: PdfObject) {
        this._objectNumber = objectNumber
        this._generation = generation
        this._object = obj
    }

    /**
     * 创建间接对象（generation = 0）
     */
    public init(objectNumber: Int32, obj: PdfObject) {
        this._objectNumber = objectNumber
        this._generation = 0
        this._object = obj
    }

    /**
     * 获取对象编号
     */
    public prop objectNumber: Int32 {
        get() { _objectNumber }
    }

    /**
     * 获取世代号
     */
    public prop generation: Int32 {
        get() { _generation }
    }

    /**
     * 获取实际对象
     */
    public prop object: PdfObject {
        get() { _object }
    }

    /**
     * 获取间接引用
     */
    public func getReference(): PdfIndirectReference {
        PdfIndirectReference(_objectNumber, _generation)
    }

    /**
     * 写入间接对象定义
     */
    public func writeTo(os: PdfOutputStream): Unit {
        os.writeInt(Int64(_objectNumber))
        os.writeSpace()
        os.writeInt(Int64(_generation))
        os.writeString(" obj")
        os.writeNewLine()
        _object.writeTo(os)
        os.writeNewLine()
        os.writeString("endobj")
        os.writeNewLine()
    }
}
