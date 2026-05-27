import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S07_Table {
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

    static PdfPCell hdrCell(String text) {
        PdfPCell cell = new PdfPCell(new Phrase(text, new Font(HELV_BF, 11, Font.BOLD, Color.WHITE)));
        cell.setBackgroundColor(new Color(50, 50, 150));
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setPadding(6);
        return cell;
    }

    static PdfPCell dataCell(String text) {
        PdfPCell cell = new PdfPCell(new Phrase(text, new Font(HELV_BF, 10)));
        cell.setHorizontalAlignment(Element.ALIGN_LEFT);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setPadding(5);
        return cell;
    }

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();

        Document doc = new Document(PageSize.A4, 50, 50, 72, 72);
        PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s07_table.pdf"));
        doc.open();

        // Title
        Paragraph title = new Paragraph("S07: PdfPTable Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);

        // ---- Table 1: Basic cell properties ----
        doc.add(new Paragraph("Table 1: Basic Cell Properties", new Font(HELV_BF, 13, Font.BOLD)));
        PdfPTable t1 = new PdfPTable(4);
        t1.setWidthPercentage(100);
        t1.setWidths(new float[]{2f, 2f, 2f, 2f});
        t1.setSpacingBefore(8);
        t1.setSpacingAfter(16);

        // Header row
        for (String h : new String[]{"Column A", "Column B", "Column C", "Column D"}) {
            t1.addCell(hdrCell(h));
        }

        // Row with different paddings
        PdfPCell c1 = new PdfPCell(new Phrase("PaddingLeft=20", helv(10)));
        c1.setPaddingLeft(20);
        t1.addCell(c1);

        PdfPCell c2 = new PdfPCell(new Phrase("PaddingTop=15", helv(10)));
        c2.setPaddingTop(15);
        t1.addCell(c2);

        PdfPCell c3 = new PdfPCell(new Phrase("PaddingRight=20", helv(10)));
        c3.setPaddingRight(20);
        t1.addCell(c3);

        PdfPCell c4 = new PdfPCell(new Phrase("PaddingBottom=15", helv(10)));
        c4.setPaddingBottom(15);
        t1.addCell(c4);

        // Row with background color
        PdfPCell bg1 = dataCell("Yellow BG");
        bg1.setBackgroundColor(new Color(255, 255, 0));
        t1.addCell(bg1);

        PdfPCell bg2 = dataCell("Cyan BG");
        bg2.setBackgroundColor(new Color(0, 255, 255));
        t1.addCell(bg2);

        PdfPCell bg3 = dataCell("Pink BG");
        bg3.setBackgroundColor(new Color(255, 200, 200));
        t1.addCell(bg3);

        PdfPCell bg4 = dataCell("Green BG");
        bg4.setBackgroundColor(new Color(200, 255, 200));
        t1.addCell(bg4);

        // Row with borders
        PdfPCell noBorder = dataCell("No border");
        noBorder.setBorder(Rectangle.NO_BORDER);
        t1.addCell(noBorder);

        PdfPCell topBorder = dataCell("Top only");
        topBorder.setBorder(Rectangle.TOP);
        topBorder.setBorderWidth(2f);
        t1.addCell(topBorder);

        PdfPCell thickBorder = dataCell("Thick border");
        thickBorder.setBorderWidth(3f);
        t1.addCell(thickBorder);

        PdfPCell noWrap = dataCell("NoWrap=true content here");
        noWrap.setNoWrap(true);
        t1.addCell(noWrap);

        // Row with fixed/min height
        PdfPCell fixedH = dataCell("fixedHeight=40");
        fixedH.setFixedHeight(40f);
        t1.addCell(fixedH);

        PdfPCell minH = dataCell("minHeight=30");
        minH.setMinimumHeight(30f);
        t1.addCell(minH);

        // addElement demo
        PdfPCell elemCell = new PdfPCell();
        Paragraph elemPara = new Paragraph("addElement(Para)", helv(10));
        elemPara.setAlignment(Element.ALIGN_CENTER);
        elemCell.addElement(elemPara);
        t1.addCell(elemCell);

        // setPhrase demo
        PdfPCell phraseCell = new PdfPCell();
        phraseCell.setPhrase(new Phrase("setPhrase()", helv(10)));
        t1.addCell(phraseCell);

        doc.add(t1);

        // ---- Table 2: Colspan and Rowspan ----
        doc.add(new Paragraph("Table 2: Colspan and Rowspan", new Font(HELV_BF, 13, Font.BOLD)));
        PdfPTable t2 = new PdfPTable(4);
        t2.setWidthPercentage(100);
        t2.setSpacingBefore(8);
        t2.setSpacingAfter(16);

        // Row 1: colspan=4 header
        PdfPCell topSpan = hdrCell("Full Width Header (colspan=4)");
        topSpan.setColspan(4);
        t2.addCell(topSpan);

        // Row 2: colspan=2 + 2 normal cells
        PdfPCell span2 = new PdfPCell(new Phrase("colspan=2", helv(10)));
        span2.setColspan(2);
        span2.setBackgroundColor(new Color(200, 220, 255));
        span2.setPadding(6);
        t2.addCell(span2);
        t2.addCell(dataCell("Cell 3"));
        t2.addCell(dataCell("Cell 4"));

        // Row 3: rowspan=2 on first cell + 3 normal cells
        PdfPCell rowSpan = new PdfPCell(new Phrase("rowspan=2", helv(10)));
        rowSpan.setRowspan(2);
        rowSpan.setBackgroundColor(new Color(255, 220, 200));
        rowSpan.setVerticalAlignment(Element.ALIGN_MIDDLE);
        rowSpan.setHorizontalAlignment(Element.ALIGN_CENTER);
        rowSpan.setPadding(6);
        t2.addCell(rowSpan);
        t2.addCell(dataCell("R3-C2"));
        t2.addCell(dataCell("R3-C3"));
        t2.addCell(dataCell("R3-C4"));

        // Row 4: 3 cells (rowspan cell spans row 3 and 4)
        t2.addCell(dataCell("R4-C2"));
        t2.addCell(dataCell("R4-C3"));
        t2.addCell(dataCell("R4-C4"));

        // Row 5: colspan=2 x2
        PdfPCell span2a = new PdfPCell(new Phrase("Bottom Left (colspan=2)", helv(10)));
        span2a.setColspan(2);
        span2a.setBackgroundColor(new Color(230, 255, 230));
        span2a.setPadding(6);
        t2.addCell(span2a);

        PdfPCell span2b = new PdfPCell(new Phrase("Bottom Right (colspan=2)", helv(10)));
        span2b.setColspan(2);
        span2b.setBackgroundColor(new Color(255, 230, 255));
        span2b.setPadding(6);
        t2.addCell(span2b);

        doc.add(t2);

        // ---- Table 3: Long table with header/footer rows spanning pages ----
        doc.add(new Paragraph("Table 3: Long Table with Header Rows (spans to page 2)", new Font(HELV_BF, 13, Font.BOLD)));
        PdfPTable t3 = new PdfPTable(5);
        t3.setWidthPercentage(100);
        t3.setWidths(new float[]{1f, 2f, 2f, 2f, 1f});
        t3.setSpacingBefore(8);
        t3.setSpacingAfter(16);
        t3.setHeaderRows(2);  // first 2 rows repeat as header on each page
        t3.setFooterRows(1);  // last 1 of headerRows is footer
        t3.setSkipFirstHeader(false);

        // Header row 1
        for (String h : new String[]{"#", "Name", "Description", "Value", "Status"}) {
            t3.addCell(hdrCell(h));
        }
        // Footer row (counted in headerRows)
        PdfPCell footerCell = new PdfPCell(new Phrase("Footer — repeated on each page", helv(9)));
        footerCell.setColspan(5);
        footerCell.setBackgroundColor(new Color(200, 200, 200));
        footerCell.setHorizontalAlignment(Element.ALIGN_CENTER);
        footerCell.setPadding(4);
        t3.addCell(footerCell);

        // Add 40 data rows to force page overflow
        String[] statuses = {"OK", "WARN", "ERROR", "INFO"};
        Color[] statusColors = {new Color(200,255,200), new Color(255,255,200), new Color(255,200,200), new Color(200,230,255)};
        for (int i = 1; i <= 40; i++) {
            t3.addCell(dataCell(String.valueOf(i)));
            t3.addCell(dataCell("Item " + i));
            t3.addCell(dataCell("Description for row " + i));
            t3.addCell(dataCell("$" + (i * 9.99)));
            PdfPCell statusCell = dataCell(statuses[i % 4]);
            statusCell.setBackgroundColor(statusColors[i % 4]);
            statusCell.setHorizontalAlignment(Element.ALIGN_CENTER);
            t3.addCell(statusCell);
        }
        doc.add(t3);

        // ---- Table 4: Total width locked ----
        doc.add(new Paragraph("Table 4: Total Width Locked + disableBorderSide", new Font(HELV_BF, 13, Font.BOLD)));
        PdfPTable t4 = new PdfPTable(3);
        t4.setTotalWidth(350f);
        t4.setLockedWidth(true);
        t4.setSpacingBefore(8);
        t4.setSpacingAfter(16);
        for (String h : new String[]{"Col 1", "Col 2", "Col 3"}) {
            t4.addCell(hdrCell(h));
        }
        for (int row = 0; row < 3; row++) {
            for (int col = 0; col < 3; col++) {
                PdfPCell cell = dataCell("R" + (row+1) + "C" + (col+1));
                if (col == 0) cell.disableBorderSide(Rectangle.LEFT);
                if (col == 2) cell.disableBorderSide(Rectangle.RIGHT);
                t4.addCell(cell);
            }
        }
        doc.add(t4);

        doc.close();
        System.out.println("S07 done: " + OUT_DIR + "java_s07_table.pdf");
    }
}
