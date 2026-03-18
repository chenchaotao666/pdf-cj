/**
 * PDF-CJ: PdfAnnotation - PDF 注释
 * 支持文本注释、链接、高亮等各类注释
 */
package pdf_cj.form

import pdf_cj.base.*
import pdf_cj.util.Rectangle
import std.collection.ArrayList

/**
 * 注释类型
 */
public enum AnnotationType {
    | Text          // 文本注释
    | Link          // 链接注释
    | FreeText      // 自由文本
    | Line          // 直线
    | Square        // 矩形
    | Circle        // 圆形
    | Polygon       // 多边形
    | Highlight     // 高亮
    | Underline     // 下划线
    | Squiggly      // 波浪线
    | StrikeOut     // 删除线
    | Stamp         // 图章
    | Ink           // 墨迹
    | Popup         // 弹出窗口
    | FileAttachment // 文件附件
    | Sound         // 声音
    | Movie         // 视频
    | Widget        // 表单控件
    | Unknown       // 未知
}

/**
 * PDF 注释基类
 */
public open class PdfAnnotation {
    protected var dictionary: PdfDictionary
    protected var annotType: AnnotationType

    /**
     * 构造函数
     */
    public init(annotType: AnnotationType, rect: Rectangle) {
        this.dictionary = PdfDictionary()
        this.annotType = annotType

        // 设置类型
        dictionary.put(PdfName("Type"), PdfName("Annot"))

        // 设置矩形（直接在构造函数中设置）
        let arr = PdfArray()
        arr.add(PdfNumber(rect.left))
        arr.add(PdfNumber(rect.bottom))
        arr.add(PdfNumber(rect.right))
        arr.add(PdfNumber(rect.top))
        dictionary.put(PdfName("Rect"), arr)
    }

    /**
     * 从字典创建
     */
    public init(dict: PdfDictionary) {
        this.dictionary = dict
        this.annotType = AnnotationType.Unknown
    }

    /**
     * 设置矩形区域
     */
    public func setRectangle(rect: Rectangle): Unit {
        let arr = PdfArray()
        arr.add(PdfNumber(rect.left))
        arr.add(PdfNumber(rect.bottom))
        arr.add(PdfNumber(rect.right))
        arr.add(PdfNumber(rect.top))
        dictionary.put(PdfName("Rect"), arr)
    }

    /**
     * 设置内容
     */
    public func setContents(contents: String): Unit {
        dictionary.put(PdfName("Contents"), PdfString(contents))
    }

    /**
     * 设置边框
     */
    public func setBorder(width: Float32): Unit {
        let border = PdfArray()
        border.add(PdfNumber(0))  // 水平角半径
        border.add(PdfNumber(0))  // 垂直角半径
        border.add(PdfNumber(width))  // 边框宽度
        dictionary.put(PdfName("Border"), border)
    }

    /**
     * 设置颜色
     */
    public func setColor(r: Float32, g: Float32, b: Float32): Unit {
        let color = PdfArray()
        color.add(PdfNumber(r))
        color.add(PdfNumber(g))
        color.add(PdfNumber(b))
        dictionary.put(PdfName("C"), color)
    }

    /**
     * 设置透明度
     */
    public func setOpacity(opacity: Float32): Unit {
        dictionary.put(PdfName("CA"), PdfNumber(opacity))
    }

    /**
     * 设置标题（作者）
     */
    public func setTitle(title: String): Unit {
        dictionary.put(PdfName("T"), PdfString(title))
    }

    /**
     * 获取字典
     */
    public func getDictionary(): PdfDictionary {
        dictionary
    }

    /**
     * 获取注释类型
     */
    public func getAnnotationType(): AnnotationType {
        annotType
    }

    /**
     * 设置标志
     */
    public func setFlags(flags: Int32): Unit {
        dictionary.put(PdfName("F"), PdfNumber(flags))
    }
}

/**
 * 文本注释
 * 显示为一个图标，点击后弹出文本
 */
public class PdfAnnotationText <: PdfAnnotation {
    /**
     * 构造函数
     */
    public init(rect: Rectangle, contents: String) {
        super(AnnotationType.Text, rect)
        dictionary.put(PdfName("Subtype"), PdfName("Text"))
        setContents(contents)

        // 默认图标
        setIcon("Note")
    }

    /**
     * 设置图标类型
     * 可选值: Comment, Key, Note, Help, NewParagraph, Paragraph, Insert
     */
    public func setIcon(icon: String): Unit {
        dictionary.put(PdfName("Name"), PdfName(icon))
    }

    /**
     * 设置是否默认打开
     */
    public func setOpen(open: Bool): Unit {
        dictionary.put(PdfName("Open"), PdfBoolean(open))
    }
}

/**
 * 链接注释
 * 创建可点击的超链接区域
 */
public class PdfAnnotationLink <: PdfAnnotation {
    /**
     * 构造函数
     */
    public init(rect: Rectangle) {
        super(AnnotationType.Link, rect)
        dictionary.put(PdfName("Subtype"), PdfName("Link"))

        // 链接通常不显示边框
        setBorder(0.0)
    }

    /**
     * 设置动作
     */
    public func setAction(action: PdfAction): Unit {
        dictionary.put(PdfName("A"), action.getDictionary())
    }

    /**
     * 设置目标位置
     */
    public func setDestination(dest: PdfDestination): Unit {
        dictionary.put(PdfName("Dest"), dest.getArray())
    }

    /**
     * 设置高亮模式
     * 可选值: N(None), I(Invert), O(Outline), P(Push)
     */
    public func setHighlightMode(mode: String): Unit {
        dictionary.put(PdfName("H"), PdfName(mode))
    }
}

/**
 * 高亮注释
 * 高亮显示文本
 */
public class PdfAnnotationHighlight <: PdfAnnotation {
    /**
     * 构造函数
     */
    public init(rect: Rectangle) {
        super(AnnotationType.Highlight, rect)
        dictionary.put(PdfName("Subtype"), PdfName("Highlight"))

        // 默认黄色高亮
        setColor(1.0, 1.0, 0.0)
    }

    /**
     * 设置四边形点
     * 高亮区域由四边形定义
     */
    public func setQuadPoints(points: Array<Float32>): Unit {
        let arr = PdfArray()
        for (point in points) {
            arr.add(PdfNumber(point))
        }
        dictionary.put(PdfName("QuadPoints"), arr)
    }
}

/**
 * 下划线注释
 */
public class PdfAnnotationUnderline <: PdfAnnotation {
    /**
     * 构造函数
     */
    public init(rect: Rectangle) {
        super(AnnotationType.Underline, rect)
        dictionary.put(PdfName("Subtype"), PdfName("Underline"))
    }

    /**
     * 设置四边形点
     */
    public func setQuadPoints(points: Array<Float32>): Unit {
        let arr = PdfArray()
        for (point in points) {
            arr.add(PdfNumber(point))
        }
        dictionary.put(PdfName("QuadPoints"), arr)
    }
}

/**
 * 删除线注释
 */
public class PdfAnnotationStrikeOut <: PdfAnnotation {
    /**
     * 构造函数
     */
    public init(rect: Rectangle) {
        super(AnnotationType.StrikeOut, rect)
        dictionary.put(PdfName("Subtype"), PdfName("StrikeOut"))
    }

    /**
     * 设置四边形点
     */
    public func setQuadPoints(points: Array<Float32>): Unit {
        let arr = PdfArray()
        for (point in points) {
            arr.add(PdfNumber(point))
        }
        dictionary.put(PdfName("QuadPoints"), arr)
    }
}

/**
 * 自由文本注释
 * 直接在页面上显示文本
 */
public class PdfAnnotationFreeText <: PdfAnnotation {
    /**
     * 构造函数
     */
    public init(rect: Rectangle, contents: String) {
        super(AnnotationType.FreeText, rect)
        dictionary.put(PdfName("Subtype"), PdfName("FreeText"))
        setContents(contents)
    }

    /**
     * 设置默认外观
     */
    public func setDefaultAppearance(da: String): Unit {
        dictionary.put(PdfName("DA"), PdfString(da))
    }

    /**
     * 设置对齐方式
     * 0: 左对齐, 1: 居中, 2: 右对齐
     */
    public func setAlignment(align: Int32): Unit {
        dictionary.put(PdfName("Q"), PdfNumber(align))
    }
}

/**
 * 图章注释
 * 显示预定义的图章图标
 */
public class PdfAnnotationStamp <: PdfAnnotation {
    // 预定义图章名称
    public static let APPROVED = "Approved"
    public static let EXPERIMENTAL = "Experimental"
    public static let NOT_APPROVED = "NotApproved"
    public static let AS_IS = "AsIs"
    public static let EXPIRED = "Expired"
    public static let NOT_FOR_PUBLIC_RELEASE = "NotForPublicRelease"
    public static let CONFIDENTIAL = "Confidential"
    public static let FINAL = "Final"
    public static let SOLD = "Sold"
    public static let DEPARTMENTAL = "Departmental"
    public static let FOR_COMMENT = "ForComment"
    public static let TOP_SECRET = "TopSecret"
    public static let FOR_PUBLIC_RELEASE = "ForPublicRelease"
    public static let DRAFT = "Draft"

    /**
     * 构造函数
     */
    public init(rect: Rectangle, stampName: String) {
        super(AnnotationType.Stamp, rect)
        dictionary.put(PdfName("Subtype"), PdfName("Stamp"))
        dictionary.put(PdfName("Name"), PdfName(stampName))
    }
}

/**
 * 矩形注释
 */
public class PdfAnnotationSquare <: PdfAnnotation {
    /**
     * 构造函数
     */
    public init(rect: Rectangle) {
        super(AnnotationType.Square, rect)
        dictionary.put(PdfName("Subtype"), PdfName("Square"))
    }

    /**
     * 设置内部颜色
     */
    public func setInteriorColor(r: Float32, g: Float32, b: Float32): Unit {
        let color = PdfArray()
        color.add(PdfNumber(r))
        color.add(PdfNumber(g))
        color.add(PdfNumber(b))
        dictionary.put(PdfName("IC"), color)
    }
}

/**
 * 圆形注释
 */
public class PdfAnnotationCircle <: PdfAnnotation {
    /**
     * 构造函数
     */
    public init(rect: Rectangle) {
        super(AnnotationType.Circle, rect)
        dictionary.put(PdfName("Subtype"), PdfName("Circle"))
    }

    /**
     * 设置内部颜色
     */
    public func setInteriorColor(r: Float32, g: Float32, b: Float32): Unit {
        let color = PdfArray()
        color.add(PdfNumber(r))
        color.add(PdfNumber(g))
        color.add(PdfNumber(b))
        dictionary.put(PdfName("IC"), color)
    }
}

/**
 * 注释工厂
 * 提供便捷的注释创建方法
 */
public class PdfAnnotationFactory {
    /**
     * 创建文本注释
     */
    public static func createText(x: Float32, y: Float32, contents: String): PdfAnnotationText {
        let rect = Rectangle(x, y, x + 20.0, y + 20.0)
        PdfAnnotationText(rect, contents)
    }

    /**
     * 创建链接注释
     */
    public static func createLink(rect: Rectangle, action: PdfAction): PdfAnnotationLink {
        let link = PdfAnnotationLink(rect)
        link.setAction(action)
        link
    }

    /**
     * 创建URL链接
     */
    public static func createURLLink(rect: Rectangle, url: String): PdfAnnotationLink {
        let action = PdfActionURI(url)
        createLink(rect, action)
    }

    /**
     * 创建高亮注释
     */
    public static func createHighlight(rect: Rectangle, quadPoints: Array<Float32>): PdfAnnotationHighlight {
        let highlight = PdfAnnotationHighlight(rect)
        highlight.setQuadPoints(quadPoints)
        highlight
    }

    /**
     * 创建图章注释
     */
    public static func createStamp(rect: Rectangle, stampName: String): PdfAnnotationStamp {
        PdfAnnotationStamp(rect, stampName)
    }
}
