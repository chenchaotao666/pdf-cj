import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S05_Paragraph {
    static final String FONT_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc,0";
    static final String IMG_DIR   = "images/";
    static final String OUT_DIR   = "output/";

    static BaseFont CJK_BF;
    static BaseFont HELV_BF;
    static {
        try {
            CJK_BF  = BaseFont.createFont(FONT_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
            HELV_BF = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED);
        } catch (Exception e) { throw new RuntimeException(e); }
    }
    static Font cjk(float s)     { return new Font(CJK_BF, s); }
    static Font cjkBold(float s) { return new Font(CJK_BF, s, Font.BOLD); }
    static Font helv(float s)    { return new Font(HELV_BF, s); }

    static final String LOREM = "The quick brown fox jumps over the lazy dog. " +
            "Pack my box with five dozen liquor jugs. " +
            "How vividly the brilliant morning sun shines on the trembling sea.";
    static final String LOREM_CJK = "天下皆知美之为美，斯恶已；皆知善之为善，斯不善已。" +
            "故有无相生，难易相成，长短相形，高下相倾，音声相和，前后相随。";

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();

        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s05_paragraph.pdf"));
        doc.open();

        // Title
        Paragraph title = new Paragraph("S05: Paragraph Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);

        // 1. Paragraph constructors
        doc.add(new Paragraph("--- Constructors ---", helv(12)));

        // no-arg + add
        Paragraph p1 = new Paragraph();
        p1.add(new Chunk("1a. no-arg Paragraph with add(Chunk)", helv(12)));
        doc.add(p1);

        // Paragraph(String)
        Paragraph p2 = new Paragraph("1b. Paragraph(String) constructor");
        doc.add(p2);

        // Paragraph(String, Font)
        Paragraph p3 = new Paragraph("1c. Paragraph(String, Font) constructor", helv(13));
        doc.add(p3);

        // Paragraph(float leading, String)
        Paragraph p4 = new Paragraph(22f, "1d. Paragraph(leading=22, String)");
        doc.add(p4);

        // Paragraph(float leading, String, Font)
        Paragraph p5 = new Paragraph(20f, "1e. Paragraph(leading=20, String, Font)", helv(12));
        doc.add(p5);

        // Paragraph(Phrase)
        Phrase phrase = new Phrase("1f. Paragraph(Phrase) constructor", helv(12));
        Paragraph p6 = new Paragraph(phrase);
        doc.add(p6);

        // 2. Alignments
        doc.add(new Paragraph("--- Alignments ---", helv(12)));

        Paragraph left = new Paragraph(LOREM, helv(11));
        left.setAlignment(Element.ALIGN_LEFT);
        left.setSpacingBefore(4);
        left.setSpacingAfter(4);
        doc.add(new Paragraph("ALIGN_LEFT:", helv(10)));
        doc.add(left);

        Paragraph center = new Paragraph(LOREM, helv(11));
        center.setAlignment(Element.ALIGN_CENTER);
        center.setSpacingBefore(4);
        center.setSpacingAfter(4);
        doc.add(new Paragraph("ALIGN_CENTER:", helv(10)));
        doc.add(center);

        Paragraph right = new Paragraph(LOREM, helv(11));
        right.setAlignment(Element.ALIGN_RIGHT);
        right.setSpacingBefore(4);
        right.setSpacingAfter(4);
        doc.add(new Paragraph("ALIGN_RIGHT:", helv(10)));
        doc.add(right);

        Paragraph justified = new Paragraph(LOREM, helv(11));
        justified.setAlignment(Element.ALIGN_JUSTIFIED);
        justified.setSpacingBefore(4);
        justified.setSpacingAfter(4);
        doc.add(new Paragraph("ALIGN_JUSTIFIED:", helv(10)));
        doc.add(justified);

        // 3. Leading variants
        doc.add(new Paragraph("--- Leading Variants ---", helv(12)));

        Paragraph fixedLeading = new Paragraph(LOREM, helv(11));
        fixedLeading.setLeading(20f);
        doc.add(new Paragraph("setLeading(20f) fixed:", helv(10)));
        doc.add(fixedLeading);

        Paragraph multipliedLeading = new Paragraph(LOREM, helv(11));
        multipliedLeading.setLeading(0f, 1.8f);  // 0 fixed + 1.8x multiplier
        doc.add(new Paragraph("setLeading(0, 1.8) multiplied:", helv(10)));
        doc.add(multipliedLeading);

        // 4. Spacing before/after
        doc.add(new Paragraph("--- Spacing ---", helv(12)));
        Paragraph spaced = new Paragraph("Paragraph with spacingBefore=20 and spacingAfter=20", helv(11));
        spaced.setSpacingBefore(20f);
        spaced.setSpacingAfter(20f);
        doc.add(spaced);
        doc.add(new Paragraph("Paragraph after spaced one", helv(11)));

        // 5. First line indent
        Paragraph indented = new Paragraph(LOREM, helv(11));
        indented.setFirstLineIndent(30f);
        doc.add(new Paragraph("setFirstLineIndent(30):", helv(10)));
        doc.add(indented);

        // 6. Left/Right indentation
        Paragraph sidePadded = new Paragraph(LOREM, helv(11));
        sidePadded.setIndentationLeft(40f);
        sidePadded.setIndentationRight(40f);
        doc.add(new Paragraph("setIndentationLeft/Right(40):", helv(10)));
        doc.add(sidePadded);

        // 7. keepTogether
        Paragraph kept = new Paragraph(LOREM + " " + LOREM, helv(11));
        kept.setKeepTogether(true);
        doc.add(new Paragraph("setKeepTogether(true):", helv(10)));
        doc.add(kept);

        // 8. Extra paragraph space
        Paragraph extra = new Paragraph("8. Paragraph with setExtraParagraphSpace(12)", helv(11));
        extra.setExtraParagraphSpace(12f);
        extra.setSpacingAfter(8);
        doc.add(extra);

        // 9. CJK paragraph with justified alignment
        Paragraph cjkPara = new Paragraph(LOREM_CJK + LOREM_CJK, cjk(12));
        cjkPara.setAlignment(Element.ALIGN_JUSTIFIED);
        cjkPara.setLeading(0f, 1.5f);
        doc.add(new Paragraph("CJK Justified:", helv(10)));
        doc.add(cjkPara);

        // 10. Add mixed content
        Paragraph mixed = new Paragraph();
        mixed.add(new Chunk("10. Mixed: Latin text ", helv(12)));
        mixed.add(new Chunk("中文 ", cjk(12)));
        mixed.add(new Phrase("with Anchor", new Font(HELV_BF, 12, Font.UNDERLINE, Color.BLUE)));
        Anchor anchor = new Anchor(" [link]", new Font(HELV_BF, 12, Font.UNDERLINE, Color.BLUE));
        anchor.setReference("https://example.com");
        mixed.add(anchor);
        doc.add(mixed);

        doc.close();
        System.out.println("S05 done: " + OUT_DIR + "java_s05_paragraph.pdf");
    }
}
