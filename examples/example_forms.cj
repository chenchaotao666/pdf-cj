/**
 * PDF-CJ 表单功能示例
 * 演示如何在 PDF 中添加可交互的表单字段（文本框、复选框、下拉框）。
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.form.PdfFormFieldFactory
import pdf_cj.text.{BaseFont, Font}
import pdf_cj.util.PageSize
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
        println("\n示例：创建 PDF 交互表单...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_forms_form.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let labelFont = cjkFont(12.0)     // 标签字体
        let titleFont = cjkFont(16.0)
        let GAP:   Float32 = 6.0          // 行间距（段落 leading≈9pt）
        let FIELD_X: Float32 = 120.0      // 输入框起始 x（标签列约 90pt 宽）

        // ── 标题区 ─────────────────────────────────────────────
        document.add(Paragraph("PDF 交互表单示例", titleFont))
        document.add(Paragraph("请填写以下信息：", labelFont))
        document.add(Paragraph(" ", cjkFont(GAP)))

        // ── 辅助函数：记录行顶 Y，添加标签，返回字段所需的 (y_bottom, field_height) ──
        // 用法：
        //   let y0 = writer.currentY          // 行基线（标签绘制处）
        //   document.add(Paragraph(label, labelFont))
        //   let fh = y0 - writer.currentY + 4.0  // 字段高度 = leading + 4
        //   let fy = writer.currentY - 2.0        // 字段底边
        //   writer.addFormField(createXxx(name, FIELD_X, fy, w, fh))
        //   document.add(Paragraph(" ", cjkFont(GAP)))   // 行间距

        // ── 姓名 ───────────────────────────────────────────────
        var y0 = writer.currentY
        document.add(Paragraph("姓名：", labelFont))
        var fh = y0 - writer.currentY + 4.0
        var fy = writer.currentY - 2.0
        let nameField = PdfFormFieldFactory.createTextField("name", FIELD_X, fy, 220.0, fh)
        nameField.setValue("张三")
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
        writer.addFormField(cityField)
        document.add(Paragraph(" ", cjkFont(GAP)))

        // ── 同意协议（复选框）────────────────────────────────
        y0 = writer.currentY
        document.add(Paragraph("同意用户协议：", labelFont))
        fh = y0 - writer.currentY + 4.0
        fy = writer.currentY - 2.0
        let agreeField = PdfFormFieldFactory.createCheckBox("agree", FIELD_X, fy, fh)
        agreeField.setChecked(true)
        writer.addFormField(agreeField)
        document.add(Paragraph(" ", cjkFont(GAP)))

        // ── 邮箱 ───────────────────────────────────────────────
        y0 = writer.currentY
        document.add(Paragraph("邮箱：", labelFont))
        fh = y0 - writer.currentY + 4.0
        fy = writer.currentY - 2.0
        let emailField = PdfFormFieldFactory.createTextField("email", FIELD_X, fy, 250.0, fh)
        emailField.setValue("zhangsan@example.com")
        writer.addFormField(emailField)
        document.add(Paragraph(" ", cjkFont(GAP)))

        // ── 备注（多行文本框，标签在上，字段在下）───────────
        document.add(Paragraph("备注（多行）：", labelFont))
        // 字段紧接在标签下方，高度为 4 行
        let NOTES_H: Float32 = 72.0
        fy = writer.currentY - 2.0
        let notesField = PdfFormFieldFactory.createTextField("notes", writer.marginLeft, fy - NOTES_H + fh, 400.0, NOTES_H)
        notesField.setMultiline(true)
        notesField.setValue("请在此输入备注信息...")
        writer.addFormField(notesField)

        document.close()
        file.close()

        println("  - 已添加文本字段 (name, email, notes)、下拉框 (city)、复选框 (agree)")
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
    println("  example_forms_form.pdf - 文本框、下拉框、复选框")
    0
}
