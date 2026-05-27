package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}
import std.math.{sin, cos}

let _s09_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s09_OUT  = "output/"



func s09_drawing(): Unit {
    println("S09: PdfContentByte Drawing Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path(_s09_OUT + "cj_s09_drawing.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        let cb = writer.getDirectContent()
        let _s09_HELV_NAME = writer.addFont(helvBf)
        let _s09_CJK_NAME = writer.addFont(cjkBf)

        // Page 1: Lines, curves, shapes
        cb.beginText()
        cb.setFontAndSize(helvBf, _s09_HELV_NAME, 16.0)
        cb.setTextMatrix(50.0, 800.0)
        cb.showText("S09: PdfContentByte Drawing Demo — Page 1")
        cb.endText()

        // 1. Basic line with saveState/restoreState
        cb.saveState()
        cb.setLineWidth(2.0)
        cb.setColorStroke(Color(220, 0, 0))
        cb.moveTo(50.0, 770.0)
        cb.lineTo(300.0, 770.0)
        cb.stroke()
        cb.restoreState()

        // 2. Line dash patterns
        cb.saveState()
        cb.setLineWidth(2.0)
        cb.setColorStroke(Color(0, 0, 0))
        cb.setLineDash(5.0)
        cb.moveTo(50.0, 750.0)
        cb.lineTo(300.0, 750.0)
        cb.stroke()

        cb.setLineDash(8.0, 4.0, 0.0)
        cb.moveTo(50.0, 735.0)
        cb.lineTo(300.0, 735.0)
        cb.stroke()

        cb.setLineDash([Float32(10.0), Float32(3.0), Float32(3.0), Float32(3.0)], 0.0)
        cb.moveTo(50.0, 720.0)
        cb.lineTo(300.0, 720.0)
        cb.stroke()
        cb.restoreState()

        // 3. Line cap styles
        cb.saveState()
        cb.setLineWidth(8.0)
        let caps: Array<Int32> = [0i32, 1i32, 2i32]  // LINE_CAP_BUTT=0, LINE_CAP_ROUND=1, LINE_CAP_PROJECTING_SQUARE=2
        let capColors = [Color(0, 0, 180), Color(0, 0, 140), Color(0, 0, 100)]
        for (i in 0..3) {
            cb.setLineCap(caps[i])
            cb.setColorStroke(capColors[i])
            cb.moveTo(Float32(50 + i * 120), 695.0)
            cb.lineTo(Float32(120 + i * 120), 695.0)
            cb.stroke()
        }
        cb.restoreState()

        // 4. Curves (curveTo)
        cb.saveState()
        cb.setLineWidth(2.0)
        cb.setColorStroke(Color(0, 150, 0))
        cb.moveTo(50.0, 670.0)
        cb.curveTo(100.0, 690.0, 200.0, 650.0, 250.0, 670.0)
        cb.stroke()
        cb.restoreState()

        // 5. Fill and stroke operations
        cb.saveState()
        // Rectangle fill
        cb.setColorFill(Color(255, 200, 100))
        cb.setColorStroke(Color(200, 100, 0))
        cb.setLineWidth(2.0)
        cb.rectangle(50.0, 610.0, 80.0, 50.0)
        cb.fillStroke()

        // Ellipse fill
        cb.setColorFill(Color(150, 200, 255))
        cb.setColorStroke(Color(0, 100, 200))
        cb.ellipse(150.0, 610.0, 250.0, 660.0)
        cb.fillStroke()

        // Rounded rectangle
        cb.setColorFill(Color(200, 255, 150))
        cb.setColorStroke(Color(100, 200, 0))
        cb.roundRectangle(270.0, 610.0, 80.0, 50.0, 10.0)
        cb.fillStroke()
        cb.restoreState()

        // 6. Arc
        cb.saveState()
        cb.setColorStroke(Color(200, 0, 200))
        cb.setLineWidth(2.0)
        cb.arc(50.0, 550.0, 150.0, 600.0, 0.0, 270.0)
        cb.stroke()
        cb.restoreState()

        // 7. Colors: RGB, CMYK, gray
        cb.saveState()
        // RGB fill
        cb.setColorFill(Color(255, 100, 100))
        cb.rectangle(50.0, 510.0, 60.0, 30.0)
        cb.fill()

        // Gray fill
        cb.setGrayFill(0.6)
        cb.rectangle(120.0, 510.0, 60.0, 30.0)
        cb.fill()

        // CMYK fill — params are Float32 0.0-1.0
        cb.setCMYKColorFill(Float32(0.0), Float32(0.5), Float32(1.0), Float32(0.0))
        cb.rectangle(190.0, 510.0, 60.0, 30.0)
        cb.fill()

        cb.setColorFill(Color(100, 100, 255))
        cb.rectangle(260.0, 510.0, 60.0, 30.0)
        cb.fill()
        cb.restoreState()

        // 8. Text operations
        cb.saveState()
        cb.beginText()
        cb.setFontAndSize(helvBf, _s09_HELV_NAME, 14.0)
        cb.setColorFill(Color(0, 0, 0))
        cb.setTextMatrix(50.0, 480.0)
        cb.showText("8. showText at matrix position")
        cb.endText()

        cb.beginText()
        cb.setFontAndSize(helvBf, _s09_HELV_NAME, 12.0)
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER, "Centered text at (300, 460)", 300.0, 460.0, 0.0)
        cb.showTextAligned(PdfContentByte.ALIGN_RIGHT, "Right-aligned text", 500.0, 445.0, 0.0)
        cb.endText()
        cb.restoreState()

        // 9. Character spacing and word spacing
        cb.saveState()
        cb.beginText()
        cb.setFontAndSize(helvBf, _s09_HELV_NAME, 11.0)
        cb.setCharacterSpacing(2.0)
        cb.setWordSpacing(5.0)
        cb.setTextMatrix(50.0, 420.0)
        cb.showText("9. CharSpacing=2 WordSpacing=5 demo text")
        cb.endText()
        cb.restoreState()

        // 10. concatCTM / save-restore for transformation
        cb.saveState()
        cb.concatCTM(1.0, 0.0, 0.0, 1.0, 50.0, 380.0)
        cb.setColorFill(Color(200, 200, 50))
        cb.rectangle(0.0, 0.0, 100.0, 30.0)
        cb.fill()
        cb.beginText()
        cb.setFontAndSize(helvBf, _s09_HELV_NAME, 10.0)
        cb.setColorFill(Color(0, 0, 0))
        cb.setTextMatrix(5.0, 10.0)
        cb.showText("10. concatCTM translation")
        cb.endText()
        cb.restoreState()

        // 11. Clipping path
        cb.saveState()
        cb.rectangle(320.0, 350.0, 200.0, 80.0)
        cb.clip()
        cb.newPath()
        // Fill large area - only visible within clip
        cb.setColorFill(Color(255, 200, 100))
        cb.rectangle(300.0, 330.0, 250.0, 120.0)
        cb.fill()
        cb.setColorFill(Color(0, 100, 200))
        cb.ellipse(350.0, 360.0, 500.0, 420.0)
        cb.fill()
        cb.beginText()
        cb.setFontAndSize(helvBf, _s09_HELV_NAME, 12.0)
        cb.setColorFill(Color(255, 255, 255))
        cb.setTextMatrix(330.0, 382.0)
        cb.showText("11. Clip path demo")
        cb.endText()
        cb.restoreState()

        // Page 2: More drawing
        doc.newPage()

        cb.beginText()
        cb.setFontAndSize(helvBf, _s09_HELV_NAME, 16.0)
        cb.setTextMatrix(50.0, 800.0)
        cb.showText("S09: PdfContentByte Drawing Demo — Page 2")
        cb.endText()

        // 12. Star polygon (moveTo/lineTo path)
        cb.saveState()
        cb.setColorFill(Color(255, 200, 0))
        cb.setColorStroke(Color(200, 100, 0))
        cb.setLineWidth(1.5)
        let cx: Float32 = 150.0
        let cy: Float32 = 720.0
        let r: Float32 = 50.0
        cb.moveTo(cx, cy + r)
        for (i in 1..5) {
            let angle1 = Float64(i) * 4.0 * 3.14159 / 5.0 - 3.14159 / 2.0
            cb.lineTo(cx + r * Float32(sin(angle1)), cy + r * Float32(cos(angle1)))
        }
        cb.closePath()
        cb.fillStroke()
        cb.restoreState()

        // 13. CJK text via cb
        cb.saveState()
        cb.beginText()
        cb.setFontAndSize(cjkBf, _s09_CJK_NAME, 16.0)
        cb.setColorFill(Color(0, 80, 160))
        cb.setTextMatrix(50.0, 660.0)
        cb.showText("13. CJK文字直接绘制: 仓颉PDF库")
        cb.endText()
        cb.restoreState()

        // 14. Line join styles
        cb.saveState()
        cb.setLineWidth(6.0)
        let joins: Array<Int32> = [0i32, 1i32, 2i32]  // LINE_JOIN_MITER=0, LINE_JOIN_ROUND=1, LINE_JOIN_BEVEL=2
        let joinColors = [Color(180, 0, 0), Color(140, 0, 0), Color(100, 0, 0)]
        for (i in 0..3) {
            cb.setLineJoin(joins[i])
            cb.setColorStroke(joinColors[i])
            cb.moveTo(Float32(50 + i * 150), 620.0)
            cb.lineTo(Float32(100 + i * 150), 640.0)
            cb.lineTo(Float32(150 + i * 150), 620.0)
            cb.stroke()
        }
        cb.restoreState()

        doc.close()
        println("  S09 done: ${_s09_OUT}cj_s09_drawing.pdf")
    } catch (e: Exception) {
        println("  ✗ S09: ${e.message}")
    }
}
