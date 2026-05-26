/**
 * PDF-CJ: Phrase - 短语
 * 由多个 Chunk 组成的文本序列，共享默认字体
 */
package pdf_cj.api

import std.collection.ArrayList
import pdf_cj.text.Font

/**
 * Phrase 类 - 短语
 * 包含多个 Chunk，具有统一的行距
 */
public open class Phrase <: Element {
    protected var chunks: ArrayList<Element> = ArrayList<Element>()
    protected var _font: Font
    protected var _leading: Float32

    // 默认行距系数
    public static let DEFAULT_LEADING_MULTIPLIER: Float32 = 1.5

    /**
     * 创建空的 Phrase
     * 与 OpenPDF 一致：Phrase() 默认行距为 16（不依赖字号）
     */
    public init() {
        this._font = Font.DEFAULT
        this._leading = 16.0
    }

    /**
     * 使用文本内容创建 Phrase
     */
    public init(text: String) {
        this._font = Font.DEFAULT
        this._leading = Font.DEFAULTSIZE * DEFAULT_LEADING_MULTIPLIER
        chunks.add(Chunk(text))
    }

    /**
     * 使用文本内容和字体创建 Phrase
     */
    public init(text: String, font: Font) {
        this._font = font
        this._leading = font.size * DEFAULT_LEADING_MULTIPLIER
        chunks.add(Chunk(text, font))
    }

    /**
     * 使用行距创建 Phrase
     */
    public init(leading: Float32) {
        this._font = Font.DEFAULT
        this._leading = leading
    }

    /**
     * 使用行距和文本创建 Phrase
     */
    public init(leading: Float32, text: String) {
        this._font = Font.DEFAULT
        this._leading = leading
        chunks.add(Chunk(text))
    }

    /**
     * 使用行距、文本和字体创建 Phrase
     */
    public init(leading: Float32, text: String, font: Font) {
        this._font = font
        this._leading = leading
        chunks.add(Chunk(text, font))
    }

    /**
     * 获取字体
     */
    public prop font: Font {
        get() { _font }
    }

    /**
     * 设置字体
     */
    public func setFont(font: Font): Unit {
        this._font = font
    }

    /**
     * 获取行距
     */
    public prop leading: Float32 {
        get() { _leading }
    }

    /**
     * 设置行距
     */
    public func setLeading(leading: Float32): Unit {
        this._leading = leading
    }

    /**
     * 添加元素
     */
    public func add(element: Element): Bool {
        match (element.getType()) {
            case Chunk => addChunk(element)
            case Phrase => addPhrase(element)
            case _ => false
        }
    }

    private func addChunk(element: Element): Bool {
        chunks.add(element)
        true
    }

    private func addPhrase(element: Element): Bool {
        for (chunk in element.getChunks()) {
            chunks.add(chunk)
        }
        true
    }

    /**
     * 添加文本（使用默认字体）
     */
    public func add(text: String): Bool {
        add(Chunk(text, _font))
    }

    /**
     * 添加 Chunk
     */
    public func addChunk(chunk: Chunk): Unit {
        chunks.add(chunk)
    }

    /**
     * 清空内容
     */
    public func clear(): Unit {
        chunks.clear()
    }

    /**
     * 是否为空
     */
    public func isEmpty(): Bool {
        chunks.isEmpty()
    }

    /**
     * 获取纯文本内容
     */
    public func getContent(): String {
        var result = ""
        for (element in chunks) {
            match (element) {
                case chunk: Chunk => result = result + chunk.content
                case _ => ()
            }
        }
        result
    }

    /**
     * 获取总宽度
     */
    public func getWidth(): Float32 {
        var width: Float32 = 0.0
        for (chunk in getChunks()) {
            width += chunk.getWidthPoint()
        }
        width
    }

    // ===== Element 接口实现 =====

    public open func getType(): ElementType {
        ElementType.Phrase
    }

    public func getChunks(): ArrayList<Chunk> {
        let result = ArrayList<Chunk>()
        for (element in chunks) {
            match (element) {
                case chunk: Chunk => result.add(chunk)
                case _ => addChunksFrom(element, result)
            }
        }
        result
    }

    private func addChunksFrom(element: Element, result: ArrayList<Chunk>): Unit {
        for (c in element.getChunks()) {
            result.add(c)
        }
    }

    public func isContent(): Bool {
        true
    }

    public func isNestable(): Bool {
        true
    }

    public func process(listener: ElementListener): Bool {
        listener.add(this)
    }

    /**
     * 获取内部元素数量
     */
    public prop size: Int64 {
        get() { chunks.size }
    }

    /**
     * 获取指定索引的元素
     */
    public func get(index: Int64): Element {
        chunks[index]
    }
}
