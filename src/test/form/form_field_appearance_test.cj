/**
 * 表单字段外观生成单元测试（4.2 /AP generation）
 *
 * 覆盖：
 *   - TextField / ComboBox → /AP /N 文本流
 *   - CheckBox → /AP /N << /Yes /Off >>，/AS 正确
 *   - RadioButton → 每个 widget 各自 /AP /N，/AS 跟随选中状态
 *   - PushButton → /AP /N 背景+文字流
 *   - 流内容验证（BT/ET、路径操作符等）
 */
package pdf_cj.test.form

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.form.{
    PdfFormFieldFactory,
    PdfTextFormField,
    PdfCheckBoxFormField,
    PdfRadioButtonFormField,
    PdfComboBoxFormField,
    PdfPushButtonFormField
}
import pdf_cj.base.{PdfName, PdfDictionary, PdfArray, PdfStream, PdfString}
import pdf_cj.util.Rectangle

// ── 辅助函数 ──────────────────────────────────────────────────────────────────

func getWidgetAP(field: PdfTextFormField): ?PdfDictionary {
    let widgets = field.getWidgets()
    if (widgets.size == 0) { return None }
    match (widgets[0].getDictionary().get(PdfName("AP"))) {
        case Some(obj) => match (obj) {
            case d: PdfDictionary => Some(d)
            case _ => None
        }
        case None => None
    }
}

func getCheckBoxAP(field: PdfCheckBoxFormField): ?PdfDictionary {
    let widgets = field.getWidgets()
    if (widgets.size == 0) { return None }
    match (widgets[0].getDictionary().get(PdfName("AP"))) {
        case Some(obj) => match (obj) {
            case d: PdfDictionary => Some(d)
            case _ => None
        }
        case None => None
    }
}

func streamContent(stream: PdfStream): String {
    let bytes = stream.getContent()
    var s = ""
    for (b in bytes) { s += String(Rune(UInt32(b))) }
    s
}

// ── TextField ────────────────────────────────────────────────────────────────

@Test
public class TextFieldAppearanceTests {

    @TestCase
    func testGenerateAppearanceCreatesAP(): Unit {
        let field = PdfFormFieldFactory.createTextField("name", 100.0, 700.0, 200.0, 20.0)
        field.setValue("Hello")
        field.generateAppearance()

        let widgets = field.getWidgets()
        @Expect(widgets.size > 0, true)
        let apOpt = widgets[0].getDictionary().get(PdfName("AP"))
        @Expect(apOpt.isSome(), true)
    }

    @TestCase
    func testAPContainsNEntry(): Unit {
        let field = PdfFormFieldFactory.createTextField("email", 100.0, 680.0, 200.0, 18.0)
        field.setValue("user@example.com")
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(obj) => match (obj) {
                case apDict: PdfDictionary =>
                    @Expect(apDict.contains(PdfName("N")), true)
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testNEntryIsStream(): Unit {
        let field = PdfFormFieldFactory.createTextField("txt", 50.0, 600.0, 150.0, 20.0)
        field.setValue("test")
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(apObj) => match (apObj) {
                case apDict: PdfDictionary =>
                    match (apDict.get(PdfName("N"))) {
                        case Some(nObj) => match (nObj) {
                            case _: PdfStream => @Expect(true, true)
                            case _ => @Expect(true, false)
                        }
                        case None => @Expect(true, false)
                    }
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testStreamIsFormXObject(): Unit {
        let field = PdfFormFieldFactory.createTextField("f", 0.0, 0.0, 100.0, 20.0)
        field.setValue("abc")
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(apObj) => match (apObj) {
                case apDict: PdfDictionary =>
                    match (apDict.get(PdfName("N"))) {
                        case Some(nObj) => match (nObj) {
                            case stream: PdfStream =>
                                @Expect(stream.dictionary.contains(PdfName("Subtype")), true)
                                match (stream.dictionary.get(PdfName("Subtype"))) {
                                    case Some(sub) => match (sub) {
                                        case name: PdfName => @Expect(name.name, "Form")
                                        case _ => @Expect(true, false)
                                    }
                                    case None => @Expect(true, false)
                                }
                            case _ => @Expect(true, false)
                        }
                        case None => @Expect(true, false)
                    }
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testStreamContainsBTET(): Unit {
        let field = PdfFormFieldFactory.createTextField("g", 0.0, 0.0, 120.0, 20.0)
        field.setValue("PDF")
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(apObj) => match (apObj) {
                case apDict: PdfDictionary =>
                    match (apDict.get(PdfName("N"))) {
                        case Some(nObj) => match (nObj) {
                            case stream: PdfStream =>
                                let content = streamContent(stream)
                                @Expect(content.contains("BT"), true)
                                @Expect(content.contains("ET"), true)
                                @Expect(content.contains("Helv"), true)
                            case _ => @Expect(true, false)
                        }
                        case None => @Expect(true, false)
                    }
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testStreamContainsValue(): Unit {
        let field = PdfFormFieldFactory.createTextField("h", 0.0, 0.0, 200.0, 20.0)
        field.setValue("MyValue")
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(apObj) => match (apObj) {
                case apDict: PdfDictionary =>
                    match (apDict.get(PdfName("N"))) {
                        case Some(nObj) => match (nObj) {
                            case stream: PdfStream =>
                                let content = streamContent(stream)
                                @Expect(content.contains("MyValue"), true)
                            case _ => @Expect(true, false)
                        }
                        case None => @Expect(true, false)
                    }
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testBBoxPresent(): Unit {
        let field = PdfFormFieldFactory.createTextField("bbox", 0.0, 0.0, 150.0, 20.0)
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(apObj) => match (apObj) {
                case apDict: PdfDictionary =>
                    match (apDict.get(PdfName("N"))) {
                        case Some(nObj) => match (nObj) {
                            case stream: PdfStream =>
                                @Expect(stream.dictionary.contains(PdfName("BBox")), true)
                            case _ => @Expect(true, false)
                        }
                        case None => @Expect(true, false)
                    }
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }
}

// ── CheckBox ─────────────────────────────────────────────────────────────────

@Test
public class CheckBoxAppearanceTests {

    @TestCase
    func testCheckedAPHasYesAndOff(): Unit {
        let field = PdfFormFieldFactory.createCheckBox("cb1", 100.0, 700.0, 15.0)
        field.setChecked(true)
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(apObj) => match (apObj) {
                case apDict: PdfDictionary =>
                    match (apDict.get(PdfName("N"))) {
                        case Some(nObj) => match (nObj) {
                            case nDict: PdfDictionary =>
                                @Expect(nDict.contains(PdfName("Yes")), true)
                                @Expect(nDict.contains(PdfName("Off")), true)
                            case _ => @Expect(true, false)
                        }
                        case None => @Expect(true, false)
                    }
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testCheckedASIsYes(): Unit {
        let field = PdfFormFieldFactory.createCheckBox("cb2", 100.0, 680.0, 15.0)
        field.setChecked(true)
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AS"))) {
            case Some(asObj) => match (asObj) {
                case name: PdfName => @Expect(name.name, "Yes")
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testUncheckedASIsOff(): Unit {
        let field = PdfFormFieldFactory.createCheckBox("cb3", 100.0, 660.0, 15.0)
        field.setChecked(false)
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AS"))) {
            case Some(asObj) => match (asObj) {
                case name: PdfName => @Expect(name.name, "Off")
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testYesStreamContainsPathOps(): Unit {
        let field = PdfFormFieldFactory.createCheckBox("cb4", 50.0, 600.0, 15.0)
        field.setChecked(true)
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(apObj) => match (apObj) {
                case apDict: PdfDictionary =>
                    match (apDict.get(PdfName("N"))) {
                        case Some(nObj) => match (nObj) {
                            case nDict: PdfDictionary =>
                                match (nDict.get(PdfName("Yes"))) {
                                    case Some(yesObj) => match (yesObj) {
                                        case stream: PdfStream =>
                                            let content = streamContent(stream)
                                            @Expect(content.contains(" m\n"), true)  // moveto
                                            @Expect(content.contains(" l\n"), true)  // lineto
                                            @Expect(content.contains("S\n"), true)   // stroke
                                        case _ => @Expect(true, false)
                                    }
                                    case None => @Expect(true, false)
                                }
                            case _ => @Expect(true, false)
                        }
                        case None => @Expect(true, false)
                    }
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testOffStreamIsEmpty(): Unit {
        let field = PdfFormFieldFactory.createCheckBox("cb5", 50.0, 580.0, 15.0)
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(apObj) => match (apObj) {
                case apDict: PdfDictionary =>
                    match (apDict.get(PdfName("N"))) {
                        case Some(nObj) => match (nObj) {
                            case nDict: PdfDictionary =>
                                match (nDict.get(PdfName("Off"))) {
                                    case Some(offObj) => match (offObj) {
                                        case stream: PdfStream =>
                                            let content = streamContent(stream)
                                            @Expect(content.size == 0, true)
                                        case _ => @Expect(true, false)
                                    }
                                    case None => @Expect(true, false)
                                }
                            case _ => @Expect(true, false)
                        }
                        case None => @Expect(true, false)
                    }
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }
}

// ── RadioButton ──────────────────────────────────────────────────────────────

@Test
public class RadioButtonAppearanceTests {

    @TestCase
    func testEachWidgetHasAP(): Unit {
        let field = PdfFormFieldFactory.createRadioButtonGroup("gender")
        field.addOption("male",   Rectangle(100.0, 700.0, 115.0, 715.0))
        field.addOption("female", Rectangle(150.0, 700.0, 165.0, 715.0))
        field.selectOption("male")
        field.generateAppearance()

        let widgets = field.getWidgets()
        @Expect(widgets.size, 2)
        for (i in 0..widgets.size) {
            @Expect(widgets[i].getDictionary().get(PdfName("AP")).isSome(), true)
        }
    }

    @TestCase
    func testSelectedWidgetASMatchesOption(): Unit {
        let field = PdfFormFieldFactory.createRadioButtonGroup("color")
        field.addOption("red",  Rectangle(100.0, 680.0, 115.0, 695.0))
        field.addOption("blue", Rectangle(150.0, 680.0, 165.0, 695.0))
        field.selectOption("red")
        field.generateAppearance()

        let widgets = field.getWidgets()
        // widget 0 = "red" → selected
        match (widgets[0].getDictionary().get(PdfName("AS"))) {
            case Some(asObj) => match (asObj) {
                case name: PdfName => @Expect(name.name, "red")
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
        // widget 1 = "blue" → off
        match (widgets[1].getDictionary().get(PdfName("AS"))) {
            case Some(asObj) => match (asObj) {
                case name: PdfName => @Expect(name.name, "Off")
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testSelectedStreamContainsCircle(): Unit {
        let field = PdfFormFieldFactory.createRadioButtonGroup("size")
        field.addOption("sm", Rectangle(100.0, 650.0, 115.0, 665.0))
        field.selectOption("sm")
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(apObj) => match (apObj) {
                case apDict: PdfDictionary =>
                    match (apDict.get(PdfName("N"))) {
                        case Some(nObj) => match (nObj) {
                            case nDict: PdfDictionary =>
                                match (nDict.get(PdfName("sm"))) {
                                    case Some(smObj) => match (smObj) {
                                        case stream: PdfStream =>
                                            let content = streamContent(stream)
                                            @Expect(content.contains(" c\n"), true)  // curveto (Bézier)
                                            @Expect(content.contains("f\n"), true)   // fill
                                        case _ => @Expect(true, false)
                                    }
                                    case None => @Expect(true, false)
                                }
                            case _ => @Expect(true, false)
                        }
                        case None => @Expect(true, false)
                    }
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }
}

// ── ComboBox ─────────────────────────────────────────────────────────────────

@Test
public class ComboBoxAppearanceTests {

    @TestCase
    func testGenerateAppearanceCreatesAP(): Unit {
        let field = PdfFormFieldFactory.createComboBox("city", 100.0, 700.0, 160.0, 18.0)
        field.addOptions(["北京", "上海", "深圳"])
        field.setValue("上海")
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        @Expect(wDict.get(PdfName("AP")).isSome(), true)
    }

    @TestCase
    func testStreamIsFormXObject(): Unit {
        let field = PdfFormFieldFactory.createComboBox("lang", 100.0, 680.0, 120.0, 18.0)
        field.addOptions(["中文", "English"])
        field.setValue("中文")
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(apObj) => match (apObj) {
                case apDict: PdfDictionary =>
                    match (apDict.get(PdfName("N"))) {
                        case Some(nObj) => match (nObj) {
                            case stream: PdfStream =>
                                match (stream.dictionary.get(PdfName("Subtype"))) {
                                    case Some(sub) => match (sub) {
                                        case name: PdfName => @Expect(name.name, "Form")
                                        case _ => @Expect(true, false)
                                    }
                                    case None => @Expect(true, false)
                                }
                            case _ => @Expect(true, false)
                        }
                        case None => @Expect(true, false)
                    }
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }
}

// ── PushButton ───────────────────────────────────────────────────────────────

@Test
public class PushButtonAppearanceTests {

    @TestCase
    func testGenerateAppearanceCreatesAP(): Unit {
        let field = PdfFormFieldFactory.createPushButton("btn1", 100.0, 100.0, 80.0, 24.0, "提交")
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        @Expect(wDict.get(PdfName("AP")).isSome(), true)
    }

    @TestCase
    func testStreamContainsRectFill(): Unit {
        let field = PdfFormFieldFactory.createPushButton("btn2", 100.0, 70.0, 80.0, 24.0, "Cancel")
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(apObj) => match (apObj) {
                case apDict: PdfDictionary =>
                    match (apDict.get(PdfName("N"))) {
                        case Some(nObj) => match (nObj) {
                            case stream: PdfStream =>
                                let content = streamContent(stream)
                                @Expect(content.contains("rg"), true)   // fill color
                                @Expect(content.contains(" re "), true) // rectangle
                                @Expect(content.contains("f\n"), true)  // fill
                            case _ => @Expect(true, false)
                        }
                        case None => @Expect(true, false)
                    }
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testStreamContainsCaption(): Unit {
        let field = PdfFormFieldFactory.createPushButton("btn3", 200.0, 100.0, 80.0, 24.0, "Submit")
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(apObj) => match (apObj) {
                case apDict: PdfDictionary =>
                    match (apDict.get(PdfName("N"))) {
                        case Some(nObj) => match (nObj) {
                            case stream: PdfStream =>
                                let content = streamContent(stream)
                                @Expect(content.contains("Submit"), true)
                                @Expect(content.contains("Helv"), true)
                            case _ => @Expect(true, false)
                        }
                        case None => @Expect(true, false)
                    }
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testStreamIsFormXObject(): Unit {
        let field = PdfFormFieldFactory.createPushButton("btn4", 0.0, 0.0, 60.0, 20.0, "OK")
        field.generateAppearance()

        let wDict = field.getWidgets()[0].getDictionary()
        match (wDict.get(PdfName("AP"))) {
            case Some(apObj) => match (apObj) {
                case apDict: PdfDictionary =>
                    match (apDict.get(PdfName("N"))) {
                        case Some(nObj) => match (nObj) {
                            case stream: PdfStream =>
                                @Expect(stream.dictionary.contains(PdfName("BBox")), true)
                                @Expect(stream.dictionary.contains(PdfName("Subtype")), true)
                            case _ => @Expect(true, false)
                        }
                        case None => @Expect(true, false)
                    }
                case _ => @Expect(true, false)
            }
            case None => @Expect(true, false)
        }
    }
}
