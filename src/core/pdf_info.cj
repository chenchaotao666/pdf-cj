/**
 * PDF-CJ: PdfInfo - PDF 文档信息字典
 */
package pdf_cj.core

import pdf_cj.base.{PdfDictionary, PdfName, PdfString, PdfStringEncoding}
import pdf_cj.api.Document

/**
 * PDF 文档信息字典
 */
public class PdfInfo {
    private var _dictionary: PdfDictionary = PdfDictionary()

    public init() {}

    /**
     * 从 Document 创建信息字典
     */
    public init(document: Document) {
        match (document.title) {
            case Some(title) => setTitle(title)
            case None => ()
        }
        match (document.author) {
            case Some(author) => setAuthor(author)
            case None => ()
        }
        match (document.subject) {
            case Some(subject) => setSubject(subject)
            case None => ()
        }
        match (document.keywords) {
            case Some(keywords) => setKeywords(keywords)
            case None => ()
        }
        match (document.creator) {
            case Some(creator) => setCreator(creator)
            case None => ()
        }
        setProducer(document.producer)
    }

    /**
     * 设置标题
     */
    public func setTitle(title: String): Unit {
        _dictionary.put(PdfName.TITLE, PdfString(title, PdfStringEncoding.Unicode))
    }

    /**
     * 设置作者
     */
    public func setAuthor(author: String): Unit {
        _dictionary.put(PdfName.AUTHOR, PdfString(author, PdfStringEncoding.Unicode))
    }

    /**
     * 设置主题
     */
    public func setSubject(subject: String): Unit {
        _dictionary.put(PdfName.SUBJECT, PdfString(subject, PdfStringEncoding.Unicode))
    }

    /**
     * 设置关键词
     */
    public func setKeywords(keywords: String): Unit {
        _dictionary.put(PdfName.KEYWORDS, PdfString(keywords, PdfStringEncoding.Unicode))
    }

    /**
     * 设置创建者
     */
    public func setCreator(creator: String): Unit {
        _dictionary.put(PdfName.CREATOR, PdfString(creator, PdfStringEncoding.Unicode))
    }

    /**
     * 设置生成器
     */
    public func setProducer(producer: String): Unit {
        _dictionary.put(PdfName.PRODUCER, PdfString(producer, PdfStringEncoding.Unicode))
    }

    /**
     * 设置创建日期
     */
    public func setCreationDate(date: String): Unit {
        _dictionary.put(PdfName.CREATIONDATE, PdfString("D:" + date))
    }

    /**
     * 设置修改日期
     */
    public func setModDate(date: String): Unit {
        _dictionary.put(PdfName.MODDATE, PdfString("D:" + date))
    }

    /**
     * 获取字典
     */
    public prop dictionary: PdfDictionary {
        get() { _dictionary }
    }
}
