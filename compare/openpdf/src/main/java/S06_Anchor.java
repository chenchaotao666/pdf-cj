import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S06_Anchor {
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
        PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s06_anchor.pdf"));
        doc.open();

        // Title
        Paragraph title = new Paragraph("S06: Anchor Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);

        // 1. Basic external URL anchor
        Font linkFont = new Font(HELV_BF, 12, Font.UNDERLINE, Color.BLUE);
        Anchor a1 = new Anchor("1. OpenPDF GitHub Page", linkFont);
        a1.setReference("https://github.com/LibrePDF/OpenPDF");
        doc.add(new Paragraph(a1));

        // 2. Anchor with setName() - named anchor (internal destination)
        Anchor namedAnchor = new Anchor("2a. [Named Anchor: top-section]", helv(12));
        namedAnchor.setName("top-section");
        doc.add(new Paragraph(namedAnchor));

        doc.add(new Paragraph("Some content below the named anchor...", helv(11)));
        doc.add(new Paragraph("More content...", helv(11)));

        // 3. Anchor embedded inside Paragraph
        Paragraph p3 = new Paragraph("3. Inline anchor: Visit ", helv(12));
        Anchor a3 = new Anchor("Google", linkFont);
        a3.setReference("https://www.google.com");
        p3.add(a3);
        p3.add(new Chunk(" for searching.", helv(12)));
        doc.add(p3);

        // 4. Anchor added directly to document
        Anchor a4 = new Anchor("4. Direct anchor to Apache", linkFont);
        a4.setReference("https://www.apache.org");
        doc.add(a4);

        // 5. Mixed text + Anchor in same paragraph
        Paragraph p5 = new Paragraph();
        p5.add(new Chunk("5. Start of paragraph. ", helv(12)));
        Anchor a5a = new Anchor("First link", linkFont);
        a5a.setReference("https://example.com/1");
        p5.add(a5a);
        p5.add(new Chunk(" — middle text — ", helv(12)));
        Anchor a5b = new Anchor("Second link", linkFont);
        a5b.setReference("https://example.com/2");
        p5.add(a5b);
        p5.add(new Chunk(" — end.", helv(12)));
        doc.add(p5);

        // 6. Internal link (goto named anchor)
        Paragraph p6 = new Paragraph("6. Internal link: ");
        Anchor a6 = new Anchor("Jump to top-section", linkFont);
        a6.setReference("#top-section");
        p6.add(a6);
        doc.add(p6);

        // 7. Named anchor with reference (both name and ref set)
        Anchor a7 = new Anchor("7. Anchor with both name and reference", linkFont);
        a7.setName("dual-anchor");
        a7.setReference("https://example.com/dual");
        doc.add(new Paragraph(a7));

        // 8. CJK anchor
        Font cjkLink = new Font(CJK_BF, 13, Font.UNDERLINE, Color.BLUE);
        Anchor a8 = new Anchor("8. 中文链接：点击访问百度", cjkLink);
        a8.setReference("https://www.baidu.com");
        doc.add(new Paragraph(a8));

        // 9. Paragraph with multiple mixed anchors
        Paragraph p9 = new Paragraph();
        p9.add(new Chunk("9. 文字 ", cjk(12)));
        Anchor a9 = new Anchor("中文链接", cjkLink);
        a9.setReference("https://example.com/cjk");
        p9.add(a9);
        p9.add(new Chunk(" and ", helv(12)));
        Anchor a9b = new Anchor("English link", linkFont);
        a9b.setReference("https://example.com/en");
        p9.add(a9b);
        p9.add(new Chunk(" in one paragraph.", helv(12)));
        doc.add(p9);

        // 10. Anchor as named destination for second page
        doc.newPage();
        Anchor pageAnchor = new Anchor("10. [Page 2 Named Anchor]", helv(12));
        pageAnchor.setName("page2-anchor");
        doc.add(new Paragraph(pageAnchor));
        doc.add(new Paragraph("This is page 2 content.", helv(12)));

        // Back reference from page 2 to page 1
        Paragraph backRef = new Paragraph("Back: ");
        Anchor backLink = new Anchor("Return to top-section", linkFont);
        backLink.setReference("#top-section");
        backRef.add(backLink);
        doc.add(backRef);

        doc.close();
        System.out.println("S06 done: " + OUT_DIR + "java_s06_anchor.pdf");
    }
}
