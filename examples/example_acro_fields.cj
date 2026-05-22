/**
 * PDF-CJ AcroFields 示例（4.3）
 *
 * 演示两种使用场景：
 *
 * 1. 从头创建带 AcroForm 的 PDF（通过 PdfWriter），填写字段并生成外观
 * 2. 用 PdfStamper 打开已有 PDF，通过 AcroFields 修改字段值，以增量方式写回
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.form.PdfFormFieldFactory
import pdf_cj.reader.{PdfReader, PdfStamper, AcroFields}
import pdf_cj.base.PdfFileOutputStream
import pdf_cj.text.{BaseFont, Font}
import pdf_cj.util.PageSize
import std.collection.HashMap
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_PATH_AF = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_BASE_AF: BaseFont = BaseFont.createFont(NOTO_CJK_PATH_AF, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
func cjkFontAF(size: Float32): Font { Font(CJK_BASE_AF, size) }

// ═══════════════════════════════════════════════════════════════════════════
// 场景一：创建含表单的 PDF，通过 AcroFields 读取并重新填写字段
// ═══════════════════════════════════════════════════════════════════════════

/**
 * 步骤 1：创建带 AcroForm 字段的源 PDF
 */
func createFormPdfForAcro(outputPath: String): Unit {
    println("  [1/2] 创建源表单 PDF: ${outputPath}")
    let document = Document(PageSize.A4)
    let file = File(Path(outputPath), OpenMode.Write)
    let writer = PdfWriter.getInstance(document, file)
    document.open()

    let labelFont = cjkFontAF(12.0)
    let titleFont = cjkFontAF(16.0)
    let GAP: Float32 = 8.0
    let FIELD_X: Float32 = 130.0

    document.add(Paragraph("员工信息表（AcroFields 演示）", titleFont))
    document.add(Paragraph(" ", cjkFontAF(GAP)))

    // 姓名（文本框）
    var y0 = writer.currentY
    document.add(Paragraph("姓名：", labelFont))
    var fh = y0 - writer.currentY + 4.0
    var fy = writer.currentY - 2.0
    let nameField = PdfFormFieldFactory.createTextField("name", FIELD_X, fy, 200.0, fh)
    nameField.setValue("（待填写）")
    nameField.generateAppearance()
    writer.addFormField(nameField)
    document.add(Paragraph(" ", cjkFontAF(GAP)))

    // 部门（文本框）
    y0 = writer.currentY
    document.add(Paragraph("部门：", labelFont))
    fh = y0 - writer.currentY + 4.0
    fy = writer.currentY - 2.0
    let deptField = PdfFormFieldFactory.createTextField("dept", FIELD_X, fy, 200.0, fh)
    deptField.setValue("（待填写）")
    deptField.generateAppearance()
    writer.addFormField(deptField)
    document.add(Paragraph(" ", cjkFontAF(GAP)))

    // 职级（下拉框）
    y0 = writer.currentY
    document.add(Paragraph("职级：", labelFont))
    fh = y0 - writer.currentY + 4.0
    fy = writer.currentY - 2.0
    let rankField = PdfFormFieldFactory.createComboBox("rank", FIELD_X, fy, 160.0, fh)
    rankField.addOptions(["P4", "P5", "P6", "P7", "P8"])
    rankField.setValue("P5")
    rankField.generateAppearance()
    writer.addFormField(rankField)
    document.add(Paragraph(" ", cjkFontAF(GAP)))

    // 在职状态（复选框）
    y0 = writer.currentY
    document.add(Paragraph("在职：", labelFont))
    fh = y0 - writer.currentY + 4.0
    fy = writer.currentY - 2.0
    let activeField = PdfFormFieldFactory.createCheckBox("active", FIELD_X, fy, fh)
    activeField.setChecked(false)
    activeField.generateAppearance()
    writer.addFormField(activeField)
    document.add(Paragraph(" ", cjkFontAF(GAP)))

    document.close()
    file.close()
    println("     字段：name（文本）、dept（文本）、rank（下拉）、active（复选框）")
}

/**
 * 步骤 2：用 PdfStamper + AcroFields 增量填写字段并重新生成外观
 */
func fillFormWithAcroFields(sourcePath: String, outputPath: String): Unit {
    println("  [2/2] 通过 AcroFields 填写字段并写入: ${outputPath}")

    let reader = PdfReader(sourcePath)
    let outFile = File(Path(outputPath), OpenMode.Write)
    let os = PdfFileOutputStream(outFile)
    let stamper = PdfStamper(reader, os)

    let fields = stamper.getAcroFields()

    println("     PDF 中共有 ${fields.getFieldCount()} 个字段")
    println("     原字段值：")
    let names = fields.getFieldNames()
    for (i in 0..names.size) {
        let n = names[i]
        let v = match (fields.getField(n)) {
            case Some(val) => val
            case None => "(空)"
        }
        println("       ${n} = ${v}")
    }

    // 填写新值
    fields.setField("name",   "李四")
    fields.setField("dept",   "研发部")
    fields.setField("rank",   "P6")
    fields.setField("active", "Yes")   // 复选框勾选

    // 重新生成外观流
    fields.generateAppearances()

    println("     已设置：name=李四 / dept=研发部 / rank=P6 / active=Yes")

    stamper.close()
    outFile.close()
}

/**
 * 场景一主函数
 */
public func exampleAcroFieldsFillForm(): Unit {
    try {
        println("\n场景一：创建表单 PDF → 用 AcroFields 增量填写...")
        createFormPdfForAcro("output/example_acro_source_form.pdf")
        fillFormWithAcroFields("output/example_acro_source_form.pdf", "output/example_acro_filled_form.pdf")
        println("✓ 场景一完成")
        println("  example_acro_source_form.pdf  — 原始空表单")
        println("  example_acro_filled_form.pdf  — 增量填写后的表单")
    } catch (e: Exception) {
        println("✗ 场景一错误: ${e.message}")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// 场景二：演示 AcroFields API（无需真实 PDF）
// ═══════════════════════════════════════════════════════════════════════════

/**
 * 在内存 PDF 上演示 AcroFields 读写 API
 */
public func exampleAcroFieldsAPI(): Unit {
    println("\n场景二：AcroFields API 演示（内存 PDF）...")

    // 构建最小带 AcroForm 的测试 PDF
    let pdfData = buildTestPdf()
    let reader = PdfReader(pdfData)
    let fields = reader.getAcroFields()

    println("  字段数量: ${fields.getFieldCount()}")

    // 读取字段值
    let usernameOpt = fields.getField("username")
    match (usernameOpt) {
        case Some(v) => println("  username 当前值: ${v}")
        case None    => println("  username: 字段不存在")
    }

    // 设置字段值
    let ok = fields.setField("username", "张伟")
    println("  setField(\"username\", \"张伟\") → ${ok}")
    println("  username 新值: ${fields.getField("username").getOrThrow()}")

    // 导出所有字段
    let data = fields.exportFormData()
    println("  exportFormData() 返回 ${data.size} 条记录")

    // 批量导入
    let importData = HashMap<String, String>()
    importData["username"] = "王芳"
    fields.importFormData(importData)
    println("  importFormData 后 username = ${fields.getField("username").getOrThrow()}")

    // validateRequiredFields
    println("  validateRequiredFields() = ${fields.validateRequiredFields()}")

    // 重置
    fields.resetAllFields()
    println("  resetAllFields() 后 username = \"${fields.getField("username").getOrThrow()}\"（空，无 /DV）")

    println("✓ 场景二完成")
}

// ═══════════════════════════════════════════════════════════════════════════
// 内存 PDF 构建辅助
// ═══════════════════════════════════════════════════════════════════════════

func buildTestPdf(): Array<UInt8> {
    var s = "%PDF-1.4\n"
    let off1 = Int64(s.size)
    s += "1 0 obj\n<< /Type /Catalog /Pages 2 0 R /AcroForm 5 0 R >>\nendobj\n"
    let off2 = Int64(s.size)
    s += "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"
    let off3 = Int64(s.size)
    s += "3 0 obj\n<< /Type /Page /MediaBox [0 0 595 842] /Parent 2 0 R /Contents 4 0 R >>\nendobj\n"
    let off4 = Int64(s.size)
    s += "4 0 obj\n<< /Length 6 >>\nstream\nBT ET\nendstream\nendobj\n"
    let off5 = Int64(s.size)
    s += "5 0 obj\n<< /Fields [6 0 R] >>\nendobj\n"
    let off6 = Int64(s.size)
    s += "6 0 obj\n<< /FT /Tx /T (username) /V (Alice) /Rect [100 700 300 720] >>\nendobj\n"
    let xrefOff = Int64(s.size)
    s += "xref\n0 7\n" +
        "0000000000 65535 f \r\n" +
        acroL10AF(off1) + " 00000 n \r\n" +
        acroL10AF(off2) + " 00000 n \r\n" +
        acroL10AF(off3) + " 00000 n \r\n" +
        acroL10AF(off4) + " 00000 n \r\n" +
        acroL10AF(off5) + " 00000 n \r\n" +
        acroL10AF(off6) + " 00000 n \r\n" +
        "trailer\n<< /Size 7 /Root 1 0 R >>\n" +
        "startxref\n${xrefOff}\n%%EOF\n"
    let arr = Array<UInt8>(s.size, repeat: 0)
    var i = 0
    for (r in s.runes()) {
        arr[i] = UInt8(UInt32(r))
        i += 1
    }
    arr
}

func acroL10AF(n: Int64): String {
    var s = "${n}"
    while (s.size < 10) { s = "0" + s }
    s
}

// ═══════════════════════════════════════════════════════════════════════════
// 主函数
// ═══════════════════════════════════════════════════════════════════════════

main(): Int64 {
    println("=== PDF-CJ AcroFields 示例 ===\n")

    exampleAcroFieldsAPI()
    exampleAcroFieldsFillForm()

    println("\n=== 完成 ===")
    println("请检查 output/ 目录：")
    println("  example_acro_source_form.pdf  — 含 AcroForm 的原始表单")
    println("  example_acro_filled_form.pdf  — AcroFields 增量填写后的结果")
    0
}
