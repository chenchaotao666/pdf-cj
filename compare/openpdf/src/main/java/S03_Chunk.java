import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S03_Chunk {
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
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s03_chunk.pdf"));
        doc.open();

        // Title
        Paragraph title = new Paragraph("S03: Chunk Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);

        // 1. Basic Chunk constructor
        Chunk c1 = new Chunk("1. Basic Chunk text  ", helv(12));
        doc.add(new Paragraph(c1));

        // 2. Chunk with font
        Chunk c2 = new Chunk("2. Chunk with font: ", helv(12));
        c2.setFont(new Font(HELV_BF, 14, Font.BOLD, Color.BLUE));
        doc.add(new Paragraph(c2));

        // 3. Chunk with underline
        Paragraph p3 = new Paragraph();
        Chunk c3 = new Chunk("3. Underlined chunk text", helv(12));
        c3.setUnderline(0.5f, -2f);  // thickness, yPos (negative = below baseline)
        p3.add(c3);
        doc.add(p3);

        // 4. Strikethrough simulation via setUnderline with positive yPos
        Paragraph p4 = new Paragraph();
        Chunk c4 = new Chunk("4. Strikethrough simulation", helv(12));
        c4.setUnderline(0.6f, 4f);  // positive y = above baseline = strikethrough effect
        p4.add(c4);
        doc.add(p4);

        // 5. Multiple underlines (called twice)
        Paragraph p5 = new Paragraph();
        Chunk c5 = new Chunk("5. Double underline chunk", helv(12));
        c5.setUnderline(0.5f, -2f);
        c5.setUnderline(0.5f, -5f);
        p5.add(c5);
        doc.add(p5);

        // 6. Background color
        Paragraph p6 = new Paragraph();
        Chunk c6 = new Chunk("6. Background color chunk", helv(12));
        c6.setBackground(new Color(255, 255, 0), 1f, 1f, 1f, 2f);  // yellow, extraLeft,Bottom,Right,Top
        p6.add(c6);
        doc.add(p6);

        // 7. Anchor URL
        Paragraph p7 = new Paragraph("7. Anchor URL: ");
        Chunk c7 = new Chunk("Click here for OpenPDF", new Font(HELV_BF, 12, Font.UNDERLINE, Color.BLUE));
        c7.setAnchor("https://github.com/LibrePDF/OpenPDF");
        p7.add(c7);
        doc.add(p7);

        // 8. Local destination and goto
        Paragraph p8dest = new Paragraph();
        Chunk destChunk = new Chunk("8a. [Destination: section1]", helv(12));
        destChunk.setLocalDestination("section1");
        p8dest.add(destChunk);
        doc.add(p8dest);

        Paragraph p8goto = new Paragraph();
        Chunk gotoChunk = new Chunk("8b. Jump to section1 above", new Font(HELV_BF, 12, Font.UNDERLINE, Color.BLUE));
        gotoChunk.setLocalGoto("section1");
        p8goto.add(gotoChunk);
        doc.add(p8goto);

        // 9. Generic tag
        Paragraph p9 = new Paragraph();
        Chunk c9 = new Chunk("9. Chunk with generic tag", helv(12));
        c9.setGenericTag("myTag");
        p9.add(c9);
        doc.add(p9);

        // 10. Chunk.NEWLINE
        Paragraph p10 = new Paragraph("10. Before NEWLINE");
        p10.add(Chunk.NEWLINE);
        p10.add(new Chunk("After NEWLINE", helv(12)));
        doc.add(p10);

        // 11. TAB (Chunk.SPACETABBING not available in OpenPDF 2.x, use a tab character)
        Paragraph p11 = new Paragraph("11. Tab:");
        p11.add(new Chunk("\t", helv(12)));  // TAB character
        p11.add(new Chunk("After tab", helv(12)));
        doc.add(p11);

        // 12. append()
        Chunk c12 = new Chunk("12. First part", helv(12));
        c12.append(" — appended part");
        doc.add(new Paragraph(c12));

        // 13. getWidthPoint()
        Chunk c13 = new Chunk("13. Width measurement", helv(12));
        float width = c13.getWidthPoint();
        doc.add(new Paragraph(c13));
        doc.add(new Paragraph("    (width = " + width + " pt)", helv(10)));

        // 14. Chunk.NEWPAGE
        Paragraph p14 = new Paragraph("14. Before NEWPAGE — next content on new page");
        p14.add(Chunk.NEWPAGE);
        doc.add(p14);
        doc.add(new Paragraph("After NEWPAGE — on page 2", helv(14)));

        // 15. CJK Chunk
        Chunk cjkChunk = new Chunk("15. CJK块: 这是仓颉文字块测试", cjk(14));
        cjkChunk.setBackground(new Color(200, 230, 255), 1f, 1f, 1f, 2f);
        doc.add(new Paragraph(cjkChunk));

        doc.close();
        System.out.println("S03 done: " + OUT_DIR + "java_s03_chunk.pdf");
    }
}
