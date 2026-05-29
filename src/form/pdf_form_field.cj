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

// ===== 辅助函数 =====

func fmtF(v: Float32): String {
    let intPart = Int32(v)
    if (Float32(intPart) == v) {
        return intPart.toString()
    }
    var s = v.toString()
    if (s.contains(".")) {
        while (s.endsWith("0") && !s.endsWith(".0")) {
            s = s[0..s.size - 1]
        }
        if (s.endsWith(".0")) { s = s[0..s.size - 2] }
    }
    s
}

func escapePdfStr(s: String): String {
    var result = ""
    for (c in s.runes()) {
        let code = UInt32(c)
        if (code == 40u32 || code == 41u32 || code == 92u32) {  // ( ) \
            result += "\\"
        }
        result += String(c)
    }
    result
}

// Parse font size from a DA string like "/Helv 11 Tf 0 g" → 11.0
func parseDaFsFromStr(da: String): Float32 {
    let chars = ArrayList<Rune>()
    for (c in da.runes()) { chars.add(c) }
    let n = chars.size
    var i: Int64 = 1
    while (i < n) {
        if (UInt32(chars[i - 1]) == 84u32 && UInt32(chars[i]) == 102u32) {  // 'T' 'f'
            var j = i - 2
            while (j >= 0 && UInt32(chars[j]) == 32u32) { j -= 1 }
            let numEnd = j
            while (j >= 0) {
                let code = UInt32(chars[j])
                if ((code >= 48u32 && code <= 57u32) || code == 46u32) { j -= 1 } else { break }
            }
            let numStart = j + 1
            if (numStart <= numEnd) {
                var numStr = ""
                var k = numStart
                while (k <= numEnd) { numStr += String(chars[k]); k += 1 }
                var intPart: Int32 = 0
                var fracPart: Float32 = 0.0
                var fracDiv: Float32 = 10.0
                var seenDot = false
                for (c2 in numStr.runes()) {
                    let code = UInt32(c2)
                    if (code >= 48u32 && code <= 57u32) {
                        let d = Int32(code - 48u32)
                        if (!seenDot) { intPart = intPart * 10 + d }
                        else { fracPart += Float32(d) / fracDiv; fracDiv *= 10.0 }
                    } else if (code == 46u32) { seenDot = true }
                }
                return Float32(intPart) + fracPart
            }
        }
        i += 1
    }
    0.0
}

// ===== FormAppearanceBuilder =====

/**
 * 表单外观流构建器（包内可见）
 * 提供静态方法构建 PDF XObject 流
 */
class FormAppearanceBuilder {

    private static func helveticaResources(): PdfDictionary {
        let helvFont = PdfDictionary()
        helvFont.put(PdfName("Type"), PdfName("Font"))
        helvFont.put(PdfName("Subtype"), PdfName("Type1"))
        helvFont.put(PdfName("BaseFont"), PdfName("Helvetica"))
        let fonts = PdfDictionary()
        fonts.put(PdfName("Helv"), helvFont)
        let res = PdfDictionary()
        res.put(PdfName("Font"), fonts)
        res
    }

    private static func makeXObject(stream: PdfStream, w: Float32, h: Float32, resources: PdfDictionary): Unit {
        stream.put(PdfName("Type"), PdfName("XObject"))
        stream.put(PdfName("Subtype"), PdfName("Form"))
        let bbox = PdfArray()
        bbox.add(PdfNumber(0))
        bbox.add(PdfNumber(0))
        bbox.add(PdfNumber(w))
        bbox.add(PdfNumber(h))
        stream.put(PdfName("BBox"), bbox)
        stream.put(PdfName("Resources"), resources)
    }

    /**
     * 构建文本字段外观流（基础版）
     */
    static func buildTextStream(w: Float32, h: Float32, value: String): PdfStream {
        buildTextStreamFull(w, h, value, 0.0, false, 0.0, 0.0, 0.0, false, 0.0, 0.0, 0.0)
    }

    /**
     * 构建文本字段外观流（完整版，支持背景色和边框色）
     * bgR/G/B: 背景色（0.0–1.0）；hasBg=false 时不绘制背景
     * bcR/G/B: 边框色（0.0–1.0）；hasBorder=false 时不绘制边框
     */
    static func buildTextStreamFull(w: Float32, h: Float32, value: String, fontSize: Float32,
                                     hasBg: Bool, bgR: Float32, bgG: Float32, bgB: Float32,
                                     hasBorder: Bool, bcR: Float32, bcG: Float32, bcB: Float32): PdfStream {
        let fs: Float32 = if (fontSize > 0.0) { fontSize } else if (12.0 < h * 0.7) { 12.0 } else { h * 0.7 }
        let baseline: Float32 = (h - fs) / 2.0 + 1.0
        let escaped = escapePdfStr(value)
        var inner = ""
        if (hasBg) {
            inner += "${fmtF(bgR)} ${fmtF(bgG)} ${fmtF(bgB)} rg\n0 0 ${fmtF(w)} ${fmtF(h)} re f\n"
        }
        if (hasBorder) {
            inner += "${fmtF(bcR)} ${fmtF(bcG)} ${fmtF(bcB)} RG\n1 w\n0.5 0.5 ${fmtF(w - 1.0)} ${fmtF(h - 1.0)} re S\n"
        }
        inner += "BT\n/Helv ${fmtF(fs)} Tf\n0 0 0 rg\n2 ${fmtF(baseline)} Td\n(${escaped}) Tj\nET\n"
        let content = "/Tx BMC\nq\n${inner}Q\nEMC\n"
        let stream = PdfStream(content)
        makeXObject(stream, w, h, helveticaResources())
        stream
    }

    /**
     * 构建复选框选中状态流
     */
    static func buildCheckBoxYesStream(w: Float32, h: Float32): PdfStream {
        let x1 = fmtF(w * 0.2)
        let y1 = fmtF(h * 0.5)
        let x2 = fmtF(w * 0.42)
        let y2 = fmtF(h * 0.22)
        let x3 = fmtF(w * 0.8)
        let y3 = fmtF(h * 0.75)
        let content = "q\n0 0 0 rg\n1.5 w\n${x1} ${y1} m\n${x2} ${y2} l\n${x3} ${y3} l\nS\nQ\n"
        let stream = PdfStream(content)
        makeXObject(stream, w, h, PdfDictionary())
        stream
    }

    /**
     * 构建复选框未选中状态流
     */
    static func buildCheckBoxOffStream(w: Float32, h: Float32): PdfStream {
        let stream = PdfStream("")
        makeXObject(stream, w, h, PdfDictionary())
        stream
    }

    /**
     * 构建单选按钮选中状态流
     */
    static func buildRadioSelectedStream(w: Float32, h: Float32): PdfStream {
        let cx: Float32 = w / 2.0
        let cy: Float32 = h / 2.0
        let minWH: Float32 = if (w < h) { w } else { h }
        let r: Float32 = minWH * 0.3
        let k: Float32 = r * 0.5523
        let content = "q\n0 0 0 rg\n${fmtF(cx + r)} ${fmtF(cy)} m\n${fmtF(cx + r)} ${fmtF(cy + k)} ${fmtF(cx + k)} ${fmtF(cy + r)} ${fmtF(cx)} ${fmtF(cy + r)} c\n${fmtF(cx - k)} ${fmtF(cy + r)} ${fmtF(cx - r)} ${fmtF(cy + k)} ${fmtF(cx - r)} ${fmtF(cy)} c\n${fmtF(cx - r)} ${fmtF(cy - k)} ${fmtF(cx - k)} ${fmtF(cy - r)} ${fmtF(cx)} ${fmtF(cy - r)} c\n${fmtF(cx + k)} ${fmtF(cy - r)} ${fmtF(cx + r)} ${fmtF(cy - k)} ${fmtF(cx + r)} ${fmtF(cy)} c\nf\nQ\n"
        let stream = PdfStream(content)
        makeXObject(stream, w, h, PdfDictionary())
        stream
    }

    /**
     * 构建单选按钮未选中状态流
     */
    static func buildRadioOffStream(w: Float32, h: Float32): PdfStream {
        let stream = PdfStream("")
        makeXObject(stream, w, h, PdfDictionary())
        stream
    }

    /**
     * 构建按钮外观流
     */
    static func buildPushButtonStream(w: Float32, h: Float32, caption: String): PdfStream {
        let fontSize: Float32 = if (12.0 < h * 0.65) { 12.0 } else { h * 0.65 }
        let captionLen = Float32(caption.size)
        let tx: Float32 = (w - captionLen * fontSize * 0.5) / 2.0
        let ty: Float32 = (h - fontSize) / 2.0 + 1.0
        let escaped = escapePdfStr(caption)
        let content = "q\n0.75 0.75 0.75 rg\n0 0 ${fmtF(w)} ${fmtF(h)} re f\n0.5 0.5 0.5 RG\n0.5 w\n0 0 ${fmtF(w)} ${fmtF(h)} re S\n0 0 0 rg\nBT\n/Helv ${fmtF(fontSize)} Tf\n${fmtF(tx)} ${fmtF(ty)} Td\n(${escaped}) Tj\nET\nQ\n"
        let stream = PdfStream(content)
        makeXObject(stream, w, h, helveticaResources())
        stream
    }
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

    // 字段矩形（用于外观生成）
    protected var rect: Rectangle = Rectangle(0.0, 0.0, 0.0, 0.0)

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
     * 获取控件注释列表
     */
    public func getWidgets(): ArrayList<PdfAnnotation> {
        widgets
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
    // 边框色（-1 表示未设置）
    private var mkBcR: Float32 = -1.0
    private var mkBcG: Float32 = -1.0
    private var mkBcB: Float32 = -1.0
    // 背景色（-1 表示未设置）
    private var mkBgR: Float32 = -1.0
    private var mkBgG: Float32 = -1.0
    private var mkBgB: Float32 = -1.0

    /**
     * 构造函数
     */
    public init(fieldName: String, rect: Rectangle) {
        super(FieldType.Text, fieldName)
        this.rect = rect
        dictionary.put(PdfName("FT"), PdfName("Tx"))

        // 创建控件注释
        let widget = PdfAnnotation(AnnotationType.Widget, rect)
        widget.getDictionary().put(PdfName("Subtype"), PdfName("Widget"))
        addWidget(widget)
    }

    /** 设置边框颜色（0.0–1.0 分量），同时写入 /MK 和 /BS */
    public func setBorderColor(r: Float32, g: Float32, b: Float32): Unit {
        mkBcR = r; mkBcG = g; mkBcB = b
        writeMKDict()
        writeBSDict()
    }

    /** 设置背景填充颜色（0.0–1.0 分量），同时写入 /MK */
    public func setBackgroundColor(r: Float32, g: Float32, b: Float32): Unit {
        mkBgR = r; mkBgG = g; mkBgB = b
        writeMKDict()
    }

    private func writeMKDict(): Unit {
        let mkDict = PdfDictionary()
        if (mkBcR >= 0.0) {
            let bc = PdfArray()
            bc.add(PdfNumber(mkBcR)); bc.add(PdfNumber(mkBcG)); bc.add(PdfNumber(mkBcB))
            mkDict.put(PdfName("BC"), bc)
        }
        if (mkBgR >= 0.0) {
            let bg = PdfArray()
            bg.add(PdfNumber(mkBgR)); bg.add(PdfNumber(mkBgG)); bg.add(PdfNumber(mkBgB))
            mkDict.put(PdfName("BG"), bg)
        }
        dictionary.put(PdfName("MK"), mkDict)
    }

    private func writeBSDict(): Unit {
        let bsDict = PdfDictionary()
        bsDict.put(PdfName("S"), PdfName("S"))
        bsDict.put(PdfName("W"), PdfNumber(1))
        dictionary.put(PdfName("BS"), bsDict)
    }

    /**
     * 生成外观字典 /AP（读取 /DA 中的字号，绘制背景和边框）
     */
    public func generateAppearance(): Unit {
        let w = rect.right - rect.left
        let h = rect.top - rect.bottom
        let value = getValue()
        var fs: Float32 = 0.0
        match (dictionary.get(PdfName("DA"))) {
            case Some(s: PdfString) => fs = parseDaFsFromStr(s.value)
            case _ => ()
        }
        let normalStream = FormAppearanceBuilder.buildTextStreamFull(
            w, h, value, fs,
            mkBgR >= 0.0, mkBgR, mkBgG, mkBgB,
            mkBcR >= 0.0, mkBcR, mkBcG, mkBcB
        )
        let normalDict = PdfDictionary()
        normalDict.put(PdfName("N"), normalStream)
        for (i in 0..widgets.size) {
            widgets[i].getDictionary().put(PdfName("AP"), normalDict)
        }
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
        this.rect = rect
        dictionary.put(PdfName("FT"), PdfName("Btn"))

        // 创建控件注释
        let widget = PdfAnnotation(AnnotationType.Widget, rect)
        widget.getDictionary().put(PdfName("Subtype"), PdfName("Widget"))
        addWidget(widget)
    }

    /**
     * 生成外观字典 /AP
     * 包含 Yes 和 Off 两个状态流
     */
    public func generateAppearance(): Unit {
        let w = rect.right - rect.left
        let h = rect.top - rect.bottom
        let yesStream = FormAppearanceBuilder.buildCheckBoxYesStream(w, h)
        let offStream = FormAppearanceBuilder.buildCheckBoxOffStream(w, h)
        let nDict = PdfDictionary()
        nDict.put(PdfName("Yes"), yesStream)
        nDict.put(PdfName("Off"), offStream)
        let apDict = PdfDictionary()
        apDict.put(PdfName("N"), nDict)
        let asName: PdfName = if (isChecked()) { PdfName("Yes") } else { PdfName("Off") }
        for (i in 0..widgets.size) {
            widgets[i].getDictionary().put(PdfName("AP"), apDict)
            widgets[i].getDictionary().put(PdfName("AS"), asName)
        }
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

    /**
     * 生成外观字典 /AP
     * 每个 widget 获得对应 optionName 的选中流和 Off 流
     */
    public func generateAppearance(): Unit {
        // 获取当前选中值
        let selectedValue = match (dictionary.get(PdfName("V"))) {
            case Some(obj) =>
                match (obj) {
                    case name: PdfName => name.name
                    case _ => ""
                }
            case None => ""
        }
        for (i in 0..widgets.size) {
            let widget = widgets[i]
            let wDict = widget.getDictionary()
            // 读取该 widget 对应的 optionName
            let optionName = match (wDict.get(PdfName("AS"))) {
                case Some(obj) =>
                    match (obj) {
                        case name: PdfName => name.name
                        case _ => ""
                    }
                case None => ""
            }
            // 从 widget 字典的 /Rect 数组读取宽高
            var w: Float32 = 12.0
            var h: Float32 = 12.0
            match (wDict.get(PdfName("Rect"))) {
                case Some(obj) =>
                    match (obj) {
                        case rectArr: PdfArray =>
                            if (rectArr.size >= 4) {
                                let left: Float32 = match (rectArr.getAsNumber(0)) {
                                    case Some(n) => Float32(n.floatVal())
                                    case None => Float32(0)
                                }
                                let bottom: Float32 = match (rectArr.getAsNumber(1)) {
                                    case Some(n) => Float32(n.floatVal())
                                    case None => Float32(0)
                                }
                                let right: Float32 = match (rectArr.getAsNumber(2)) {
                                    case Some(n) => Float32(n.floatVal())
                                    case None => Float32(12)
                                }
                                let top: Float32 = match (rectArr.getAsNumber(3)) {
                                    case Some(n) => Float32(n.floatVal())
                                    case None => Float32(12)
                                }
                                w = right - left
                                h = top - bottom
                            }
                        case _ => ()
                    }
                case None => ()
            }
            let selectedStream = FormAppearanceBuilder.buildRadioSelectedStream(w, h)
            let offStream = FormAppearanceBuilder.buildRadioOffStream(w, h)
            let nDict = PdfDictionary()
            if (optionName != "") {
                nDict.put(PdfName(optionName), selectedStream)
            }
            nDict.put(PdfName("Off"), offStream)
            let apDict = PdfDictionary()
            apDict.put(PdfName("N"), nDict)
            wDict.put(PdfName("AP"), apDict)
            // 更新 AS 以反映当前选中状态
            if (optionName != "" && optionName == selectedValue) {
                wDict.put(PdfName("AS"), PdfName(optionName))
            } else {
                wDict.put(PdfName("AS"), PdfName("Off"))
            }
        }
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
        this.rect = rect
        dictionary.put(PdfName("FT"), PdfName("Ch"))

        // Ff bit 18: Combo - 设置为下拉框
        setFlags(131072)

        // 创建控件注释
        let widget = PdfAnnotation(AnnotationType.Widget, rect)
        widget.getDictionary().put(PdfName("Subtype"), PdfName("Widget"))
        addWidget(widget)
    }

    /**
     * 生成外观字典 /AP（与文本字段相同，显示当前选中值）
     */
    public func generateAppearance(): Unit {
        let w = rect.right - rect.left
        let h = rect.top - rect.bottom
        let value = getValue()
        let normalStream = FormAppearanceBuilder.buildTextStream(w, h, value)
        let normalDict = PdfDictionary()
        normalDict.put(PdfName("N"), normalStream)
        for (i in 0..widgets.size) {
            widgets[i].getDictionary().put(PdfName("AP"), normalDict)
        }
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
    private var caption: String

    /**
     * 构造函数
     */
    public init(fieldName: String, rect: Rectangle, caption: String) {
        super(FieldType.Button, fieldName)
        this.rect = rect
        this.caption = caption
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
     * 生成外观字典 /AP
     */
    public func generateAppearance(): Unit {
        let w = rect.right - rect.left
        let h = rect.top - rect.bottom
        // 优先从 widget MK/CA 读取标题，回退到存储的 caption
        var captionText = caption
        for (i in 0..widgets.size) {
            let wDict = widgets[i].getDictionary()
            match (wDict.get(PdfName("MK"))) {
                case Some(obj) =>
                    match (obj) {
                        case mk: PdfDictionary =>
                            match (mk.get(PdfName("CA"))) {
                                case Some(caObj) =>
                                    match (caObj) {
                                        case str: PdfString => captionText = str.value
                                        case _ => ()
                                    }
                                case None => ()
                            }
                        case _ => ()
                    }
                case None => ()
            }
            let normalStream = FormAppearanceBuilder.buildPushButtonStream(w, h, captionText)
            let normalDict = PdfDictionary()
            normalDict.put(PdfName("N"), normalStream)
            wDict.put(PdfName("AP"), normalDict)
        }
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
