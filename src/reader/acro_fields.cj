/**
 * PDF-CJ: AcroFields - PDF 交互表单字段管理（4.3）
 *
 * 功能：
 *   - 解析 PDF /AcroForm 字段树（支持间接引用、嵌套 Kids）
 *   - 读取字段当前值（/V）
 *   - 设置字段新值（/V），标记为 dirty
 *   - 重新生成外观流 /AP（文本/复选框/单选/按钮）
 *   - 导出修改后的字段字典列表，供 PdfStamper 增量写入
 */
package pdf_cj.reader

import pdf_cj.base.*
import pdf_cj.form.FieldType
import pdf_cj.util.PdfException
import std.collection.{HashMap, ArrayList}

// ═══════════════════════════════════════════════════════════════════════════
// 外观流构建（与 pdf_form_field.cj 中的逻辑独立，避免跨包依赖）
// ═══════════════════════════════════════════════════════════════════════════

private func fmtF(v: Float32): String {
    let intPart = Int32(v)
    if (Float32(intPart) == v) { return intPart.toString() }
    var s = v.toString()
    if (s.contains(".")) {
        while (s.endsWith("0") && !s.endsWith(".0")) { s = s[0..s.size - 1] }
        if (s.endsWith(".0")) { s = s[0..s.size - 2] }
    }
    s
}

private func escapeStr(s: String): String {
    var r = ""
    for (c in s.runes()) {
        let code = UInt32(c)
        if (code == 40u32 || code == 41u32 || code == 92u32) { r += "\\" }
        r += String(c)
    }
    r
}

private func helveticaRes(): PdfDictionary {
    let helvFont = PdfDictionary()
    helvFont.put(PdfName("Type"),     PdfName("Font"))
    helvFont.put(PdfName("Subtype"),  PdfName("Type1"))
    helvFont.put(PdfName("BaseFont"), PdfName("Helvetica"))
    let fonts = PdfDictionary()
    fonts.put(PdfName("Helv"), helvFont)
    let res = PdfDictionary()
    res.put(PdfName("Font"), fonts)
    res
}

private func makeXObj(stream: PdfStream, w: Float32, h: Float32, res: PdfDictionary): Unit {
    stream.put(PdfName("Type"),      PdfName("XObject"))
    stream.put(PdfName("Subtype"),   PdfName("Form"))
    let bbox = PdfArray()
    bbox.add(PdfNumber(0))
    bbox.add(PdfNumber(0))
    bbox.add(PdfNumber(w))
    bbox.add(PdfNumber(h))
    stream.put(PdfName("BBox"),      bbox)
    stream.put(PdfName("Resources"), res)
}

private func buildTextAP(w: Float32, h: Float32, value: String): PdfStream {
    let fs: Float32 = if (12.0 < h * 0.7) { 12.0 } else { h * 0.7 }
    let bl: Float32 = (h - fs) / 2.0 + 1.0
    let content = "/Tx BMC\nq\nBT\n/Helv ${fmtF(fs)} Tf\n0 0 0 rg\n2 ${fmtF(bl)} Td\n(${escapeStr(value)}) Tj\nET\nQ\nEMC\n"
    let stream = PdfStream(content)
    makeXObj(stream, w, h, helveticaRes())
    stream
}

private func buildCheckYesAP(w: Float32, h: Float32): PdfStream {
    let content = "q\n0 0 0 rg\n1.5 w\n${fmtF(w*0.2)} ${fmtF(h*0.5)} m\n${fmtF(w*0.42)} ${fmtF(h*0.22)} l\n${fmtF(w*0.8)} ${fmtF(h*0.75)} l\nS\nQ\n"
    let stream = PdfStream(content)
    makeXObj(stream, w, h, PdfDictionary())
    stream
}

private func buildCheckOffAP(w: Float32, h: Float32): PdfStream {
    let stream = PdfStream("")
    makeXObj(stream, w, h, PdfDictionary())
    stream
}

private func buildRadioSelAP(w: Float32, h: Float32): PdfStream {
    let cx: Float32 = w / 2.0
    let cy: Float32 = h / 2.0
    let minWH: Float32 = if (w < h) { w } else { h }
    let r: Float32 = minWH * 0.3
    let k: Float32 = r * 0.5523
    let content = "q\n0 0 0 rg\n${fmtF(cx+r)} ${fmtF(cy)} m\n${fmtF(cx+r)} ${fmtF(cy+k)} ${fmtF(cx+k)} ${fmtF(cy+r)} ${fmtF(cx)} ${fmtF(cy+r)} c\n${fmtF(cx-k)} ${fmtF(cy+r)} ${fmtF(cx-r)} ${fmtF(cy+k)} ${fmtF(cx-r)} ${fmtF(cy)} c\n${fmtF(cx-r)} ${fmtF(cy-k)} ${fmtF(cx-k)} ${fmtF(cy-r)} ${fmtF(cx)} ${fmtF(cy-r)} c\n${fmtF(cx+k)} ${fmtF(cy-r)} ${fmtF(cx+r)} ${fmtF(cy-k)} ${fmtF(cx+r)} ${fmtF(cy)} c\nf\nQ\n"
    let stream = PdfStream(content)
    makeXObj(stream, w, h, PdfDictionary())
    stream
}

private func buildRadioOffAP(w: Float32, h: Float32): PdfStream {
    let stream = PdfStream("")
    makeXObj(stream, w, h, PdfDictionary())
    stream
}

private func buildPushButtonAP(w: Float32, h: Float32, caption: String): PdfStream {
    let fs: Float32 = if (12.0 < h * 0.65) { 12.0 } else { h * 0.65 }
    let captionLen = Float32(caption.size)
    let tx: Float32 = (w - captionLen * fs * 0.5) / 2.0
    let ty: Float32 = (h - fs) / 2.0 + 1.0
    let content = "q\n0.75 0.75 0.75 rg\n0 0 ${fmtF(w)} ${fmtF(h)} re f\n0.5 0.5 0.5 RG\n0.5 w\n0 0 ${fmtF(w)} ${fmtF(h)} re S\n0 0 0 rg\nBT\n/Helv ${fmtF(fs)} Tf\n${fmtF(tx)} ${fmtF(ty)} Td\n(${escapeStr(caption)}) Tj\nET\nQ\n"
    let stream = PdfStream(content)
    makeXObj(stream, w, h, helveticaRes())
    stream
}

// ═══════════════════════════════════════════════════════════════════════════
// FieldItem — 代表一个已解析字段
// ═══════════════════════════════════════════════════════════════════════════

/**
 * 已解析的 PDF 表单字段
 */
public class FieldItem {
    public var fieldName:  String
    public var fieldType:  FieldType
    public var dictionary: PdfDictionary   // 字段字典（包含 /FT /V /DV /Ff 等）
    public var widgets:    ArrayList<PdfDictionary> = ArrayList<PdfDictionary>()

    // 对象号：用于增量写入时更新同一对象
    public var objectNumber: Int32 = 0

    // 待写入的新值（None = 未修改）
    private var pendingValue: ?String = None

    // 字段矩形（从第一个 widget 的 /Rect 中提取，宽 × 高）
    public var rectW: Float32 = 100.0
    public var rectH: Float32 = 20.0

    public init(name: String, dict: PdfDictionary) {
        this.fieldName  = name
        this.dictionary = dict
        // 检测字段类型（内联，避免 init 前调用成员函数）
        var ft = FieldType.Unknown
        match (dict.get(PdfName("FT"))) {
            case Some(n: PdfName) =>
                match (n.name) {
                    case "Tx"  => ft = FieldType.Text
                    case "Btn" => ft = FieldType.Button
                    case "Ch"  => ft = FieldType.Choice
                    case "Sig" => ft = FieldType.Signature
                    case _     => ()
                }
            case _ => ()
        }
        this.fieldType = ft
    }

    /** 读取字段当前值（从 /V 键） */
    public func getValue(): String {
        match (pendingValue) {
            case Some(v) => return v
            case None => ()
        }
        match (dictionary.get(PdfName("V"))) {
            case Some(s: PdfString) => s.value
            case Some(n: PdfName)   => n.name
            case _ => ""
        }
    }

    /** 标记新值（下次 generateAppearances 时生效） */
    public func setValue(v: String): Unit {
        pendingValue = Some(v)
    }

    /** 是否有未提交的值变更 */
    public func isDirty(): Bool {
        pendingValue.isSome()
    }

    /** 将 pendingValue 写入字典，清除 dirty 状态 */
    public func commitValue(): Unit {
        match (pendingValue) {
            case Some(v) =>
                dictionary.put(PdfName("V"), PdfString(v))
                pendingValue = None
            case None => ()
        }
    }

    /** 获取 Ff 标志位 */
    public func getFlags(): Int32 {
        match (dictionary.get(PdfName("Ff"))) {
            case Some(n: PdfNumber) => Int32(n.intVal())
            case _ => 0
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// AcroFields
// ═══════════════════════════════════════════════════════════════════════════

/**
 * AcroFields — 管理 PDF 文档中的交互表单字段
 *
 * 通过 PdfReader 或 PdfStamper.getAcroFields() 获得实例。
 * 典型用法（通过 PdfStamper 增量填写）：
 *
 *   let stamper = PdfStamper(reader, os)
 *   let fields  = stamper.getAcroFields()
 *   fields.setField("name", "张三")
 *   fields.setField("agree", "Yes")
 *   fields.generateAppearances()
 *   stamper.close()          // 自动写入增量更新
 */
public class AcroFields {
    private var reader: PdfReader
    private var fields: HashMap<String, FieldItem> = HashMap<String, FieldItem>()

    public init(reader: PdfReader) {
        this.reader = reader
        parseAcroForm()
    }

    // ── 解析 ──────────────────────────────────────────────────────────────

    private func parseAcroForm(): Unit {
        let catalog = match (reader.getCatalog()) {
            case Some(c) => c
            case None => return
        }
        let acroFormObj = match (catalog.get(PdfName("AcroForm"))) {
            case Some(o) => o
            case None => return
        }
        let acroDict = match (resolveToDict(acroFormObj)) {
            case Some(d) => d
            case None => return
        }
        let fieldsArr = match (acroDict.get(PdfName("Fields"))) {
            case Some(a: PdfArray) => a
            case _ => return
        }
        for (i in 0..fieldsArr.size) {
            parseFieldObj(fieldsArr.get(i), "")
        }
    }

    private func parseFieldObj(obj: PdfObject, parentName: String): Unit {
        var objNum: Int32 = 0
        let dict = match (obj) {
            case ref: PdfIndirectReference =>
                objNum = ref.objectNumber
                match (reader.getObjectByNumber(ref.objectNumber)) {
                    case Some(d: PdfDictionary) => d
                    case _ => return
                }
            case d: PdfDictionary => d
            case _ => return
        }

        // 字段部分名
        let partName = match (dict.get(PdfName("T"))) {
            case Some(s: PdfString) => s.value
            case _ => ""
        }
        let fullName = if (parentName.size > 0 && partName.size > 0) {
            "${parentName}.${partName}"
        } else if (partName.size > 0) {
            partName
        } else {
            parentName
        }

        // 检查是否有子节点
        match (dict.get(PdfName("Kids"))) {
            case Some(kids: PdfArray) =>
                // 判断是否是真正的父字段节点还是 widget 集合
                // 如果第一个 kid 有 /Subtype /Widget 且无 /T，则 Kids 是 widget 列表
                let isWidgetKids = kidsAreWidgets(kids)
                if (isWidgetKids && fullName.size > 0) {
                    // 当前 dict 是叶子字段，kids 是其 widget 注释
                    let item = FieldItem(fullName, dict)
                    item.objectNumber = objNum
                    extractWidgetsFromKids(kids, item)
                    extractRectFromItem(item)
                    fields[fullName] = item
                } else {
                    // 递归解析子字段
                    for (j in 0..kids.size) {
                        parseFieldObj(kids.get(j), fullName)
                    }
                }
            case _ =>
                // 叶子字段（同时也是 widget）
                if (fullName.size > 0) {
                    let item = FieldItem(fullName, dict)
                    item.objectNumber = objNum
                    item.widgets.add(dict)
                    extractRectFromItem(item)
                    fields[fullName] = item
                }
        }
    }

    private func kidsAreWidgets(kids: PdfArray): Bool {
        if (kids.size == 0) { return false }
        let first = kids.get(0)
        let firstDict = match (first) {
            case ref: PdfIndirectReference =>
                match (reader.getObjectByNumber(ref.objectNumber)) {
                    case Some(d: PdfDictionary) => d
                    case _ => return false
                }
            case d: PdfDictionary => d
            case _ => return false
        }
        // 如果子对象有 /Subtype /Widget，那就是 widget 节点
        match (firstDict.get(PdfName("Subtype"))) {
            case Some(n: PdfName) => n.name == "Widget"
            case _ => false
        }
    }

    private func extractWidgetsFromKids(kids: PdfArray, item: FieldItem): Unit {
        for (i in 0..kids.size) {
            let widgetDict = match (kids.get(i)) {
                case ref: PdfIndirectReference =>
                    match (reader.getObjectByNumber(ref.objectNumber)) {
                        case Some(d: PdfDictionary) => d
                        case _ => continue
                    }
                case d: PdfDictionary => d
                case _ => continue
            }
            item.widgets.add(widgetDict)
        }
    }

    private func extractRectFromItem(item: FieldItem): Unit {
        let sourceDict = if (item.widgets.size > 0) { item.widgets[0] } else { item.dictionary }
        match (sourceDict.get(PdfName("Rect"))) {
            case Some(arr: PdfArray) =>
                if (arr.size >= 4) {
                    let left   = toF32(arr.get(0))
                    let bottom = toF32(arr.get(1))
                    let right  = toF32(arr.get(2))
                    let top    = toF32(arr.get(3))
                    item.rectW = right - left
                    item.rectH = top - bottom
                }
            case _ => ()
        }
    }

    private func resolveToDict(obj: PdfObject): ?PdfDictionary {
        match (obj) {
            case d: PdfDictionary => Some(d)
            case ref: PdfIndirectReference =>
                match (reader.getObjectByNumber(ref.objectNumber)) {
                    case Some(d: PdfDictionary) => Some(d)
                    case _ => None
                }
            case _ => None
        }
    }

    private func toF32(obj: PdfObject): Float32 {
        match (obj) {
            case n: PdfNumber => Float32(n.floatVal())
            case _ => 0.0
        }
    }

    // ── 读取与设置 ────────────────────────────────────────────────────────

    /** 获取字段当前值，若字段不存在返回 None */
    public func getField(name: String): ?String {
        match (fields.get(name)) {
            case Some(item) => Some(item.getValue())
            case None => None
        }
    }

    /**
     * 设置字段值。
     * - 文本字段 / 下拉框：直接设置文本
     * - 复选框：值为 "Yes" 表示勾选，其他（如 "Off"）表示未勾选
     * - 单选按钮：值为选项名
     * @return 字段是否存在
     */
    public func setField(name: String, value: String): Bool {
        match (fields.get(name)) {
            case Some(item) =>
                item.setValue(value)
                return true
            case None => false
        }
    }

    /** 是否存在指定字段 */
    public func hasField(name: String): Bool {
        fields.contains(name)
    }

    /** 获取字段类型 */
    public func getFieldType(name: String): FieldType {
        match (fields.get(name)) {
            case Some(item) => item.fieldType
            case None => FieldType.Unknown
        }
    }

    /** 获取所有字段名 */
    public func getFieldNames(): ArrayList<String> {
        let result = ArrayList<String>()
        for ((name, _) in fields) { result.add(name) }
        result
    }

    /** 获取字段总数 */
    public func getFieldCount(): Int64 { fields.size }

    /** 导出所有字段的当前值 */
    public func exportFormData(): HashMap<String, String> {
        let result = HashMap<String, String>()
        for ((name, item) in fields) { result[name] = item.getValue() }
        result
    }

    /** 批量导入字段值 */
    public func importFormData(data: HashMap<String, String>): Unit {
        for ((name, value) in data) { setField(name, value) }
    }

    /** 重置所有字段为默认值（/DV）或空 */
    public func resetAllFields(): Unit {
        for ((_, item) in fields) {
            let dv = match (item.dictionary.get(PdfName("DV"))) {
                case Some(s: PdfString) => s.value
                case Some(n: PdfName)   => n.name
                case _ => ""
            }
            item.setValue(dv)
        }
    }

    /** 验证所有 Required 字段（Ff bit1）是否已填写 */
    public func validateRequiredFields(): Bool {
        for ((_, item) in fields) {
            if ((item.getFlags() & 2) != 0 && item.getValue().size == 0) {
                return false
            }
        }
        true
    }

    // ── 外观生成 ─────────────────────────────────────────────────────────

    /**
     * 为所有 dirty 字段重新生成 /AP 外观流，并将值提交到字典。
     * 调用此方法后，dirty 状态清除；PdfStamper.close() 会把修改写入增量更新。
     */
    public func generateAppearances(): Unit {
        for ((_, item) in fields) {
            if (!item.isDirty()) { continue }
            item.commitValue()
            generateFieldAppearance(item)
        }
    }

    private func generateFieldAppearance(item: FieldItem): Unit {
        let w = item.rectW
        let h = item.rectH
        let value = item.getValue()

        match (item.fieldType) {
            case FieldType.Text | FieldType.Choice =>
                let stream = buildTextAP(w, h, value)
                let apDict = PdfDictionary()
                apDict.put(PdfName("N"), stream)
                putAPOnWidgets(item, apDict)

            case FieldType.Button =>
                let flags = item.getFlags()
                let isPushButton = (flags & 65536) != 0  // bit17
                let isRadio      = (flags & 32768) != 0  // bit16

                if (isPushButton) {
                    // 按钮：从 MK/CA 或 value 读标题
                    var caption = value
                    if (item.widgets.size > 0) {
                        match (item.widgets[0].get(PdfName("MK"))) {
                            case Some(mk: PdfDictionary) =>
                                match (mk.get(PdfName("CA"))) {
                                    case Some(s: PdfString) => caption = s.value
                                    case _ => ()
                                }
                            case _ => ()
                        }
                    }
                    let stream = buildPushButtonAP(w, h, caption)
                    let apDict = PdfDictionary()
                    apDict.put(PdfName("N"), stream)
                    putAPOnWidgets(item, apDict)

                } else if (isRadio) {
                    // 单选：每个 widget 有自己的 optionName（存在 /AS）
                    for (i in 0..item.widgets.size) {
                        let wDict = item.widgets[i]
                        let wW = item.rectW
                        let wH = item.rectH
                        let optionName = match (wDict.get(PdfName("AS"))) {
                            case Some(n: PdfName) => n.name
                            case _ => ""
                        }
                        let selStream = buildRadioSelAP(wW, wH)
                        let offStream = buildRadioOffAP(wW, wH)
                        let nDict = PdfDictionary()
                        if (optionName != "") {
                            nDict.put(PdfName(optionName), selStream)
                        }
                        nDict.put(PdfName("Off"), offStream)
                        let apDict = PdfDictionary()
                        apDict.put(PdfName("N"), nDict)
                        wDict.put(PdfName("AP"), apDict)
                        // 更新 AS
                        if (optionName != "" && optionName == value) {
                            wDict.put(PdfName("AS"), PdfName(optionName))
                        } else {
                            wDict.put(PdfName("AS"), PdfName("Off"))
                        }
                    }

                } else {
                    // 复选框
                    let yesStream = buildCheckYesAP(w, h)
                    let offStream = buildCheckOffAP(w, h)
                    let nDict = PdfDictionary()
                    nDict.put(PdfName("Yes"), yesStream)
                    nDict.put(PdfName("Off"), offStream)
                    let apDict = PdfDictionary()
                    apDict.put(PdfName("N"), nDict)
                    let asName: PdfName = if (value == "Yes") { PdfName("Yes") } else { PdfName("Off") }
                    for (i in 0..item.widgets.size) {
                        item.widgets[i].put(PdfName("AP"), apDict)
                        item.widgets[i].put(PdfName("AS"), asName)
                    }
                }

            case _ => ()
        }
    }

    private func putAPOnWidgets(item: FieldItem, apDict: PdfDictionary): Unit {
        if (item.widgets.size > 0) {
            for (i in 0..item.widgets.size) {
                item.widgets[i].put(PdfName("AP"), apDict)
            }
        } else {
            item.dictionary.put(PdfName("AP"), apDict)
        }
    }

    // ── 增量写入支持 ──────────────────────────────────────────────────────

    /**
     * 收集所有已修改字段的（对象号，字典）列表，供 PdfStamper 写入增量更新。
     * 只返回有真实 objectNumber（> 0）的字段。
     */
    public func getDirtyFieldObjects(): ArrayList<(Int32, PdfDictionary)> {
        let result = ArrayList<(Int32, PdfDictionary)>()
        for ((_, item) in fields) {
            if (item.objectNumber > 0) {
                result.add((item.objectNumber, item.dictionary))
            }
        }
        result
    }

    /**
     * 判断是否有需要写入的字段修改
     */
    public func hasDirtyFields(): Bool {
        for ((_, item) in fields) {
            if (item.objectNumber > 0) { return true }
        }
        false
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// FieldParser — 供外部直接解析字段数组（测试辅助）
// ═══════════════════════════════════════════════════════════════════════════

/**
 * 轻量级字段解析器（不依赖 PdfReader，供 UT 直接传入字典数组使用）
 */
public class FieldParser {
    private var fields: HashMap<String, FieldItem> = HashMap<String, FieldItem>()

    public func parseFields(fieldsArray: PdfArray): Unit {
        for (i in 0..fieldsArray.size) {
            parseField(fieldsArray.get(i), "")
        }
    }

    private func parseField(obj: PdfObject, parentName: String): Unit {
        let dict = match (obj) {
            case d: PdfDictionary => d
            case _ => return
        }
        let partName = match (dict.get(PdfName("T"))) {
            case Some(s: PdfString) => s.value
            case _ => ""
        }
        let fullName = if (parentName.size > 0 && partName.size > 0) {
            "${parentName}.${partName}"
        } else if (partName.size > 0) {
            partName
        } else {
            parentName
        }
        match (dict.get(PdfName("Kids"))) {
            case Some(kids: PdfArray) =>
                for (j in 0..kids.size) {
                    parseField(kids.get(j), fullName)
                }
            case _ =>
                if (fullName.size > 0) {
                    fields[fullName] = FieldItem(fullName, dict)
                }
        }
    }

    public func getFields(): HashMap<String, FieldItem> { fields }
}

// ═══════════════════════════════════════════════════════════════════════════
// AcroFieldsFactory
// ═══════════════════════════════════════════════════════════════════════════

public class AcroFieldsFactory {
    public static func createFromReader(reader: PdfReader): AcroFields {
        AcroFields(reader)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// FieldAppearanceGenerator（保留旧 API 以免破坏其他代码）
// ═══════════════════════════════════════════════════════════════════════════

public class FieldAppearanceGenerator {
    public static func generateTextFieldAppearance(value: String, rect: Array<Float32>, fontSize: Float32): PdfStream {
        let w: Float32 = if (rect.size >= 4) { rect[2] - rect[0] } else { 100.0 }
        let h: Float32 = if (rect.size >= 4) { rect[3] - rect[1] } else { 20.0 }
        buildTextAP(w, h, value)
    }

    public static func generateCheckBoxAppearance(checked: Bool, rect: Array<Float32>): PdfStream {
        let w: Float32 = if (rect.size >= 4) { rect[2] - rect[0] } else { 15.0 }
        let h: Float32 = if (rect.size >= 4) { rect[3] - rect[1] } else { 15.0 }
        if (checked) { buildCheckYesAP(w, h) } else { buildCheckOffAP(w, h) }
    }
}
