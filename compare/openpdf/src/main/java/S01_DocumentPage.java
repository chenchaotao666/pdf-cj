import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S01_DocumentPage {
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

        // Document with A4 and explicit margins: left=72, right=72, top=72, bottom=72
        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s01_document_page.pdf"));
        doc.open();

        // Page 1: show page size info and margins
        doc.addTitle("Document & Page Demo");
        float w = doc.getPageSize().getWidth();
        float h = doc.getPageSize().getHeight();
        float ml = doc.leftMargin();
        float mr = doc.rightMargin();
        float mt = doc.topMargin();
        float mb = doc.bottomMargin();

        Paragraph title = new Paragraph("S01: Document & Page Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);

        doc.add(new Paragraph("Page 1 — A4 Portrait", helv(14)));
        doc.add(new Paragraph(String.format("Page size: %.1f x %.1f pt", w, h), helv(12)));
        doc.add(new Paragraph(String.format("Margins — Left:%.1f  Right:%.1f  Top:%.1f  Bottom:%.1f", ml, mr, mt, mb), helv(12)));
        doc.add(new Paragraph(String.format("Current page number: %d", writer.getPageNumber()), helv(12)));
        doc.add(new Paragraph("中文文字测试 — CJK text on Page 1", cjk(14)));

        // Page 2: A4 rotated (landscape)
        doc.newPage();
        writer.setPageSize(PageSize.A4.rotate());
        writer.setMargins(36, 36, 36, 36);
        doc.newPage(); // force the new page size to take effect
        // Actually setPageSize takes effect on next page — add content
        doc.add(new Paragraph("Page 2 — A4 Rotated (Landscape)", helv(14)));
        float w2 = doc.getPageSize().getWidth();
        float h2 = doc.getPageSize().getHeight();
        doc.add(new Paragraph(String.format("Page size: %.1f x %.1f pt", w2, h2), helv(12)));
        doc.add(new Paragraph(String.format("Page number: %d", writer.getPageNumber()), helv(12)));
        doc.add(new Paragraph("横向页面 — Landscape page", cjk(14)));

        // Page 3: back to A4 portrait
        writer.setPageSize(PageSize.A4);
        writer.setMargins(72, 72, 72, 72);
        doc.newPage();
        doc.add(new Paragraph("Page 3 — Back to A4 Portrait", helv(14)));
        float w3 = doc.getPageSize().getWidth();
        float h3 = doc.getPageSize().getHeight();
        doc.add(new Paragraph(String.format("Page size: %.1f x %.1f pt", w3, h3), helv(12)));
        doc.add(new Paragraph(String.format("Page number: %d", writer.getPageNumber()), helv(12)));

        // Reset page count demo
        doc.resetPageCount();
        doc.add(new Paragraph(String.format("After resetPageCount(), page number: %d", writer.getPageNumber()), helv(12)));
        doc.add(new Paragraph("第三页 — Page 3 (A4竖向)", cjk(14)));

        doc.close();
        System.out.println("S01 done: " + OUT_DIR + "java_s01_document_page.pdf");
    }
}
