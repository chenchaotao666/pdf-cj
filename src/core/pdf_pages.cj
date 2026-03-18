/**
 * PDF-CJ: PdfPages - PDF 页面树
 * 管理所有页面
 */
package pdf_cj.core

import std.collection.ArrayList
import pdf_cj.base.{PdfDictionary, PdfName, PdfIndirectReference, PdfArray, PdfNumber}
import pdf_cj.util.Rectangle

/**
 * 页面引用记录
 */
public class PageReference {
    public let pageRef: PdfIndirectReference
    public let index: Int32

    public init(pageRef: PdfIndirectReference, index: Int32) {
        this.pageRef = pageRef
        this.index = index
    }
}

/**
 * PDF 页面树
 */
public class PdfPages {
    private var pages: ArrayList<PageReference> = ArrayList<PageReference>()
    private var _dictionary: PdfDictionary = PdfDictionary(PdfName.PAGES)
    private var pageCount: Int32 = 0

    public init() {}

    /**
     * 添加页面引用
     */
    public func addPage(pageRef: PdfIndirectReference): Int32 {
        pageCount += 1
        pages.add(PageReference(pageRef, pageCount))
        pageCount
    }

    /**
     * 获取页面数量
     */
    public prop count: Int32 {
        get() { pageCount }
    }

    /**
     * 获取页面引用
     */
    public func getPage(index: Int32): ?PdfIndirectReference {
        for (page in pages) {
            if (page.index == index) {
                return Some(page.pageRef)
            }
        }
        None
    }

    /**
     * 生成页面树字典
     */
    public func toDictionary(): PdfDictionary {
        // Kids 数组
        let kids = PdfArray()
        for (page in pages) {
            kids.add(page.pageRef)
        }
        _dictionary.put(PdfName.KIDS, kids)

        // Count
        _dictionary.put(PdfName.COUNT, PdfNumber(Int32(pageCount)))

        _dictionary
    }

    /**
     * 获取字典
     */
    public prop dictionary: PdfDictionary {
        get() { toDictionary() }
    }

    /**
     * 设置自身引用（用于子页面的 Parent）
     */
    public func setReference(ref: PdfIndirectReference): Unit {
        // 页面树不需要 Parent，只有子页面需要
    }
}
