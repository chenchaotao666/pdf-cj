/**
 * PDF-CJ: Anchor - 超链接锚点
 * 继承自 Phrase，支持 URI 超链接，与 OpenPDF Anchor API 一致
 */
package pdf_cj.api

import std.collection.ArrayList
import pdf_cj.text.Font

/**
 * Anchor 类 - 带超链接的文本短语
 *
 * 用法（与 OpenPDF 一致）：
 *   let anchor = Anchor("点击访问", font)
 *   anchor.setReference("https://example.com")
 *   doc.add(Paragraph(anchor))
 */
public class Anchor <: Phrase {
    private var _reference: ?String = None
    private var _name: ?String = None

    public init() {
        super()
    }

    public init(text: String) {
        super(text)
    }

    public init(text: String, font: Font) {
        super(text, font)
    }

    public init(leading: Float32, text: String, font: Font) {
        super(leading, text, font)
    }

    /**
     * 设置超链接 URL（对应 Java anchor.setReference(url)）
     */
    public func setReference(reference: String): Unit {
        this._reference = Some(reference)
    }

    public prop reference: ?String {
        get() { _reference }
    }

    /**
     * 设置锚点名称（用于页内跳转目标）
     */
    public func setName(name: String): Unit {
        this._name = Some(name)
    }

    public prop anchorName: ?String {
        get() { _name }
    }

    public override func getType(): ElementType {
        ElementType.Anchor
    }

    /**
     * 返回各 Chunk，并将 URL 注入每个 Chunk 的 ANCHOR 属性
     * processParagraph 渲染时读取此属性并生成 Link 注释
     */
    public override func getChunks(): ArrayList<Chunk> {
        let result = super.getChunks()
        match (_reference) {
            case Some(url) =>
                for (chunk in result) {
                    chunk.setAnchorURL(url)
                }
            case None => ()
        }
        result
    }
}
