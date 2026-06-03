package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.{PdfWriter, PdfContentByte, PdfAxialShading, PdfRadialShading, PdfShadingPattern}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let _s15_OUT  = "output/"



func s15_shading(): Unit {
    println("S15: Shading & Gradient Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s15_OUT + "cj_s15_shading.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        let cb = writer.getDirectContent()

        var title = Paragraph("S15: Shading & Gradient Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)

        // 1. Axial (linear) gradient — horizontal Red → Blue
        doc.add(Paragraph("1. Axial (Linear) Gradient — Horizontal (Red → Blue):", Font(helvBf, 11.0)))
        doc.add(Paragraph(" ", Font(helvBf, 4.0)))

        try {
            let axial1 = PdfAxialShading(72.0, 680.0, Color(255, 0, 0), 450.0, 680.0, Color(0, 0, 255))
            let patName1 = writer.addShadingPattern(PdfShadingPattern(axial1))
            cb.setColorFillPattern(patName1)
            cb.rectangle(72.0, 650.0, 378.0, 60.0)
            cb.fill()
        } catch (e: Exception) {
            doc.add(Paragraph("  Axial1 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 2. Axial gradient — vertical Yellow → Green
        doc.add(Paragraph(" ", Font(helvBf, 22.0)))
        doc.add(Paragraph("2. Axial Gradient — Vertical (Yellow → Green):", Font(helvBf, 11.0)))
        doc.add(Paragraph(" ", Font(helvBf, 4.0)))

        try {
            let axial2 = PdfAxialShading(72.0, 610.0, Color(255, 255, 0), 72.0, 570.0, Color(0, 255, 0))
            let patName2 = writer.addShadingPattern(PdfShadingPattern(axial2))
            cb.setColorFillPattern(patName2)
            cb.rectangle(72.0, 570.0, 378.0, 60.0)
            cb.fill()
        } catch (e: Exception) {
            doc.add(Paragraph("  Axial2 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 3. Axial gradient — diagonal Cyan → Magenta
        doc.add(Paragraph(" ", Font(helvBf, 22.0)))
        doc.add(Paragraph("3. Axial Gradient — Diagonal (Cyan → Magenta):", Font(helvBf, 11.0)))
        doc.add(Paragraph(" ", Font(helvBf, 4.0)))

        try {
            let axial3 = PdfAxialShading(72.0, 530.0, Color(0, 255, 255), 450.0, 490.0, Color(255, 0, 255))
            let patName3 = writer.addShadingPattern(PdfShadingPattern(axial3))
            cb.setColorFillPattern(patName3)
            cb.rectangle(72.0, 490.0, 378.0, 60.0)
            cb.fill()
        } catch (e: Exception) {
            doc.add(Paragraph("  Axial3 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 4. Radial gradient — circle Orange center → White
        doc.add(Paragraph(" ", Font(helvBf, 22.0)))
        doc.add(Paragraph("4. Radial Gradient — Orange center → White:", Font(helvBf, 11.0)))
        doc.add(Paragraph(" ", Font(helvBf, 4.0)))

        try {
            let radial1 = PdfRadialShading(261.0, 420.0, 0.0, Color(255, 140, 0), 261.0, 420.0, 80.0, Color(255, 255, 255))
            let patName4 = writer.addShadingPattern(PdfShadingPattern(radial1))
            cb.setColorFillPattern(patName4)
            cb.ellipse(181.0, 370.0, 341.0, 460.0)
            cb.fill()
        } catch (e: Exception) {
            doc.add(Paragraph("  Radial1 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 5. Radial gradient — 3D sphere effect
        doc.add(Paragraph(" ", Font(helvBf, 50.0)))
        doc.add(Paragraph("5. Radial Gradient — 3D Sphere Effect:", Font(helvBf, 11.0)))
        doc.add(Paragraph(" ", Font(helvBf, 4.0)))

        try {
            let radial2 = PdfRadialShading(305.0, 305.0, 10.0, Color(255, 255, 255), 261.0, 275.0, 60.0, Color(0, 0, 180))
            let patName5 = writer.addShadingPattern(PdfShadingPattern(radial2))
            cb.setColorFillPattern(patName5)
            cb.ellipse(200.0, 240.0, 322.0, 322.0)
            cb.fill()
        } catch (e: Exception) {
            doc.add(Paragraph("  Radial2 error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 6. Multiple gradient bars
        doc.add(Paragraph(" ", Font(helvBf, 30.0)))
        doc.add(Paragraph("6. Multiple Gradient Bars:", Font(helvBf, 11.0)))
        doc.add(Paragraph(" ", Font(helvBf, 4.0)))

        let gradColorPairs = [
            (Color(255, 0, 0),   Color(255, 255, 0)),
            (Color(255, 255, 0), Color(0, 255, 0)),
            (Color(0, 255, 0),   Color(0, 255, 255)),
            (Color(0, 255, 255), Color(0, 0, 255)),
            (Color(0, 0, 255),   Color(255, 0, 255)),
            (Color(255, 0, 255), Color(255, 0, 0))
        ]

        for (i in 0..6) {
            let bx = Float32(72 + i * 63)
            let (c1, c2) = gradColorPairs[i]
            try {
                let barShading = PdfAxialShading(bx, 160.0, c1, bx + 63.0, 160.0, c2)
                let barPatName = writer.addShadingPattern(PdfShadingPattern(barShading))
                cb.setColorFillPattern(barPatName)
                cb.rectangle(bx, 130.0, 63.0, 50.0)
                cb.fill()
            } catch (e: Exception) {
                // skip bar if error
            }
        }

        doc.close()
        println("  S15 done: ${_s15_OUT}cj_s15_shading.pdf")
    } catch (e: Exception) {
        println("  ✗ S15: ${e.message}")
    }
}
