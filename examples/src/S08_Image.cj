package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.PdfWriter
import pdf_cj.image.Image
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let _s08_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s08_IMG  = "images/"
let _s08_OUT  = "output/"



func s08_image(): Unit {
    println("S08: Image Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s08_OUT + "cj_s08_image.pdf"), OpenMode.Write)
        PdfWriter.getInstance(doc, file)
        doc.open()

        var title = Paragraph("S08: Image Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)

        // 1. river.jpg — original size + scaleAbsolute
        try {
            doc.add(Paragraph("1. river.jpg — original size:", Font(helvBf, 11.0)))
            let img1 = Image.getInstance(_s08_IMG + "river.jpg")
            doc.add(Paragraph("   Original: ${Int32(img1.plainWidth)}.0 x ${Int32(img1.plainHeight)}.0 px", Font(helvBf, 10.0)))
            img1.scaleAbsolute(150.0, 100.0)
            img1.setAlignment(Alignment.Left)
            img1.setSpacingBefore(4.0)
            img1.setSpacingAfter(8.0)
            doc.add(img1)
        } catch (e: Exception) {
            doc.add(Paragraph("  1. river.jpg error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 2. mountain.png — scalePercent
        try {
            doc.add(Paragraph("2. mountain.png — scalePercent(30%):", Font(helvBf, 11.0)))
            let img2 = Image.getInstance(_s08_IMG + "mountain.png")
            img2.scalePercent(30.0)
            img2.setAlignment(Alignment.Center)
            img2.setSpacingBefore(4.0)
            img2.setSpacingAfter(8.0)
            doc.add(img2)
        } catch (e: Exception) {
            doc.add(Paragraph("  2. mountain.png error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 3. nodes.jpeg — scalePercent different x/y
        try {
            doc.add(Paragraph("3. nodes.jpeg — scalePercent(50%, 30%):", Font(helvBf, 11.0)))
            let img3 = Image.getInstance(_s08_IMG + "nodes.jpeg")
            img3.scalePercent(50.0, 30.0)
            img3.setAlignment(Alignment.Right)
            img3.setSpacingBefore(4.0)
            img3.setSpacingAfter(8.0)
            doc.add(img3)
        } catch (e: Exception) {
            doc.add(Paragraph("  3. nodes.jpeg error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 4. scaleToFit
        try {
            doc.add(Paragraph("4. river.jpg — scaleToFit(200, 120):", Font(helvBf, 11.0)))
            let img4 = Image.getInstance(_s08_IMG + "river.jpg")
            img4.scaleToFit(200.0, 120.0)
            img4.setAlignment(Alignment.Center)
            img4.setSpacingBefore(4.0)
            img4.setSpacingAfter(8.0)
            doc.add(img4)
        } catch (e: Exception) {
            doc.add(Paragraph("  4. scaleToFit error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 5. Alignment Left
        try {
            doc.add(Paragraph("5. mountain.png — ALIGN_LEFT:", Font(helvBf, 11.0)))
            let img5 = Image.getInstance(_s08_IMG + "mountain.png")
            img5.scaleAbsolute(120.0, 80.0)
            img5.setAlignment(Alignment.Left)
            doc.add(img5)
        } catch (e: Exception) {
            doc.add(Paragraph("  5. error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 6. Alignment Center (MIDDLE)
        try {
            doc.add(Paragraph("6. mountain.png — ALIGN_MIDDLE:", Font(helvBf, 11.0)))
            let img6 = Image.getInstance(_s08_IMG + "mountain.png")
            img6.scaleAbsolute(120.0, 80.0)
            img6.setAlignment(Alignment.Center)
            doc.add(img6)
        } catch (e: Exception) {
            doc.add(Paragraph("  6. error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 7. Alignment Right
        try {
            doc.add(Paragraph("7. mountain.png — ALIGN_RIGHT:", Font(helvBf, 11.0)))
            let img7 = Image.getInstance(_s08_IMG + "mountain.png")
            img7.scaleAbsolute(120.0, 80.0)
            img7.setAlignment(Alignment.Right)
            doc.add(img7)
        } catch (e: Exception) {
            doc.add(Paragraph("  7. error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 8. setRotationDegrees - new page
        doc.newPage()
        try {
            doc.add(Paragraph("8. river.jpg — setRotationDegrees(15):", Font(helvBf, 11.0)))
            let img8 = Image.getInstance(_s08_IMG + "river.jpg")
            img8.scaleAbsolute(200.0, 130.0)
            img8.setRotation(15.0)
            img8.setAlignment(Alignment.Center)
            img8.setSpacingBefore(10.0)
            img8.setSpacingAfter(10.0)
            doc.add(img8)
        } catch (e: Exception) {
            doc.add(Paragraph("  8. rotation error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 9. setRotation (radians)
        try {
            doc.add(Paragraph("9. nodes.jpeg — setRotation(0.3 rad):", Font(helvBf, 11.0)))
            let img9 = Image.getInstance(_s08_IMG + "nodes.jpeg")
            img9.scaleToFit(180.0, 120.0)
            img9.setRotationRadians(0.3)
            img9.setAlignment(Alignment.Center)
            img9.setSpacingBefore(10.0)
            img9.setSpacingAfter(10.0)
            doc.add(img9)
        } catch (e: Exception) {
            doc.add(Paragraph("  9. setRotation error: ${e.message}", Font(helvBf, 10.0)))
        }

        // 10. setAbsolutePosition
        try {
            doc.add(Paragraph("10. river.jpg — absolute position (300, 200):", Font(helvBf, 11.0)))
            let img10 = Image.getInstance(_s08_IMG + "river.jpg")
            img10.scaleAbsolute(150.0, 100.0)
            img10.setAbsolutePosition(300.0, 200.0)
            doc.add(img10)
        } catch (e: Exception) {
            doc.add(Paragraph("  10. absolute position error: ${e.message}", Font(helvBf, 10.0)))
        }

        // Force some space
        doc.add(Paragraph(" ", Font(helvBf, 60.0)))

        // 11. Wrap text around image (ALIGN_LEFT | TEXTWRAP)
        try {
            doc.add(Paragraph("11. Wrap text around image (ALIGN_LEFT | TEXTWRAP):", Font(helvBf, 11.0)))
            let img11 = Image.getInstance(_s08_IMG + "mountain.png")
            img11.scaleAbsolute(120.0, 80.0)
            img11.setAlignment(Alignment.Left)
            img11.setTextWrap(true)
            img11.setIndentationLeft(10.0)
            img11.setSpacingBefore(6.0)
            img11.setSpacingAfter(6.0)
            doc.add(img11)
            doc.add(Paragraph(
                "This text should wrap around the image on the right side. " +
                "The image is aligned to the left with TEXTWRAP flag. " +
                "More text to demonstrate the wrapping behavior in OpenPDF. " +
                "Keep going to ensure we have enough text to wrap.",
                Font(helvBf, 11.0)))
        } catch (e: Exception) {
            doc.add(Paragraph("  11. textwrap error: ${e.message}", Font(helvBf, 10.0)))
        }

        doc.close()
        println("  S08 done: ${_s08_OUT}cj_s08_image.pdf")
    } catch (e: Exception) {
        println("  ✗ S08: ${e.message}")
    }
}
