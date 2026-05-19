/**
 * PDF-CJ: PdfCatalog - PDF Catalog 字典
 * 文档的根目录
 */
package pdf_cj.core

import pdf_cj.base.{PdfDictionary, PdfName, PdfIndirectReference}

/**
 * PDF Catalog 字典
 */
public class PdfCatalog {
    private var _dictionary: PdfDictionary = PdfDictionary(PdfName.CATALOG)
    private var _pagesRef: ?PdfIndirectReference = None

    public init() {}

    /**
     * 设置页面树引用
     */
    public func setPages(pagesRef: PdfIndirectReference): Unit {
        this._pagesRef = Some(pagesRef)
        _dictionary.put(PdfName.PAGES, pagesRef)
    }

    /**
     * 获取页面树引用
     */
    public prop pagesRef: ?PdfIndirectReference {
        get() { _pagesRef }
    }

    /**
     * 设置页面布局
     */
    public func setPageLayout(layout: PageLayout): Unit {
        let name = match (layout) {
            case SinglePage => "SinglePage"
            case OneColumn => "OneColumn"
            case TwoColumnLeft => "TwoColumnLeft"
            case TwoColumnRight => "TwoColumnRight"
            case TwoPageLeft => "TwoPageLeft"
            case TwoPageRight => "TwoPageRight"
        }
        _dictionary.put(PdfName("PageLayout"), PdfName(name))
    }

    /**
     * 设置页面模式
     */
    public func setPageMode(mode: PageMode): Unit {
        let name = match (mode) {
            case UseNone => "UseNone"
            case UseOutlines => "UseOutlines"
            case UseThumbs => "UseThumbs"
            case FullScreen => "FullScreen"
            case UseOC => "UseOC"
            case UseAttachments => "UseAttachments"
        }
        _dictionary.put(PdfName("PageMode"), PdfName(name))
    }

    /**
     * 设置语言
     */
    public func setLanguage(lang: String): Unit {
        _dictionary.put(PdfName.LANG, lang)
    }

    /**
     * 设置大纲/书签根节点引用
     */
    public func setOutlines(ref: PdfIndirectReference): Unit {
        _dictionary.put(PdfName("Outlines"), ref)
    }

    /**
     * 设置 AcroForm 字典
     */
    public func setAcroForm(acroForm: PdfDictionary): Unit {
        _dictionary.put(PdfName("AcroForm"), acroForm)
    }

    /**
     * 获取字典
     */
    public prop dictionary: PdfDictionary {
        get() { _dictionary }
    }
}

/**
 * 页面布局枚举
 */
public enum PageLayout {
    | SinglePage
    | OneColumn
    | TwoColumnLeft
    | TwoColumnRight
    | TwoPageLeft
    | TwoPageRight
}

/**
 * 页面模式枚举
 */
public enum PageMode {
    | UseNone
    | UseOutlines
    | UseThumbs
    | FullScreen
    | UseOC
    | UseAttachments
}
