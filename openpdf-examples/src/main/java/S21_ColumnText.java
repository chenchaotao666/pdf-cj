import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S21_ColumnText {
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

    static final String ARTICLE_LEFT =
        "The ancient art of PDF generation has long fascinated developers. " +
        "OpenPDF provides a rich set of tools for creating professional documents. " +
        "With ColumnText, you can lay out content in multiple columns, wrap text, " +
        "and handle overflow seamlessly across pages. " +
        "This left column demonstrates a long article that flows from the first page " +
        "to subsequent pages, illustrating the power of ColumnText layout. " +
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " +
        "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. " +
        "Ut enim ad minim veniam, quis nostrud exercitation ullamco. " +
        "Duis aute irure dolor in reprehenderit in voluptate velit esse. " +
        "Cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat. " +
        "Cupidatat non proident, sunt in culpa qui officia deserunt mollit. " +
        "Anim id est laborum. Sed ut perspiciatis unde omnis iste natus error. " +
        "Sit voluptatem accusantium doloremque laudantium, totam rem aperiam. " +
        "Eaque ipsa quae ab illo inventore veritatis et quasi architecto. " +
        "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit. ";

    static final String ARTICLE_RIGHT =
        "右栏内容：这是右侧栏的中文文章内容，用于展示ColumnText的多栏排版功能。" +
        "PDF文档的多栏排版在报纸、杂志等出版物中非常常见。" +
        "OpenPDF的ColumnText类提供了强大的文字排版功能，支持多栏布局。" +
        "通过setSimpleColumn方法可以设置栏的边界，通过go方法可以渲染内容。" +
        "当内容超出当前栏的边界时，可以检测溢出状态并翻页继续排版。" +
        "这种能力使得OpenPDF非常适合用于生成复杂的报告、书籍和杂志等文档。" +
        "Right column: Text extraction and layout in multiple columns. " +
        "ColumnText supports both simple columns and complex custom shapes. " +
        "You can mix CJK and Latin text in the same column layout. " +
        "The overflow handling ensures all content is properly rendered. " +
        "Additional text to ensure this column also overflows to the next page. " +
        "More content here to demonstrate multi-page column text rendering. ";

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();

        Document doc = new Document(PageSize.A4, 50, 50, 72, 60);
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s21_column_text.pdf"));
        doc.open();

        PdfContentByte cb = writer.getDirectContent();

        // Page dimensions
        float pageWidth = doc.getPageSize().getWidth();
        float pageHeight = doc.getPageSize().getHeight();
        float leftMargin = 50;
        float rightMargin = 50;
        float topMargin = 72;
        float bottomMargin = 60;
        float colGap = 20;
        float colWidth = (pageWidth - leftMargin - rightMargin - colGap) / 2;

        // Column bounds
        float col1LLX = leftMargin;
        float col1URX = leftMargin + colWidth;
        float col2LLX = leftMargin + colWidth + colGap;
        float col2URX = pageWidth - rightMargin;
        float colTop = pageHeight - topMargin;
        float colBottom = bottomMargin;

        // Title
        cb.beginText();
        cb.setFontAndSize(CJK_BF, 18);
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER, "S21: ColumnText Demo — 多栏排版", pageWidth / 2, pageHeight - 50, 0);
        cb.endText();

        // Draw column divider line
        cb.saveState();
        cb.setColorStroke(new Color(200, 200, 200));
        cb.setLineWidth(0.5f);
        cb.moveTo((col1URX + col2LLX) / 2, colTop - 30);
        cb.lineTo((col1URX + col2LLX) / 2, colBottom);
        cb.stroke();
        cb.restoreState();

        // Build content for both columns
        // Left column content
        ColumnText ct1 = new ColumnText(cb);
        ct1.setAlignment(Element.ALIGN_JUSTIFIED);
        ct1.setLeading(0f, 1.4f);

        // Add header to left column
        Paragraph leftHeader = new Paragraph("Left Column: English Article", new Font(HELV_BF, 12, Font.BOLD));
        leftHeader.setSpacingAfter(8);
        ct1.addElement(leftHeader);

        // Add article text, repeat for more content
        for (int i = 0; i < 3; i++) {
            Paragraph p = new Paragraph(ARTICLE_LEFT, helv(10));
            p.setAlignment(Element.ALIGN_JUSTIFIED);
            p.setSpacingAfter(6);
            ct1.addElement(p);
        }

        // Right column content
        ColumnText ct2 = new ColumnText(cb);
        ct2.setAlignment(Element.ALIGN_JUSTIFIED);
        ct2.setLeading(0f, 1.4f);
        ct2.setIndent(10f);
        ct2.setFollowingIndent(0f);
        ct2.setRightIndent(5f);

        Paragraph rightHeader = new Paragraph("右栏：中文文章", cjkBold(12));
        rightHeader.setSpacingAfter(8);
        ct2.addElement(rightHeader);

        for (int i = 0; i < 3; i++) {
            Paragraph p = new Paragraph(ARTICLE_RIGHT, cjk(10));
            p.setAlignment(Element.ALIGN_JUSTIFIED);
            p.setSpacingAfter(6);
            ct2.addElement(p);
        }

        // Render columns page by page
        boolean done1 = false, done2 = false;
        boolean firstPage = true;
        int pageNum = 1;

        while (!done1 || !done2) {
            if (!firstPage) {
                doc.newPage();
                cb = writer.getDirectContent();

                // Redraw divider
                cb.saveState();
                cb.setColorStroke(new Color(200, 200, 200));
                cb.setLineWidth(0.5f);
                cb.moveTo((col1URX + col2LLX) / 2, colTop);
                cb.lineTo((col1URX + col2LLX) / 2, colBottom);
                cb.stroke();
                cb.restoreState();

                // Update cb references
                ct1 = new ColumnText(cb);
                ct1.setAlignment(Element.ALIGN_JUSTIFIED);
                ct1.setLeading(0f, 1.4f);

                ct2 = new ColumnText(cb);
                ct2.setAlignment(Element.ALIGN_JUSTIFIED);
                ct2.setLeading(0f, 1.4f);
            }

            // Render left column
            if (!done1) {
                ct1.setSimpleColumn(col1LLX, colBottom, col1URX, firstPage ? colTop - 30 : colTop);
                int status1 = ct1.go();
                done1 = !ColumnText.hasMoreText(status1);
            }

            // Render right column
            if (!done2) {
                ct2.setSimpleColumn(col2LLX, colBottom, col2URX, firstPage ? colTop - 30 : colTop);
                int status2 = ct2.go();
                done2 = !ColumnText.hasMoreText(status2);
            }

            // Page footer
            cb.beginText();
            cb.setFontAndSize(HELV_BF, 8);
            cb.setColorFill(Color.GRAY);
            cb.showTextAligned(PdfContentByte.ALIGN_CENTER,
                    "Page " + pageNum + " — S21 ColumnText Demo", pageWidth / 2, 30, 0);
            cb.endText();

            firstPage = false;
            pageNum++;

            // Safety check to avoid infinite loop
            if (pageNum > 10) break;
        }

        doc.close();
        System.out.println("S21 done: " + OUT_DIR + "java_s21_column_text.pdf");
    }
}
