/**
 * PDF-CJ: Document - 文档类
 * PDF 文档的核心类，用于创建和管理 PDF 内容
 */
package pdf_cj.api

import std.collection.ArrayList
import pdf_cj.util.{Rectangle, PageSize, PdfException, DocumentNotOpenException, DocumentClosedException}
import pdf_cj.text.{Font, Alignment}

// 前向声明 PdfWriter（将在 core 模块中定义）
// import pdf_cj.core.PdfWriter

/**
 * Document 类 - PDF 文档
 * 实现 ElementListener 接口以接收和处理元素
 */
public class Document <: ElementListener {
    // 页面设置
    private var _pageSize: Rectangle
    private var _marginLeft: Float32
    private var _marginRight: Float32
    private var _marginTop: Float32
    private var _marginBottom: Float32

    // 文档状态
    private var _opened: Bool = false
    private var _closed: Bool = false
    private var _pageNumber: Int32 = 0

    // 页眉页脚
    private var _header: ?HeaderFooter = None
    private var _footer: ?HeaderFooter = None

    // 文档元数据
    private var _title: ?String = None
    private var _author: ?String = None
    private var _subject: ?String = None
    private var _keywords: ?String = None
    private var _creator: ?String = None
    private var _producer: String = "PDF-CJ"

    // 内部使用
    private var _docListeners: ArrayList<DocListener> = ArrayList<DocListener>()
    private var _javaScript: ?String = None

    // 默认边距（0.5 英寸 = 36 点）
    public static let DEFAULT_MARGIN: Float32 = 36.0

    /**
     * 使用默认 A4 页面大小创建文档
     */
    public init() {
        this(PageSize.A4)
    }

    /**
     * 使用指定页面大小创建文档
     */
    public init(pageSize: Rectangle) {
        this(pageSize, DEFAULT_MARGIN, DEFAULT_MARGIN, DEFAULT_MARGIN, DEFAULT_MARGIN)
    }

    /**
     * 使用指定页面大小和边距创建文档
     */
    public init(pageSize: Rectangle, marginLeft: Float32, marginRight: Float32,
                marginTop: Float32, marginBottom: Float32) {
        this._pageSize = pageSize
        this._marginLeft = marginLeft
        this._marginRight = marginRight
        this._marginTop = marginTop
        this._marginBottom = marginBottom
    }

    // ===== 文档生命周期 =====

    /**
     * 打开文档以开始写入
     */
    public func open(): Unit {
        if (_opened) {
            throw PdfException("Document is already open")
        }
        _opened = true
        _pageNumber = 1

        // 通知所有监听器
        for (listener in _docListeners) {
            listener.open()
        }
    }

    /**
     * 关闭文档并完成写入
     */
    public func close(): Unit {
        if (_closed) {
            return
        }
        if (!_opened) {
            return
        }

        // 通知所有监听器
        for (listener in _docListeners) {
            listener.close()
        }

        _closed = true
    }

    /**
     * 检查文档是否已打开
     */
    public prop isOpen: Bool {
        get() { _opened && !_closed }
    }

    /**
     * 创建新页面
     */
    public func newPage(): Bool {
        if (!_opened || _closed) {
            return false
        }

        // 通知监听器
        for (listener in _docListeners) {
            listener.newPage()
        }

        _pageNumber++
        true
    }

    /**
     * 重置页码
     */
    public func resetPageCount(): Unit {
        _pageNumber = 0
    }

    // ===== 页面设置 =====

    /**
     * 获取页面大小
     */
    public prop pageSize: Rectangle {
        get() { _pageSize }
    }

    /**
     * 设置页面大小
     */
    public func setPageSize(size: Rectangle): Bool {
        this._pageSize = size

        // 通知监听器
        for (listener in _docListeners) {
            listener.setPageSize(size)
        }
        true
    }

    /**
     * 设置页面边距
     */
    public func setMargins(left: Float32, right: Float32,
                           top: Float32, bottom: Float32): Bool {
        this._marginLeft = left
        this._marginRight = right
        this._marginTop = top
        this._marginBottom = bottom

        // 通知监听器
        for (listener in _docListeners) {
            listener.setMargins(left, right, top, bottom)
        }
        true
    }

    /**
     * 获取左边距
     */
    public prop left: Float32 {
        get() { _marginLeft }
    }

    /**
     * 获取右边界位置
     */
    public prop right: Float32 {
        get() { _pageSize.width - _marginRight }
    }

    /**
     * 获取上边界位置
     */
    public prop top: Float32 {
        get() { _pageSize.height - _marginTop }
    }

    /**
     * 获取下边距
     */
    public prop bottom: Float32 {
        get() { _marginBottom }
    }

    /**
     * 获取左边距值
     */
    public prop leftMargin: Float32 {
        get() { _marginLeft }
    }

    /**
     * 获取右边距值
     */
    public prop rightMargin: Float32 {
        get() { _marginRight }
    }

    /**
     * 获取上边距值
     */
    public prop topMargin: Float32 {
        get() { _marginTop }
    }

    /**
     * 获取下边距值
     */
    public prop bottomMargin: Float32 {
        get() { _marginBottom }
    }

    /**
     * 获取当前页码
     */
    public prop currentPageNumber: Int32 {
        get() { _pageNumber }
    }

    // ===== 页眉页脚 =====

    /**
     * 设置页眉
     */
    public func setHeader(header: HeaderFooter): Unit {
        this._header = Some(header)
        for (listener in _docListeners) {
            listener.setHeader(header)
        }
    }

    /**
     * 获取页眉
     */
    public prop header: ?HeaderFooter {
        get() { _header }
    }

    /**
     * 重置页眉
     */
    public func resetHeader(): Unit {
        this._header = None
        for (listener in _docListeners) {
            listener.resetHeader()
        }
    }

    /**
     * 设置页脚
     */
    public func setFooter(footer: HeaderFooter): Unit {
        this._footer = Some(footer)
        for (listener in _docListeners) {
            listener.setFooter(footer)
        }
    }

    /**
     * 获取页脚
     */
    public prop footer: ?HeaderFooter {
        get() { _footer }
    }

    /**
     * 重置页脚
     */
    public func resetFooter(): Unit {
        this._footer = None
        for (listener in _docListeners) {
            listener.resetFooter()
        }
    }

    // ===== 元素添加 =====

    /**
     * 添加元素到文档（ElementListener 接口实现）
     */
    public func add(element: Element): Bool {
        if (!_opened) {
            throw DocumentNotOpenException()
        }
        if (_closed) {
            throw DocumentClosedException()
        }

        // 处理特殊元素类型
        match (element.getType()) {
            case Chapter => handleChapter()
            case _ => ()
        }

        // 通知监听器
        var success = true
        for (listener in _docListeners) {
            if (!listener.add(element)) {
                success = false
            }
        }
        success
    }

    // ===== 文档元数据 =====

    /**
     * 添加文档标题
     */
    public func addTitle(title: String): Bool {
        this._title = Some(title)
        true
    }

    /**
     * 添加文档作者
     */
    public func addAuthor(author: String): Bool {
        this._author = Some(author)
        true
    }

    /**
     * 添加文档主题
     */
    public func addSubject(subject: String): Bool {
        this._subject = Some(subject)
        true
    }

    /**
     * 添加文档关键词
     */
    public func addKeywords(keywords: String): Bool {
        this._keywords = Some(keywords)
        true
    }

    /**
     * 添加文档创建者
     */
    public func addCreator(creator: String): Bool {
        this._creator = Some(creator)
        true
    }

    /**
     * 添加创建日期（自动设置为当前时间）
     */
    public func addCreationDate(): Bool {
        // TODO: 实现日期添加
        true
    }

    /**
     * 获取文档标题
     */
    public prop title: ?String {
        get() { _title }
    }

    /**
     * 获取文档作者
     */
    public prop author: ?String {
        get() { _author }
    }

    /**
     * 获取文档主题
     */
    public prop subject: ?String {
        get() { _subject }
    }

    /**
     * 获取文档关键词
     */
    public prop keywords: ?String {
        get() { _keywords }
    }

    /**
     * 获取文档创建者
     */
    public prop creator: ?String {
        get() { _creator }
    }

    /**
     * 获取文档生成器
     */
    public prop producer: String {
        get() { _producer }
    }

    // ===== JavaScript =====

    /**
     * 添加 JavaScript
     */
    public func addJavaScript(js: String): Unit {
        this._javaScript = Some(js)
    }

    // ===== 私有辅助方法 =====

    /**
     * 处理章节元素（章节从新页面开始）
     */
    private func handleChapter(): Unit {
        if (_pageNumber > 1) {
            newPage()
        }
    }

    // ===== 监听器管理 =====

    /**
     * 添加文档监听器
     */
    public func addDocListener(listener: DocListener): Unit {
        _docListeners.add(listener)
    }

    /**
     * 移除文档监听器
     */
    public func removeDocListener(listener: DocListener): Unit {
        // TODO: 实现移除逻辑
    }
}

/**
 * 文档监听器接口
 * PdfWriter 等类实现此接口以接收文档事件
 */
public interface DocListener <: ElementListener {
    func open(): Unit
    func close(): Unit
    func newPage(): Bool
    func setPageSize(size: Rectangle): Bool
    func setMargins(left: Float32, right: Float32, top: Float32, bottom: Float32): Bool
    func setHeader(header: HeaderFooter): Unit
    func setFooter(footer: HeaderFooter): Unit
    func resetHeader(): Unit
    func resetFooter(): Unit
}
