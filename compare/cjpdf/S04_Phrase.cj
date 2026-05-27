package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.PdfWriter
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize}
import std.fs.{File, OpenMode, Path}

let _s04_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s04_OUT  = "output/"

func s04_phrase(): Unit {
    println("S04: Phrase Demo")
    try {
        let cjkBf  = BaseFont.createFont(_s04_FONT, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
        let helvBf = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s04_OUT + "cj_s04_phrase.pdf"), OpenMode.Write)
        PdfWriter.getInstance(doc, file)
        doc.open()

        var title = Paragraph("S04: Phrase Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)

        // 1. No-arg constructor
        var ph1 = Phrase()
        _ = ph1.add(Chunk("1. Phrase (no-arg constructor)", Font(helvBf, 12.0)))
        doc.add(Paragraph(ph1))

        // 2. Phrase(String text)
        let ph2 = Phrase("2. Phrase(String) constructor")
        doc.add(Paragraph(ph2))

        // 3. Phrase(String text, Font font)
        let ph3 = Phrase("3. Phrase(String, Font) with bold", Font(helvBf, 13.0, FontStyle.Bold))
        doc.add(Paragraph(ph3))

        // 4. Phrase with leading
        var ph4 = Phrase(24.0)
        _ = ph4.add(Chunk("4. Phrase(leading=24)", Font(helvBf, 12.0)))
        doc.add(Paragraph(ph4))

        // 5. Phrase(leading, String)
        let ph5 = Phrase(20.0, "5. Phrase(leading=20, text)")
        doc.add(Paragraph(ph5))

        // 6. Phrase(leading, String, Font)
        let ph6 = Phrase(18.0, "6. Phrase(leading=18, text, font)", Font(helvBf, 12.0, FontStyle.Italic))
        doc.add(Paragraph(ph6))

        // 7. add(Chunk) multiple chunks
        var ph7 = Phrase()
        _ = ph7.add(Chunk("7. add(Chunk): first", Font(helvBf, 12.0)))
        _ = ph7.add(Chunk(" + second chunk", Font(helvBf, 12.0, FontStyle.Bold, Color(200, 0, 0))))
        doc.add(Paragraph(ph7))

        // 8. add(Phrase) - nested phrase
        let inner = Phrase("(nested phrase)", Font(helvBf, 11.0, FontStyle.Italic, Color(0, 0, 200)))
        var ph8 = Phrase("8. add(Phrase): outer ")
        _ = ph8.add(inner)
        doc.add(Paragraph(ph8))

        // 9. add(Chunk) variation
        var ph9 = Phrase("9. add(Chunk): ")
        _ = ph9.add(Chunk("added via add(Chunk)", Font(helvBf, 12.0, FontStyle.Bold)))
        doc.add(Paragraph(ph9))

        // 10. setLeading()
        var ph10 = Phrase("10. setLeading(30): This phrase has extra leading set programmatically. " +
                "This is enough text to show the effect.")
        ph10.setLeading(30.0)
        doc.add(Paragraph(ph10))

        // 11. setFont()
        var ph11 = Phrase("11. setFont(): originally plain")
        ph11.setFont(Font(helvBf, 13.0, FontStyle.BoldItalic, Color(180, 0, 180)))
        doc.add(Paragraph(ph11))

        // 12. getContent()
        var ph12 = Phrase("12. Content: ", Font(helvBf, 12.0))
        _ = ph12.add(Chunk("Hello World", Font(helvBf, 12.0)))
        let content = ph12.getContent()
        doc.add(Paragraph("getContent() => \"${content}\"", Font(helvBf, 11.0)))

        // 13. CJK Phrase
        let cjkPhrase = Phrase("13. CJK短语: 你好世界，这是短语测试。", Font(cjkBf, 13.0))
        doc.add(Paragraph(cjkPhrase))

        // 14. Mixed phrase with CJK and Latin
        var mixedPhrase = Phrase()
        _ = mixedPhrase.add(Chunk("14. Mixed: Hello ", Font(helvBf, 12.0)))
        _ = mixedPhrase.add(Chunk("你好 ", Font(cjkBf, 12.0)))
        _ = mixedPhrase.add(Chunk("World ", Font(helvBf, 12.0)))
        _ = mixedPhrase.add(Chunk("世界", Font(cjkBf, 12.0)))
        doc.add(Paragraph(mixedPhrase))

        // 15. Nested phrases
        var outerPhrase = Phrase("15. Nested: ")
        var innerPhrase1 = Phrase("first inner ", Font(helvBf, 12.0, FontStyle.Bold, Color(0, 150, 0)))
        var innerPhrase2 = Phrase("second inner ", Font(helvBf, 12.0, FontStyle.Italic, Color(200, 100, 0)))
        _ = outerPhrase.add(innerPhrase1)
        _ = outerPhrase.add(innerPhrase2)
        _ = outerPhrase.add(Chunk("end", Font(helvBf, 12.0)))
        doc.add(Paragraph(outerPhrase))

        doc.close()
        println("  S04 done: ${_s04_OUT}cj_s04_phrase.pdf")
    } catch (e: Exception) {
        println("  ✗ S04: ${e.message}")
    }
}
