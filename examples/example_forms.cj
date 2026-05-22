/**
 * PDF-CJ 表单功能示例
 * 演示如何在 PDF 中添加可交互的表单字段：
 *   - 文本框（单行 / 多行）
 *   - 下拉框
 *   - 复选框
 *   - 单选按钮组
 *   - 按钮
 * 每个字段均调用 generateAppearance() 生成 /AP 外观字典，
 * 使 PDF 阅读器无需自行渲染字段外观。
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.form.PdfFormFieldFactory
import pdf_cj.text.{BaseFont, Font}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_BASE: BaseFont = BaseFont.createFont(NOTO_CJK_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)

func cjkFont(size: Float32): Font { Font(CJK_BASE, size) }

/**
 * 示例：创建带表单字段的 PDF（文本框、复选框、下拉框）
 *
 * 布局原理：
 *   1. 读取 writer.currentY（段落基线，即 Tf 绘制位置）
 *   2. 添加标签段落（leading=fontSize×1.5，之后 currentY 下移 leading 个点）
 *   3. 将表单字段放在标签右侧，垂直范围 = [currentY-2, y_before+2]，
 *      这样字段恰好与标签文字处于同一行
 */
public func exampleCreateForm(): Unit {
    try {
        println("\n示例：创建 PDF 交互表单（含外观生成）...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_forms_form.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let labelFont = cjkFont(12.0)
        let titleFont = cjkFont(16.0)
        let GAP:     Float32 = 6.0
        let FIELD_X: Float32 = 120.0

        // ── 标题 ───────────────────────────────────────────────
        document.add(Paragraph("PDF 交互表单示例", titleFont))
        document.add(Paragraph("请填写以下信息：", labelFont))
        document.add(Paragraph(" ", cjkFont(GAP)))

        // ── 姓名（文本框）─────────────────────────────────────
        var y0 = writer.currentY
        document.add(Paragraph("姓名：", labelFont))
        var fh = y0 - writer.currentY + 4.0
        var fy = writer.currentY - 2.0
        let nameField = PdfFormFieldFactory.createTextField("name", FIELD_X, fy, 220.0, fh)
        nameField.setValue("张三")
        nameField.generateAppearance()
        writer.addFormField(nameField)
        document.add(Paragraph(" ", cjkFont(GAP)))

        // ── 城市（下拉框）─────────────────────────────────────
        y0 = writer.currentY
        document.add(Paragraph("城市：", labelFont))
        fh = y0 - writer.currentY + 4.0
        fy = writer.currentY - 2.0
        let cityField = PdfFormFieldFactory.createComboBox("city", FIELD_X, fy, 160.0, fh)
        cityField.addOptions(["北京", "上海", "深圳", "杭州", "成都"])
        cityField.setValue("上海")
        cityField.generateAppearance()
        writer.addFormField(cityField)
        document.add(Paragraph(" ", cjkFont(GAP)))

        // ── 同意协议（复选框）────────────────────────────────
        y0 = writer.currentY
        document.add(Paragraph("同意用户协议：", labelFont))
        fh = y0 - writer.currentY + 4.0
        fy = writer.currentY - 2.0
        let agreeField = PdfFormFieldFactory.createCheckBox("agree", FIELD_X, fy, fh)
        agreeField.setChecked(true)
        agreeField.generateAppearance()
        writer.addFormField(agreeField)
        document.add(Paragraph(" ", cjkFont(GAP)))

        // ── 邮箱 ───────────────────────────────────────────────
        y0 = writer.currentY
        document.add(Paragraph("邮箱：", labelFont))
        fh = y0 - writer.currentY + 4.0
        fy = writer.currentY - 2.0
        let emailField = PdfFormFieldFactory.createTextField("email", FIELD_X, fy, 250.0, fh)
        emailField.setValue("zhangsan@example.com")
        emailField.generateAppearance()
        writer.addFormField(emailField)
        document.add(Paragraph(" ", cjkFont(GAP)))

        // ── 备注（多行文本框）────────────────────────────────
        document.add(Paragraph("备注（多行）：", labelFont))
        let NOTES_H: Float32 = 72.0
        fy = writer.currentY - 2.0
        let notesField = PdfFormFieldFactory.createTextField("notes", writer.marginLeft, fy - NOTES_H + fh, 400.0, NOTES_H)
        notesField.setMultiline(true)
        notesField.setValue("请在此输入备注信息...")
        notesField.generateAppearance()
        writer.addFormField(notesField)
        document.add(Paragraph(" ", cjkFont(NOTES_H)))
        document.add(Paragraph(" ", cjkFont(GAP)))

        // ── 性别（单选按钮组）────────────────────────────────
        y0 = writer.currentY
        document.add(Paragraph("性别：", labelFont))
        fh = y0 - writer.currentY + 4.0
        fy = writer.currentY - 2.0
        let genderField = PdfFormFieldFactory.createRadioButtonGroup("gender")
        // 两个 radio button 并排
        let RB_SIZE: Float32 = fh
        genderField.addOption("male",   Rectangle(FIELD_X,              fy, FIELD_X + RB_SIZE,              fy + RB_SIZE))
        genderField.addOption("female", Rectangle(FIELD_X + RB_SIZE + 30.0, fy, FIELD_X + RB_SIZE * 2.0 + 30.0, fy + RB_SIZE))
        genderField.selectOption("male")
        genderField.generateAppearance()
        writer.addFormField(genderField)
        // 标签（男 / 女）用固定坐标 Paragraph 方式简化处理
        document.add(Paragraph(" ", cjkFont(GAP)))

        // ── 操作按钮（提交 / 重置）───────────────────────────
        document.add(Paragraph("操作：", labelFont))
        let BTN_Y = writer.currentY - 2.0
        let BTN_H: Float32 = 20.0
        let BTN_W: Float32 = 60.0

        let submitBtn = PdfFormFieldFactory.createPushButton("submit", FIELD_X, BTN_Y, BTN_W, BTN_H, "Submit")
        submitBtn.generateAppearance()
        writer.addFormField(submitBtn)

        let resetBtn = PdfFormFieldFactory.createPushButton("reset", FIELD_X + BTN_W + 10.0, BTN_Y, BTN_W, BTN_H, "Reset")
        resetBtn.generateAppearance()
        writer.addFormField(resetBtn)

        document.close()
        file.close()

        println("  - 文本字段 (name, email, notes)：含 /AP 外观")
        println("  - 下拉框 (city)：含 /AP 外观")
        println("  - 复选框 (agree)：含 /AP 外观，已勾选")
        println("  - 单选按钮组 (gender)：male / female，默认选 male")
        println("  - 按钮 (submit, reset)：含 /AP 外观（灰色背景 + 文字）")
        println("✓ 成功创建: output/example_forms_form.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 主函数
 */
main(): Int64 {
    println("=== PDF-CJ 表单功能验证 ===\n")

    exampleCreateForm()

    println("\n=== 验证完成 ===")
    println("请检查 output/ 目录中的 PDF 文件")
    println("  example_forms_form.pdf - 文本框、下拉框、复选框、单选按钮、按钮")
    0
}
