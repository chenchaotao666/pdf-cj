package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.form.PdfFormFieldFactory
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let _s13_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s13_OUT  = "output/"



func s13_formField(): Unit {
    println("S13: Form Field Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s13_OUT + "cj_s13_formfield.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        var title = Paragraph("S13: Form Field Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)
        doc.add(Paragraph("This PDF contains interactive form fields.", Font(helvBf, 11.0)))

        let fieldX: Float32 = 200.0
        let fieldW: Float32 = 280.0
        var yPos: Float32 = 720.0

        // 1. Text field (single line)
        try {
            doc.add(Paragraph(" ", Font(helvBf, 4.0)))
            doc.add(Paragraph("1. Text Field (single line):", Font(helvBf, 11.0)))
            let tf = PdfFormFieldFactory.createTextField("textField1", fieldX, yPos - 20.0, fieldW, 20.0)
            tf.setValue("Default text value")
            tf.generateAppearance()
            writer.addFormField(tf)
            yPos -= 40.0
        } catch (e: Exception) {
            doc.add(Paragraph("1. TextField error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 2. Multiline text field
        try {
            doc.add(Paragraph("2. Text Field (multiline):", Font(helvBf, 11.0)))
            let mlTf = PdfFormFieldFactory.createTextField("multilineField", fieldX, yPos - 60.0, fieldW, 60.0)
            mlTf.setValue("Line 1\nLine 2\nLine 3")
            mlTf.generateAppearance()
            writer.addFormField(mlTf)
            yPos -= 80.0
        } catch (e: Exception) {
            doc.add(Paragraph("2. Multiline TextField error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 3. Checkbox (checked)
        try {
            doc.add(Paragraph("3. Checkbox (checked):", Font(helvBf, 11.0)))
            let cb = PdfFormFieldFactory.createCheckBox("checkbox1", fieldX, yPos - 20.0, 14.0)
            cb.generateAppearance()
            writer.addFormField(cb)
            yPos -= 35.0
        } catch (e: Exception) {
            doc.add(Paragraph("3. Checkbox error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 4. Checkbox (unchecked)
        try {
            doc.add(Paragraph("4. Checkbox (unchecked):", Font(helvBf, 11.0)))
            let cb2 = PdfFormFieldFactory.createCheckBox("checkbox2", fieldX, yPos - 20.0, 14.0)
            cb2.generateAppearance()
            writer.addFormField(cb2)
            yPos -= 35.0
        } catch (e: Exception) {
            doc.add(Paragraph("4. Checkbox unchecked error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 5. Radio button group
        try {
            doc.add(Paragraph("5. Radio Button Group:", Font(helvBf, 11.0)))
            let radioGroup = PdfFormFieldFactory.createRadioButtonGroup("radioGroup1")
            radioGroup.addOption("Option A", Rectangle(fieldX, yPos - 18.0, fieldX + 14.0, yPos))
            radioGroup.addOption("Option B", Rectangle(fieldX, yPos - 43.0, fieldX + 14.0, yPos - 25.0))
            radioGroup.addOption("Option C", Rectangle(fieldX, yPos - 68.0, fieldX + 14.0, yPos - 50.0))
            radioGroup.selectOption("Option A")
            radioGroup.generateAppearance()
            writer.addFormField(radioGroup)
            yPos -= 90.0
        } catch (e: Exception) {
            doc.add(Paragraph("5. Radio button error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 6. Combo box (dropdown)
        try {
            doc.add(Paragraph("6. Combo Box (dropdown):", Font(helvBf, 11.0)))
            let combo = PdfFormFieldFactory.createComboBox("comboField1", fieldX, yPos - 20.0, fieldW, 20.0)
            combo.addOptions(["-- Select --", "Apple", "Banana", "Cherry", "Date"])
            combo.setValue("-- Select --")
            combo.generateAppearance()
            writer.addFormField(combo)
            yPos -= 35.0
        } catch (e: Exception) {
            doc.add(Paragraph("6. Combo box error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 7. List box
        try {
            doc.add(Paragraph("7. List Box:", Font(helvBf, 11.0)))
            let listbox = PdfFormFieldFactory.createListBox("listField1", fieldX, yPos - 70.0, fieldW, 70.0)
            listbox.addOptions(["Red", "Green", "Blue", "Yellow", "Purple"])
            writer.addFormField(listbox)
            yPos -= 90.0
        } catch (e: Exception) {
            doc.add(Paragraph("7. List box error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 8. Push button
        try {
            doc.add(Paragraph("8. Push Button:", Font(helvBf, 11.0)))
            let btn = PdfFormFieldFactory.createPushButton("pushButton1", fieldX, yPos - 24.0, 120.0, 24.0, "Submit 提交")
            btn.generateAppearance()
            writer.addFormField(btn)
            yPos -= 40.0
        } catch (e: Exception) {
            doc.add(Paragraph("8. Push button error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 9. CJK text field
        try {
            doc.add(Paragraph("9. CJK Text Field (中文输入):", Font(cjkBf, 11.0)))
            let cjkTf = PdfFormFieldFactory.createTextField("cjkField", fieldX, yPos - 20.0, fieldW, 20.0)
            cjkTf.setValue("请输入中文内容")
            cjkTf.generateAppearance()
            writer.addFormField(cjkTf)
        } catch (e: Exception) {
            doc.add(Paragraph("9. CJK TextField error: ${e.message}", Font(helvBf, 10.0)))
        }

        doc.close()
        println("  S13 done: ${_s13_OUT}cj_s13_formfield.pdf")
    } catch (e: Exception) {
        println("  ✗ S13: ${e.message}")
    }
}
