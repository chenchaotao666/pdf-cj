/**
 * PDF-CJ 表单功能验证示例
 */
package pdf_cj_examples

import pdf_cj.api.Document
import pdf_cj.core.PdfWriter
import pdf_cj.form.*
import pdf_cj.util.{PageSize, Rectangle}
import std.io.{File, FileMode}
import std.fs.Path

/**
 * 示例：创建表单字段
 */
public func exampleCreateForm(): Unit {
    try {
        println("\n示例：创建 PDF 表单...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_form.pdf"), FileMode.Write)
        let writer = PdfWriter.getInstance(document, file)

        document.open()

        // 添加说明文字
        println("  - 添加表单说明...")

        // 创建文本字段
        println("  - 创建文本字段...")
        let textField = PdfFormFieldFactory.createTextField(
            "name",
            100.0, 700.0, 200.0, 25.0
        )
        textField.setValue("请输入姓名")

        // 创建复选框
        println("  - 创建复选框...")
        let checkBox = PdfFormFieldFactory.createCheckBox(
            "agree",
            100.0, 650.0, 20.0
        )
        checkBox.setChecked(false)

        // 创建下拉框
        println("  - 创建下拉框...")
        let comboBox = PdfFormFieldFactory.createComboBox(
            "city",
            100.0, 600.0, 150.0, 25.0
        )
        comboBox.addOptions(Array<String>(3, item: i => {
            if (i == 0) { "北京" }
            else if (i == 1) { "上海" }
            else { "深圳" }
        }))

        document.close()
        file.close()

        println("✓ 成功创建表单: output/example_form.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例：添加注释
 */
public func exampleAnnotations(): Unit {
    try {
        println("\n示例：添加注释...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_annotations.pdf"), FileMode.Write)
        let writer = PdfWriter.getInstance(document, file)

        document.open()

        // 创建文本注释
        println("  - 创建文本注释...")
        let textAnnot = PdfAnnotationFactory.createText(
            100.0, 700.0,
            "这是一个文本注释"
        )

        // 创建链接注释
        println("  - 创建超链接...")
        let linkRect = Rectangle(100.0, 650.0, 300.0, 670.0)
        let linkAnnot = PdfAnnotationFactory.createURLLink(
            linkRect,
            "https://www.example.com"
        )

        // 创建高亮注释
        println("  - 创建高亮标记...")
        let highlightRect = Rectangle(100.0, 600.0, 300.0, 620.0)
        let quadPoints = Array<Float32>(8, item: i => {
            if (i == 0) { 100.0 }
            else if (i == 1) { 600.0 }
            else if (i == 2) { 300.0 }
            else if (i == 3) { 600.0 }
            else if (i == 4) { 100.0 }
            else if (i == 5) { 620.0 }
            else if (i == 6) { 300.0 }
            else { 620.0 }
        })
        let highlight = PdfAnnotationFactory.createHighlight(
            highlightRect,
            quadPoints
        )

        document.close()
        file.close()

        println("✓ 成功创建注释: output/example_annotations.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例：创建书签
 */
public func exampleOutlines(): Unit {
    try {
        println("\n示例：创建书签...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_outlines.pdf"), FileMode.Write)
        let writer = PdfWriter.getInstance(document, file)

        document.open()

        // 创建书签树
        println("  - 创建书签结构...")
        let outlineTree = PdfOutlineTree()

        // 创建一级书签
        let chapter1Dest = PdfDestination(PdfIndirectReference(1))
        let chapter1 = PdfOutline("第一章", chapter1Dest)
        outlineTree.addOutline(chapter1)

        // 创建二级书签
        let section1Dest = PdfDestination(PdfIndirectReference(2))
        let section1 = PdfOutline("1.1 节", section1Dest)
        chapter1.addChild(section1)

        println("  - 书签数量: ${outlineTree.getOutlineCount()}")

        document.close()
        file.close()

        println("✓ 成功创建书签: output/example_outlines.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 主函数
 */
main(): Int64 {
    println("=== PDF-CJ 表单和交互功能验证 ===")

    exampleCreateForm()
    exampleAnnotations()
    exampleOutlines()

    println("\n=== 验证完成 ===")
    0
}
