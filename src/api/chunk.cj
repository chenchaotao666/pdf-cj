/**
 * PDF-CJ: Chunk - 文本块
 * 最小的文本单元，包含文本内容和字体属性
 */
package pdf_cj.api

import std.collection.{ArrayList, HashMap}
import pdf_cj.text.Font
import pdf_cj.text.Color

/**
 * Chunk 类 - 最小的文本单元
 * 一个 Chunk 包含具有相同格式的文本内容
 */
public class Chunk <: Element {
    private var _content: String
    private var _font: Font
    private var _color: ?Color = None

    // 预定义常量
    public static let NEWLINE = Chunk("\n")
    public static let NEWPAGE = Chunk("")  // 用于触发分页
    public static let SPACETABBING = Chunk(" \t")
    public static let TAB = Chunk("\t")

    // 特殊属性键
    public static let LOCALGOTO = "LOCALGOTO"
    public static let LOCALDESTINATION = "LOCALDESTINATION"
    public static let GENERICTAG = "GENERICTAG"
    public static let NEWPAGE_TAG = "NEWPAGE"

    // 附加属性
    private var attributes: ?HashMap<String, String> = None

    /**
     * 使用文本内容创建 Chunk（使用默认字体）
     */
    public init(content: String) {
        this._content = content
        this._font = Font.DEFAULT
    }

    /**
     * 使用文本内容和字体创建 Chunk
     */
    public init(content: String, font: Font) {
        this._content = content
        this._font = font
    }

    /**
     * 使用字符创建 Chunk
     */
    public init(c: Rune) {
        this._content = String([c])
        this._font = Font.DEFAULT
    }

    /**
     * 使用字符和字体创建 Chunk
     */
    public init(c: Rune, font: Font) {
        this._content = String([c])
        this._font = font
    }

    /**
     * 获取文本内容
     */
    public prop content: String {
        get() { _content }
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
     * 获取颜色
     */
    public prop color: ?Color {
        get() { _color }
    }

    /**
     * 设置颜色
     */
    public func setColor(color: Color): Chunk {
        this._color = Some(color)
        this
    }

    /**
     * 追加文本
     */
    public func append(text: String): Chunk {
        this._content = this._content + text
        this
    }

    /**
     * 获取文本宽度
     */
    public func getWidthPoint(): Float32 {
        _font.getWidthPoint(_content)
    }

    /**
     * 设置本地跳转目标
     */
    public func setLocalGoto(name: String): Chunk {
        setAttribute(LOCALGOTO, name)
        this
    }

    /**
     * 设置本地锚点
     */
    public func setLocalDestination(name: String): Chunk {
        setAttribute(LOCALDESTINATION, name)
        this
    }

    /**
     * 设置通用标签
     */
    public func setGenericTag(tag: String): Chunk {
        setAttribute(GENERICTAG, tag)
        this
    }

    /**
     * 设置属性
     */
    private func setAttribute(key: String, value: String): Unit {
        if (attributes.isNone()) {
            attributes = Some(HashMap<String, String>())
        }
        match (attributes) {
            case Some(attrs) => attrs[key] = value
            case None => ()
        }
    }

    /**
     * 获取属性
     */
    public func getAttribute(key: String): ?String {
        match (attributes) {
            case Some(attrs) => attrs.get(key)
            case None => None
        }
    }

    /**
     * 是否为空
     */
    public func isEmpty(): Bool {
        _content.isEmpty()
    }

    /**
     * 是否为空白字符
     */
    public func isWhitespace(): Bool {
        for (c in _content) {
            if (c != UInt8(32) && c != UInt8(9) && c != UInt8(10) && c != UInt8(13)) {
                return false
            }
        }
        true
    }

    // ===== Element 接口实现 =====

    public func getType(): ElementType {
        ElementType.Chunk
    }

    public func getChunks(): ArrayList<Chunk> {
        let list = ArrayList<Chunk>()
        list.add(this)
        list
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
     * 创建新行 Chunk
     */
    public static func newLine(): Chunk {
        NEWLINE
    }

    /**
     * 创建带指定行数的空行
     */
    public static func newLines(count: Int32): Chunk {
        var s = ""
        for (_ in 0..count) {
            s = s + "\n"
        }
        Chunk(s)
    }
}
