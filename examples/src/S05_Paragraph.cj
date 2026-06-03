package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk, Anchor}
import pdf_cj.core.PdfWriter
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let _s05_OUT  = "output/"



let _s05_LOREM = "The quick brown fox jumps over the lazy dog. " +
    "Pack my box with five dozen liquor jugs. " +
    "How vividly the brilliant morning sun shines on the trembling sea."

let _s05_LOREM_CJK = "天下皆知美之为美，斯恶已；皆知善之为善，斯不善已。" +
    "故有无相生，难易相成，长短相形，高下相倾，音声相和，前后相随。"

func s05_paragraph(): Unit {
    println("S05: Paragraph Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s05_OUT + "cj_s05_paragraph.pdf"), OpenMode.Write)
        PdfWriter.getInstance(doc, file)
        doc.open()

        var title = Paragraph("S05: Paragraph Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)

        // 1. Paragraph constructors
        doc.add(Paragraph("--- Constructors ---", Font(helvBf, 12.0)))

        // no-arg + add
        var p1 = Paragraph()
        _ = p1.add(Chunk("1a. no-arg Paragraph with add(Chunk)", Font(helvBf, 12.0)))
        doc.add(p1)

        // Paragraph(String)
        let p2 = Paragraph("1b. Paragraph(String) constructor")
        doc.add(p2)

        // Paragraph(String, Font)
        let p3 = Paragraph("1c. Paragraph(String, Font) constructor", Font(helvBf, 13.0))
        doc.add(p3)

        // Paragraph(float leading, String)
        let p4 = Paragraph(22.0, "1d. Paragraph(leading=22, String)")
        doc.add(p4)

        // Paragraph(float leading, String, Font)
        let p5 = Paragraph(20.0, "1e. Paragraph(leading=20, String, Font)", Font(helvBf, 12.0))
        doc.add(p5)

        // Paragraph(Phrase)
        let phrase = Phrase("1f. Paragraph(Phrase) constructor", Font(helvBf, 12.0))
        let p6 = Paragraph(phrase)
        doc.add(p6)

        // 2. Alignments
        doc.add(Paragraph("--- Alignments ---", Font(helvBf, 12.0)))

        var left = Paragraph(_s05_LOREM, Font(helvBf, 11.0))
        left.setAlignment(Alignment.Left)
        left.setSpacingBefore(4.0)
        left.setSpacingAfter(4.0)
        doc.add(Paragraph("ALIGN_LEFT:", Font(helvBf, 10.0)))
        doc.add(left)

        var center = Paragraph(_s05_LOREM, Font(helvBf, 11.0))
        center.setAlignment(Alignment.Center)
        center.setSpacingBefore(4.0)
        center.setSpacingAfter(4.0)
        doc.add(Paragraph("ALIGN_CENTER:", Font(helvBf, 10.0)))
        doc.add(center)

        var right = Paragraph(_s05_LOREM, Font(helvBf, 11.0))
        right.setAlignment(Alignment.Right)
        right.setSpacingBefore(4.0)
        right.setSpacingAfter(4.0)
        doc.add(Paragraph("ALIGN_RIGHT:", Font(helvBf, 10.0)))
        doc.add(right)

        var justified = Paragraph(_s05_LOREM, Font(helvBf, 11.0))
        justified.setAlignment(Alignment.Justified)
        justified.setSpacingBefore(4.0)
        justified.setSpacingAfter(4.0)
        doc.add(Paragraph("ALIGN_JUSTIFIED:", Font(helvBf, 10.0)))
        doc.add(justified)

        // 3. Leading variants
        doc.add(Paragraph("--- Leading Variants ---", Font(helvBf, 12.0)))

        var fixedLeading = Paragraph(_s05_LOREM, Font(helvBf, 11.0))
        fixedLeading.setLeading(20.0)
        doc.add(Paragraph("setLeading(20f) fixed:", Font(helvBf, 10.0)))
        doc.add(fixedLeading)

        var multipliedLeading = Paragraph(_s05_LOREM, Font(helvBf, 11.0))
        multipliedLeading.setLeading(0.0, 1.8)
        doc.add(Paragraph("setLeading(0, 1.8) multiplied:", Font(helvBf, 10.0)))
        doc.add(multipliedLeading)

        // 4. Spacing before/after
        doc.add(Paragraph("--- Spacing ---", Font(helvBf, 12.0)))
        var spaced = Paragraph("Paragraph with spacingBefore=20 and spacingAfter=20", Font(helvBf, 11.0))
        spaced.setSpacingBefore(20.0)
        spaced.setSpacingAfter(20.0)
        doc.add(spaced)
        doc.add(Paragraph("Paragraph after spaced one", Font(helvBf, 11.0)))

        // 5. First line indent
        var indented = Paragraph(_s05_LOREM, Font(helvBf, 11.0))
        indented.setFirstLineIndent(30.0)
        doc.add(Paragraph("setFirstLineIndent(30):", Font(helvBf, 10.0)))
        doc.add(indented)

        // 6. Left/Right indentation
        var sidePadded = Paragraph(_s05_LOREM, Font(helvBf, 11.0))
        sidePadded.setIndentationLeft(40.0)
        sidePadded.setIndentationRight(40.0)
        doc.add(Paragraph("setIndentationLeft/Right(40):", Font(helvBf, 10.0)))
        doc.add(sidePadded)

        // 7. keepTogether
        var kept = Paragraph(_s05_LOREM + " " + _s05_LOREM, Font(helvBf, 11.0))
        kept.setKeepTogether(true)
        doc.add(Paragraph("setKeepTogether(true):", Font(helvBf, 10.0)))
        doc.add(kept)

        // 8. Extra paragraph space
        var extra = Paragraph("8. Paragraph with setExtraParagraphSpace(12)", Font(helvBf, 11.0))
        extra.setExtraParagraphSpace(12.0)
        extra.setSpacingAfter(8.0)
        doc.add(extra)

        // 9. CJK paragraph with justified alignment
        var cjkPara = Paragraph(_s05_LOREM_CJK + _s05_LOREM_CJK, Font(cjkBf, 12.0))
        cjkPara.setAlignment(Alignment.Justified)
        cjkPara.setMultipliedLeading(1.5)
        doc.add(Paragraph("CJK Justified:", Font(helvBf, 10.0)))
        doc.add(cjkPara)

        // 10. Add mixed content
        var mixed = Paragraph()
        _ = mixed.add(Chunk("10. Mixed: Latin text ", Font(helvBf, 12.0)))
        _ = mixed.add(Chunk("中文 ", Font(cjkBf, 12.0)))
        _ = mixed.add(Phrase("with Anchor", Font(helvBf, 12.0, FontStyle.Underline, Color(0, 0, 255))))
        let a = Anchor(" [link]", Font(helvBf, 12.0, FontStyle.Underline, Color(0, 0, 255)))
        a.setReference("https://example.com")
        _ = mixed.add(a)
        doc.add(mixed)

        doc.close()
        println("  S05 done: ${_s05_OUT}cj_s05_paragraph.pdf")
    } catch (e: Exception) {
        println("  ✗ S05: ${e.message}")
    }
}
