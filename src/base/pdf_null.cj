/**
 * PDF-CJ: PdfNull - PDF 空对象
 */
package pdf_cj.base

/**
 * PDF 空对象
 * 表示 PDF 中的 null 值
 */
public class PdfNull <: PdfObjectBase {
    // 单例实例
    public static let INSTANCE = PdfNull()

    private init() {}

    public override func getType(): PdfObjectType {
        PdfObjectType.Null
    }

    public override func writeTo(os: PdfOutputStream): Unit {
        os.writeString("null")
    }
}
