package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.text.{Font, FontFactory, FontStyle, Color, Alignment}
import pdf_cj.api.FontSelector
import pdf_cj.util.{PageSize}
import std.fs.{File, OpenMode, Path}

let _s02_OUT   = "output/"

func s02_fontText(): Unit {
    println("S02: Font & Text Demo")
    try {
        let cjkBf  = newCjkBf()
        let helvBf = newHelvBf()

        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s02_OUT + "cj_s02_font_text.pdf"), OpenMode.Write)
        PdfWriter.getInstance(doc, file)
        doc.open()

        var title = Paragraph("S02: Font & Text Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)

        // 1. CJK font - normal
        doc.add(Paragraph("1. CJK Normal: 你好，世界！Hello World！", Font(cjkBf, 14.0)))

        // 2. CJK font - bold
        doc.add(Paragraph("2. CJK Bold: 粗体文字测试", Font(cjkBf, 14.0, FontStyle.Bold)))

        // 3. Helvetica normal
        doc.add(Paragraph("3. Helvetica Normal: The quick brown fox", Font(helvBf, 14.0)))

        // 4. Helvetica Bold
        doc.add(Paragraph("4. Helvetica Bold: Bold text sample", Font(helvBf, 14.0, FontStyle.Bold)))

        // 5. Helvetica Italic
        doc.add(Paragraph("5. Helvetica Italic: Italic text sample", Font(helvBf, 14.0, FontStyle.Italic)))

        // 6. Helvetica BoldItalic
        doc.add(Paragraph("6. Helvetica BoldItalic: BoldItalic text", Font(helvBf, 14.0, FontStyle.BoldItalic)))

        // 7. Font with color (4-arg constructor)
        doc.add(Paragraph("7. Font with color (RED): Colored text", Font(helvBf, 14.0, FontStyle.Normal, Color(255, 0, 0))))

        // 8. Font with color - blue bold
        doc.add(Paragraph("8. Blue Bold font: Blue bold text", Font(helvBf, 14.0, FontStyle.Bold, Color(0, 0, 255))))

        // 9. CJK with color
        doc.add(Paragraph("9. CJK Green: 绿色中文字体", Font(cjkBf, 14.0, FontStyle.Normal, Color(0, 128, 0))))

        // 10. FontSelector - mix CJK and Latin
        doc.add(Paragraph("--- FontSelector Demo ---", Font(helvBf, 12.0)))
        let selector = FontSelector()
        selector.addFont(Font(cjkBf, 12.0))
        selector.addFont(Font(helvBf, 12.0))
        let mixed = selector.process("Mixed: Hello 你好 World 世界 123")
        doc.add(Paragraph(mixed))

        // 11. FontFactory.getFont - Helvetica with color
        doc.add(Paragraph("--- FontFactory Demo ---", Font(helvBf, 12.0)))
        let ffHelv = FontFactory.getFont(FontFactory.HELVETICA, 13.0, FontStyle.Normal, Color.DARK_GRAY)
        doc.add(Paragraph("11. FontFactory Helvetica: Sample text", ffHelv))

        // 12. FontFactory Courier Bold
        let ffCourier = FontFactory.getFont(FontFactory.COURIER, 12.0, FontStyle.Bold)
        doc.add(Paragraph("12. FontFactory Courier Bold: Monospace text", ffCourier))

        // 13. FontFactory Times Italic
        let ffTimes = FontFactory.getFont(FontFactory.TIMES_ROMAN, 13.0, FontStyle.Italic)
        doc.add(Paragraph("13. FontFactory Times Italic: Serif italic text", ffTimes))

        // 14. Font size variations
        doc.add(Paragraph("--- Size Variations ---", Font(helvBf, 12.0)))
        let sizes: Array<Float32> = [8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 24.0]
        for (size in sizes) {
            doc.add(Paragraph("Size ${size}: Sample text 示例文字", Font(cjkBf, size)))
        }

        // 15. Underline via FontStyle
        doc.add(Paragraph("15. Underline: Underlined text", Font(helvBf, 14.0, FontStyle.Underline)))

        // 16. Strikethrough via FontStyle
        doc.add(Paragraph("16. Strikethrough: Strikethrough text", Font(helvBf, 14.0, FontStyle.Strikethrough)))

        doc.close()
        println("  S02 done: ${_s02_OUT}cj_s02_font_text.pdf")
    } catch (e: Exception) {
        println("  ✗ S02: ${e.message}")
    }
}
