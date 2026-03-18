/**
 * PDF-CJ: PdfBoolean - PDF 布尔对象
 */
package pdf_cj.base

/**
 * PDF 布尔对象
 */
public class PdfBoolean <: PdfObjectBase {
    private let _value: Bool

    // 预定义实例
    public static let TRUE = PdfBoolean(true)
    public static let FALSE = PdfBoolean(false)

    public init(value: Bool) {
        this._value = value
    }

    /**
     * 获取布尔值
     */
    public prop value: Bool {
        get() { _value }
    }

    public override func getType(): PdfObjectType {
        PdfObjectType.Boolean
    }

    public override func writeTo(os: PdfOutputStream): Unit {
        if (_value) {
            os.writeString("true")
        } else {
            os.writeString("false")
        }
    }

    /**
     * 获取 PdfBoolean 实例
     */
    public static func getInstance(value: Bool): PdfBoolean {
        if (value) {
            TRUE
        } else {
            FALSE
        }
    }
}
