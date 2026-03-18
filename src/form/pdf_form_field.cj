/**
 * PDF-CJ: PdfFormField - PDF 表单字段
 * 支持文本框、复选框、单选按钮、下拉列表等表单控件
 */
package pdf_cj.form

import pdf_cj.base.*
import pdf_cj.util.Rectangle
import std.collection.ArrayList

/**
 * 表单字段类型
 */
public enum FieldType {
    | Button        // 按钮字段（包括复选框、单选按钮、按钮）
    | Text          // 文本字段
    | Choice        // 选择字段（列表框、下拉框）
    | Signature     // 签名字段
    | Unknown       // 未知类型
}

/**
 * 按钮子类型
 */
public enum ButtonType {
    | PushButton    // 普通按钮
    | CheckBox      // 复选框
    | RadioButton   // 单选按钮
}

/**
 * 选择字段子类型
 */
public enum ChoiceType {
    | ComboBox      // 下拉框
    | ListBox       // 列表框
}

/**
 * PDF 表单字段基类
 */
public open class PdfFormField {
    protected var dictionary: PdfDictionary
    protected var fieldType: FieldType
    protected var fieldName: String

    // 控件注释
    protected var widgets: ArrayList<PdfAnnotation> = ArrayList<PdfAnnotation>()

    // 引用
    protected var reference: ?PdfIndirectReference = None

    /**
     * 构造函数
     */
    public init(fieldType: FieldType, fieldName: String) {
        this.dictionary = PdfDictionary()
        this.fieldType = fieldType
        this.fieldName = fieldName

        // 设置字段名
        dictionary.put(PdfName("T"), PdfString(fieldName))
    }

    /**
     * 从字典创建
     */
    public init(dict: PdfDictionary) {
        this.dictionary = dict
        this.fieldType = FieldType.Unknown
        this.fieldName = ""
    }

    /**
     * 设置字段值
     */
    public func setValue(value: String): Unit {
        dictionary.put(PdfName("V"), PdfString(value))
    }

    /**
     * 获取字段值
     */
    public func getValue(): String {
        match (dictionary.get(PdfName("V"))) {
            case Some(obj) =>
                match (obj) {
                    case str: PdfString => return str.value
                    case _ => ()
                }
            case None => ()
        }
        ""
    }

    /**
     * 设置默认值
     */
    public func setDefaultValue(value: String): Unit {
        dictionary.put(PdfName("DV"), PdfString(value))
    }

    /**
     * 设置字段标志
     */
    public func setFlags(flags: Int32): Unit {
        dictionary.put(PdfName("Ff"), PdfNumber(flags))
    }

    /**
     * 设置为只读
     */
    public func setReadOnly(readOnly: Bool): Unit {
        if (readOnly) {
            // Ff bit 1: ReadOnly
            setFlags(1)
        }
    }

    /**
     * 设置为必填
     */
    public func setRequired(required: Bool): Unit {
        if (required) {
            // Ff bit 2: Required
            setFlags(2)
        }
    }

    /**
     * 添加控件注释
     */
    public func addWidget(widget: PdfAnnotation): Unit {
        widgets.add(widget)
    }

    /**
     * 获取字典
     */
    public func getDictionary(): PdfDictionary {
        dictionary
    }

    /**
     * 获取字段名
     */
    public func getFieldName(): String {
        fieldName
    }

    /**
     * 获取字段类型
     */
    public func getFieldType(): FieldType {
        fieldType
    }

    /**
     * 设置引用
     */
    public func setReference(ref: PdfIndirectReference): Unit {
        this.reference = Some(ref)
    }

    /**
     * 获取引用
     */
    public func getReference(): ?PdfIndirectReference {
        reference
    }
}

/**
 * 文本字段
 * 用于输入单行或多行文本
 */
public class PdfTextFormField <: PdfFormField {
    /**
     * 构造函数
     */
    public init(fieldName: String, rect: Rectangle) {
        super(FieldType.Text, fieldName)
        dictionary.put(PdfName("FT"), PdfName("Tx"))

        // 创建控件注释
        let widget = PdfAnnotation(AnnotationType.Widget, rect)
        widget.getDictionary().put(PdfName("Subtype"), PdfName("Widget"))
        addWidget(widget)
    }

    /**
     * 设置为多行文本
     */
    public func setMultiline(multiline: Bool): Unit {
        if (multiline) {
            // Ff bit 13: Multiline
            setFlags(4096)
        }
    }

    /**
     * 设置为密码字段
     */
    public func setPassword(password: Bool): Unit {
        if (password) {
            // Ff bit 14: Password
            setFlags(8192)
        }
    }

    /**
     * 设置最大长度
     */
    public func setMaxLength(maxLen: Int32): Unit {
        dictionary.put(PdfName("MaxLen"), PdfNumber(maxLen))
    }

    /**
     * 设置默认外观
     */
    public func setDefaultAppearance(da: String): Unit {
        dictionary.put(PdfName("DA"), PdfString(da))
    }
}

/**
 * 复选框字段
 */
public class PdfCheckBoxFormField <: PdfFormField {
    /**
     * 构造函数
     */
    public init(fieldName: String, rect: Rectangle) {
        super(FieldType.Button, fieldName)
        dictionary.put(PdfName("FT"), PdfName("Btn"))

        // 创建控件注释
        let widget = PdfAnnotation(AnnotationType.Widget, rect)
        widget.getDictionary().put(PdfName("Subtype"), PdfName("Widget"))
        addWidget(widget)
    }

    /**
     * 设置选中状态
     */
    public func setChecked(checked: Bool): Unit {
        if (checked) {
            dictionary.put(PdfName("V"), PdfName("Yes"))
        } else {
            dictionary.put(PdfName("V"), PdfName("Off"))
        }
    }

    /**
     * 检查是否选中
     */
    public func isChecked(): Bool {
        match (dictionary.get(PdfName("V"))) {
            case Some(obj) =>
                match (obj) {
                    case name: PdfName => return name.name == "Yes"
                    case _ => ()
                }
            case None => ()
        }
        false
    }
}

/**
 * 单选按钮字段
 */
public class PdfRadioButtonFormField <: PdfFormField {
    /**
     * 构造函数
     */
    public init(fieldName: String) {
        super(FieldType.Button, fieldName)
        dictionary.put(PdfName("FT"), PdfName("Btn"))

        // Ff bit 16: Radio - 设置为单选按钮
        setFlags(32768)
    }

    /**
     * 添加选项
     */
    public func addOption(optionName: String, rect: Rectangle): Unit {
        let widget = PdfAnnotation(AnnotationType.Widget, rect)
        widget.getDictionary().put(PdfName("Subtype"), PdfName("Widget"))
        widget.getDictionary().put(PdfName("AS"), PdfName(optionName))
        addWidget(widget)
    }

    /**
     * 选择选项
     */
    public func selectOption(optionName: String): Unit {
        dictionary.put(PdfName("V"), PdfName(optionName))
    }
}

/**
 * 下拉框字段
 */
public class PdfComboBoxFormField <: PdfFormField {
    private var options: ArrayList<String> = ArrayList<String>()

    /**
     * 构造函数
     */
    public init(fieldName: String, rect: Rectangle) {
        super(FieldType.Choice, fieldName)
        dictionary.put(PdfName("FT"), PdfName("Ch"))

        // Ff bit 18: Combo - 设置为下拉框
        setFlags(131072)

        // 创建控件注释
        let widget = PdfAnnotation(AnnotationType.Widget, rect)
        widget.getDictionary().put(PdfName("Subtype"), PdfName("Widget"))
        addWidget(widget)
    }

    /**
     * 添加选项
     */
    public func addOption(option: String): Unit {
        options.add(option)
        updateOptions()
    }

    /**
     * 添加多个选项
     */
    public func addOptions(opts: Array<String>): Unit {
        for (opt in opts) {
            options.add(opt)
        }
        updateOptions()
    }

    /**
     * 更新选项数组
     */
    private func updateOptions(): Unit {
        let arr = PdfArray()
        for (i in 0..options.size) {
            arr.add(PdfString(options[i]))
        }
        dictionary.put(PdfName("Opt"), arr)
    }
}

/**
 * 列表框字段
 */
public class PdfListBoxFormField <: PdfFormField {
    private var options: ArrayList<String> = ArrayList<String>()

    /**
     * 构造函数
     */
    public init(fieldName: String, rect: Rectangle) {
        super(FieldType.Choice, fieldName)
        dictionary.put(PdfName("FT"), PdfName("Ch"))

        // 创建控件注释
        let widget = PdfAnnotation(AnnotationType.Widget, rect)
        widget.getDictionary().put(PdfName("Subtype"), PdfName("Widget"))
        addWidget(widget)
    }

    /**
     * 添加选项
     */
    public func addOption(option: String): Unit {
        options.add(option)
        updateOptions()
    }

    /**
     * 添加多个选项
     */
    public func addOptions(opts: Array<String>): Unit {
        for (opt in opts) {
            options.add(opt)
        }
        updateOptions()
    }

    /**
     * 设置为多选
     */
    public func setMultiSelect(multiSelect: Bool): Unit {
        if (multiSelect) {
            // Ff bit 22: MultiSelect
            setFlags(2097152)
        }
    }

    /**
     * 更新选项数组
     */
    private func updateOptions(): Unit {
        let arr = PdfArray()
        for (i in 0..options.size) {
            arr.add(PdfString(options[i]))
        }
        dictionary.put(PdfName("Opt"), arr)
    }
}

/**
 * 按钮字段
 */
public class PdfPushButtonFormField <: PdfFormField {
    /**
     * 构造函数
     */
    public init(fieldName: String, rect: Rectangle, caption: String) {
        super(FieldType.Button, fieldName)
        dictionary.put(PdfName("FT"), PdfName("Btn"))

        // Ff bit 17: Pushbutton
        setFlags(65536)

        // 创建控件注释
        let widget = PdfAnnotation(AnnotationType.Widget, rect)
        widget.getDictionary().put(PdfName("Subtype"), PdfName("Widget"))
        addWidget(widget)

        // 设置标题
        let mkDict = PdfDictionary()
        mkDict.put(PdfName("CA"), PdfString(caption))
        widget.getDictionary().put(PdfName("MK"), mkDict)
    }

    /**
     * 设置动作
     */
    public func setAction(action: PdfAction): Unit {
        dictionary.put(PdfName("A"), action.getDictionary())
    }
}

/**
 * 签名字段
 */
public class PdfSignatureFormField <: PdfFormField {
    /**
     * 构造函数
     */
    public init(fieldName: String, rect: Rectangle) {
        super(FieldType.Signature, fieldName)
        dictionary.put(PdfName("FT"), PdfName("Sig"))

        // 创建控件注释
        let widget = PdfAnnotation(AnnotationType.Widget, rect)
        widget.getDictionary().put(PdfName("Subtype"), PdfName("Widget"))
        addWidget(widget)
    }
}

/**
 * 表单字段工厂
 * 提供便捷的字段创建方法
 */
public class PdfFormFieldFactory {
    /**
     * 创建文本字段
     */
    public static func createTextField(name: String, x: Float32, y: Float32, width: Float32, height: Float32): PdfTextFormField {
        let rect = Rectangle(x, y, x + width, y + height)
        PdfTextFormField(name, rect)
    }

    /**
     * 创建复选框
     */
    public static func createCheckBox(name: String, x: Float32, y: Float32, size: Float32): PdfCheckBoxFormField {
        let rect = Rectangle(x, y, x + size, y + size)
        PdfCheckBoxFormField(name, rect)
    }

    /**
     * 创建单选按钮组
     */
    public static func createRadioButtonGroup(name: String): PdfRadioButtonFormField {
        PdfRadioButtonFormField(name)
    }

    /**
     * 创建下拉框
     */
    public static func createComboBox(name: String, x: Float32, y: Float32, width: Float32, height: Float32): PdfComboBoxFormField {
        let rect = Rectangle(x, y, x + width, y + height)
        PdfComboBoxFormField(name, rect)
    }

    /**
     * 创建列表框
     */
    public static func createListBox(name: String, x: Float32, y: Float32, width: Float32, height: Float32): PdfListBoxFormField {
        let rect = Rectangle(x, y, x + width, y + height)
        PdfListBoxFormField(name, rect)
    }

    /**
     * 创建按钮
     */
    public static func createPushButton(name: String, x: Float32, y: Float32, width: Float32, height: Float32, caption: String): PdfPushButtonFormField {
        let rect = Rectangle(x, y, x + width, y + height)
        PdfPushButtonFormField(name, rect, caption)
    }
}
