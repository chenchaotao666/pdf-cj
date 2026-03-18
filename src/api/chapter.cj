/**
 * PDF-CJ: Chapter & Section - 章节
 * 用于组织文档结构
 */
package pdf_cj.api

import std.collection.ArrayList
import pdf_cj.text.Font

/**
 * Section 类 - 小节
 * 文档结构单元，可嵌套
 */
public open class Section <: Element {
    protected var _title: ?Paragraph = None
    protected var _numberDepth: Int32 = 0
    protected var _numbers: ArrayList<Int32> = ArrayList<Int32>()
    protected var _content: ArrayList<Element> = ArrayList<Element>()
    protected var _triggerNewPage: Bool = false
    protected var _indentation: Float32 = 0.0
    protected var _indentationLeft: Float32 = 0.0
    protected var _indentationRight: Float32 = 0.0
    protected var _bookmarkOpen: Bool = true
    protected var _bookmarkTitle: ?String = None
    protected var _subsections: ArrayList<Section> = ArrayList<Section>()
    protected var _addedCompletely: Bool = false

    /**
     * 创建空 Section
     */
    public init() {}

    /**
     * 使用标题创建 Section
     */
    public init(title: Paragraph) {
        this._title = Some(title)
    }

    /**
     * 使用标题和编号深度创建 Section
     */
    public init(title: Paragraph, numberDepth: Int32) {
        this._title = Some(title)
        this._numberDepth = numberDepth
    }

    /**
     * 获取标题
     */
    public prop title: ?Paragraph {
        get() { _title }
    }

    /**
     * 设置标题
     */
    public func setTitle(title: Paragraph): Unit {
        this._title = Some(title)
    }

    /**
     * 获取编号深度
     */
    public prop numberDepth: Int32 {
        get() { _numberDepth }
    }

    /**
     * 设置编号深度
     */
    public func setNumberDepth(depth: Int32): Unit {
        this._numberDepth = depth
    }

    /**
     * 是否触发新页面
     */
    public prop triggerNewPage: Bool {
        get() { _triggerNewPage }
    }

    /**
     * 设置是否触发新页面
     */
    public func setTriggerNewPage(trigger: Bool): Unit {
        this._triggerNewPage = trigger
    }

    /**
     * 添加元素到 Section
     */
    public func add(element: Element): Bool {
        _content.add(element)
        true
    }

    /**
     * 添加子 Section
     */
    public func addSection(title: Paragraph): Section {
        let section = Section(title, _numberDepth + 1)
        _subsections.add(section)
        section
    }

    /**
     * 添加子 Section（带编号深度）
     */
    public func addSection(title: Paragraph, numberDepth: Int32): Section {
        let section = Section(title, numberDepth)
        _subsections.add(section)
        section
    }

    /**
     * 添加子 Section（使用字符串标题）
     */
    public func addSection(title: String): Section {
        addSection(Paragraph(title))
    }

    /**
     * 添加子 Section（使用缩进）
     */
    public func addSection(indentation: Float32, title: Paragraph): Section {
        let section = Section(title, _numberDepth + 1)
        section._indentation = indentation
        _subsections.add(section)
        section
    }

    /**
     * 获取缩进
     */
    public prop indentation: Float32 {
        get() { _indentation }
    }

    /**
     * 设置缩进
     */
    public func setIndentation(indentation: Float32): Unit {
        this._indentation = indentation
    }

    /**
     * 获取左缩进
     */
    public prop indentationLeft: Float32 {
        get() { _indentationLeft }
    }

    /**
     * 设置左缩进
     */
    public func setIndentationLeft(indentation: Float32): Unit {
        this._indentationLeft = indentation
    }

    /**
     * 获取右缩进
     */
    public prop indentationRight: Float32 {
        get() { _indentationRight }
    }

    /**
     * 设置右缩进
     */
    public func setIndentationRight(indentation: Float32): Unit {
        this._indentationRight = indentation
    }

    /**
     * 是否在书签中展开
     */
    public prop bookmarkOpen: Bool {
        get() { _bookmarkOpen }
    }

    /**
     * 设置是否在书签中展开
     */
    public func setBookmarkOpen(open: Bool): Unit {
        this._bookmarkOpen = open
    }

    /**
     * 获取书签标题
     */
    public prop bookmarkTitle: ?String {
        get() { _bookmarkTitle }
    }

    /**
     * 设置书签标题
     */
    public func setBookmarkTitle(title: String): Unit {
        this._bookmarkTitle = Some(title)
    }

    // ===== Element 接口实现 =====

    public open func getType(): ElementType {
        ElementType.Section
    }

    public func getChunks(): ArrayList<Chunk> {
        let result = ArrayList<Chunk>()

        // 添加标题的 Chunks
        match (_title) {
            case Some(t) => addElementChunks(t, result)
            case None => ()
        }

        // 添加内容的 Chunks
        for (element in _content) {
            addElementChunks(element, result)
        }

        result
    }

    private func addElementChunks(element: Element, result: ArrayList<Chunk>): Unit {
        for (chunk in element.getChunks()) {
            result.add(chunk)
        }
    }

    private func processTitle(title: Element, listener: ElementListener): Bool {
        if (!listener.add(title)) {
            return false
        }
        true
    }

    public func isContent(): Bool {
        false
    }

    public func isNestable(): Bool {
        false
    }

    public func process(listener: ElementListener): Bool {
        // 处理标题
        match (_title) {
            case Some(t) => processTitle(t, listener)
            case None => true
        }

        // 处理内容
        for (element in _content) {
            if (!listener.add(element)) {
                return false
            }
        }

        // 处理子 Section
        for (section in _subsections) {
            if (!listener.add(section)) {
                return false
            }
        }

        true
    }

    /**
     * 获取内容元素数量
     */
    public prop contentSize: Int64 {
        get() { _content.size }
    }

    /**
     * 获取子 Section 数量
     */
    public prop subsectionSize: Int64 {
        get() { _subsections.size }
    }
}

/**
 * Chapter 类 - 章节
 * 顶级文档结构单元，总是从新页面开始
 */
public class Chapter <: Section {
    private var _chapterNumber: Int32

    /**
     * 使用章节号创建 Chapter
     */
    public init(number: Int32) {
        super()
        this._chapterNumber = number
        this._triggerNewPage = true
        this._numberDepth = 0
    }

    /**
     * 使用标题和章节号创建 Chapter
     */
    public init(title: Paragraph, number: Int32) {
        super(title)
        this._chapterNumber = number
        this._triggerNewPage = true
        this._numberDepth = 0
    }

    /**
     * 使用字符串标题和章节号创建 Chapter
     */
    public init(title: String, number: Int32) {
        super(Paragraph(title))
        this._chapterNumber = number
        this._triggerNewPage = true
        this._numberDepth = 0
    }

    /**
     * 获取章节号
     */
    public prop chapterNumber: Int32 {
        get() { _chapterNumber }
    }

    public override func getType(): ElementType {
        ElementType.Chapter
    }
}
