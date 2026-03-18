# 仓颉 PDF 组件方案设计

## 1. 概述

### 1.1 项目目标
基于仓颉语言开发一款 PDF 编辑组件（pdf-cj），用于创建、编辑、渲染 PDF 文档，对标 Java 语言实现的 OpenPDF 开源软件。

### 1.2 设计原则
- **仓颉原生**：充分利用仓颉语言特性（类型安全、模式匹配、并发支持）
- **API 友好**：提供符合仓颉习惯的 API 设计，而非简单翻译 Java API
- **内存高效**：支持流式处理，避免大文档 OOM
- **标准兼容**：兼容 PDF 1.7 标准（ISO 32000-1:2008）

---

## 2. 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         Application Layer                        │
│                    (业务应用: eSight, NCE, MAE-CN)                │
└─────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                           API Layer                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ Document │ │ Element  │ │  Font    │ │  Image   │            │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │  Table   │ │  Chapter │ │  Header  │ │  Event   │            │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘            │
└─────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Core Layer                               │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐     │
│  │   PdfWriter    │  │   PdfReader    │  │    PdfCopy     │     │
│  │  (文档写入)     │  │  (文档解析)     │  │  (文档复制)    │     │
│  └────────────────┘  └────────────────┘  └────────────────┘     │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐     │
│  │  ContentStream │  │  PageLayout    │  │  ResourceDict  │     │
│  │  (内容流生成)   │  │  (页面布局)     │  │  (资源管理)    │     │
│  └────────────────┘  └────────────────┘  └────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Base Layer                                │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐     │
│  │   PdfObject    │  │   PdfStream    │  │   XRefTable    │     │
│  │  (PDF 对象)     │  │  (流处理)       │  │  (交叉引用表)   │     │
│  └────────────────┘  └────────────────┘  └────────────────┘     │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐     │
│  │   Tokenizer    │  │   Encoder      │  │   Compress     │     │
│  │  (词法解析)     │  │  (编码转换)     │  │  (压缩/解压)    │     │
│  └────────────────┘  └────────────────┘  └────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. 模块设计

### 3.1 模块划分

```
pdf-cj/
├── src/
│   ├── api/                    # API 层 - 面向用户的接口
│   │   ├── document.cj         # Document 文档类
│   │   ├── element.cj          # Element 元素接口
│   │   ├── chunk.cj            # Chunk 文本块
│   │   ├── paragraph.cj        # Paragraph 段落
│   │   ├── phrase.cj           # Phrase 短语
│   │   ├── chapter.cj          # Chapter 章节
│   │   ├── section.cj          # Section 小节
│   │   └── header_footer.cj    # HeaderFooter 页眉页脚
│   │
│   ├── text/                   # 文本模块
│   │   ├── font.cj             # Font 字体类
│   │   ├── base_font.cj        # BaseFont 基础字体
│   │   ├── font_factory.cj     # FontFactory 字体工厂
│   │   ├── color.cj            # Color 颜色类
│   │   └── alignment.cj        # Alignment 对齐方式
│   │
│   ├── image/                  # 图片模块
│   │   ├── image.cj            # Image 图片基类
│   │   ├── jpeg.cj             # JPEG 图片处理
│   │   ├── png.cj              # PNG 图片处理
│   │   └── raw_image.cj        # 原始图片数据
│   │
│   ├── table/                  # 表格模块
│   │   ├── pdf_table.cj        # PdfPTable 表格类
│   │   ├── pdf_cell.cj         # PdfPCell 单元格类
│   │   └── table_event.cj      # 表格事件
│   │
│   ├── core/                   # 核心层 - PDF 读写逻辑
│   │   ├── pdf_writer.cj       # PdfWriter 写入器
│   │   ├── pdf_reader.cj       # PdfReader 读取器
│   │   ├── pdf_copy.cj         # PdfCopy 复制器
│   │   ├── pdf_content_byte.cj # PdfContentByte 内容字节
│   │   ├── pdf_template.cj     # PdfTemplate 模板
│   │   ├── column_text.cj      # ColumnText 列文本
│   │   └── page_event.cj       # 页面事件接口
│   │
│   ├── base/                   # 基础层 - PDF 底层结构
│   │   ├── pdf_object.cj       # PDF 对象抽象
│   │   ├── pdf_array.cj        # PDF 数组
│   │   ├── pdf_dictionary.cj   # PDF 字典
│   │   ├── pdf_stream.cj       # PDF 流
│   │   ├── pdf_string.cj       # PDF 字符串
│   │   ├── pdf_number.cj       # PDF 数字
│   │   ├── pdf_name.cj         # PDF 名称
│   │   ├── pdf_indirect.cj     # PDF 间接引用
│   │   ├── xref_table.cj       # 交叉引用表
│   │   └── trailer.cj          # 文件尾
│   │
│   ├── codec/                  # 编解码模块
│   │   ├── flate.cj            # Flate 压缩 (zlib)
│   │   ├── ascii85.cj          # ASCII85 编码
│   │   ├── hex.cj              # 十六进制编码
│   │   └── lzw.cj              # LZW 压缩
│   │
│   └── util/                   # 工具模块
│       ├── rectangle.cj        # Rectangle 矩形
│       ├── page_size.cj        # PageSize 页面尺寸常量
│       ├── pdf_exception.cj    # 异常定义
│       └── stream_util.cj      # 流处理工具
│
├── test/                       # 测试目录
│   ├── api_test.cj
│   ├── writer_test.cj
│   ├── reader_test.cj
│   └── integration_test.cj
│
├── examples/                   # 示例代码
│   ├── hello_world.cj
│   ├── table_example.cj
│   └── merge_pdf.cj
│
└── cjpm.toml                   # 项目配置
```

### 3.2 模块职责

| 模块 | 职责 | 预估工作量 |
|------|------|-----------|
| api | 提供面向用户的高层 API（Document、Element 等） | 10K |
| text | 字体、颜色、对齐等文本相关功能 | 8K |
| image | 图片加载、转换、嵌入 | 8K |
| table | 表格、单元格、布局 | 12K |
| core | PDF 读写核心逻辑 | 15K |
| base | PDF 底层对象模型 | 8K |
| codec | 压缩/编码算法 | 5K |
| util | 工具类 | 2K |
| **总计** | | **~68K** |

---

## 4. 核心类设计

### 4.1 Element 元素接口体系

```cangjie
// 所有可添加到文档的元素的基接口
interface Element {
    // 获取元素类型
    func getType(): ElementType

    // 获取所有内嵌的元素块
    func getChunks(): ArrayList<Chunk>

    // 是否为内容元素（可直接渲染）
    func isContent(): Bool

    // 处理元素（由 Document 调用）
    func process(listener: ElementListener): Bool
}

// 元素类型枚举
enum ElementType {
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
}

// 元素监听器接口
interface ElementListener {
    func add(element: Element): Bool
}
```

### 4.2 Document 文档类

```cangjie
/**
 * PDF 文档类 - 核心 API 入口
 */
public class Document <: ElementListener {
    private var pageSize: Rectangle
    private var marginLeft: Float32
    private var marginRight: Float32
    private var marginTop: Float32
    private var marginBottom: Float32

    private var writer: ?PdfWriter = None
    private var opened: Bool = false
    private var closed: Bool = false
    private var pageNumber: Int32 = 0

    private var header: ?HeaderFooter = None
    private var footer: ?HeaderFooter = None

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
        this(pageSize, 36.0, 36.0, 36.0, 36.0)  // 默认边距 0.5 英寸
    }

    /**
     * 使用指定页面大小和边距创建文档
     */
    public init(pageSize: Rectangle, marginLeft: Float32, marginRight: Float32,
                marginTop: Float32, marginBottom: Float32) {
        this.pageSize = pageSize
        this.marginLeft = marginLeft
        this.marginRight = marginRight
        this.marginTop = marginTop
        this.marginBottom = marginBottom
    }

    /**
     * 打开文档以开始写入
     */
    public func open(): Unit {
        if (opened) {
            throw PdfException("Document is already open")
        }
        opened = true
        pageNumber = 1
        writer?.open()
    }

    /**
     * 关闭文档并完成写入
     */
    public func close(): Unit {
        if (closed) {
            return
        }
        if (opened) {
            writer?.close()
        }
        closed = true
    }

    /**
     * 添加元素到文档
     */
    public func add(element: Element): Bool {
        if (!opened || closed) {
            throw PdfException("Document is not open for writing")
        }
        return element.process(this)
    }

    /**
     * 创建新页面
     */
    public func newPage(): Bool {
        if (!opened || closed) {
            return false
        }
        pageNumber++
        writer?.newPage()
        return true
    }

    /**
     * 设置页面大小
     */
    public func setPageSize(size: Rectangle): Bool {
        this.pageSize = size
        return true
    }

    /**
     * 设置页面边距
     */
    public func setMargins(left: Float32, right: Float32,
                           top: Float32, bottom: Float32): Bool {
        this.marginLeft = left
        this.marginRight = right
        this.marginTop = top
        this.marginBottom = bottom
        return true
    }

    /**
     * 设置页眉
     */
    public func setHeader(header: HeaderFooter): Unit {
        this.header = Some(header)
    }

    /**
     * 设置页脚
     */
    public func setFooter(footer: HeaderFooter): Unit {
        this.footer = Some(footer)
    }

    // Getters
    public prop left: Float32 { get() { marginLeft } }
    public prop right: Float32 { get() { pageSize.width - marginRight } }
    public prop top: Float32 { get() { pageSize.height - marginTop } }
    public prop bottom: Float32 { get() { marginBottom } }
    public prop currentPageNumber: Int32 { get() { pageNumber } }
}
```

### 4.3 PdfWriter 写入器

```cangjie
/**
 * PDF 写入器 - 将文档内容写入输出流
 */
public class PdfWriter {
    private let document: Document
    private let output: OutputStream
    private var directContent: ?PdfContentByte = None
    private var pageEvents: ArrayList<PdfPageEvent> = ArrayList<PdfPageEvent>()

    // PDF 对象管理
    private var objectNumber: Int32 = 0
    private var xref: ArrayList<Int64> = ArrayList<Int64>()
    private var currentPosition: Int64 = 0

    /**
     * 创建 PdfWriter 实例并绑定到文档
     */
    public static func getInstance(document: Document, output: OutputStream): PdfWriter {
        let writer = PdfWriter(document, output)
        document.setWriter(writer)
        return writer
    }

    private init(document: Document, output: OutputStream) {
        this.document = document
        this.output = output
    }

    /**
     * 打开写入器
     */
    public func open(): Unit {
        // 写入 PDF 文件头
        writeLine("%PDF-1.7")
        writeLine("%\u{E2}\u{E3}\u{CF}\u{D3}")  // 二进制标记
    }

    /**
     * 关闭写入器
     */
    public func close(): Unit {
        // 触发页面结束事件
        firePageEvent(PageEventType.EndPage)

        // 写入交叉引用表
        let xrefOffset = currentPosition
        writeLine("xref")
        writeLine("0 ${objectNumber + 1}")
        writeLine("0000000000 65535 f ")
        for (offset in xref) {
            writeLine("${formatOffset(offset)} 00000 n ")
        }

        // 写入 trailer
        writeLine("trailer")
        writeLine("<<")
        writeLine("/Size ${objectNumber + 1}")
        writeLine("/Root 1 0 R")
        writeLine(">>")
        writeLine("startxref")
        writeLine("${xrefOffset}")
        writeLine("%%EOF")

        output.flush()
        output.close()
    }

    /**
     * 获取直接内容对象
     */
    public func getDirectContent(): PdfContentByte {
        match (directContent) {
            case Some(content) => content
            case None => {
                let content = PdfContentByte(this)
                directContent = Some(content)
                content
            }
        }
    }

    /**
     * 设置页面事件处理器
     */
    public func setPageEvent(event: PdfPageEvent): Unit {
        pageEvents.append(event)
    }

    /**
     * 创建新页面
     */
    public func newPage(): Unit {
        firePageEvent(PageEventType.EndPage)
        // 创建新页面对象
        firePageEvent(PageEventType.StartPage)
    }

    /**
     * 分配新的对象编号
     */
    internal func allocateObjectNumber(): Int32 {
        objectNumber++
        objectNumber
    }

    /**
     * 写入 PDF 对象
     */
    internal func writeObject(obj: PdfObject): Int32 {
        let num = allocateObjectNumber()
        xref.append(currentPosition)
        writeLine("${num} 0 obj")
        obj.writeTo(this)
        writeLine("endobj")
        num
    }

    private func writeLine(line: String): Unit {
        let bytes = line.toArray()
        output.write(bytes)
        output.write([0x0A])  // 换行符
        currentPosition += bytes.size + 1
    }

    private func firePageEvent(eventType: PageEventType): Unit {
        for (event in pageEvents) {
            match (eventType) {
                case StartPage => event.onStartPage(this, document)
                case EndPage => event.onEndPage(this, document)
            }
        }
    }

    private func formatOffset(offset: Int64): String {
        // 格式化为 10 位数字
        let s = "${offset}"
        let padding = "0".repeat(10 - s.size)
        padding + s
    }
}

// 页面事件类型
enum PageEventType {
    | StartPage
    | EndPage
}

// 页面事件接口
interface PdfPageEvent {
    func onStartPage(writer: PdfWriter, document: Document): Unit
    func onEndPage(writer: PdfWriter, document: Document): Unit
}

// 页面事件辅助类
open class PdfPageEventHelper <: PdfPageEvent {
    public open func onStartPage(writer: PdfWriter, document: Document): Unit {}
    public open func onEndPage(writer: PdfWriter, document: Document): Unit {}
}
```

### 4.4 文本相关类

```cangjie
/**
 * Chunk - 最小的文本单元
 */
public class Chunk <: Element {
    private var content: String
    private var font: Font

    // 预定义常量
    public static let NEWLINE = Chunk("\n")

    public init(content: String) {
        this(content, Font.DEFAULT)
    }

    public init(content: String, font: Font) {
        this.content = content
        this.font = font
    }

    public func getType(): ElementType {
        ElementType.Chunk
    }

    public func getChunks(): ArrayList<Chunk> {
        let list = ArrayList<Chunk>()
        list.append(this)
        list
    }

    public func isContent(): Bool { true }

    public func process(listener: ElementListener): Bool {
        listener.add(this)
    }

    public prop text: String { get() { content } }
    public prop currentFont: Font { get() { font } }
}

/**
 * Paragraph - 段落
 */
public class Paragraph <: Element {
    private var chunks: ArrayList<Element> = ArrayList<Element>()
    private var font: Font
    private var alignment: Alignment = Alignment.Left
    private var leading: Float32 = 0.0
    private var indentationLeft: Float32 = 0.0
    private var indentationRight: Float32 = 0.0
    private var spacingBefore: Float32 = 0.0
    private var spacingAfter: Float32 = 0.0

    public init() {
        this.font = Font.DEFAULT
    }

    public init(content: String) {
        this(content, Font.DEFAULT)
    }

    public init(content: String, font: Font) {
        this.font = font
        add(Chunk(content, font))
    }

    public func add(element: Element): Bool {
        chunks.append(element)
        true
    }

    public func setFont(font: Font): Unit {
        this.font = font
    }

    public func setAlignment(alignment: Alignment): Unit {
        this.alignment = alignment
    }

    public func getType(): ElementType {
        ElementType.Paragraph
    }

    public func getChunks(): ArrayList<Chunk> {
        let result = ArrayList<Chunk>()
        for (element in chunks) {
            result.appendAll(element.getChunks())
        }
        result
    }

    public func isContent(): Bool { true }

    public func process(listener: ElementListener): Bool {
        listener.add(this)
    }
}

/**
 * 对齐方式
 */
public enum Alignment {
    | Left
    | Center
    | Right
    | Justified

    public func toInt(): Int32 {
        match (this) {
            case Left => 0
            case Center => 1
            case Right => 2
            case Justified => 3
        }
    }

    public static func fromInt(value: Int32): Alignment {
        match (value) {
            case 0 => Left
            case 1 => Center
            case 2 => Right
            case 3 => Justified
            case _ => Left
        }
    }
}
```

### 4.5 字体相关类

```cangjie
/**
 * 基础字体 - PDF 底层字体对象
 */
public class BaseFont {
    private let fontName: String
    private let encoding: String
    private let embedded: Bool

    // 标准字体常量
    public static let HELVETICA = "Helvetica"
    public static let HELVETICA_BOLD = "Helvetica-Bold"
    public static let TIMES_ROMAN = "Times-Roman"
    public static let TIMES_BOLD = "Times-Bold"
    public static let COURIER = "Courier"

    // 编码常量
    public static let WINANSI = "Cp1252"
    public static let IDENTITY_H = "Identity-H"  // Unicode 水平书写

    private init(fontName: String, encoding: String, embedded: Bool) {
        this.fontName = fontName
        this.encoding = encoding
        this.embedded = embedded
    }

    /**
     * 创建字体
     */
    public static func createFont(name: String, encoding: String,
                                   embedded: Bool): BaseFont {
        // TODO: 实现字体加载逻辑
        BaseFont(name, encoding, embedded)
    }

    /**
     * 获取字符串宽度
     */
    public func getWidthPoint(text: String, fontSize: Float32): Float32 {
        // TODO: 实现宽度计算
        text.size.toFloat32() * fontSize * 0.5
    }

    public prop name: String { get() { fontName } }
}

/**
 * 字体 - 高层字体封装
 */
public class Font {
    private let baseFont: ?BaseFont
    private let size: Float32
    private let style: FontStyle
    private let color: ?Color

    // 默认字体
    public static let DEFAULT = Font(None, 12.0, FontStyle.Normal, None)

    public init(baseFont: ?BaseFont, size: Float32, style: FontStyle, color: ?Color) {
        this.baseFont = baseFont
        this.size = size
        this.style = style
        this.color = color
    }

    public init(baseFont: BaseFont, size: Float32) {
        this(Some(baseFont), size, FontStyle.Normal, None)
    }

    public init(baseFont: BaseFont, size: Float32, style: FontStyle) {
        this(Some(baseFont), size, style, None)
    }

    public init(baseFont: BaseFont, size: Float32, style: FontStyle, color: Color) {
        this(Some(baseFont), size, style, Some(color))
    }

    public prop fontSize: Float32 { get() { size } }
    public prop fontStyle: FontStyle { get() { style } }
    public prop fontColor: ?Color { get() { color } }
    public prop base: ?BaseFont { get() { baseFont } }
}

/**
 * 字体样式
 */
public enum FontStyle {
    | Normal
    | Bold
    | Italic
    | BoldItalic
    | Underline
    | Strikethrough

    public func toInt(): Int32 {
        match (this) {
            case Normal => 0
            case Bold => 1
            case Italic => 2
            case BoldItalic => 3
            case Underline => 4
            case Strikethrough => 8
        }
    }
}

/**
 * 字体工厂
 */
public class FontFactory {
    private static var fonts: HashMap<String, BaseFont> = HashMap<String, BaseFont>()

    public static let HELVETICA = "Helvetica"
    public static let HELVETICA_BOLD = "Helvetica-Bold"
    public static let TIMES_ROMAN = "Times-Roman"

    /**
     * 获取字体
     */
    public static func getFont(fontName: String, size: Float32): Font {
        getFont(fontName, size, FontStyle.Normal, None)
    }

    public static func getFont(fontName: String, size: Float32,
                                style: FontStyle): Font {
        getFont(fontName, size, style, None)
    }

    public static func getFont(fontName: String, size: Float32,
                                style: FontStyle, color: ?Color): Font {
        let baseFont = getBaseFont(fontName)
        Font(baseFont, size, style, color.getOrDefault { Color.BLACK })
    }

    private static func getBaseFont(fontName: String): BaseFont {
        match (fonts.get(fontName)) {
            case Some(font) => font
            case None => {
                let font = BaseFont.createFont(fontName, BaseFont.WINANSI, false)
                fonts.put(fontName, font)
                font
            }
        }
    }
}

/**
 * 颜色
 */
public struct Color {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let alpha: UInt8

    // 预定义颜色
    public static let BLACK = Color(0, 0, 0, 255)
    public static let WHITE = Color(255, 255, 255, 255)
    public static let RED = Color(255, 0, 0, 255)
    public static let GREEN = Color(0, 255, 0, 255)
    public static let BLUE = Color(0, 0, 255, 255)
    public static let LIGHT_GRAY = Color(192, 192, 192, 255)
    public static let GRAY = Color(128, 128, 128, 255)

    public init(red: UInt8, green: UInt8, blue: UInt8) {
        this(red, green, blue, 255)
    }

    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        this.red = red
        this.green = green
        this.blue = blue
        this.alpha = alpha
    }

    public func toRgbFloat(): (Float32, Float32, Float32) {
        (red.toFloat32() / 255.0, green.toFloat32() / 255.0, blue.toFloat32() / 255.0)
    }
}
```

### 4.6 表格相关类

```cangjie
/**
 * PDF 表格
 */
public class PdfPTable <: Element {
    private let numColumns: Int32
    private var rows: ArrayList<PdfPRow> = ArrayList<PdfPRow>()
    private var currentRow: ArrayList<PdfPCell> = ArrayList<PdfPCell>()

    private var widthPercentage: Float32 = 80.0
    private var totalWidth: Float32 = 0.0
    private var lockedWidth: Bool = false
    private var headerRows: Int32 = 0
    private var keepTogether: Bool = false
    private var splitLate: Bool = true
    private var splitRows: Bool = true
    private var skipFirstHeader: Bool = false
    private var horizontalAlignment: Alignment = Alignment.Center

    private var defaultCell: PdfPCell = PdfPCell()
    private var columnWidths: ?Array<Float32> = None

    public init(numColumns: Int32) {
        this.numColumns = numColumns
    }

    /**
     * 添加单元格
     */
    public func addCell(cell: PdfPCell): Unit {
        currentRow.append(cell)
        if (currentRow.size == numColumns) {
            rows.append(PdfPRow(currentRow))
            currentRow = ArrayList<PdfPCell>()
        }
    }

    public func addCell(phrase: Phrase): Unit {
        addCell(PdfPCell(phrase))
    }

    public func addCell(paragraph: Paragraph): Unit {
        let cell = PdfPCell()
        cell.addElement(paragraph)
        addCell(cell)
    }

    public func addCell(text: String): Unit {
        addCell(Phrase(text))
    }

    /**
     * 设置宽度百分比
     */
    public func setWidthPercentage(percentage: Float32): Unit {
        this.widthPercentage = percentage
    }

    /**
     * 设置是否保持在一页
     */
    public func setKeepTogether(keep: Bool): Unit {
        this.keepTogether = keep
    }

    /**
     * 设置是否延迟拆分
     */
    public func setSplitLate(splitLate: Bool): Unit {
        this.splitLate = splitLate
    }

    /**
     * 设置是否允许拆分行
     */
    public func setSplitRows(splitRows: Bool): Unit {
        this.splitRows = splitRows
    }

    /**
     * 设置锁定宽度
     */
    public func setLockedWidth(locked: Bool): Unit {
        this.lockedWidth = locked
    }

    /**
     * 设置列宽
     */
    public func setTotalWidth(widths: Array<Float32>): Unit {
        if (widths.size != numColumns) {
            throw PdfException("Wrong number of column widths")
        }
        this.columnWidths = Some(widths)
        var total: Float32 = 0.0
        for (w in widths) {
            total += w
        }
        this.totalWidth = total
    }

    /**
     * 设置表头行数
     */
    public func setHeaderRows(rows: Int32): Unit {
        this.headerRows = rows
    }

    /**
     * 设置水平对齐
     */
    public func setHorizontalAlignment(alignment: Alignment): Unit {
        this.horizontalAlignment = alignment
    }

    /**
     * 获取默认单元格（用于设置默认样式）
     */
    public func getDefaultCell(): PdfPCell {
        defaultCell
    }

    /**
     * 删除所有非表头行
     */
    public func deleteBodyRows(): Unit {
        while (rows.size > headerRows) {
            rows.removeLast()
        }
    }

    /**
     * 设置跳过第一个表头
     */
    public func setSkipFirstHeader(skip: Bool): Unit {
        this.skipFirstHeader = skip
    }

    // Element 接口实现
    public func getType(): ElementType {
        ElementType.Table
    }

    public func getChunks(): ArrayList<Chunk> {
        ArrayList<Chunk>()  // 表格没有直接的 Chunk
    }

    public func isContent(): Bool { true }

    public func process(listener: ElementListener): Bool {
        listener.add(this)
    }

    public prop columns: Int32 { get() { numColumns } }
    public prop rowCount: Int32 { get() { rows.size } }
}

/**
 * 表格行
 */
internal class PdfPRow {
    private let cells: ArrayList<PdfPCell>

    public init(cells: ArrayList<PdfPCell>) {
        this.cells = cells
    }

    public func getCell(index: Int32): ?PdfPCell {
        if (index >= 0 && index < cells.size) {
            Some(cells[index])
        } else {
            None
        }
    }
}

/**
 * 表格单元格
 */
public class PdfPCell <: Element {
    private var content: ArrayList<Element> = ArrayList<Element>()
    private var phrase: ?Phrase = None

    private var border: Int32 = Border.BOX
    private var borderWidth: Float32 = 1.0
    private var backgroundColor: ?Color = None
    private var horizontalAlignment: Alignment = Alignment.Left
    private var verticalAlignment: VerticalAlignment = VerticalAlignment.Top
    private var padding: Float32 = 2.0
    private var useBorderPadding: Bool = false
    private var colspan: Int32 = 1
    private var rowspan: Int32 = 1

    public init() {}

    public init(phrase: Phrase) {
        this.phrase = Some(phrase)
    }

    /**
     * 添加元素到单元格
     */
    public func addElement(element: Element): Unit {
        content.append(element)
    }

    /**
     * 设置边框
     */
    public func setBorder(border: Int32): Unit {
        this.border = border
    }

    /**
     * 设置边框宽度
     */
    public func setBorderWidth(width: Float32): Unit {
        this.borderWidth = width
    }

    /**
     * 设置背景色
     */
    public func setBackgroundColor(color: Color): Unit {
        this.backgroundColor = Some(color)
    }

    /**
     * 设置水平对齐
     */
    public func setHorizontalAlignment(alignment: Alignment): Unit {
        this.horizontalAlignment = alignment
    }

    /**
     * 设置是否使用边框内边距
     */
    public func setUseBorderPadding(use: Bool): Unit {
        this.useBorderPadding = use
    }

    /**
     * 设置列跨度
     */
    public func setColspan(colspan: Int32): Unit {
        this.colspan = colspan
    }

    // Element 接口实现
    public func getType(): ElementType {
        ElementType.Cell
    }

    public func getChunks(): ArrayList<Chunk> {
        let result = ArrayList<Chunk>()
        match (phrase) {
            case Some(p) => result.appendAll(p.getChunks())
            case None => ()
        }
        for (elem in content) {
            result.appendAll(elem.getChunks())
        }
        result
    }

    public func isContent(): Bool { true }

    public func process(listener: ElementListener): Bool {
        listener.add(this)
    }
}

/**
 * 边框常量
 */
public class Border {
    public static let NO_BORDER: Int32 = 0
    public static let TOP: Int32 = 1
    public static let BOTTOM: Int32 = 2
    public static let LEFT: Int32 = 4
    public static let RIGHT: Int32 = 8
    public static let BOX: Int32 = TOP | BOTTOM | LEFT | RIGHT
}

/**
 * 垂直对齐
 */
public enum VerticalAlignment {
    | Top
    | Middle
    | Bottom
}
```

### 4.7 图片类

```cangjie
/**
 * 图片元素
 */
public class Image <: Element {
    private var rawData: ?Array<UInt8> = None
    private var filePath: ?String = None
    private var imageType: ImageType = ImageType.Unknown

    private var width: Float32 = 0.0
    private var height: Float32 = 0.0
    private var scaledWidth: Float32 = 0.0
    private var scaledHeight: Float32 = 0.0
    private var alignment: Alignment = Alignment.Left
    private var rotation: Float32 = 0.0

    private init() {}

    /**
     * 从文件路径加载图片
     */
    public static func getInstance(filename: String): Image {
        let img = Image()
        img.filePath = Some(filename)
        img.loadFromFile(filename)
        img
    }

    /**
     * 从字节数组创建图片
     */
    public static func getInstance(data: Array<UInt8>): Image {
        let img = Image()
        img.rawData = Some(data)
        img.detectType(data)
        img
    }

    /**
     * 缩放到绝对大小
     */
    public func scaleAbsolute(newWidth: Float32, newHeight: Float32): Unit {
        this.scaledWidth = newWidth
        this.scaledHeight = newHeight
    }

    /**
     * 按百分比缩放
     */
    public func scalePercent(percent: Float32): Unit {
        scalePercent(percent, percent)
    }

    public func scalePercent(percentX: Float32, percentY: Float32): Unit {
        this.scaledWidth = width * percentX / 100.0
        this.scaledHeight = height * percentY / 100.0
    }

    /**
     * 缩放以适应指定大小
     */
    public func scaleToFit(maxWidth: Float32, maxHeight: Float32): Unit {
        let ratioWidth = maxWidth / width
        let ratioHeight = maxHeight / height
        let ratio = if (ratioWidth < ratioHeight) { ratioWidth } else { ratioHeight }
        this.scaledWidth = width * ratio
        this.scaledHeight = height * ratio
    }

    /**
     * 设置对齐方式
     */
    public func setAlignment(alignment: Alignment): Unit {
        this.alignment = alignment
    }

    /**
     * 设置旋转角度（弧度）
     */
    public func setRotation(rotation: Float32): Unit {
        this.rotation = rotation
    }

    private func loadFromFile(filename: String): Unit {
        // TODO: 实现文件加载
    }

    private func detectType(data: Array<UInt8>): Unit {
        if (data.size >= 8) {
            // JPEG 魔数: FF D8 FF
            if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
                imageType = ImageType.Jpeg
                return
            }
            // PNG 魔数: 89 50 4E 47 0D 0A 1A 0A
            if (data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47) {
                imageType = ImageType.Png
                return
            }
        }
        imageType = ImageType.Unknown
    }

    // Element 接口实现
    public func getType(): ElementType {
        ElementType.Image
    }

    public func getChunks(): ArrayList<Chunk> {
        ArrayList<Chunk>()
    }

    public func isContent(): Bool { true }

    public func process(listener: ElementListener): Bool {
        listener.add(this)
    }

    public prop plainWidth: Float32 { get() { width } }
    public prop plainHeight: Float32 { get() { height } }
    public prop getScaledWidth: Float32 {
        get() { if (scaledWidth > 0.0) { scaledWidth } else { width } }
    }
    public prop getScaledHeight: Float32 {
        get() { if (scaledHeight > 0.0) { scaledHeight } else { height } }
    }
}

/**
 * 图片类型
 */
public enum ImageType {
    | Unknown
    | Jpeg
    | Png
    | Gif
    | Bmp
    | Tiff
}
```

### 4.8 PdfReader 和 PdfCopy

```cangjie
/**
 * PDF 读取器
 */
public class PdfReader {
    private let filePath: String
    private var pageCount: Int32 = 0
    private var pages: ArrayList<PdfPage> = ArrayList<PdfPage>()
    private var trailer: ?PdfDictionary = None

    public init(filename: String) {
        this.filePath = filename
        parse()
    }

    /**
     * 获取页数
     */
    public func getNumberOfPages(): Int32 {
        pageCount
    }

    /**
     * 获取页面尺寸
     */
    public func getPageSize(pageNum: Int32): Rectangle {
        if (pageNum < 1 || pageNum > pageCount) {
            throw PdfException("Invalid page number: ${pageNum}")
        }
        pages[pageNum - 1].size
    }

    /**
     * 获取页面内容
     */
    internal func getPageContent(pageNum: Int32): PdfPage {
        if (pageNum < 1 || pageNum > pageCount) {
            throw PdfException("Invalid page number: ${pageNum}")
        }
        pages[pageNum - 1]
    }

    private func parse(): Unit {
        // TODO: 实现 PDF 解析
        // 1. 读取文件尾找到 xref 位置
        // 2. 解析交叉引用表
        // 3. 解析 trailer
        // 4. 按需解析页面对象
    }
}

/**
 * PDF 页面（内部表示）
 */
internal class PdfPage {
    public var size: Rectangle = PageSize.A4
    public var content: ?PdfStream = None
    public var resources: ?PdfDictionary = None
}

/**
 * PDF 复制器 - 用于合并 PDF
 */
public class PdfCopy {
    private let document: Document
    private let output: OutputStream
    private var writer: ?PdfWriter = None
    private var importedPages: ArrayList<PdfImportedPage> = ArrayList<PdfImportedPage>()

    public init(document: Document, output: OutputStream) {
        this.document = document
        this.output = output
        this.writer = Some(PdfWriter.getInstance(document, output))
    }

    /**
     * 从 Reader 导入页面
     */
    public func getImportedPage(reader: PdfReader, pageNumber: Int32): PdfImportedPage {
        let page = PdfImportedPage(reader, pageNumber)
        importedPages.append(page)
        page
    }

    /**
     * 添加导入的页面
     */
    public func addPage(page: PdfImportedPage): Unit {
        document.newPage()
        // TODO: 将页面内容写入当前文档
    }

    /**
     * 刷新缓冲区
     */
    public func flush(): Unit {
        match (writer) {
            case Some(w) => output.flush()
            case None => ()
        }
    }

    /**
     * 关闭
     */
    public func close(): Unit {
        document.close()
    }
}

/**
 * 导入的页面
 */
public class PdfImportedPage {
    private let reader: PdfReader
    private let pageNumber: Int32

    internal init(reader: PdfReader, pageNumber: Int32) {
        this.reader = reader
        this.pageNumber = pageNumber
    }

    public func getPageSize(): Rectangle {
        reader.getPageSize(pageNumber)
    }
}
```

### 4.9 页面布局工具

```cangjie
/**
 * 在指定位置显示文本
 */
public class ColumnText {
    /**
     * 在页面指定位置显示对齐的文本
     * @param canvas 内容字节对象
     * @param alignment 对齐方式
     * @param phrase 要显示的短语
     * @param x X 坐标
     * @param y Y 坐标
     * @param rotation 旋转角度
     */
    public static func showTextAligned(canvas: PdfContentByte,
                                        alignment: Alignment,
                                        phrase: Phrase,
                                        x: Float32, y: Float32,
                                        rotation: Float32): Unit {
        canvas.saveState()

        // 计算文本宽度用于对齐
        let textWidth = phrase.getWidth()
        var xOffset: Float32 = 0.0

        match (alignment) {
            case Center => xOffset = -textWidth / 2.0
            case Right => xOffset = -textWidth
            case _ => ()
        }

        // 应用变换
        if (rotation != 0.0) {
            canvas.transform(x, y, rotation)
        } else {
            canvas.setTextMatrix(x + xOffset, y)
        }

        // 输出文本
        canvas.showText(phrase)

        canvas.restoreState()
    }
}

/**
 * PDF 内容字节 - 底层绘图 API
 */
public class PdfContentByte {
    private let writer: PdfWriter
    private var content: ArrayList<UInt8> = ArrayList<UInt8>()

    internal init(writer: PdfWriter) {
        this.writer = writer
    }

    /**
     * 创建模板
     */
    public func createTemplate(width: Float32, height: Float32): PdfTemplate {
        PdfTemplate(width, height)
    }

    /**
     * 添加模板
     */
    public func addTemplate(template: PdfTemplate, x: Float32, y: Float32): Unit {
        addTemplate(template, 1.0, 0.0, 0.0, 1.0, x, y)
    }

    public func addTemplate(template: PdfTemplate,
                            a: Float32, b: Float32, c: Float32,
                            d: Float32, e: Float32, f: Float32): Unit {
        // 写入变换矩阵和模板引用
        appendRaw("q ")
        appendRaw("${a} ${b} ${c} ${d} ${e} ${f} cm ")
        appendRaw("/Tm Do ")
        appendRaw("Q ")
    }

    /**
     * 保存图形状态
     */
    public func saveState(): Unit {
        appendRaw("q ")
    }

    /**
     * 恢复图形状态
     */
    public func restoreState(): Unit {
        appendRaw("Q ")
    }

    /**
     * 设置文本矩阵
     */
    public func setTextMatrix(x: Float32, y: Float32): Unit {
        appendRaw("1 0 0 1 ${x} ${y} Tm ")
    }

    /**
     * 应用变换（平移+旋转）
     */
    public func transform(x: Float32, y: Float32, rotation: Float32): Unit {
        let cos = Float32.cos(rotation)
        let sin = Float32.sin(rotation)
        appendRaw("${cos} ${sin} ${-sin} ${cos} ${x} ${y} cm ")
    }

    /**
     * 显示文本
     */
    public func showText(phrase: Phrase): Unit {
        appendRaw("BT ")
        for (chunk in phrase.getChunks()) {
            appendRaw("(${escapeString(chunk.text)}) Tj ")
        }
        appendRaw("ET ")
    }

    /**
     * 设置字体
     */
    public func setFontAndSize(font: BaseFont, size: Float32): Unit {
        appendRaw("/F1 ${size} Tf ")
    }

    /**
     * 设置填充颜色
     */
    public func setColorFill(color: Color): Unit {
        let (r, g, b) = color.toRgbFloat()
        appendRaw("${r} ${g} ${b} rg ")
    }

    /**
     * 设置描边颜色
     */
    public func setColorStroke(color: Color): Unit {
        let (r, g, b) = color.toRgbFloat()
        appendRaw("${r} ${g} ${b} RG ")
    }

    /**
     * 绘制矩形
     */
    public func rectangle(x: Float32, y: Float32, w: Float32, h: Float32): Unit {
        appendRaw("${x} ${y} ${w} ${h} re ")
    }

    /**
     * 填充
     */
    public func fill(): Unit {
        appendRaw("f ")
    }

    /**
     * 描边
     */
    public func stroke(): Unit {
        appendRaw("S ")
    }

    private func appendRaw(s: String): Unit {
        for (byte in s.toArray()) {
            content.append(byte)
        }
    }

    private func escapeString(s: String): String {
        // 转义 PDF 字符串中的特殊字符
        s.replace("\\", "\\\\")
         .replace("(", "\\(")
         .replace(")", "\\)")
    }
}

/**
 * PDF 模板 - 可重用的内容块
 */
public class PdfTemplate {
    private let width: Float32
    private let height: Float32
    private var content: PdfContentByte? = None

    internal init(width: Float32, height: Float32) {
        this.width = width
        this.height = height
    }

    public func getWidth(): Float32 { width }
    public func getHeight(): Float32 { height }
}
```

### 4.10 工具类

```cangjie
/**
 * 矩形
 */
public struct Rectangle {
    public let left: Float32
    public let bottom: Float32
    public let right: Float32
    public let top: Float32

    public init(width: Float32, height: Float32) {
        this(0.0, 0.0, width, height)
    }

    public init(left: Float32, bottom: Float32, right: Float32, top: Float32) {
        this.left = left
        this.bottom = bottom
        this.right = right
        this.top = top
    }

    public prop width: Float32 { get() { right - left } }
    public prop height: Float32 { get() { top - bottom } }
}

/**
 * 页面尺寸常量
 */
public class PageSize {
    // 常用纸张尺寸（单位：点，1点 = 1/72 英寸）
    public static let A0 = Rectangle(2384.0, 3370.0)
    public static let A1 = Rectangle(1684.0, 2384.0)
    public static let A2 = Rectangle(1190.0, 1684.0)
    public static let A3 = Rectangle(842.0, 1190.0)
    public static let A4 = Rectangle(595.0, 842.0)
    public static let A5 = Rectangle(420.0, 595.0)
    public static let A6 = Rectangle(297.0, 420.0)

    public static let LETTER = Rectangle(612.0, 792.0)
    public static let LEGAL = Rectangle(612.0, 1008.0)

    // 横向
    public static func rotate(rect: Rectangle): Rectangle {
        Rectangle(rect.height, rect.width)
    }
}

/**
 * PDF 异常
 */
public class PdfException <: Exception {
    public init(message: String) {
        super(message)
    }
}
```

---

## 5. 关键流程设计

### 5.1 文档创建流程

```
┌─────────────────────────────────────────────────────────────┐
│                     Document Creation Flow                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Create Document       2. Get PdfWriter Instance         │
│  ┌─────────────┐          ┌──────────────────────┐         │
│  │  Document   │   ───>   │ PdfWriter.getInstance │         │
│  │  (PageSize) │          │ (document, output)   │         │
│  └─────────────┘          └──────────────────────┘         │
│         │                            │                      │
│         ▼                            ▼                      │
│  3. Open Document         4. Write PDF Header               │
│  ┌─────────────┐          ┌──────────────────────┐         │
│  │ doc.open()  │   ───>   │   %PDF-1.7           │         │
│  └─────────────┘          │   %âãÏÓ              │         │
│         │                 └──────────────────────┘         │
│         ▼                                                   │
│  5. Add Elements          6. Process & Render               │
│  ┌─────────────┐          ┌──────────────────────┐         │
│  │ doc.add()   │   ───>   │ Layout calculation   │         │
│  │ (Paragraph) │          │ Content stream gen   │         │
│  └─────────────┘          └──────────────────────┘         │
│         │                            │                      │
│         ▼                            ▼                      │
│  7. Close Document        8. Write Trailer & XRef           │
│  ┌─────────────┐          ┌──────────────────────┐         │
│  │ doc.close() │   ───>   │   xref               │         │
│  └─────────────┘          │   trailer            │         │
│                           │   %%EOF              │         │
│                           └──────────────────────┘         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 页面布局流程

```
┌─────────────────────────────────────────────────────────────┐
│                    Page Layout Algorithm                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Input: List<Element>                                       │
│                                                             │
│  ┌─────────────────────────────────────────────┐           │
│  │  For each element:                          │           │
│  │                                             │           │
│  │  1. Calculate element height                │           │
│  │     - Text: line height × line count        │           │
│  │     - Image: scaled height                  │           │
│  │     - Table: sum of row heights             │           │
│  │                                             │           │
│  │  2. Check if fits current page              │           │
│  │     currentY - height >= marginBottom?      │           │
│  │                                             │           │
│  │  3. If no: trigger newPage()                │           │
│  │     - Fire onEndPage event                  │           │
│  │     - Write current page                    │           │
│  │     - Fire onStartPage event                │           │
│  │     - Reset currentY                        │           │
│  │                                             │           │
│  │  4. Render element at (marginLeft, currentY)│           │
│  │                                             │           │
│  │  5. Update currentY -= elementHeight        │           │
│  │                                             │           │
│  └─────────────────────────────────────────────┘           │
│                                                             │
│  Output: Page contents + cross-references                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5.3 PDF 合并流程

```
┌─────────────────────────────────────────────────────────────┐
│                     PDF Merge Flow                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Input: List<PDF files>                                     │
│                                                             │
│  ┌─────────────────────────────────────────────┐           │
│  │  1. Create output Document & PdfCopy        │           │
│  │                                             │           │
│  │  2. For each input PDF:                     │           │
│  │     a. Create PdfReader                     │           │
│  │     b. Get page count                       │           │
│  │     c. For each page:                       │           │
│  │        - Import page: getImportedPage()     │           │
│  │        - Add to output: addPage()           │           │
│  │                                             │           │
│  │  3. Close document                          │           │
│  │                                             │           │
│  └─────────────────────────────────────────────┘           │
│                                                             │
│  Output: Merged PDF file                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. 数据结构设计

### 6.1 PDF 对象模型

```cangjie
/**
 * PDF 对象基类
 */
public abstract class PdfObject {
    public abstract func writeTo(writer: PdfWriter): Unit
    public abstract func getType(): PdfObjectType
}

public enum PdfObjectType {
    | Null
    | Boolean
    | Number
    | String
    | Name
    | Array
    | Dictionary
    | Stream
    | IndirectReference
}

/**
 * PDF 数字
 */
public class PdfNumber <: PdfObject {
    private let value: Float64

    public init(value: Int64) {
        this.value = value.toFloat64()
    }

    public init(value: Float64) {
        this.value = value
    }

    public func writeTo(writer: PdfWriter): Unit {
        // 写入数字
    }

    public func getType(): PdfObjectType {
        PdfObjectType.Number
    }
}

/**
 * PDF 字符串
 */
public class PdfString <: PdfObject {
    private let value: String
    private let isHex: Bool

    public init(value: String) {
        this(value, false)
    }

    public init(value: String, isHex: Bool) {
        this.value = value
        this.isHex = isHex
    }

    public func writeTo(writer: PdfWriter): Unit {
        if (isHex) {
            // 写入 <hex>
        } else {
            // 写入 (string)
        }
    }

    public func getType(): PdfObjectType {
        PdfObjectType.String
    }
}

/**
 * PDF 名称
 */
public class PdfName <: PdfObject {
    private let name: String

    // 常用名称
    public static let TYPE = PdfName("Type")
    public static let PAGE = PdfName("Page")
    public static let PAGES = PdfName("Pages")
    public static let CATALOG = PdfName("Catalog")
    public static let CONTENTS = PdfName("Contents")
    public static let RESOURCES = PdfName("Resources")
    public static let FONT = PdfName("Font")
    public static let MEDIABOX = PdfName("MediaBox")

    public init(name: String) {
        this.name = name
    }

    public func writeTo(writer: PdfWriter): Unit {
        // 写入 /Name
    }

    public func getType(): PdfObjectType {
        PdfObjectType.Name
    }
}

/**
 * PDF 数组
 */
public class PdfArray <: PdfObject {
    private var elements: ArrayList<PdfObject> = ArrayList<PdfObject>()

    public init() {}

    public init(values: Array<Float64>) {
        for (v in values) {
            elements.append(PdfNumber(v))
        }
    }

    public func add(obj: PdfObject): Unit {
        elements.append(obj)
    }

    public func writeTo(writer: PdfWriter): Unit {
        // 写入 [ ... ]
    }

    public func getType(): PdfObjectType {
        PdfObjectType.Array
    }
}

/**
 * PDF 字典
 */
public class PdfDictionary <: PdfObject {
    private var entries: HashMap<String, PdfObject> = HashMap<String, PdfObject>()

    public init() {}

    public func put(key: PdfName, value: PdfObject): Unit {
        entries.put(key.toString(), value)
    }

    public func get(key: PdfName): ?PdfObject {
        entries.get(key.toString())
    }

    public func writeTo(writer: PdfWriter): Unit {
        // 写入 << /Key Value ... >>
    }

    public func getType(): PdfObjectType {
        PdfObjectType.Dictionary
    }
}

/**
 * PDF 流
 */
public class PdfStream <: PdfDictionary {
    private var data: Array<UInt8> = []
    private var compressed: Bool = false

    public func setData(data: Array<UInt8>): Unit {
        this.data = data
    }

    public func compress(): Unit {
        if (!compressed) {
            // 使用 Flate 压缩
            data = FlateEncoder.encode(data)
            put(PdfName("Filter"), PdfName("FlateDecode"))
            compressed = true
        }
    }

    public override func writeTo(writer: PdfWriter): Unit {
        put(PdfName("Length"), PdfNumber(data.size))
        // 写入字典部分
        super.writeTo(writer)
        // 写入 stream ... endstream
    }
}

/**
 * PDF 间接引用
 */
public class PdfIndirectReference <: PdfObject {
    private let objectNumber: Int32
    private let generation: Int32

    public init(objectNumber: Int32, generation: Int32 = 0) {
        this.objectNumber = objectNumber
        this.generation = generation
    }

    public func writeTo(writer: PdfWriter): Unit {
        // 写入 n g R
    }

    public func getType(): PdfObjectType {
        PdfObjectType.IndirectReference
    }
}
```

---

## 7. 实现计划

### 7.1 阶段划分

| 阶段 | 内容 | 目标 | 预估工作量 |
|------|------|------|-----------|
| P0 | 基础框架 | 项目骨架、PDF 对象模型、基本写入能力 | 2周 |
| P1 | 文本输出 | Document/Paragraph/Chunk、字体支持 | 2周 |
| P2 | 表格支持 | PdfPTable/PdfPCell、布局算法 | 3周 |
| P3 | 图片支持 | JPEG/PNG 图片嵌入 | 1周 |
| P4 | 页面事件 | 页眉页脚、水印、页码 | 1周 |
| P5 | PDF 读取 | PdfReader、页面解析 | 2周 |
| P6 | PDF 合并 | PdfCopy、多文档合并 | 1周 |
| P7 | 优化完善 | 性能优化、内存优化、测试完善 | 2周 |

**总计：约 14 周（3.5 个月）**

### 7.2 P0 阶段详细任务

1. **项目初始化**
   - 创建 cjpm.toml 配置
   - 设计目录结构
   - 配置构建脚本

2. **PDF 对象模型**
   - PdfObject 抽象基类
   - PdfNumber/PdfString/PdfName
   - PdfArray/PdfDictionary/PdfStream
   - PdfIndirectReference

3. **基本写入能力**
   - PdfWriter 框架
   - 文件头写入
   - 交叉引用表生成
   - Trailer 写入

4. **工具类**
   - Rectangle/PageSize
   - PdfException
   - 基本编码器（ASCII85, Hex）

### 7.3 P1 阶段详细任务

1. **Document 类**
   - 页面管理
   - 边距设置
   - 元素添加

2. **Element 体系**
   - Element 接口
   - Chunk 实现
   - Paragraph 实现
   - Phrase 实现

3. **字体支持**
   - BaseFont 类
   - Font 类
   - FontFactory
   - 标准 14 字体支持

4. **布局引擎**
   - 行布局
   - 段落布局
   - 分页处理

---

## 8. 测试策略

### 8.1 单元测试

```cangjie
// 示例：Document 测试
class DocumentTest {
    @Test
    func testCreateDocument(): Unit {
        let doc = Document()
        assert(doc.pageSize == PageSize.A4)
    }

    @Test
    func testSetMargins(): Unit {
        let doc = Document()
        doc.setMargins(10.0, 10.0, 10.0, 10.0)
        assert(doc.left == 10.0)
    }

    @Test
    func testAddParagraph(): Unit {
        let buffer = ByteArrayOutputStream()
        let doc = Document()
        PdfWriter.getInstance(doc, buffer)
        doc.open()
        doc.add(Paragraph("Hello World"))
        doc.close()

        let pdfData = buffer.toArray()
        assert(pdfData.size > 0)
        assert(startsWith(pdfData, "%PDF"))
    }
}
```

### 8.2 集成测试

- 生成包含文本的 PDF，验证可用 PDF 阅读器打开
- 生成包含表格的 PDF，验证表格渲染正确
- 生成包含图片的 PDF，验证图片显示正确
- 合并多个 PDF，验证合并结果正确

### 8.3 性能测试

| 场景 | 指标 |
|------|------|
| 10 页文档生成 | < 500ms |
| 100 页文档生成 | < 5s |
| 1000 页文档生成 | < 50s |
| 内存占用（100页） | < 100MB |
| 内存占用（1000页） | < 400MB |

---

## 9. 使用示例

### 9.1 创建简单文档

```cangjie
import pdf_cj.api.*
import pdf_cj.text.*
import pdf_cj.core.*

main() {
    // 创建文档
    let document = Document()

    // 创建输出流
    let output = FileOutputStream("hello.pdf")

    // 绑定 Writer
    PdfWriter.getInstance(document, output)

    // 打开文档
    document.open()

    // 添加标题
    let titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18.0)
    document.add(Paragraph("Hello, PDF-CJ!", titleFont))

    // 添加正文
    let bodyFont = FontFactory.getFont(FontFactory.HELVETICA, 12.0)
    document.add(Paragraph("This is a sample PDF created with pdf-cj library.", bodyFont))

    // 关闭文档
    document.close()

    println("PDF created successfully!")
}
```

### 9.2 创建表格文档

```cangjie
import pdf_cj.api.*
import pdf_cj.text.*
import pdf_cj.table.*
import pdf_cj.core.*

main() {
    let document = Document()
    let output = FileOutputStream("table.pdf")
    PdfWriter.getInstance(document, output)

    document.open()

    // 添加标题
    let titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16.0)
    document.add(Paragraph("Monthly Sales Report", titleFont))
    document.add(Chunk.NEWLINE)

    // 创建 4 列表格
    let table = PdfPTable(4)
    table.setWidthPercentage(100.0)

    // 添加表头
    let headerFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12.0)
    table.addCell(Paragraph("Product", headerFont))
    table.addCell(Paragraph("Qty", headerFont))
    table.addCell(Paragraph("Price", headerFont))
    table.addCell(Paragraph("Total", headerFont))

    // 添加数据行
    let bodyFont = FontFactory.getFont(FontFactory.HELVETICA, 10.0)
    let data = [
        ("Laptop", "5", "$1200", "$6000"),
        ("Mouse", "20", "$25", "$500"),
        ("Keyboard", "15", "$45", "$675")
    ]

    for ((product, qty, price, total) in data) {
        table.addCell(Paragraph(product, bodyFont))
        table.addCell(Paragraph(qty, bodyFont))
        table.addCell(Paragraph(price, bodyFont))
        table.addCell(Paragraph(total, bodyFont))
    }

    document.add(table)
    document.close()

    println("PDF with table created!")
}
```

### 9.3 合并 PDF 文档

```cangjie
import pdf_cj.core.*
import pdf_cj.api.*

main() {
    // 准备合并的文件列表
    let inputFiles = ["doc1.pdf", "doc2.pdf", "doc3.pdf"]

    // 创建输出文档
    let document = Document()
    let output = FileOutputStream("merged.pdf")
    let copy = PdfCopy(document, output)

    document.open()

    // 逐个合并
    for (inputFile in inputFiles) {
        let reader = PdfReader(inputFile)
        let pageCount = reader.getNumberOfPages()

        for (i in 1..=pageCount) {
            document.newPage()
            let page = copy.getImportedPage(reader, i)
            copy.addPage(page)
        }
    }

    document.close()
    println("PDFs merged successfully!")
}
```

### 9.4 添加页眉页脚

```cangjie
import pdf_cj.api.*
import pdf_cj.text.*
import pdf_cj.core.*

// 自定义页面事件处理器
class HeaderFooterEvent <: PdfPageEventHelper {
    private let headerText: String

    public init(headerText: String) {
        this.headerText = headerText
    }

    public override func onEndPage(writer: PdfWriter, document: Document): Unit {
        let cb = writer.getDirectContent()

        // 添加页眉
        ColumnText.showTextAligned(
            cb,
            Alignment.Left,
            Phrase(headerText),
            document.left,
            document.top + 10.0,
            0.0
        )

        // 添加页脚（页码）
        ColumnText.showTextAligned(
            cb,
            Alignment.Center,
            Phrase("Page ${document.currentPageNumber}"),
            (document.left + document.right) / 2.0,
            document.bottom - 20.0,
            0.0
        )
    }
}

main() {
    let document = Document()
    let output = FileOutputStream("with_header_footer.pdf")
    let writer = PdfWriter.getInstance(document, output)

    // 设置页面事件
    writer.setPageEvent(HeaderFooterEvent("My Document Title"))

    document.open()

    // 添加多页内容
    for (i in 1..=5) {
        document.add(Paragraph("This is page ${i}"))
        document.add(Paragraph("Lorem ipsum dolor sit amet..."))
        document.newPage()
    }

    document.close()
}
```

---

## 10. 风险与应对

| 风险 | 影响 | 应对措施 |
|------|------|---------|
| 仓颉标准库能力不足 | 高 | 提前调研，必要时实现底层功能 |
| PDF 规范复杂性 | 中 | 优先实现常用功能，迭代完善 |
| 字体嵌入复杂 | 中 | 先支持标准字体，后期添加嵌入 |
| 图片格式支持 | 中 | 优先 JPEG/PNG，其他格式后期添加 |
| 性能达不到要求 | 中 | 设计时考虑流式处理，避免全量加载 |

---

## 11. 后续演进

### 11.1 功能增强
- PDF/A 标准支持
- 数字签名
- 加密支持
- 表单填写
- 注释支持

### 11.2 性能优化
- 增量更新支持
- 并行渲染
- 内存映射文件

### 11.3 生态扩展
- HTML 转 PDF（类似 openpdf-html）
- PDF 预览组件（类似 pdf-swing）
- 鸿蒙 ArkUI 集成

---

## 附录 A：cjpm.toml 配置

```toml
[package]
name = "pdf-cj"
version = "1.0.0"
description = "PDF library for Cangjie - OpenPDF equivalent"
license = "LGPL-2.1"

[dependencies]
# 压缩库（如果仓颉标准库不支持）
# zlib-cj = "1.0.0"

[build]
output-type = "static"

[test]
include = ["test/**/*.cj"]
```

## 附录 B：参考文档

1. ISO 32000-1:2008 (PDF 1.7 规范)
2. OpenPDF 源码: https://github.com/LibrePDF/OpenPDF
3. 仓颉语言规范
4. PDF 标准详解系列文章
