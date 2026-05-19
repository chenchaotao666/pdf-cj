/**
 * PDF-CJ 表单、注释与书签功能示例
 * 演示如何在 PDF 中添加可交互的表单字段、注释标记和文档书签。
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.form.{
    PdfFormFieldFactory, PdfAnnotationFactory,
    PdfOutlineTree, PdfOutline, PdfDestination
}
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
 * 示例：添加文本注释、链接注释和高亮注释
 */
public func exampleAnnotations(): Unit {
    try {
        println("\n示例：添加注释...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_forms_annotations.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = cjkFont(12.0)

        document.add(Paragraph("PDF 注释示例", cjkFont(18.0)))
        document.add(Paragraph(" ", font))
        document.add(Paragraph("本文档演示三种注释类型。", font))
        document.add(Paragraph(" ", font))
        document.add(Paragraph("1. 文本注释（气泡图标）", font))
        document.add(Paragraph("   请查看页面右侧的注释图标。", font))

        // 文本注释（显示为气泡图标，点击后弹出文字）
        let textAnnot = PdfAnnotationFactory.createText(450.0, 700.0, "这是一条文本注释，可以附加说明信息。")
        textAnnot.setTitle("作者")
        textAnnot.setOpen(false)
        writer.addAnnotation(textAnnot)

        document.add(Paragraph(" ", font))
        document.add(Paragraph("2. 超链接注释（点击可打开网页）", font))
        document.add(Paragraph("   点击下方蓝色区域可访问网站。", font))

        // 链接注释（点击打开 URL）
        let linkRect = Rectangle(72.0, 620.0, 250.0, 640.0)
        let linkAnnot = PdfAnnotationFactory.createURLLink(linkRect, "https://www.example.com")
        linkAnnot.setHighlightMode("I")
        writer.addAnnotation(linkAnnot)

        document.add(Paragraph(" ", font))
        document.add(Paragraph("3. 高亮注释（标记重要文字）", font))
        document.add(Paragraph("   下方文字已被高亮标记为重要内容。", font))

        // 高亮注释（黄色高亮）
        let hlRect = Rectangle(72.0, 570.0, 320.0, 586.0)
        let quadPoints: Array<Float32> = [72.0, 570.0, 320.0, 570.0, 72.0, 586.0, 320.0, 586.0]
        let highlight = PdfAnnotationFactory.createHighlight(hlRect, quadPoints)
        highlight.setColor(1.0, 1.0, 0.0)
        writer.addAnnotation(highlight)

        document.close()
        file.close()

        println("  - 已添加文本注释、超链接注释、高亮注释")
        println("✓ 成功创建: output/example_forms_annotations.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例：创建多页文档并添加书签导航
 */
public func exampleOutlines(): Unit {
    try {
        println("\n示例：创建书签（大纲）...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_forms_outlines.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let titleFont = cjkFont(20.0)
        let headFont = cjkFont(16.0)
        let bodyFont = cjkFont(12.0)

        // --- 第一页：第一章 ---
        let page1Ref = writer.getCurrentPageReference()

        document.add(Paragraph("第一章  语言概述", titleFont))
        document.add(Paragraph(" ", bodyFont))
        document.add(Paragraph(
            "仓颉语言是华为推出的面向全场景应用开发的通用编程语言，支持多后端、多范式编程。",
            bodyFont))
        document.add(Paragraph(" ", bodyFont))

        // 第 1.1 节（仍在第一页）
        let sec11Ref = writer.getCurrentPageReference()
        document.add(Paragraph("1.1  设计目标", headFont))
        document.add(Paragraph(
            "仓颉以安全、高效、易用为核心设计目标，提供完善的并发支持和内存安全机制。",
            bodyFont))

        // --- 第二页：第二章 ---
        document.newPage()
        let page2Ref = writer.getCurrentPageReference()

        document.add(Paragraph("第二章  基本类型", titleFont))
        document.add(Paragraph(" ", bodyFont))
        document.add(Paragraph(
            "仓颉提供丰富的基本数据类型：整型（Int8/16/32/64）、浮点型（Float32/64）、布尔型（Bool）等。",
            bodyFont))
        document.add(Paragraph(" ", bodyFont))

        let sec21Ref = writer.getCurrentPageReference()
        document.add(Paragraph("2.1  整数类型", headFont))
        document.add(Paragraph("整数类型包括有符号和无符号两类，共 8 种。", bodyFont))
        document.add(Paragraph(" ", bodyFont))

        // --- 第三页：第三章 ---
        document.newPage()
        let page3Ref = writer.getCurrentPageReference()

        document.add(Paragraph("第三章  函数与闭包", titleFont))
        document.add(Paragraph(" ", bodyFont))
        document.add(Paragraph(
            "仓颉函数是一等公民，支持高阶函数、Lambda 表达式和闭包捕获。",
            bodyFont))

        // 构建书签树
        let tree = PdfOutlineTree()

        let ch1 = PdfOutline("第一章  语言概述", PdfDestination(page1Ref))
        ch1.setBold(true)
        tree.addOutline(ch1)
        ch1.addChild(PdfOutline("1.1  设计目标", PdfDestination(sec11Ref)))

        let ch2 = PdfOutline("第二章  基本类型", PdfDestination(page2Ref))
        ch2.setBold(true)
        tree.addOutline(ch2)
        ch2.addChild(PdfOutline("2.1  整数类型", PdfDestination(sec21Ref)))

        let ch3 = PdfOutline("第三章  函数与闭包", PdfDestination(page3Ref))
        ch3.setBold(true)
        tree.addOutline(ch3)

        writer.setOutlineTree(tree)

        document.close()
        file.close()

        println("  - 已添加书签：3 章，其中 2 章含子节")
        println("✓ 成功创建: output/example_forms_outlines.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 主函数
 */
main(): Int64 {
    println("=== PDF-CJ 表单、注释与书签功能示例 ===")

    exampleCreateForm()
    exampleAnnotations()
    exampleOutlines()

    println("\n=== 完成 ===")
    0
}
