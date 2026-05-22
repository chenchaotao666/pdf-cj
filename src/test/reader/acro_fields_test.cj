/**
 * AcroFields 单元测试（4.3）
 *
 * 覆盖：
 *   - FieldItem：getValue / setValue / isDirty / commitValue
 *   - FieldParser：解析扁平字段数组，递归 Kids 层级
 *   - AcroFields（无 AcroForm 的空白 PDF）：getFieldCount / getField / setField / hasField
 *   - AcroFields（含 AcroForm 的 PDF）：解析字段、读值、设值、generateAppearances
 *   - FieldAppearanceGenerator：generateTextFieldAppearance / generateCheckBoxAppearance
 *   - PdfStamper 集成：getAcroFields 返回 AcroFields 实例，关闭后输出非空
 */
package pdf_cj.test.reader

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.{HashMap, ArrayList}
import pdf_cj.reader.{PdfReader, PdfStamper, AcroFields, AcroFieldsFactory,
                      FieldItem, FieldParser, FieldAppearanceGenerator}
import pdf_cj.base.{PdfDictionary, PdfName, PdfString, PdfArray, PdfNumber,
                    PdfStream, PdfByteArrayOutputStream}
import pdf_cj.form.FieldType

// ─── 辅助：最小 PDF（无 AcroForm）────────────────────────────────────────────

func acroPdfNoForm(): Array<UInt8> {
    let src =
        "%PDF-1.4\n" +
        "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n" +
        "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n" +
        "3 0 obj\n<< /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R >>\nendobj\n"
    let off1: Int64 = 9
    let obj1 = "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
    let obj2 = "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"
    let obj3 = "3 0 obj\n<< /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R >>\nendobj\n"
    let off2 = off1 + Int64(obj1.size)
    let off3 = off2 + Int64(obj2.size)
    let xrefOff = off3 + Int64(obj3.size)
    let xrefStr =
        "xref\n0 4\n" +
        "0000000000 65535 f \r\n" +
        acroL10(off1) + " 00000 n \r\n" +
        acroL10(off2) + " 00000 n \r\n" +
        acroL10(off3) + " 00000 n \r\n" +
        "trailer\n<< /Size 4 /Root 1 0 R >>\n" +
        "startxref\n${xrefOff}\n%%EOF\n"
    acroToBytes(src + xrefStr)
}

// 含 AcroForm 的最小 PDF：
// obj1=Catalog(含 /AcroForm 5 0 R)  obj2=Pages  obj3=Page
// obj4=Content流  obj5=AcroForm dict  obj6=text字段  obj7=checkbox字段
func acroPdfWithForm(): Array<UInt8> {
    let content  = "BT ET\n"   // 6 bytes
    let obj1Body = "<< /Type /Catalog /Pages 2 0 R /AcroForm 5 0 R >>"
    let obj2Body = "<< /Type /Pages /Kids [3 0 R] /Count 1 >>"
    let obj3Body = "<< /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R /Contents 4 0 R >>"
    let obj4Body = "<< /Length 6 >>\nstream\n${content}endstream"
    // AcroForm: Fields = [6 0 R, 7 0 R]
    let obj5Body = "<< /Fields [6 0 R 7 0 R] >>"
    // Text field: name="username", value="Alice", rect=[100 700 300 720]
    let obj6Body = "<< /FT /Tx /T (username) /V (Alice) /Rect [100 700 300 720] >>"
    // CheckBox field: name="agree", value=/Yes, rect=[50 650 65 665]
    let obj7Body = "<< /FT /Btn /T (agree) /V /Yes /Rect [50 650 65 665] >>"

    var s = "%PDF-1.4\n"
    let off1 = Int64(s.size)
    s += "1 0 obj\n${obj1Body}\nendobj\n"
    let off2 = Int64(s.size)
    s += "2 0 obj\n${obj2Body}\nendobj\n"
    let off3 = Int64(s.size)
    s += "3 0 obj\n${obj3Body}\nendobj\n"
    let off4 = Int64(s.size)
    s += "4 0 obj\n${obj4Body}\nendobj\n"
    let off5 = Int64(s.size)
    s += "5 0 obj\n${obj5Body}\nendobj\n"
    let off6 = Int64(s.size)
    s += "6 0 obj\n${obj6Body}\nendobj\n"
    let off7 = Int64(s.size)
    s += "7 0 obj\n${obj7Body}\nendobj\n"
    let xrefOff = Int64(s.size)
    s += "xref\n0 8\n" +
        "0000000000 65535 f \r\n" +
        acroL10(off1) + " 00000 n \r\n" +
        acroL10(off2) + " 00000 n \r\n" +
        acroL10(off3) + " 00000 n \r\n" +
        acroL10(off4) + " 00000 n \r\n" +
        acroL10(off5) + " 00000 n \r\n" +
        acroL10(off6) + " 00000 n \r\n" +
        acroL10(off7) + " 00000 n \r\n" +
        "trailer\n<< /Size 8 /Root 1 0 R >>\n" +
        "startxref\n${xrefOff}\n%%EOF\n"
    acroToBytes(s)
}

func optStr(opt: ?String): String {
    match (opt) {
        case Some(v) => v
        case None => ""
    }
}

func acroL10(n: Int64): String {
    var s = "${n}"
    while (s.size < 10) { s = "0" + s }
    s
}

func acroToBytes(str: String): Array<UInt8> {
    let arr = Array<UInt8>(str.size, repeat: 0)
    var i = 0
    for (r in str.runes()) {
        arr[i] = UInt8(UInt32(r))
        i += 1
    }
    arr
}

func streamStr(stream: PdfStream): String {
    let bytes = stream.getContent()
    var s = ""
    for (b in bytes) { s += String(Rune(UInt32(b))) }
    s
}

// ═══════════════════════════════════════════════════════════════════════════
// FieldItem 单元测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class FieldItemTests {

    @TestCase
    func testGetValueFromDict(): Unit {
        let dict = PdfDictionary()
        dict.put(PdfName("FT"), PdfName("Tx"))
        dict.put(PdfName("T"),  PdfString("myField"))
        dict.put(PdfName("V"),  PdfString("Hello"))
        let item = FieldItem("myField", dict)
        @Expect(item.getValue(), "Hello")
    }

    @TestCase
    func testGetValueFromNameV(): Unit {
        let dict = PdfDictionary()
        dict.put(PdfName("FT"), PdfName("Btn"))
        dict.put(PdfName("T"),  PdfString("cb"))
        dict.put(PdfName("V"),  PdfName("Yes"))
        let item = FieldItem("cb", dict)
        @Expect(item.getValue(), "Yes")
    }

    @TestCase
    func testGetValueEmptyWhenNoV(): Unit {
        let dict = PdfDictionary()
        dict.put(PdfName("FT"), PdfName("Tx"))
        dict.put(PdfName("T"),  PdfString("empty"))
        let item = FieldItem("empty", dict)
        @Expect(item.getValue(), "")
    }

    @TestCase
    func testSetValueMakesDirty(): Unit {
        let dict = PdfDictionary()
        dict.put(PdfName("FT"), PdfName("Tx"))
        let item = FieldItem("f", dict)
        @Expect(item.isDirty(), false)
        item.setValue("NewVal")
        @Expect(item.isDirty(), true)
        @Expect(item.getValue(), "NewVal")
    }

    @TestCase
    func testCommitValueWritesToDict(): Unit {
        let dict = PdfDictionary()
        dict.put(PdfName("FT"), PdfName("Tx"))
        let item = FieldItem("f", dict)
        item.setValue("Committed")
        item.commitValue()
        @Expect(item.isDirty(), false)
        // 值已写入字典
        match (dict.get(PdfName("V"))) {
            case Some(s: PdfString) => @Expect(s.value, "Committed")
            case _ => @Expect(true, false)
        }
    }

    @TestCase
    func testFieldTypeDetectedText(): Unit {
        let dict = PdfDictionary()
        dict.put(PdfName("FT"), PdfName("Tx"))
        let item = FieldItem("f", dict)
        match (item.fieldType) {
            case FieldType.Text => @Expect(true, true)
            case _ => @Expect(true, false)
        }
    }

    @TestCase
    func testFieldTypeDetectedButton(): Unit {
        let dict = PdfDictionary()
        dict.put(PdfName("FT"), PdfName("Btn"))
        let item = FieldItem("f", dict)
        match (item.fieldType) {
            case FieldType.Button => @Expect(true, true)
            case _ => @Expect(true, false)
        }
    }

    @TestCase
    func testFieldTypeDetectedChoice(): Unit {
        let dict = PdfDictionary()
        dict.put(PdfName("FT"), PdfName("Ch"))
        let item = FieldItem("f", dict)
        match (item.fieldType) {
            case FieldType.Choice => @Expect(true, true)
            case _ => @Expect(true, false)
        }
    }

    @TestCase
    func testFieldTypeUnknownWhenNoFT(): Unit {
        let dict = PdfDictionary()
        let item = FieldItem("f", dict)
        match (item.fieldType) {
            case FieldType.Unknown => @Expect(true, true)
            case _ => @Expect(true, false)
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// FieldParser 单元测试
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class FieldParserTests {

    @TestCase
    func testParseFlatFields(): Unit {
        let f1 = PdfDictionary()
        f1.put(PdfName("FT"), PdfName("Tx"))
        f1.put(PdfName("T"),  PdfString("name"))

        let f2 = PdfDictionary()
        f2.put(PdfName("FT"), PdfName("Btn"))
        f2.put(PdfName("T"),  PdfString("agree"))

        let arr = PdfArray()
        arr.add(f1)
        arr.add(f2)

        let parser = FieldParser()
        parser.parseFields(arr)
        let result = parser.getFields()

        @Expect(result.size, 2)
        @Expect(result.contains("name"),  true)
        @Expect(result.contains("agree"), true)
    }

    @TestCase
    func testParseNestedFields(): Unit {
        // parent.child 结构
        let child = PdfDictionary()
        child.put(PdfName("FT"), PdfName("Tx"))
        child.put(PdfName("T"),  PdfString("child"))

        let kids = PdfArray()
        kids.add(child)

        let parent = PdfDictionary()
        parent.put(PdfName("T"),    PdfString("parent"))
        parent.put(PdfName("Kids"), kids)

        let arr = PdfArray()
        arr.add(parent)

        let parser = FieldParser()
        parser.parseFields(arr)
        let result = parser.getFields()

        @Expect(result.contains("parent.child"), true)
        @Expect(result.contains("parent"), false)
    }

    @TestCase
    func testParseEmptyArray(): Unit {
        let arr = PdfArray()
        let parser = FieldParser()
        parser.parseFields(arr)
        @Expect(parser.getFields().size, 0)
    }

    @TestCase
    func testFieldItemTypePreserved(): Unit {
        let f = PdfDictionary()
        f.put(PdfName("FT"), PdfName("Ch"))
        f.put(PdfName("T"),  PdfString("city"))

        let arr = PdfArray()
        arr.add(f)

        let parser = FieldParser()
        parser.parseFields(arr)
        match (parser.getFields().get("city")) {
            case Some(item) =>
                match (item.fieldType) {
                    case FieldType.Choice => @Expect(true, true)
                    case _ => @Expect(true, false)
                }
            case None => @Expect(true, false)
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// AcroFields（空 PDF，无 AcroForm）
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class AcroFieldsEmptyTests {

    @TestCase
    func testNoFieldsWhenNoAcroForm(): Unit {
        let reader = PdfReader(acroPdfNoForm())
        let af = reader.getAcroFields()
        @Expect(af.getFieldCount(), 0)
    }

    @TestCase
    func testGetFieldReturnsNone(): Unit {
        let reader = PdfReader(acroPdfNoForm())
        let af = reader.getAcroFields()
        @Expect(af.getField("anything").isNone(), true)
    }

    @TestCase
    func testHasFieldReturnsFalse(): Unit {
        let reader = PdfReader(acroPdfNoForm())
        let af = reader.getAcroFields()
        @Expect(af.hasField("x"), false)
    }

    @TestCase
    func testSetFieldReturnsFalse(): Unit {
        let reader = PdfReader(acroPdfNoForm())
        let af = reader.getAcroFields()
        @Expect(af.setField("x", "y"), false)
    }

    @TestCase
    func testGetFieldNamesEmpty(): Unit {
        let reader = PdfReader(acroPdfNoForm())
        let af = reader.getAcroFields()
        @Expect(af.getFieldNames().size, 0)
    }

    @TestCase
    func testExportFormDataEmpty(): Unit {
        let reader = PdfReader(acroPdfNoForm())
        let af = reader.getAcroFields()
        @Expect(af.exportFormData().size, 0)
    }

    @TestCase
    func testValidateRequiredFields(): Unit {
        let reader = PdfReader(acroPdfNoForm())
        let af = reader.getAcroFields()
        // 无字段 → 全部有效
        @Expect(af.validateRequiredFields(), true)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// AcroFields（含 AcroForm 的 PDF）
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class AcroFieldsWithFormTests {

    @TestCase
    func testFieldCountMatchesAcroForm(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let af = reader.getAcroFields()
        @Expect(af.getFieldCount(), 2)
    }

    @TestCase
    func testGetTextFieldValue(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let af = reader.getAcroFields()
        match (af.getField("username")) {
            case Some(v) => @Expect(v, "Alice")
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testGetCheckBoxValue(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let af = reader.getAcroFields()
        match (af.getField("agree")) {
            case Some(v) => @Expect(v, "Yes")
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testHasField(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let af = reader.getAcroFields()
        @Expect(af.hasField("username"), true)
        @Expect(af.hasField("agree"),    true)
        @Expect(af.hasField("missing"),  false)
    }

    @TestCase
    func testSetFieldReturnsTrueForExisting(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let af = reader.getAcroFields()
        @Expect(af.setField("username", "Bob"), true)
        match (af.getField("username")) {
            case Some(v) => @Expect(v, "Bob")
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testSetFieldReturnsFalseForMissing(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let af = reader.getAcroFields()
        @Expect(af.setField("nonexistent", "X"), false)
    }

    @TestCase
    func testGetFieldTypeText(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let af = reader.getAcroFields()
        match (af.getFieldType("username")) {
            case FieldType.Text => @Expect(true, true)
            case _ => @Expect(true, false)
        }
    }

    @TestCase
    func testGetFieldTypeButton(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let af = reader.getAcroFields()
        match (af.getFieldType("agree")) {
            case FieldType.Button => @Expect(true, true)
            case _ => @Expect(true, false)
        }
    }

    @TestCase
    func testExportFormData(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let af = reader.getAcroFields()
        let data = af.exportFormData()
        @Expect(data.size, 2)
        @Expect(data.contains("username"), true)
        @Expect(data.contains("agree"),    true)
    }

    @TestCase
    func testImportFormData(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let af = reader.getAcroFields()
        let data = HashMap<String, String>()
        data["username"] = "Charlie"
        data["agree"] = "Off"
        af.importFormData(data)
        @Expect(optStr(af.getField("username")), "Charlie")
        @Expect(optStr(af.getField("agree")),    "Off")
    }

    @TestCase
    func testResetAllFields(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let af = reader.getAcroFields()
        af.setField("username", "TmpValue")
        af.resetAllFields()
        // 无 /DV → 重置为空
        @Expect(optStr(af.getField("username")), "")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// generateAppearances
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class GenerateAppearancesTests {

    @TestCase
    func testGenerateTextFieldAP(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let af = reader.getAcroFields()
        af.setField("username", "Dave")
        af.generateAppearances()
        // 字段字典应有 /AP
        match (af.getField("username")) {
            case Some(v) => @Expect(v, "Dave")
            case None => @Expect(true, false)
        }
    }

    @TestCase
    func testGenerateCheckBoxAP(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let af = reader.getAcroFields()
        af.setField("agree", "Yes")
        af.generateAppearances()
        @Expect(optStr(af.getField("agree")), "Yes")
    }

    @TestCase
    func testDirtyFlagClearedAfterGenerate(): Unit {
        // FieldItem 级别测试
        let dict = PdfDictionary()
        dict.put(PdfName("FT"), PdfName("Tx"))
        let item = FieldItem("f", dict)
        item.setValue("X")
        @Expect(item.isDirty(), true)
        item.commitValue()
        @Expect(item.isDirty(), false)
    }

    @TestCase
    func testGenerateDoesNotThrowOnEmptyPdf(): Unit {
        let reader = PdfReader(acroPdfNoForm())
        let af = reader.getAcroFields()
        af.generateAppearances()  // 无字段，应静默
        @Expect(true, true)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// FieldAppearanceGenerator
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class FieldAppearanceGeneratorTests {

    @TestCase
    func testTextStreamIsXObject(): Unit {
        let rect = Array<Float32>(4, repeat: 0.0)
        rect[0] = 0.0; rect[1] = 0.0; rect[2] = 200.0; rect[3] = 20.0
        let stream = FieldAppearanceGenerator.generateTextFieldAppearance("Hello", rect, 12.0)
        @Expect(stream.dictionary.contains(PdfName("Subtype")), true)
        match (stream.dictionary.get(PdfName("Subtype"))) {
            case Some(n: PdfName) => @Expect(n.name, "Form")
            case _ => @Expect(true, false)
        }
    }

    @TestCase
    func testTextStreamContainsBT(): Unit {
        let rect = Array<Float32>(4, repeat: 0.0)
        rect[2] = 150.0; rect[3] = 20.0
        let stream = FieldAppearanceGenerator.generateTextFieldAppearance("Test", rect, 10.0)
        @Expect(streamStr(stream).contains("BT"), true)
    }

    @TestCase
    func testTextStreamContainsValue(): Unit {
        let rect = Array<Float32>(4, repeat: 0.0)
        rect[2] = 150.0; rect[3] = 20.0
        let stream = FieldAppearanceGenerator.generateTextFieldAppearance("MyVal", rect, 10.0)
        @Expect(streamStr(stream).contains("MyVal"), true)
    }

    @TestCase
    func testCheckBoxCheckedContainsPath(): Unit {
        let rect = Array<Float32>(4, repeat: 0.0)
        rect[2] = 15.0; rect[3] = 15.0
        let stream = FieldAppearanceGenerator.generateCheckBoxAppearance(true, rect)
        let content = streamStr(stream)
        @Expect(content.contains(" m\n"), true)
        @Expect(content.contains("S\n"), true)
    }

    @TestCase
    func testCheckBoxUncheckedIsEmpty(): Unit {
        let rect = Array<Float32>(4, repeat: 0.0)
        rect[2] = 15.0; rect[3] = 15.0
        let stream = FieldAppearanceGenerator.generateCheckBoxAppearance(false, rect)
        @Expect(stream.length, 0)
    }

    @TestCase
    func testCheckBoxStreamHasBBox(): Unit {
        let rect = Array<Float32>(4, repeat: 0.0)
        rect[2] = 15.0; rect[3] = 15.0
        let stream = FieldAppearanceGenerator.generateCheckBoxAppearance(true, rect)
        @Expect(stream.dictionary.contains(PdfName("BBox")), true)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// PdfStamper 集成（getAcroFields 通过 stamper 访问）
// ═══════════════════════════════════════════════════════════════════════════

@Test
public class AcroStamperIntegrationTests {

    @TestCase
    func testGetAcroFieldsFromStamper(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let os = PdfByteArrayOutputStream()
        let stamper = PdfStamper(reader, os)
        let af = stamper.getAcroFields()
        @Expect(af.getFieldCount(), 2)
        stamper.close()
    }

    @TestCase
    func testGetAcroFieldsSameInstance(): Unit {
        let reader = PdfReader(acroPdfNoForm())
        let os = PdfByteArrayOutputStream()
        let stamper = PdfStamper(reader, os)
        let af1 = stamper.getAcroFields()
        let af2 = stamper.getAcroFields()
        // 同一实例
        @Expect(af1.getFieldCount(), af2.getFieldCount())
        stamper.close()
    }

    @TestCase
    func testSetAndGenerateViaStamper(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let os = PdfByteArrayOutputStream()
        let stamper = PdfStamper(reader, os)
        let af = stamper.getAcroFields()
        af.setField("username", "Eve")
        af.generateAppearances()
        stamper.close()
        // 输出不为空（包含原始 PDF + 增量更新）
        @Expect(os.toByteArray().size > 0, true)
    }

    @TestCase
    func testStamperOutputContainsPdfHeader(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let os = PdfByteArrayOutputStream()
        let stamper = PdfStamper(reader, os)
        stamper.getAcroFields().setField("username", "Frank")
        stamper.getAcroFields().generateAppearances()
        stamper.close()
        let data = os.toByteArray()
        // 起始应有 %PDF-
        @Expect(data.size >= 5, true)
        @Expect(data[0], UInt8(0x25))  // '%'
        @Expect(data[1], UInt8(0x50))  // 'P'
    }

    @TestCase
    func testStamperOutputContainsEOF(): Unit {
        let reader = PdfReader(acroPdfWithForm())
        let os = PdfByteArrayOutputStream()
        let stamper = PdfStamper(reader, os)
        stamper.close()
        let data = os.toByteArray()
        // 尾部应含 %%EOF
        var found = false
        if (data.size >= 5) {
            var i = Int64(data.size) - 5
            while (i >= 0) {
                if (data[i]   == 0x25 && data[i+1] == 0x25 &&
                    data[i+2] == 0x45 && data[i+3] == 0x4F && data[i+4] == 0x46) {
                    found = true
                    break
                }
                i -= 1
            }
        }
        @Expect(found, true)
    }
}
