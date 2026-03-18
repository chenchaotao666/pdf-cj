/**
 * PDF-CJ: PdfObject - PDF 对象基类
 * 所有 PDF 对象的抽象基类
 */
package pdf_cj.base

/**
 * PDF 对象类型枚举
 */
public enum PdfObjectType <: Equatable<PdfObjectType> {
    | Null
    | Boolean
    | Number
    | String
    | Name
    | Array
    | Dictionary
    | Stream
    | Indirect

    public operator func ==(other: PdfObjectType): Bool {
        match ((this, other)) {
            case (Null, Null) => true
            case (Boolean, Boolean) => true
            case (Number, Number) => true
            case (String, String) => true
            case (Name, Name) => true
            case (Array, Array) => true
            case (Dictionary, Dictionary) => true
            case (Stream, Stream) => true
            case (Indirect, Indirect) => true
            case _ => false
        }
    }

    public operator func !=(other: PdfObjectType): Bool {
        !(this == other)
    }
}

/**
 * PDF 对象接口
 * 所有 PDF 原始对象都实现此接口
 */
public interface PdfObject {
    /**
     * 获取对象类型
     */
    func getType(): PdfObjectType

    /**
     * 将对象写入输出流
     * @param os 输出流
     */
    func writeTo(os: PdfOutputStream): Unit

    /**
     * 转换为 PDF 字节表示
     */
    func toPdfBytes(): Array<Byte>

    /**
     * 是否为空对象
     */
    func isNull(): Bool

    /**
     * 是否为布尔对象
     */
    func isBoolean(): Bool

    /**
     * 是否为数字对象
     */
    func isNumber(): Bool

    /**
     * 是否为字符串对象
     */
    func isString(): Bool

    /**
     * 是否为名称对象
     */
    func isName(): Bool

    /**
     * 是否为数组对象
     */
    func isArray(): Bool

    /**
     * 是否为字典对象
     */
    func isDictionary(): Bool

    /**
     * 是否为流对象
     */
    func isStream(): Bool

    /**
     * 是否为间接引用
     */
    func isIndirect(): Bool
}

/**
 * PDF 对象基础实现
 * 提供通用方法的默认实现
 */
public abstract class PdfObjectBase <: PdfObject {
    /**
     * 获取对象类型（由子类实现）
     */
    public func getType(): PdfObjectType

    /**
     * 将对象写入输出流（由子类实现）
     */
    public func writeTo(os: PdfOutputStream): Unit

    /**
     * 转换为 PDF 字节表示
     */
    public func toPdfBytes(): Array<Byte> {
        let os = PdfByteArrayOutputStream()
        writeTo(os)
        os.toByteArray()
    }

    public func isNull(): Bool {
        getType() == PdfObjectType.Null
    }

    public func isBoolean(): Bool {
        getType() == PdfObjectType.Boolean
    }

    public func isNumber(): Bool {
        getType() == PdfObjectType.Number
    }

    public func isString(): Bool {
        getType() == PdfObjectType.String
    }

    public func isName(): Bool {
        getType() == PdfObjectType.Name
    }

    public func isArray(): Bool {
        getType() == PdfObjectType.Array
    }

    public func isDictionary(): Bool {
        getType() == PdfObjectType.Dictionary
    }

    public func isStream(): Bool {
        getType() == PdfObjectType.Stream
    }

    public func isIndirect(): Bool {
        getType() == PdfObjectType.Indirect
    }
}
