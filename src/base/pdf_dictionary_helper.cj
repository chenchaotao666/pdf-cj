/**
 * PDF-CJ: PdfDictionary Helper - 辅助函数
 * 用于解决类型推断问题
 */
package pdf_cj.base

/**
 * 创建 PdfNumber 的 Option
 */
public func somePdfNumber(value: PdfNumber): ?PdfNumber {
    Option<PdfNumber>.Some(value)
}

/**
 * 创建 PdfString 的 Option
 */
public func somePdfString(value: PdfString): ?PdfString {
    Option<PdfString>.Some(value)
}

/**
 * 创建 PdfName 的 Option
 */
public func somePdfName(value: PdfName): ?PdfName {
    Option<PdfName>.Some(value)
}

/**
 * 创建 PdfArray 的 Option
 */
public func somePdfArray(value: PdfArray): ?PdfArray {
    Option<PdfArray>.Some(value)
}

/**
 * 创建 PdfDictionary 的 Option
 */
public func somePdfDictionary(value: PdfDictionary): ?PdfDictionary {
    Option<PdfDictionary>.Some(value)
}
