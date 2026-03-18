/**
 * PDF-CJ: PdfException - PDF 异常类
 * 定义 PDF 操作相关的异常
 */
package pdf_cj.util

/**
 * PDF 通用异常
 */
public open class PdfException <: Exception {
    public init(message: String) {
        super(message)
    }
}

/**
 * PDF 文档未打开异常
 */
public class DocumentNotOpenException <: PdfException {
    public init() {
        super("Document is not open for writing")
    }
}

/**
 * PDF 文档已关闭异常
 */
public class DocumentClosedException <: PdfException {
    public init() {
        super("Document has been closed")
    }
}

/**
 * 无效页码异常
 */
public class InvalidPageNumberException <: PdfException {
    public init(pageNumber: Int32, maxPages: Int32) {
        super("Invalid page number: ${pageNumber}. Valid range: 1-${maxPages}")
    }
}

/**
 * PDF 解析异常
 */
public class PdfParseException <: PdfException {
    public init(message: String) {
        super("PDF parse error: ${message}")
    }
}

/**
 * 不支持的功能异常
 */
public class UnsupportedPdfFeatureException <: PdfException {
    public init(feature: String) {
        super("Unsupported PDF feature: ${feature}")
    }
}

/**
 * 字体异常
 */
public class FontException <: PdfException {
    public init(message: String) {
        super("Font error: ${message}")
    }
}

/**
 * 图片异常
 */
public class ImageException <: PdfException {
    public init(message: String) {
        super("Image error: ${message}")
    }
}
