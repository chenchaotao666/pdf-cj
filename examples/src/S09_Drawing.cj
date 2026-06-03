package pdf_cj_examples

import pdf_cj.api.Document
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.text.Color
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}
import std.math.{sin, cos}

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

        var cb = writer.getDirectContent()
        let helvName = writer.addFont(helvBf)
        let cjkName = writer.addFont(cjkBf)

        // Page 1: Lines, curves, shapes
        cb.beginText()
        cb.setFontAndSize(helvBf, helvName, 16.0)
        cb.setTextMatrix(50.0, 800.0)
        cb.showText("S09: PdfContentByte Drawing Demo — Page 1")
        cb.endText()

        // 1. Basic line with saveState/restoreState
        cb.saveState()
        cb.setLineWidth(2.0)
        cb.setColorStroke(Color(255, 0, 0))
        cb.moveTo(50.0, 770.0)
        cb.lineTo(300.0, 770.0)
        cb.stroke()
        cb.restoreState()

        // 2. Line cap styles
        cb.saveState()
        cb.setLineWidth(8.0)
        let caps: Array<Int32> = [PdfContentByte.LINE_CAP_BUTT, PdfContentByte.LINE_CAP_ROUND, PdfContentByte.LINE_CAP_PROJECTING_SQUARE]
        let capColors = [Color(0, 0, 180), Color(0, 0, 140), Color(0, 0, 100)]
        for (i in 0..3) {
            cb.setLineCap(caps[i])
            cb.setColorStroke(capColors[i])
            cb.moveTo(Float32(50 + i * 120), 750.0)
            cb.lineTo(Float32(120 + i * 120), 750.0)
            cb.stroke()
        }
        cb.restoreState()

        // 3. Line join styles
        cb.saveState()
        cb.setLineWidth(4.0)
        let joins: Array<Int32> = [PdfContentByte.LINE_JOIN_MITER, PdfContentByte.LINE_JOIN_ROUND, PdfContentByte.LINE_JOIN_BEVEL]
        let joinColors = [Color(180, 0, 0), Color(140, 0, 0), Color(100, 0, 0)]
        for (i in 0..3) {
            cb.setLineJoin(joins[i])
            cb.setColorStroke(joinColors[i])
            cb.moveTo(Float32(50 + i * 150), 710.0)
            cb.lineTo(Float32(100 + i * 150), 730.0)
            cb.lineTo(Float32(150 + i * 150), 710.0)
            cb.stroke()
        }
        cb.restoreState()

        // 4. Dash patterns
        cb.saveState()
        cb.setLineWidth(2.0)
        cb.setColorStroke(Color(0, 0, 0))
        cb.setLineDash(5.0)
        cb.moveTo(50.0, 680.0)
        cb.lineTo(250.0, 680.0)
        cb.stroke()
        cb.setLineDash(8.0, 4.0, 0.0)
        cb.moveTo(50.0, 665.0)
        cb.lineTo(250.0, 665.0)
        cb.stroke()
        cb.setLineDash([Float32(10.0), Float32(3.0), Float32(3.0), Float32(3.0)], 0.0)
        cb.moveTo(50.0, 650.0)
        cb.lineTo(250.0, 650.0)
        cb.stroke()
        cb.restoreState()

        // 5. Curves (curveTo)
        cb.saveState()
        cb.setLineWidth(2.0)
        cb.setColorStroke(Color(0, 150, 0))
        cb.moveTo(50.0, 620.0)
        cb.curveTo(100.0, 640.0, 200.0, 600.0, 250.0, 620.0)
        cb.stroke()
        cb.restoreState()

        // 6. Fill and stroke operations
        cb.saveState()
        cb.setColorFill(Color(255, 200, 100))
        cb.setColorStroke(Color(200, 100, 0))
        cb.setLineWidth(2.0)
        cb.rectangle(50.0, 550.0, 80.0, 50.0)
        cb.fillStroke()
        cb.setColorFill(Color(150, 200, 255))
        cb.setColorStroke(Color(0, 100, 200))
        cb.ellipse(150.0, 550.0, 250.0, 600.0)
        cb.fillStroke()
        cb.setColorFill(Color(200, 255, 150))
        cb.setColorStroke(Color(100, 200, 0))
        cb.roundRectangle(270.0, 550.0, 80.0, 50.0, 10.0)
        cb.fillStroke()
        cb.restoreState()

        // 7. Arc
        cb.saveState()
        cb.setColorStroke(Color(255, 0, 255))
        cb.setLineWidth(2.0)
        cb.arc(50.0, 490.0, 150.0, 540.0, 0.0, 270.0)
        cb.stroke()
        cb.restoreState()

        // 8. eoFill (Even-Odd Rule) — star shape
        cb.saveState()
        cb.setColorFill(Color(255, 100, 100))
        let PI = 3.14159265358979
        let starCx: Float32 = 430.0
        let starCy: Float32 = 560.0
        let starR1: Float32 = 40.0
        let starR2: Float32 = 20.0
        cb.moveTo(starCx, starCy + starR1)
        for (i in 1..10) {
            let angle = PI / 2.0 + Float64(i) * PI / 5.0
            let r = if (i % 2 == 0) { starR1 } else { starR2 }
            cb.lineTo(starCx + r * Float32(cos(angle)), starCy + r * Float32(sin(angle)))
        }
        cb.closePath()
        cb.eoFill()
        cb.restoreState()

        // 9. Gray fill
        cb.saveState()
        cb.setGrayFill(0.7)
        cb.setGrayStroke(0.3)
        cb.setLineWidth(1.5)
        cb.rectangle(370.0, 490.0, 80.0, 40.0)
        cb.fillStroke()
        cb.restoreState()

        // 10. CMYK color — Java int 0-255 maps to CJ float 0.0-1.0
        // Java: setCMYKColorFill(0, 255, 255, 0)  = yellow (no C, full M, full Y, no K)
        // Java: setCMYKColorStroke(255, 0, 0, 0)   = cyan  (full C, no M/Y/K)
        cb.saveState()
        cb.setCMYKColorFill(0.0, 1.0, 1.0, 0.0)
        cb.setCMYKColorStroke(1.0, 0.0, 0.0, 0.0)
        cb.setLineWidth(2.0)
        cb.rectangle(370.0, 440.0, 80.0, 40.0)
        cb.fillStroke()
        cb.restoreState()

        // 11. clip region
        cb.saveState()
        cb.rectangle(50.0, 420.0, 100.0, 40.0)
        cb.clip()
        cb.newPath()
        cb.setColorFill(Color(255, 200, 0))
        cb.rectangle(30.0, 410.0, 150.0, 60.0)
        cb.fill()
        cb.restoreState()

        // 12. eoClip
        cb.saveState()
        cb.moveTo(200.0, 460.0)
        cb.lineTo(300.0, 460.0)
        cb.lineTo(250.0, 420.0)
        cb.closePath()
        cb.eoClip()
        cb.newPath()
        cb.setColorFill(Color(0, 200, 200))
        cb.rectangle(190.0, 410.0, 130.0, 60.0)
        cb.fill()
        cb.restoreState()

        // 13. concatCTM — shear transform
        cb.saveState()
        cb.concatCTM(1.0, 0.2, 0.2, 1.0, 0.0, 0.0)
        cb.setColorFill(Color(255, 150, 200))
        cb.rectangle(50.0, 380.0, 80.0, 30.0)
        cb.fill()
        cb.restoreState()

        // Page 2: Text operations
        doc.newPage()
        cb = writer.getDirectContent()

        cb.beginText()
        cb.setFontAndSize(helvBf, helvName, 16.0)
        cb.setTextMatrix(50.0, 800.0)
        cb.showText("S09: PdfContentByte Text Operations — Page 2")
        cb.endText()

        // 14. showText
        cb.beginText()
        cb.setFontAndSize(helvBf, helvName, 12.0)
        cb.setTextMatrix(50.0, 770.0)
        cb.showText("14. showText at (50, 770)")
        cb.endText()

        // 15-18. showTextAligned (LEFT / CENTER / RIGHT / rotated)
        cb.beginText()
        cb.setFontAndSize(helvBf, helvName, 12.0)
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT,   "15. showTextAligned LEFT at (50,750)",       50.0,  750.0, 0.0)
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER, "16. showTextAligned CENTER at (297,730)",   297.0,  730.0, 0.0)
        cb.showTextAligned(PdfContentByte.ALIGN_RIGHT,  "17. showTextAligned RIGHT at (545,710)",    545.0,  710.0, 0.0)
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT,   "18. Rotated 45 deg",                         50.0,  680.0, 45.0)
        cb.endText()

        // 19. Character spacing
        cb.beginText()
        cb.setFontAndSize(helvBf, helvName, 12.0)
        cb.setCharacterSpacing(3.0)
        cb.setTextMatrix(50.0, 640.0)
        cb.showText("19. charSpacing=3: Hello World")
        cb.endText()

        // 20. Word spacing
        cb.beginText()
        cb.setFontAndSize(helvBf, helvName, 12.0)
        cb.setWordSpacing(8.0)
        cb.setTextMatrix(50.0, 620.0)
        cb.showText("20. wordSpacing=8: Hello World Text")
        cb.endText()

        // 21. Horizontal scaling
        cb.beginText()
        cb.setFontAndSize(helvBf, helvName, 12.0)
        cb.setHorizontalScaling(150.0)
        cb.setTextMatrix(50.0, 600.0)
        cb.showText("21. hScaling=150%: Wide")
        cb.endText()

        // 22. Text rendering modes
        let modeNames = ["Fill", "Stroke", "FillStroke", "Invisible", "FillClip"]
        let modeVals: Array<Int32> = [
            PdfContentByte.TEXT_RENDER_MODE_FILL,
            PdfContentByte.TEXT_RENDER_MODE_STROKE,
            PdfContentByte.TEXT_RENDER_MODE_FILL_STROKE,
            PdfContentByte.TEXT_RENDER_MODE_INVISIBLE,
            PdfContentByte.TEXT_RENDER_MODE_FILL_CLIP
        ]
        for (i in 0..5) {
            cb.beginText()
            cb.setFontAndSize(helvBf, helvName, 14.0)
            cb.setTextRenderingMode(modeVals[i])
            cb.setColorFill(Color(0, 0, 0))
            cb.setColorStroke(Color(255, 0, 0))
            cb.setLineWidth(0.5)
            cb.setTextMatrix(50.0, Float32(570 - i * 22))
            cb.showText("22.${i} TextRenderMode: ${modeNames[i]}")
            cb.endText()
        }

        // 23. Text rise (superscript effect)
        cb.beginText()
        cb.setFontAndSize(helvBf, helvName, 12.0)
        cb.setTextRenderingMode(PdfContentByte.TEXT_RENDER_MODE_FILL)
        cb.setColorFill(Color(0, 0, 0))
        cb.setTextMatrix(50.0, 450.0)
        cb.showText("23. Normal")
        cb.setTextRise(6.0)
        cb.showText("superscript")
        cb.setTextRise(0.0)
        cb.showText("back to normal")
        cb.endText()

        // 24. moveText and newlineText
        cb.beginText()
        cb.setFontAndSize(helvBf, helvName, 12.0)
        cb.setLeading(18.0)
        cb.setTextMatrix(50.0, 420.0)
        cb.showText("24a. Line 1 via setTextMatrix")
        cb.newlineText()
        cb.showText("24b. Line 2 via newlineText()")
        cb.moveText(0.0, -20.0)
        cb.showText("24c. Line 3 via moveText(0,-20)")
        cb.endText()

        // 25. CJK text on canvas
        cb.beginText()
        cb.setFontAndSize(cjkBf, cjkName, 14.0)
        cb.setTextMatrix(50.0, 370.0)
        cb.showText("25. CJK直接绘制: 这是画布上的中文文字", true, Some(cjkBf))
        cb.endText()

        doc.close()
        println("  S09 done: ${_s09_OUT}cj_s09_drawing.pdf")
    } catch (e: Exception) {
        println("  ✗ S09: ${e.message}")
    }
}
