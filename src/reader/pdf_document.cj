/**
 * PDF-CJ: PdfDocument - PDF 文档表示
 * 表示已解析的 PDF 文档结构
 */
package pdf_cj.reader

import std.collection.{HashMap, ArrayList}
import pdf_cj.base.*

/**
 * PDF 文档类
 * 维护文档对象树和页面信息
 */
public class PdfDocument {
    private var catalog: ?PdfDictionary = None
    private var pages: ArrayList<PdfPage> = ArrayList<PdfPage>()
    private var objects: HashMap<Int32, PdfObject> = HashMap<Int32, PdfObject>()
    private var info: ?PdfDictionary = None

    /**
     * 设置 Catalog
     */
    public func setCatalog(cat: PdfDictionary): Unit {
        this.catalog = Some(cat)
    }

    /**
     * 获取 Catalog
     */
    public func getCatalog(): ?PdfDictionary {
        catalog
    }

    /**
     * 添加页面
     */
    public func addPage(page: PdfPage): Unit {
        pages.add(page)
    }

    /**
     * 获取页面
     * @param pageNum 页码（从 0 开始）
     */
    public func getPage(pageNum: Int64): ?PdfPage {
        if (pageNum >= 0 && pageNum < pages.size) {
            return Some(pages[pageNum])
        }
        None
    }

    /**
     * 获取页数
     */
    public func getPageCount(): Int64 {
        pages.size
    }

    /**
     * 添加对象
     */
    public func addObject(objNum: Int32, obj: PdfObject): Unit {
        objects[objNum] = obj
    }

    /**
     * 获取对象
     */
    public func getObject(objNum: Int32): ?PdfObject {
        objects.get(objNum)
    }

    /**
     * 设置文档信息
     */
    public func setInfo(infoDict: PdfDictionary): Unit {
        this.info = Some(infoDict)
    }

    /**
     * 获取文档信息
     */
    public func getInfo(): ?PdfDictionary {
        info
    }

    /**
     * 获取文档标题
     */
    public func getTitle(): String {
        match (info) {
            case Some(infoDict) =>
                match (infoDict.get(PdfName("Title"))) {
                    case Some(obj) =>
                        match (obj) {
                            case str: PdfString => return str.value
                            case _ => ()
                        }
                    case None => ()
                }
            case None => ()
        }
        ""
    }

    /**
     * 获取文档作者
     */
    public func getAuthor(): String {
        match (info) {
            case Some(infoDict) =>
                match (infoDict.get(PdfName("Author"))) {
                    case Some(obj) =>
                        match (obj) {
                            case str: PdfString => return str.value
                            case _ => ()
                        }
                    case None => ()
                }
            case None => ()
        }
        ""
    }
}

/**
 * PDF 页面类
 * 表示单个 PDF 页面
 */
public class PdfPage {
    private var pageDict: PdfDictionary
    private var pageNumber: Int32
    private var mediaBox: ?Array<Float32> = None
    private var resources: ?PdfDictionary = None
    private var contents: ?PdfObject = None

    public init(pageDict: PdfDictionary, pageNumber: Int32) {
        this.pageDict = pageDict
        this.pageNumber = pageNumber
        parsePageDict()
    }

    /**
     * 解析页面字典
     */
    private func parsePageDict(): Unit {
        // 解析 MediaBox
        match (pageDict.get(PdfName("MediaBox"))) {
            case Some(obj) =>
                match (obj) {
                    case arr: PdfArray =>
                        mediaBox = Some(parseRectangle(arr))
                    case _ => ()
                }
            case None => ()
        }

        // 解析 Resources
        match (pageDict.get(PdfName("Resources"))) {
            case Some(obj) =>
                match (obj) {
                    case dict: PdfDictionary =>
                        resources = Some(dict)
                    case _ => ()
                }
            case None => ()
        }

        // 解析 Contents
        contents = pageDict.get(PdfName("Contents"))
    }

    /**
     * 解析矩形
     */
    private func parseRectangle(arr: PdfArray): Array<Float32> {
        let rect = Array<Float32>(4, repeat: 0.0)

        let size = arr.size
        if (size >= 4) {
            for (i in 0..4) {
                let obj = arr.get(i)
                match (obj) {
                    case num: PdfNumber =>
                        rect[Int64(i)] = Float32(num.floatVal())
                    case _ => ()
                }
            }
        }

        rect
    }

    /**
     * 获取页面号
     */
    public func getPageNumber(): Int32 {
        pageNumber
    }

    /**
     * 获取 MediaBox
     */
    public func getMediaBox(): ?Array<Float32> {
        mediaBox
    }

    /**
     * 获取页面宽度
     */
    public func getWidth(): Float32 {
        match (mediaBox) {
            case Some(box) =>
                if (box.size >= 4) {
                    return box[2] - box[0]
                }
            case None => ()
        }
        0.0
    }

    /**
     * 获取页面高度
     */
    public func getHeight(): Float32 {
        match (mediaBox) {
            case Some(box) =>
                if (box.size >= 4) {
                    return box[3] - box[1]
                }
            case None => ()
        }
        0.0
    }

    /**
     * 获取 Resources 字典
     */
    public func getResources(): ?PdfDictionary {
        resources
    }

    /**
     * 获取 Contents
     */
    public func getContents(): ?PdfObject {
        contents
    }

    /**
     * 获取页面字典
     */
    public func getPageDictionary(): PdfDictionary {
        pageDict
    }
}

/**
 * PDF 页面树遍历器
 * 用于遍历 Pages 树结构
 */
public class PageTreeTraverser {
    private var pages: ArrayList<PdfPage> = ArrayList<PdfPage>()
    private var pageCount: Int32 = 0

    /**
     * 遍历页面树
     * @param pagesDict Pages 字典
     */
    public func traverse(pagesDict: PdfDictionary): ArrayList<PdfPage> {
        traverseNode(pagesDict, 0)
        pages
    }

    /**
     * 递归遍历节点
     */
    private func traverseNode(node: PdfDictionary, level: Int32): Unit {
        // 获取节点类型
        match (node.get(PdfName("Type"))) {
            case Some(obj) =>
                match (obj) {
                    case name: PdfName =>
                        let typeName = name.name
                        if (typeName == "Pages") {
                            // 这是一个页面树节点，遍历子节点
                            traversePagesNode(node, level)
                        } else if (typeName == "Page") {
                            // 这是一个页面对象
                            addPageNode(node)
                        }
                    case _ => ()
                }
            case None => ()
        }
    }

    /**
     * 遍历 Pages 节点
     */
    private func traversePagesNode(pagesNode: PdfDictionary, level: Int32): Unit {
        // 获取 Kids 数组
        match (pagesNode.get(PdfName("Kids"))) {
            case Some(obj) =>
                match (obj) {
                    case arr: PdfArray =>
                        let count = arr.size
                        for (i in 0..count) {
                            let kidObj = arr.get(i)
                            match (kidObj) {
                                case dict: PdfDictionary =>
                                    traverseNode(dict, level + 1)
                                case _ => ()
                            }
                        }
                    case _ => ()
                }
            case None => ()
        }
    }

    /**
     * 添加页面节点
     */
    private func addPageNode(pageDict: PdfDictionary): Unit {
        let page = PdfPage(pageDict, pageCount)
        pages.add(page)
        pageCount += 1
    }

    /**
     * 获取页面数量
     */
    public func getPageCount(): Int32 {
        pageCount
    }
}
