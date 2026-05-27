import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;
import java.util.List;

public class S04_Phrase {
    static final String FONT_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc,0";
    static final String IMG_DIR   = "../../examples/images/";
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

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();

        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s04_phrase.pdf"));
        doc.open();

        // Title
        Paragraph title = new Paragraph("S04: Phrase Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);

        // 1. No-arg constructor
        Phrase ph1 = new Phrase();
        ph1.add(new Chunk("1. Phrase (no-arg constructor)", helv(12)));
        doc.add(new Paragraph(ph1));

        // 2. Phrase(String text)
        Phrase ph2 = new Phrase("2. Phrase(String) constructor");
        doc.add(new Paragraph(ph2));

        // 3. Phrase(String text, Font font)
        Phrase ph3 = new Phrase("3. Phrase(String, Font) with bold", new Font(HELV_BF, 13, Font.BOLD));
        doc.add(new Paragraph(ph3));

        // 4. Phrase(float leading)
        Phrase ph4 = new Phrase(24f);
        ph4.add(new Chunk("4. Phrase(leading=24)", helv(12)));
        doc.add(new Paragraph(ph4));

        // 5. Phrase(float leading, String text)
        Phrase ph5 = new Phrase(20f, "5. Phrase(leading=20, text)");
        doc.add(new Paragraph(ph5));

        // 6. Phrase(float leading, String text, Font font)
        Phrase ph6 = new Phrase(18f, "6. Phrase(leading=18, text, font)", new Font(HELV_BF, 12, Font.ITALIC));
        doc.add(new Paragraph(ph6));

        // 7. add(Chunk)
        Phrase ph7 = new Phrase();
        ph7.add(new Chunk("7. add(Chunk): first", helv(12)));
        ph7.add(new Chunk(" + second chunk", new Font(HELV_BF, 12, Font.BOLD, Color.RED)));
        doc.add(new Paragraph(ph7));

        // 8. add(Phrase) - nested phrase
        Phrase inner = new Phrase("(nested phrase)", new Font(HELV_BF, 11, Font.ITALIC, Color.BLUE));
        Phrase ph8 = new Phrase("8. add(Phrase): outer ");
        ph8.add(inner);
        doc.add(new Paragraph(ph8));

        // 9. add(Chunk) — addChunk() is protected in OpenPDF 2.x, use add() instead
        Phrase ph9 = new Phrase("9. add(Chunk) [was addChunk()]: ");
        ph9.add(new Chunk("added via add(Chunk)", new Font(HELV_BF, 12, Font.BOLD)));
        doc.add(new Paragraph(ph9));

        // 10. setLeading()
        Phrase ph10 = new Phrase("10. setLeading(30): This phrase has extra leading set programmatically. " +
                "This is enough text to show the effect.");
        ph10.setLeading(30f);
        doc.add(new Paragraph(ph10));

        // 11. setFont()
        Phrase ph11 = new Phrase("11. setFont(): originally plain");
        ph11.setFont(new Font(HELV_BF, 13, Font.BOLDITALIC, Color.MAGENTA));
        doc.add(new Paragraph(ph11));

        // 12. getContent()
        Phrase ph12 = new Phrase("12. Content: ", helv(12));
        ph12.add(new Chunk("Hello World", helv(12)));
        String content = ph12.getContent();
        doc.add(new Paragraph("getContent() => \"" + content + "\"", helv(11)));

        // 13. isEmpty()
        Phrase emptyPhrase = new Phrase();
        Phrase nonEmptyPhrase = new Phrase("not empty");
        doc.add(new Paragraph("13. isEmpty() on empty phrase: " + emptyPhrase.isEmpty(), helv(12)));
        doc.add(new Paragraph("    isEmpty() on non-empty phrase: " + nonEmptyPhrase.isEmpty(), helv(12)));

        // 14. getChunks() — returns ArrayList<Element> in OpenPDF 2.x
        Phrase ph14 = new Phrase();
        ph14.add(new Chunk("chunk1", helv(12)));
        ph14.add(new Chunk("chunk2", helv(12)));
        ph14.add(new Chunk("chunk3", helv(12)));
        java.util.ArrayList chunks = ph14.getChunks();
        doc.add(new Paragraph("14. getChunks() count: " + chunks.size(), helv(12)));

        // 15. CJK Phrase
        Phrase cjkPhrase = new Phrase("15. CJK短语: 你好世界，这是短语测试。", cjk(13));
        doc.add(new Paragraph(cjkPhrase));

        // 16. Mixed phrase with CJK and Latin
        Phrase mixedPhrase = new Phrase();
        mixedPhrase.add(new Chunk("16. Mixed: Hello ", helv(12)));
        mixedPhrase.add(new Chunk("你好 ", cjk(12)));
        mixedPhrase.add(new Chunk("World ", helv(12)));
        mixedPhrase.add(new Chunk("世界", cjk(12)));
        doc.add(new Paragraph(mixedPhrase));

        doc.close();
        System.out.println("S04 done: " + OUT_DIR + "java_s04_phrase.pdf");
    }
}
