import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S02_FontText {
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

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();

        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s02_font_text.pdf"));
        doc.open();

        // Title
        Paragraph title = new Paragraph("S02: Font & Text Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);

        // 1. CJK font - normal
        doc.add(new Paragraph("1. CJK Normal: 你好，世界！Hello World！", cjk(14)));

        // 2. CJK font - bold
        doc.add(new Paragraph("2. CJK Bold: 粗体文字测试", cjkBold(14)));

        // 3. Helvetica normal
        doc.add(new Paragraph("3. Helvetica Normal: The quick brown fox", helv(14)));

        // 4. Helvetica Bold
        Font helvBold = new Font(HELV_BF, 14, Font.BOLD);
        doc.add(new Paragraph("4. Helvetica Bold: Bold text sample", helvBold));

        // 5. Helvetica Italic
        Font helvItalic = new Font(HELV_BF, 14, Font.ITALIC);
        doc.add(new Paragraph("5. Helvetica Italic: Italic text sample", helvItalic));

        // 6. Helvetica BoldItalic
        Font helvBoldItalic = new Font(HELV_BF, 14, Font.BOLDITALIC);
        doc.add(new Paragraph("6. Helvetica BoldItalic: BoldItalic text", helvBoldItalic));

        // 7. Font with color (4-arg constructor)
        Font colorFont = new Font(HELV_BF, 14, Font.NORMAL, Color.RED);
        doc.add(new Paragraph("7. Font with color (RED): Colored text", colorFont));

        // 8. Font with color - blue bold
        Font blueBold = new Font(HELV_BF, 14, Font.BOLD, Color.BLUE);
        doc.add(new Paragraph("8. Blue Bold font: Blue bold text", blueBold));

        // 9. CJK with color
        Font cjkColor = new Font(CJK_BF, 14, Font.NORMAL, new Color(0, 128, 0));
        doc.add(new Paragraph("9. CJK Green: 绿色中文字体", cjkColor));

        // 10. FontSelector - mix CJK and Latin
        doc.add(new Paragraph("--- FontSelector Demo ---", helv(12)));
        FontSelector selector = new FontSelector();
        selector.addFont(cjk(12));
        selector.addFont(helv(12));
        Phrase mixed = selector.process("Mixed: Hello 你好 World 世界 123");
        doc.add(new Paragraph(mixed));

        // 11. FontFactory.getFont (built-in font)
        doc.add(new Paragraph("--- FontFactory Demo ---", helv(12)));
        Font ffHelv = FontFactory.getFont(FontFactory.HELVETICA, 13, Font.NORMAL, Color.DARK_GRAY);
        doc.add(new Paragraph("11. FontFactory Helvetica: Sample text", ffHelv));

        Font ffCourier = FontFactory.getFont(FontFactory.COURIER, 12, Font.BOLD);
        doc.add(new Paragraph("12. FontFactory Courier Bold: Monospace text", ffCourier));

        Font ffTimes = FontFactory.getFont(FontFactory.TIMES_ROMAN, 13, Font.ITALIC);
        doc.add(new Paragraph("13. FontFactory Times Italic: Serif italic text", ffTimes));

        // 14. Font size variations
        doc.add(new Paragraph("--- Size Variations ---", helv(12)));
        for (float size : new float[]{8, 10, 12, 14, 16, 18, 24}) {
            doc.add(new Paragraph("Size " + size + ": Sample text 示例文字", cjk(size)));
        }

        // 15. Underline and strikethrough via Font
        Font underlineFont = new Font(HELV_BF, 14, Font.UNDERLINE);
        doc.add(new Paragraph("15. Underline: Underlined text", underlineFont));

        Font strikeFont = new Font(HELV_BF, 14, Font.STRIKETHRU);
        doc.add(new Paragraph("16. Strikethrough: Strikethrough text", strikeFont));

        doc.close();
        System.out.println("S02 done: " + OUT_DIR + "java_s02_font_text.pdf");
    }
}
