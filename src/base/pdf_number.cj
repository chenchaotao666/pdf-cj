/**
 * PDF-CJ: PdfNumber - PDF 数字对象
 */
package pdf_cj.base

/**
 * PDF 数字对象
 * 支持整数和浮点数
 */
public class PdfNumber <: PdfObjectBase {
    private var intValue: Int64 = 0
    private var floatValue: Float64 = 0.0
    private var isInteger: Bool = true

    /**
     * 从整数创建
     */
    public init(value: Int64) {
        this.intValue = value
        this.floatValue = Float64(value)
        this.isInteger = true
    }

    /**
     * 从 Int32 创建
     */
    public init(value: Int32) {
        this.intValue = Int64(value)
        this.floatValue = Float64(value)
        this.isInteger = true
    }

    /**
     * 从浮点数创建
     */
    public init(value: Float64) {
        this.floatValue = value
        this.intValue = Int64(value)
        // 检查是否为整数
        this.isInteger = (Float64(Int64(value)) == value)
    }

    /**
     * 从 Float32 创建
     */
    public init(value: Float32) {
        this.floatValue = Float64(value)
        this.intValue = Int64(value)
        this.isInteger = (Float64(Int64(value)) == Float64(value))
    }

    /**
     * 获取整数值
     */
    public func intVal(): Int64 {
        intValue
    }

    /**
     * 获取浮点数值
     */
    public func floatVal(): Float64 {
        floatValue
    }

    /**
     * 是否为整数
     */
    public func isInt(): Bool {
        isInteger
    }

    public override func getType(): PdfObjectType {
        PdfObjectType.Number
    }

    public override func writeTo(os: PdfOutputStream): Unit {
        if (isInteger) {
            os.writeInt(intValue)
        } else {
            os.writeFloat64(floatValue)
        }
    }

    // 预定义常量
    public static let ZERO = PdfNumber(Int64(0))
    public static let ONE = PdfNumber(Int64(1))
}
