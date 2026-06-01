/**
 * PDF-CJ: PdfAction - PDF 动作
 * 支持页面跳转、超链接、JavaScript等交互动作
 */
package pdf_cj.form

import pdf_cj.base.*
import std.collection.ArrayList

/**
 * PDF 动作类型
 */
public enum PdfActionType {
    | GoTo           // 跳转到页面
    | GoToR          // 跳转到远程文档
    | URI            // 打开URL
    | Launch         // 启动应用程序
    | JavaScript     // 执行JavaScript
    | Named          // 命名动作
    | SubmitForm     // 提交表单
    | ResetForm      // 重置表单
    | Hide           // 隐藏/显示注释
    | Unknown        // 未知类型
}

/**
 * PDF 动作基类
 * 表示各种交互动作
 */
public open class PdfAction {
    protected var dictionary: PdfDictionary
    protected var actionType: PdfActionType

    /**
     * 构造函数
     */
    public init(actionType: PdfActionType) {
        this.dictionary = PdfDictionary()
        this.actionType = actionType
    }

    /**
     * 从字典创建
     */
    public init(dict: PdfDictionary) {
        this.dictionary = dict
        this.actionType = PdfActionType.Unknown
    }

    /**
     * 获取字典
     */
    public func getDictionary(): PdfDictionary {
        dictionary
    }

    /**
     * 获取动作类型
     */
    public func getActionType(): PdfActionType {
        actionType
    }

    /**
     * 设置下一个动作
     */
    public func setNext(next: PdfAction): Unit {
        dictionary.put(PdfName("Next"), next.getDictionary())
    }

    /**
     * 添加到字典
     */
    public func addToDictionary(dict: PdfDictionary, key: PdfName): Unit {
        dict.put(key, dictionary)
    }
}

/**
 * GoTo 动作
 * 跳转到文档中的指定位置
 */
public class PdfActionGoTo <: PdfAction {
    /**
     * 构造函数
     * @param destination 目标位置
     */
    public init(destination: PdfDestination) {
        super(PdfActionType.GoTo)
        dictionary.put(PdfName("S"), PdfName("GoTo"))
        dictionary.put(PdfName("D"), destination.getArray())
    }

    /**
     * 构造函数（使用页面引用）
     * @param pageRef 页面引用
     */
    public init(pageRef: PdfIndirectReference) {
        super(PdfActionType.GoTo)
        dictionary.put(PdfName("S"), PdfName("GoTo"))

        // 创建目标数组 [page /Fit]
        let dest = PdfArray()
        dest.add(pageRef)
        dest.add(PdfName("Fit"))
        dictionary.put(PdfName("D"), dest)
    }

    /**
     * 构造函数（使用命名目标字符串，用于文档内部跳转）
     * @param name 目标名称（与 setLocalDestination 对应）
     */
    public init(name: String) {
        super(PdfActionType.GoTo)
        dictionary.put(PdfName("S"), PdfName("GoTo"))
        dictionary.put(PdfName("D"), PdfString(name))
    }
}

/**
 * URI 动作
 * 打开网址
 */
public class PdfActionURI <: PdfAction {
    /**
     * 构造函数
     * @param uri 网址
     */
    public init(uri: String) {
        super(PdfActionType.URI)
        dictionary.put(PdfName("S"), PdfName("URI"))
        dictionary.put(PdfName("URI"), PdfString(uri))
    }

    /**
     * 获取URI
     */
    public func getURI(): String {
        match (dictionary.get(PdfName("URI"))) {
            case Some(obj) =>
                match (obj) {
                    case str: PdfString => return str.value
                    case _ => ()
                }
            case None => ()
        }
        ""
    }
}

/**
 * JavaScript 动作
 * 执行 JavaScript 代码
 */
public class PdfActionJavaScript <: PdfAction {
    /**
     * 构造函数
     * @param script JavaScript 代码
     */
    public init(script: String) {
        super(PdfActionType.JavaScript)
        dictionary.put(PdfName("S"), PdfName("JavaScript"))
        dictionary.put(PdfName("JS"), PdfString(script))
    }

    /**
     * 获取脚本
     */
    public func getScript(): String {
        match (dictionary.get(PdfName("JS"))) {
            case Some(obj) =>
                match (obj) {
                    case str: PdfString => return str.value
                    case _ => ()
                }
            case None => ()
        }
        ""
    }
}

/**
 * 命名动作
 * 执行预定义的命名动作
 */
public class PdfActionNamed <: PdfAction {
    // 预定义的命名动作
    public static let FIRST_PAGE = "FirstPage"
    public static let PREV_PAGE = "PrevPage"
    public static let NEXT_PAGE = "NextPage"
    public static let LAST_PAGE = "LastPage"

    /**
     * 构造函数
     * @param name 动作名称
     */
    public init(name: String) {
        super(PdfActionType.Named)
        dictionary.put(PdfName("S"), PdfName("Named"))
        dictionary.put(PdfName("N"), PdfName(name))
    }
}

/**
 * 启动动作
 * 启动外部应用程序或打开文件
 */
public class PdfActionLaunch <: PdfAction {
    /**
     * 构造函数
     * @param file 文件路径
     */
    public init(file: String) {
        super(PdfActionType.Launch)
        dictionary.put(PdfName("S"), PdfName("Launch"))

        let fileDict = PdfDictionary()
        fileDict.put(PdfName("F"), PdfString(file))
        dictionary.put(PdfName("F"), fileDict)
    }
}

/**
 * 提交表单动作
 */
public class PdfActionSubmitForm <: PdfAction {
    /**
     * 构造函数
     * @param url 提交URL
     */
    public init(url: String) {
        super(PdfActionType.SubmitForm)
        dictionary.put(PdfName("S"), PdfName("SubmitForm"))

        let fileSpec = PdfDictionary()
        fileSpec.put(PdfName("F"), PdfString(url))
        dictionary.put(PdfName("F"), fileSpec)
    }

    /**
     * 设置提交标志
     */
    public func setFlags(flags: Int32): Unit {
        dictionary.put(PdfName("Flags"), PdfNumber(flags))
    }
}

/**
 * 重置表单动作
 */
public class PdfActionResetForm <: PdfAction {
    /**
     * 构造函数
     */
    public init() {
        super(PdfActionType.ResetForm)
        dictionary.put(PdfName("S"), PdfName("ResetForm"))
    }

    /**
     * 设置要重置的字段
     */
    public func setFields(fields: Array<String>): Unit {
        let arr = PdfArray()
        for (field in fields) {
            arr.add(PdfString(field))
        }
        dictionary.put(PdfName("Fields"), arr)
    }
}

/**
 * PDF 目标位置
 * 表示文档中的一个位置
 */
public class PdfDestination {
    private var array: PdfArray

    /**
     * 构造函数 - Fit 模式（适应窗口）
     * @param pageRef 页面引用
     */
    public init(pageRef: PdfIndirectReference) {
        this.array = PdfArray()
        array.add(pageRef)
        array.add(PdfName("Fit"))
    }

    /**
     * 构造函数 - XYZ 模式（指定坐标和缩放）
     * @param pageRef 页面引用
     * @param left 左边距
     * @param top 顶部距离
     * @param zoom 缩放比例
     */
    public init(pageRef: PdfIndirectReference, left: Float32, top: Float32, zoom: Float32) {
        this.array = PdfArray()
        array.add(pageRef)
        array.add(PdfName("XYZ"))
        array.add(PdfNumber(left))
        array.add(PdfNumber(top))
        array.add(PdfNumber(zoom))
    }

    /**
     * 构造函数 - FitH 模式（适应宽度）
     * @param pageRef 页面引用
     * @param top 顶部距离
     */
    public init(pageRef: PdfIndirectReference, top: Float32) {
        this.array = PdfArray()
        array.add(pageRef)
        array.add(PdfName("FitH"))
        array.add(PdfNumber(top))
    }

    /**
     * 获取数组
     */
    public func getArray(): PdfArray {
        array
    }
}

/**
 * 动作工厂
 * 提供便捷的动作创建方法
 */
public class PdfActionFactory {
    /**
     * 创建跳转到页面的动作
     */
    public static func createGoToPage(pageRef: PdfIndirectReference): PdfActionGoTo {
        PdfActionGoTo(pageRef)
    }

    /**
     * 创建打开URL的动作
     */
    public static func createURL(url: String): PdfActionURI {
        PdfActionURI(url)
    }

    /**
     * 创建JavaScript动作
     */
    public static func createJavaScript(script: String): PdfActionJavaScript {
        PdfActionJavaScript(script)
    }

    /**
     * 创建命名动作
     */
    public static func createNamed(name: String): PdfActionNamed {
        PdfActionNamed(name)
    }

    /**
     * 创建下一页动作
     */
    public static func createNextPage(): PdfActionNamed {
        PdfActionNamed(PdfActionNamed.NEXT_PAGE)
    }

    /**
     * 创建上一页动作
     */
    public static func createPrevPage(): PdfActionNamed {
        PdfActionNamed(PdfActionNamed.PREV_PAGE)
    }

    /**
     * 创建首页动作
     */
    public static func createFirstPage(): PdfActionNamed {
        PdfActionNamed(PdfActionNamed.FIRST_PAGE)
    }

    /**
     * 创建末页动作
     */
    public static func createLastPage(): PdfActionNamed {
        PdfActionNamed(PdfActionNamed.LAST_PAGE)
    }
}
