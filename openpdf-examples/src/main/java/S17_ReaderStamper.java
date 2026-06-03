import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;
import java.util.*;

public class S17_ReaderStamper {
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

    // Create a simple multi-page source PDF in memory
    static byte[] createSourcePdf() throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter.getInstance(doc, baos);
        doc.open();

        for (int i = 1; i <= 3; i++) {
            if (i > 1) doc.newPage();
            Paragraph p = new Paragraph("Source PDF — Page " + i, new Font(HELV_BF, 18, Font.BOLD));
            p.setAlignment(Element.ALIGN_CENTER);
            doc.add(p);
            doc.add(new Paragraph("This is page " + i + " of the source document.", new Font(HELV_BF, 12)));
            doc.add(new Paragraph("Content: Lorem ipsum dolor sit amet, consectetur adipiscing elit.", new Font(HELV_BF, 11)));
            doc.add(new Paragraph("Page " + i + " of 3", new Font(HELV_BF, 10)));
        }
        doc.close();
        return baos.toByteArray();
    }

    // Create a form PDF in memory with text fields
    static byte[] createFormPdf() throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter formWriter = PdfWriter.getInstance(doc, baos);
        doc.open();

        doc.add(new Paragraph("Form PDF", new Font(HELV_BF, 18, Font.BOLD)));
        doc.add(new Paragraph("Please fill in the fields below:", new Font(HELV_BF, 12)));

        // Add form fields
        float y = 680;
        String[] labels = {"Name", "Email", "Company"};
        for (String label : labels) {
            doc.add(new Paragraph(label + ":", new Font(HELV_BF, 11)));
            Rectangle rect = new Rectangle(200, y - 20, 480, y);
            TextField tf = new TextField(formWriter, rect, label.toLowerCase());
            tf.setFontSize(11);
            tf.setFont(HELV_BF);
            tf.setBorderColor(Color.GRAY);
            tf.setBackgroundColor(new Color(245, 245, 255));
            formWriter.addAnnotation(tf.getTextField());
            y -= 40;
        }

        doc.close();
        return baos.toByteArray();
    }

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();

        // ---- Part 1: Watermark with PdfStamper ----
        byte[] sourceBytes = createSourcePdf();
        PdfReader reader = new PdfReader(sourceBytes);

        FileOutputStream watermarkedOut = new FileOutputStream(OUT_DIR + "java_s17_reader_stamper.pdf");
        PdfStamper stamper = new PdfStamper(reader, watermarkedOut);

        System.out.println("  Source PDF pages: " + stamper.getReader().getNumberOfPages());
        System.out.println("  Page 1 size: " + stamper.getReader().getPageSize(1));

        // Set additional metadata via setInfoDictionary
        Map<String, String> moreInfo = new HashMap<>();
        moreInfo.put("Watermarked", "true");
        moreInfo.put("StampedBy", "S17_ReaderStamper");
        stamper.setInfoDictionary(moreInfo);

        // Add watermark to each page
        int numPages = stamper.getReader().getNumberOfPages();
        for (int page = 1; page <= numPages; page++) {
            // Over content (on top of existing content)
            PdfContentByte over = stamper.getOverContent(page);
            over.saveState();
            PdfGState gs = new PdfGState();
            gs.setFillOpacity(0.15f);
            over.setGState(gs);
            over.beginText();
            over.setFontAndSize(HELV_BF, 60);
            over.setColorFill(Color.RED);
            over.showTextAligned(PdfContentByte.ALIGN_CENTER,
                    "WATERMARK", 297, 420, 45);
            over.endText();
            over.restoreState();

            // Under content (behind existing content)
            PdfContentByte under = stamper.getUnderContent(page);
            under.saveState();
            under.setColorFill(new Color(240, 248, 255));
            under.rectangle(0, 0, 595, 842);
            under.fill();
            under.restoreState();

            // Add page label
            over.beginText();
            over.setFontAndSize(HELV_BF, 9);
            over.setColorFill(Color.DARK_GRAY);
            over.setTextMatrix(72, 20);
            over.showText("Stamped — Page " + page + " of " + numPages);
            over.endText();
        }

        stamper.close();
        reader.close();
        System.out.println("  Watermarked PDF: " + OUT_DIR + "java_s17_reader_stamper.pdf");

        // ---- Part 2: Form fill with AcroFields ----
        byte[] formBytes = createFormPdf();
        PdfReader formReader = new PdfReader(formBytes);

        FileOutputStream formFilledOut = new FileOutputStream(OUT_DIR + "java_s17_form_filled.pdf");
        PdfStamper formStamper = new PdfStamper(formReader, formFilledOut);

        AcroFields acroFields = formStamper.getAcroFields();
        // Fill each field
        try { acroFields.setField("name", "Jane Doe"); } catch (Exception e) { System.out.println("  name field: " + e.getMessage()); }
        try { acroFields.setField("email", "jane@example.com"); } catch (Exception e) { System.out.println("  email field: " + e.getMessage()); }
        try { acroFields.setField("company", "OpenPDF Corp"); } catch (Exception e) { System.out.println("  company field: " + e.getMessage()); }

        // Print available field names — use getAllFields() in OpenPDF 2.x
        Map<String, AcroFields.Item> fields = acroFields.getAllFields();
        System.out.println("  Form fields found: " + fields.keySet());

        formStamper.close();
        formReader.close();
        System.out.println("  Form filled PDF: " + OUT_DIR + "java_s17_form_filled.pdf");

        System.out.println("S17 done.");
    }
}
