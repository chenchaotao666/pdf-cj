package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.form.{PdfAnnotationFactory, PdfAnnotationText, PdfAnnotationSquare, PdfAnnotationCircle, PdfAnnotationHighlight, PdfAnnotationUnderline, PdfAnnotationStrikeOut, PdfAnnotationFreeText}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let _s12_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s12_OUT  = "output/"



func s12_annotation(): Unit {
    println("S12: Annotation Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s12_OUT + "cj_s12_annotation.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        var title = Paragraph("S12: Annotation Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)
        doc.add(Paragraph("Various PDF annotation types are shown on this page.", Font(helvBf, 11.0)))
        doc.add(Paragraph("Some annotations are interactive — open in a PDF viewer to see them.", Font(helvBf, 11.0)))

        doc.add(Paragraph(" ", Font(helvBf, 20.0)))

        // 1. Text (sticky note) annotation
        try {
            let rect1 = Rectangle(72.0, 700.0, 100.0, 720.0)
            let ann1 = PdfAnnotationFactory.createText(rect1, "Note Title", "This is a sticky note annotation.", true, "Note")
            ann1.setColor(Float32(1.0), Float32(1.0), Float32(0.0))
            writer.addAnnotation(ann1)
            doc.add(Paragraph("1. Sticky note annotation at top-left (yellow icon)", Font(helvBf, 11.0)))
        } catch (e: Exception) {
            doc.add(Paragraph("1. Sticky note: ${e.message}", Font(helvBf, 11.0)))
        }

        // 2. Link annotation with URL
        try {
            let rect2 = Rectangle(72.0, 619.0, 310.0, 636.0)
            let ann2 = PdfAnnotationFactory.createURLLink(rect2, "https://github.com/LibrePDF/OpenPDF")
            writer.addAnnotation(ann2)
            doc.add(Paragraph("2. [Link annotation — URL to OpenPDF GitHub]", Font(helvBf, 11.0, FontStyle.Underline, Color(0, 0, 255))))
        } catch (e: Exception) {
            doc.add(Paragraph("2. Link annotation: ${e.message}", Font(helvBf, 11.0)))
        }

        // 3. Highlight annotation
        try {
            doc.add(Paragraph("3. This text has a HIGHLIGHT markup annotation overlaid.", Font(helvBf, 11.0)))
            let rect3 = Rectangle(72.0, 607.0, 400.0, 619.0)
            let quadPoints: Array<Float32> = [
                Float32(72.0), Float32(619.0), Float32(400.0), Float32(619.0),
                Float32(72.0), Float32(607.0), Float32(400.0), Float32(607.0)
            ]
            let ann3 = PdfAnnotationFactory.createHighlight(rect3, quadPoints)
            ann3.setColor(Float32(1.0), Float32(1.0), Float32(0.0))
            writer.addAnnotation(ann3)
        } catch (e: Exception) {
            doc.add(Paragraph("3. Highlight: ${e.message}", Font(helvBf, 11.0)))
        }

        // 4. Underline annotation
        try {
            doc.add(Paragraph("4. This text has an UNDERLINE markup annotation.", Font(helvBf, 11.0)))
            let rect4 = Rectangle(72.0, 591.0, 350.0, 603.0)
            let quadPoints4: Array<Float32> = [
                Float32(72.0), Float32(603.0), Float32(350.0), Float32(603.0),
                Float32(72.0), Float32(591.0), Float32(350.0), Float32(591.0)
            ]
            let ann4 = PdfAnnotationFactory.createUnderline(rect4, quadPoints4)
            ann4.setColor(Float32(0.0), Float32(0.0), Float32(1.0))
            writer.addAnnotation(ann4)
        } catch (e: Exception) {
            doc.add(Paragraph("4. Underline: ${e.message}", Font(helvBf, 11.0)))
        }

        // 5. StrikeOut annotation
        try {
            doc.add(Paragraph("5. This text has a STRIKEOUT markup annotation.", Font(helvBf, 11.0)))
            let rect5 = Rectangle(72.0, 574.0, 340.0, 586.0)
            let quadPoints5: Array<Float32> = [
                Float32(72.0), Float32(586.0), Float32(340.0), Float32(586.0),
                Float32(72.0), Float32(574.0), Float32(340.0), Float32(574.0)
            ]
            let ann5 = PdfAnnotationFactory.createStrikeOut(rect5, quadPoints5)
            ann5.setColor(Float32(1.0), Float32(0.0), Float32(0.0))
            writer.addAnnotation(ann5)
        } catch (e: Exception) {
            doc.add(Paragraph("5. StrikeOut: ${e.message}", Font(helvBf, 11.0)))
        }

        // 6. Free text annotation
        try {
            doc.add(Paragraph(" ", Font(helvBf, 8.0)))
            let rect6 = Rectangle(72.0, 540.0, 300.0, 572.0)
            let ann6 = PdfAnnotationFactory.createFreeText(rect6, "6. Free text annotation: This floats on the page!", "/Helvetica 10 Tf 0 g")
            ann6.setColor(Float32(200.0 / 255.0), Float32(230.0 / 255.0), Float32(1.0))
            writer.addAnnotation(ann6)
            doc.add(Paragraph("6. Free text annotation box above", Font(helvBf, 11.0)))
        } catch (e: Exception) {
            doc.add(Paragraph("6. Free text: ${e.message}", Font(helvBf, 11.0)))
        }

        // 7. Square annotation
        try {
            let rect7 = Rectangle(72.0, 490.0, 172.0, 530.0)
            let ann7 = PdfAnnotationSquare(rect7)
            ann7.setContents("Square annotation")
            ann7.setColor(Float32(0.0), Float32(1.0), Float32(0.0))
            writer.addAnnotation(ann7)
            doc.add(Paragraph("7. Square/stamp annotation", Font(helvBf, 11.0)))
        } catch (e: Exception) {
            doc.add(Paragraph("7. Square/stamp: ${e.message}", Font(helvBf, 11.0)))
        }

        // 8. Circle annotation
        try {
            let rect8 = Rectangle(200.0, 490.0, 320.0, 530.0)
            let ann8 = PdfAnnotationCircle(rect8)
            ann8.setContents("Circle annotation")
            ann8.setColor(Float32(1.0), Float32(200.0 / 255.0), Float32(0.0))
            writer.addAnnotation(ann8)
            doc.add(Paragraph("8. Circle/stamp annotation", Font(helvBf, 11.0)))
        } catch (e: Exception) {
            doc.add(Paragraph("8. Circle: ${e.message}", Font(helvBf, 11.0)))
        }

        // 9. Annotation with FLAGS_PRINT (value 4)
        try {
            let rect9 = Rectangle(72.0, 440.0, 200.0, 470.0)
            let ann9 = PdfAnnotationFactory.createText(rect9, "Opacity Note", "This note has 50% opacity set.", false, "Comment")
            ann9.setColor(Float32(0.0), Float32(1.0), Float32(1.0))
            ann9.setOpacity(0.5)
            ann9.setFlags(4)
            writer.addAnnotation(ann9)
            doc.add(Paragraph("9. Annotation with FLAGS_PRINT set", Font(helvBf, 11.0)))
        } catch (e: Exception) {
            doc.add(Paragraph("9. Opacity annotation: ${e.message}", Font(helvBf, 11.0)))
        }

        doc.close()
        println("  S12 done: ${_s12_OUT}cj_s12_annotation.pdf")
    } catch (e: Exception) {
        println("  ✗ S12: ${e.message}")
    }
}
