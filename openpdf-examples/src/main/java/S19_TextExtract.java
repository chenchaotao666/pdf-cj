import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;
import java.util.*;

public class S19_TextExtract {
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

    // Create a source PDF with known content
    static byte[] createSourcePdf() throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter w = PdfWriter.getInstance(doc, baos);
        w.setPdfVersion(PdfWriter.VERSION_1_7);
        doc.addTitle("S19 Text Extract Source");
        doc.addAuthor("OpenPDF Test");
        doc.addSubject("Text extraction test document");
        doc.addKeywords("test, extraction, OpenPDF");
        doc.open();

        doc.add(new Paragraph("S19: Text Extraction Source PDF", new Font(HELV_BF, 18, Font.BOLD)));
        doc.add(new Paragraph("Page 1 of 2", new Font(HELV_BF, 12)));
        doc.add(new Paragraph("Known text line 1: The quick brown fox jumps over the lazy dog.", new Font(HELV_BF, 11)));
        doc.add(new Paragraph("Known text line 2: Pack my box with five dozen liquor jugs.", new Font(HELV_BF, 11)));
        doc.add(new Paragraph("Known text line 3: 中文文字提取测试内容。", new Font(CJK_BF, 11)));
        doc.add(new Paragraph("Numbers: 1234567890", new Font(HELV_BF, 11)));
        doc.add(new Paragraph("Special: !@#$%^&*()_+", new Font(HELV_BF, 11)));

        doc.newPage();
        doc.add(new Paragraph("Page 2 of 2", new Font(HELV_BF, 14, Font.BOLD)));
        doc.add(new Paragraph("Second page content for extraction.", new Font(HELV_BF, 11)));

        doc.close();
        return baos.toByteArray();
    }

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();

        // Create the source PDF
        byte[] sourceBytes = createSourcePdf();

        // Save it as the output file
        try (FileOutputStream fos = new FileOutputStream(OUT_DIR + "java_s19_text_extract.pdf")) {
            fos.write(sourceBytes);
        }
        System.out.println("S19 source PDF saved: " + OUT_DIR + "java_s19_text_extract.pdf");

        // Now read it with PdfReader
        PdfReader reader = new PdfReader(sourceBytes);

        System.out.println("\n=== PdfReader Info ===");
        System.out.println("Number of pages: " + reader.getNumberOfPages());
        System.out.println("Page 1 size: " + reader.getPageSize(1));
        System.out.println("Page 2 size: " + reader.getPageSize(2));
        System.out.println("PDF version: " + reader.getPdfVersion());

        // Get document info
        Map<String, String> info = reader.getInfo();
        System.out.println("\n=== Document Info (reader.getInfo()) ===");
        for (Map.Entry<String, String> entry : info.entrySet()) {
            System.out.println("  " + entry.getKey() + ": " + entry.getValue());
        }

        // Try PdfTextExtractor
        System.out.println("\n=== Text Extraction Attempt ===");
        try {
            Class<?> extractorClass = Class.forName("com.lowagie.text.pdf.PdfTextExtractor");
            System.out.println("PdfTextExtractor class found in OpenPDF 2.x");
            // Try to use it via reflection
            for (int page = 1; page <= reader.getNumberOfPages(); page++) {
                try {
                    Object extractor = extractorClass.getConstructor(PdfReader.class).newInstance(reader);
                    String text = (String) extractorClass.getMethod("getTextFromPage", int.class)
                            .invoke(extractor, page);
                    System.out.println("  Page " + page + " extracted text:\n" + text.substring(0, Math.min(200, text.length())));
                } catch (Exception e) {
                    System.out.println("  Page " + page + " extraction failed: " + e.getMessage());
                }
            }
        } catch (ClassNotFoundException e) {
            System.out.println("PdfTextExtractor not available in this OpenPDF version");
            System.out.println("Using raw content stream instead...");

            // Fallback: get raw content stream bytes
            for (int page = 1; page <= reader.getNumberOfPages(); page++) {
                byte[] contentBytes = reader.getPageContent(page);
                String rawContent = new String(contentBytes, java.nio.charset.StandardCharsets.ISO_8859_1);
                // Show first 500 chars
                int limit = Math.min(500, rawContent.length());
                System.out.println("  Page " + page + " raw content stream (" + contentBytes.length + " bytes):");
                System.out.println("  [First " + limit + " chars]: " + rawContent.substring(0, limit).replaceAll("\\s+", " "));
            }
        }

        reader.close();
        System.out.println("\nS19 done.");
    }
}
