/**
 * PDF-CJ: Element - 元素接口
 * 所有可添加到 PDF 文档的元素的基接口
 */
package pdf_cj.api

import std.collection.ArrayList

/**
 * 元素类型枚举
 */
public enum ElementType {
    | Chunk
    | Phrase
    | Paragraph
    | Chapter
    | Section
    | List
    | ListItem
    | Table
    | Cell
    | Image
    | Header
    | Footer
    | Anchor
    | Annotation
}

/**
 * 元素接口 - 所有 PDF 元素的基接口
 */
public interface Element {
    /**
     * 获取元素类型
     */
    func getType(): ElementType

    /**
     * 获取所有内嵌的 Chunk 元素
     * Chunk 是最小的文本单元
     */
    func getChunks(): ArrayList<Chunk>

    /**
     * 是否为内容元素（可直接渲染）
     */
    func isContent(): Bool

    /**
     * 是否可嵌套
     */
    func isNestable(): Bool

    /**
     * 处理元素（由 Document 调用）
     * @param listener 元素监听器
     * @return 是否处理成功
     */
    func process(listener: ElementListener): Bool
}

/**
 * 元素监听器接口
 * Document 实现此接口以接收元素
 */
public interface ElementListener {
    /**
     * 添加元素
     * @param element 要添加的元素
     * @return 是否添加成功
     */
    func add(element: Element): Bool
}

/**
 * 文本元素接口
 * 包含文本内容的元素
 */
public interface TextElement <: Element {
    /**
     * 添加文本内容
     */
    func append(text: String): Unit

    /**
     * 获取纯文本内容
     */
    func getText(): String
}

// 前向声明 Chunk 类型（将在 chunk.cj 中定义）
// 这里用于 getChunks() 返回类型
