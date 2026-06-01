package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.form.PdfFormFieldFactory
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let _s13_OUT = "output/"

// Draw a label at absolute position using PdfContentByte
func s13Label(cb: PdfContentByte, helvBf: BaseFont, helvName: String, text: String, x: Float32, y: Float32): Unit {
    cb.beginText()
    cb.setFontAndSize(helvBf, helvName, 11.0)
    cb.setColorFill(Color(0, 0, 0))
    cb.setTextMatrix(x, y)
    cb.showText(text, false, Some(helvBf))
    cb.endText()
}

func s13_formField(): Unit {
    println("S13: Form Field Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s13_OUT + "cj_s13_formfield.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        let cb = writer.getDirectContent()
        let helvName = writer.addFont(helvBf)
        let cjkName = writer.addFont(cjkBf)

        // Title
        cb.beginText()
        cb.setFontAndSize(cjkBf, cjkName, 18.0)
        cb.setColorFill(Color(0, 0, 0))
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER, "S13: Form Field Demo", 297.0, 780.0, 0.0)
        cb.endText()

        cb.beginText()
        cb.setFontAndSize(helvBf, helvName, 11.0)
        cb.setColorFill(Color(0, 0, 0))
        cb.setTextMatrix(72.0, 755.0)
        cb.showText("Each type: (a) default settings  (b) custom settings.", false, Some(helvBf))
        cb.endText()

        let labelX: Float32 = 72.0
        let fieldX: Float32 = 200.0
        let fieldW: Float32 = 280.0
        var yPos: Float32 = 720.0

        // ---- 1. Text Field ----
        s13Label(cb, helvBf, helvName, "1a. Text Field (default):", labelX, yPos + 5.0)
        try {
            let tf1a = PdfFormFieldFactory.createTextField("tf_default", fieldX, yPos - 18.0, fieldW, 18.0)
            tf1a.setText("Default text")
            writer.addFormField(tf1a)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }
        yPos -= 32.0

        s13Label(cb, helvBf, helvName, "1b. Text Field (custom: size=11, gray border, light-blue bg):", labelX, yPos + 5.0)
        try {
            let tf1b = PdfFormFieldFactory.createTextField("tf_custom", fieldX, yPos - 18.0, fieldW, 18.0)
            tf1b.setText("Custom text")
            tf1b.setFontSize(11.0)
            tf1b.setBorderColor(128, 128, 128)
            tf1b.setBackgroundColor(240, 248, 255)
            writer.addFormField(tf1b)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }
        yPos -= 38.0

        // ---- 2. Multiline Text Field ----
        s13Label(cb, helvBf, helvName, "2a. Multiline (default):", labelX, yPos + 5.0)
        try {
            let tf2a = PdfFormFieldFactory.createTextField("ml_default", fieldX, yPos - 42.0, fieldW, 42.0)
            tf2a.setText("Line 1\nLine 2\nLine 3")
            tf2a.setMultiline(true)
            writer.addFormField(tf2a)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }
        yPos -= 55.0

        s13Label(cb, helvBf, helvName, "2b. Multiline (custom: size=10, gray border, light-yellow bg):", labelX, yPos + 5.0)
        try {
            let tf2b = PdfFormFieldFactory.createTextField("ml_custom", fieldX, yPos - 42.0, fieldW, 42.0)
            tf2b.setText("Line 1\nLine 2\nLine 3")
            tf2b.setFontSize(10.0)
            tf2b.setMultiline(true)
            tf2b.setBorderColor(128, 128, 128)
            tf2b.setBackgroundColor(255, 255, 240)
            writer.addFormField(tf2b)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }
        yPos -= 58.0

        // ---- 3. Checkbox ----
        s13Label(cb, helvBf, helvName, "3a. Checkbox (default, checked):", labelX, yPos + 5.0)
        try {
            let cb3a = PdfFormFieldFactory.createCheckBox("cb_default", fieldX, yPos - 16.0, 16.0)
            cb3a.setChecked(true)
            writer.addFormField(cb3a)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }
        yPos -= 28.0

        s13Label(cb, helvBf, helvName, "3b. Checkbox (custom: black border, white bg, unchecked):", labelX, yPos + 5.0)
        try {
            let cb3b = PdfFormFieldFactory.createCheckBox("cb_custom", fieldX, yPos - 16.0, 16.0)
            cb3b.setChecked(false)
            cb3b.setBorderColor(0, 0, 0)
            cb3b.setBackgroundColor(255, 255, 255)
            writer.addFormField(cb3b)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }
        yPos -= 35.0

        // ---- 4. Radio Button Group ----
        s13Label(cb, helvBf, helvName, "4a. Radio Group (default):", labelX, yPos + 5.0)
        try {
            let rg4a = PdfFormFieldFactory.createRadioButtonGroup("radio_default")
            rg4a.addOption("A", Rectangle(fieldX, yPos - 16.0, fieldX + 16.0, yPos))
            rg4a.addOption("B", Rectangle(fieldX, yPos - 34.0, fieldX + 16.0, yPos - 18.0))
            rg4a.addOption("C", Rectangle(fieldX, yPos - 52.0, fieldX + 16.0, yPos - 36.0))
            rg4a.selectOption("A")
            writer.addFormField(rg4a)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }
        yPos -= 65.0

        s13Label(cb, helvBf, helvName, "4b. Radio Group (custom: black border, white bg):", labelX, yPos + 5.0)
        try {
            let rg4b = PdfFormFieldFactory.createRadioButtonGroup("radio_custom")
            rg4b.addOption("A", Rectangle(fieldX, yPos - 16.0, fieldX + 16.0, yPos), 0, 0, 0, 255, 255, 255)
            rg4b.addOption("B", Rectangle(fieldX, yPos - 34.0, fieldX + 16.0, yPos - 18.0), 0, 0, 0, 255, 255, 255)
            rg4b.addOption("C", Rectangle(fieldX, yPos - 52.0, fieldX + 16.0, yPos - 36.0), 0, 0, 0, 255, 255, 255)
            rg4b.selectOption("A")
            writer.addFormField(rg4b)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }
        yPos -= 68.0

        // ---- 5. Combo Box ----
        s13Label(cb, helvBf, helvName, "5a. Combo Box (default):", labelX, yPos + 5.0)
        try {
            let cb5a = PdfFormFieldFactory.createComboBox("combo_default", fieldX, yPos - 18.0, fieldW, 18.0)
            cb5a.addOptions(["Apple", "Banana", "Cherry"])
            cb5a.setValue("Apple")
            writer.addFormField(cb5a)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }
        yPos -= 30.0

        s13Label(cb, helvBf, helvName, "5b. Combo Box (custom: size=10, gray border):", labelX, yPos + 5.0)
        try {
            let cb5b = PdfFormFieldFactory.createComboBox("combo_custom", fieldX, yPos - 18.0, fieldW, 18.0)
            cb5b.addOptions(["Apple", "Banana", "Cherry"])
            cb5b.setValue("Apple")
            cb5b.setBorderColor(128, 128, 128)
            writer.addFormField(cb5b)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }
        yPos -= 35.0

        // ---- 6. List Box ----
        s13Label(cb, helvBf, helvName, "6a. List Box (default):", labelX, yPos + 5.0)
        try {
            let lb6a = PdfFormFieldFactory.createListBox("list_default", fieldX, yPos - 48.0, fieldW, 48.0)
            lb6a.addOptions(["Red", "Green", "Blue"])
            lb6a.setValue("Red")
            writer.addFormField(lb6a)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }
        yPos -= 62.0

        s13Label(cb, helvBf, helvName, "6b. List Box (custom: multiselect, gray border):", labelX, yPos + 5.0)
        try {
            let lb6b = PdfFormFieldFactory.createListBox("list_custom", fieldX, yPos - 48.0, fieldW, 48.0)
            lb6b.addOptions(["Red", "Green", "Blue"])
            lb6b.setValue("Green")
            lb6b.setMultiSelect(true)
            lb6b.setBorderColor(128, 128, 128)
            writer.addFormField(lb6b)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }
        yPos -= 65.0

        // ---- 7. Push Button ----
        s13Label(cb, helvBf, helvName, "7a. Push Button (default: outline):", labelX, yPos + 5.0)
        try {
            let btn7a = PdfFormFieldFactory.createPushButton("btn_default", fieldX, yPos - 20.0, 120.0, 20.0, "Click Me!")
            btn7a.setFilled(false)
            writer.addFormField(btn7a)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }
        yPos -= 32.0

        s13Label(cb, helvBf, helvName, "7b. Push Button (custom: blue bg):", labelX, yPos + 5.0)
        try {
            let btn7b = PdfFormFieldFactory.createPushButton("btn_custom", fieldX, yPos - 20.0, 120.0, 20.0, "Click Me!")
            writer.addFormField(btn7b)
        } catch (e: Exception) { s13Label(cb, helvBf, helvName, "error: ${e.message}", labelX, yPos - 10.0) }

        doc.close()
        println("  S13 done: ${_s13_OUT}cj_s13_formfield.pdf")
    } catch (e: Exception) {
        println("  ✗ S13: ${e.message}")
    }
}
