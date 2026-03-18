/**
 * PDF-CJ: PageEvent - 页面事件接口
 */
package pdf_cj.core

import pdf_cj.api.Document
import pdf_cj.util.Rectangle

/**
 * 页面事件接口
 * 允许在页面生命周期的关键点执行自定义操作
 */
public interface PdfPageEvent {
    /**
     * 文档打开时调用
     */
    func onOpenDocument(writer: PdfWriter, document: Document): Unit

    /**
     * 文档关闭时调用
     */
    func onCloseDocument(writer: PdfWriter, document: Document): Unit

    /**
     * 页面开始时调用
     */
    func onStartPage(writer: PdfWriter, document: Document): Unit

    /**
     * 页面结束时调用
     */
    func onEndPage(writer: PdfWriter, document: Document): Unit

    /**
     * 段落开始时调用
     */
    func onParagraph(writer: PdfWriter, document: Document, paragraphPosition: Float32): Unit

    /**
     * 段落结束时调用
     */
    func onParagraphEnd(writer: PdfWriter, document: Document, paragraphPosition: Float32): Unit

    /**
     * 章节开始时调用
     */
    func onChapter(writer: PdfWriter, document: Document, paragraphPosition: Float32, title: String): Unit

    /**
     * 章节结束时调用
     */
    func onChapterEnd(writer: PdfWriter, document: Document, paragraphPosition: Float32): Unit

    /**
     * 节开始时调用
     */
    func onSection(writer: PdfWriter, document: Document, paragraphPosition: Float32, depth: Int32, title: String): Unit

    /**
     * 节结束时调用
     */
    func onSectionEnd(writer: PdfWriter, document: Document, paragraphPosition: Float32): Unit

    /**
     * 通用标签触发时调用
     */
    func onGenericTag(writer: PdfWriter, document: Document, rect: Rectangle, text: String): Unit
}

/**
 * 页面事件适配器
 * 提供空实现，便于只覆盖需要的方法
 */
public open class PdfPageEventAdapter <: PdfPageEvent {
    public func onOpenDocument(writer: PdfWriter, document: Document): Unit {}

    public func onCloseDocument(writer: PdfWriter, document: Document): Unit {}

    public func onStartPage(writer: PdfWriter, document: Document): Unit {}

    public func onEndPage(writer: PdfWriter, document: Document): Unit {}

    public func onParagraph(writer: PdfWriter, document: Document, paragraphPosition: Float32): Unit {}

    public func onParagraphEnd(writer: PdfWriter, document: Document, paragraphPosition: Float32): Unit {}

    public func onChapter(writer: PdfWriter, document: Document, paragraphPosition: Float32, title: String): Unit {}

    public func onChapterEnd(writer: PdfWriter, document: Document, paragraphPosition: Float32): Unit {}

    public func onSection(writer: PdfWriter, document: Document, paragraphPosition: Float32, depth: Int32, title: String): Unit {}

    public func onSectionEnd(writer: PdfWriter, document: Document, paragraphPosition: Float32): Unit {}

    public func onGenericTag(writer: PdfWriter, document: Document, rect: Rectangle, text: String): Unit {}
}
