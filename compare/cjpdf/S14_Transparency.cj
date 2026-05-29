package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.{PdfWriter, PdfContentByte, PdfGState, BlendMode}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let _s14_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s14_OUT  = "output/"



func s14_transparency(): Unit {
    println("S14: Transparency & GState Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s14_OUT + "cj_s14_transparency.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        let cb = writer.getDirectContent()
        let _s14_HELV_NAME = writer.addFont(helvBf)

        var title = Paragraph("S14: Transparency & GState Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)

        // 1. Three overlapping rectangles with different fill opacities
        doc.add(Paragraph("1. Three overlapping rectangles with different fill opacities:", Font(helvBf, 11.0)))
        doc.add(Paragraph(" ", Font(helvBf, 6.0)))

        let baseY: Float32 = 580.0

        // Background rectangle (fully opaque gray)
        cb.saveState()
        cb.setColorFill(Color(200, 200, 200))
        cb.rectangle(100.0, baseY, 300.0, 80.0)
        cb.fill()
        cb.restoreState()

        // Red rectangle at 80% opacity
        let gs1 = PdfGState()
        gs1.setFillAlpha(Float32(0.8))
        gs1.setStrokeAlpha(Float32(0.8))
        let gsName1 = writer.addGState(gs1)
        cb.saveState()
        cb.setExtGState(gsName1)
        cb.setColorFill(Color(255, 0, 0))
        cb.rectangle(80.0, baseY + 20.0, 150.0, 100.0)
        cb.fill()
        cb.restoreState()

        // Green rectangle at 50% opacity (overlapping red)
        let gs2 = PdfGState()
        gs2.setFillAlpha(Float32(0.5))
        gs2.setStrokeAlpha(Float32(0.5))
        let gsName2 = writer.addGState(gs2)
        cb.saveState()
        cb.setExtGState(gsName2)
        cb.setColorFill(Color(0, 255, 0))
        cb.rectangle(160.0, baseY + 30.0, 150.0, 100.0)
        cb.fill()
        cb.restoreState()

        // Blue rectangle at 30% opacity (overlapping both)
        let gs3 = PdfGState()
        gs3.setFillAlpha(Float32(0.3))
        gs3.setStrokeAlpha(Float32(0.3))
        let gsName3 = writer.addGState(gs3)
        cb.saveState()
        cb.setExtGState(gsName3)
        cb.setColorFill(Color(0, 0, 255))
        cb.rectangle(240.0, baseY + 10.0, 150.0, 100.0)
        cb.fill()
        cb.restoreState()

        // Labels
        cb.beginText()
        cb.setFontAndSize(helvBf, _s14_HELV_NAME, 9.0)
        cb.setColorFill(Color(0, 0, 0))
        cb.setTextMatrix(80.0, baseY - 15.0)
        cb.showText("Red 80%")
        cb.setTextMatrix(185.0, baseY - 15.0)
        cb.showText("Green 50%")
        cb.setTextMatrix(290.0, baseY - 15.0)
        cb.showText("Blue 30%")
        cb.endText()

        // 2. Blend modes
        doc.add(Paragraph(" ", Font(helvBf, 60.0)))
        doc.add(Paragraph("2. Blend mode demonstrations:", Font(helvBf, 11.0)))

        let blendY: Float32 = 430.0
        let blendNames = ["Normal", "Multiply", "Screen", "Overlay", "Darken", "Lighten"]
        let blendModes = [
            BlendMode.NORMAL,
            BlendMode.MULTIPLY,
            BlendMode.SCREEN,
            BlendMode.OVERLAY,
            BlendMode.DARKEN,
            BlendMode.LIGHTEN
        ]

        for (i in 0..6) {
            let bx = Float32(72 + i * 82)

            // Background orange rectangle
            cb.saveState()
            cb.setColorFill(Color(255, 200, 0))
            cb.rectangle(bx, blendY, 70.0, 60.0)
            cb.fill()
            cb.restoreState()

            // Overlay with blend mode
            let gsBlend = PdfGState()
            gsBlend.setFillAlpha(Float32(0.7))
            gsBlend.setBlendMode(blendModes[i])
            let gsBlendName = writer.addGState(gsBlend)
            cb.saveState()
            cb.setExtGState(gsBlendName)
            cb.setColorFill(Color(0, 0, 255))
            cb.rectangle(bx + 15.0, blendY + 15.0, 50.0, 50.0)
            cb.fill()
            cb.restoreState()

            cb.beginText()
            cb.setFontAndSize(helvBf, _s14_HELV_NAME, 8.0)
            cb.setColorFill(Color(0, 0, 0))
            cb.setTextMatrix(bx, blendY - 12.0)
            cb.showText(blendNames[i])
            cb.endText()
        }

        // 3. Transparent text over colored background
        doc.add(Paragraph(" ", Font(helvBf, 60.0)))
        doc.add(Paragraph("3. Transparent text over colored background:", Font(helvBf, 11.0)))

        let txtY: Float32 = 270.0

        // Colorful background stripes
        let stripeColors = [
            Color(255, 0, 0), Color(255, 200, 0), Color(255, 255, 0),
            Color(0, 255, 0), Color(0, 0, 255), Color(255, 0, 255)
        ]
        for (i in 0..6) {
            cb.setColorFill(stripeColors[i])
            cb.rectangle(72.0, txtY + Float32(i) * 15.0, 450.0, 15.0)
            cb.fill()
        }

        // Semi-transparent text overlay
        let gsTxt = PdfGState()
        gsTxt.setFillAlpha(Float32(0.85))
        let gsTxtName = writer.addGState(gsTxt)
        cb.saveState()
        cb.setExtGState(gsTxtName)
        cb.beginText()
        cb.setFontAndSize(helvBf, _s14_HELV_NAME, 36.0)
        cb.setColorFill(Color(255, 255, 255))
        cb.setTextMatrix(90.0, txtY + 25.0)
        cb.showText("TRANSPARENT TEXT")
        cb.endText()
        cb.restoreState()

        // 4. Varying stroke opacity on circles
        doc.add(Paragraph(" ", Font(helvBf, 40.0)))
        doc.add(Paragraph("4. Varying stroke opacity on circles:", Font(helvBf, 11.0)))

        let circY: Float32 = 160.0
        for (i in 0..5) {
            let opacity = Float32(0.2) + Float32(i) * Float32(0.2)
            let gsCircle = PdfGState()
            gsCircle.setStrokeAlpha(opacity)
            let gsCircleName = writer.addGState(gsCircle)
            cb.saveState()
            cb.setExtGState(gsCircleName)
            cb.setColorStroke(Color(255, 0, 0))
            cb.setLineWidth(4.0)
            let cx = Float32(100 + i * 90)
            cb.ellipse(cx - 35.0, circY - 30.0, cx + 35.0, circY + 30.0)
            cb.stroke()
            cb.restoreState()

            cb.beginText()
            cb.setFontAndSize(helvBf, _s14_HELV_NAME, 9.0)
            cb.setColorFill(Color(0, 0, 0))
            let pct = Int64(Float64(opacity) * 100.0)
            cb.setTextMatrix(cx - 20.0, circY - 45.0)
            cb.showText("${pct}%")
            cb.endText()
        }

        doc.close()
        println("  S14 done: ${_s14_OUT}cj_s14_transparency.pdf")
    } catch (e: Exception) {
        println("  ✗ S14: ${e.message}")
    }
}
