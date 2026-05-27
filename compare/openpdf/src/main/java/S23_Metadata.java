import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;
import java.util.*;

public class S23_Metadata {
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

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter writer = PdfWriter.getInstance(doc, baos);

        // Set PDF version
        writer.setPdfVersion(PdfWriter.VERSION_1_7);

        // Add DocListener demo — implement all methods required by DocListener interface in OpenPDF 2.x
        doc.addDocListener(new DocListener() {
            @Override public void open() {
                System.out.println("  [DocListener] document opened");
            }
            @Override public void close() {
                System.out.println("  [DocListener] document closed");
            }
            @Override public boolean add(Element element) throws DocumentException {
                return true;
            }
            @Override public boolean newPage() {
                System.out.println("  [DocListener] new page");
                return true;
            }
            @Override public boolean setPageSize(Rectangle pageSize) { return true; }
            @Override public boolean setMargins(float marginLeft, float marginRight, float marginTop, float marginBottom) { return true; }
            @Override public boolean setMarginMirroring(boolean marginMirroring) { return true; }
            @Override public boolean setMarginMirroringTopBottom(boolean marginMirroringTopBottom) { return true; }
            @Override public void resetPageCount() {}
            @Override public void setPageCount(int pageN) {}
            @Override public void setHeader(HeaderFooter header) {}
            @Override public void resetHeader() {}
            @Override public void setFooter(HeaderFooter footer) {}
            @Override public void resetFooter() {}
        });

        // Set metadata BEFORE doc.open()
        doc.addTitle("S23 Metadata Demo Document");
        doc.addAuthor("OpenPDF Test Author");
        doc.addSubject("Demonstrating PDF metadata features");
        doc.addKeywords("OpenPDF, metadata, PDF, Java, test");
        doc.addCreator("S23_Metadata.java");
        doc.addCreationDate();

        doc.open();

        // Add JavaScript via PdfWriter (not Document) in OpenPDF 2.x
        try {
            writer.addJavaScript("// PDF JavaScript\nvar docTitle = this.info.Title;");
        } catch (Exception e) {
            System.out.println("  addJavaScript: " + e.getMessage());
        }

        // Add custom header (arbitrary metadata key/value)
        try {
            doc.addHeader("CustomKey1", "CustomValue1");
            doc.addHeader("CustomKey2", "仓颉语言PDF测试");
            doc.addHeader("Project", "pdf-cj");
        } catch (Exception e) {
            System.out.println("  addHeader: " + e.getMessage());
        }

        // addJavaScript is on PdfWriter (not Document) in OpenPDF 2.x
        // We'll call it after doc.open()

        // Title
        Paragraph title = new Paragraph("S23: Metadata Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);

        doc.add(new Paragraph("This document demonstrates all PDF metadata setting methods.", helv(11)));
        doc.add(new Paragraph("Open document properties in a PDF viewer to see the metadata.", helv(11)));

        doc.add(new Paragraph(" ", helv(8)));
        doc.add(new Paragraph("Metadata Set:", new Font(HELV_BF, 12, Font.BOLD)));
        doc.add(new Paragraph("• Title: S23 Metadata Demo Document", helv(11)));
        doc.add(new Paragraph("• Author: OpenPDF Test Author", helv(11)));
        doc.add(new Paragraph("• Subject: Demonstrating PDF metadata features", helv(11)));
        doc.add(new Paragraph("• Keywords: OpenPDF, metadata, PDF, Java, test", helv(11)));
        doc.add(new Paragraph("• Creator: S23_Metadata.java", helv(11)));
        doc.add(new Paragraph("• Creation Date: (auto-set)", helv(11)));
        doc.add(new Paragraph("• PDF Version: 1.7", helv(11)));
        doc.add(new Paragraph("• Custom headers: CustomKey1, CustomKey2, Project", helv(11)));

        doc.add(new Paragraph(" ", helv(8)));
        doc.add(new Paragraph("CJK metadata: 这是包含中文元数据的PDF文档。", cjk(12)));

        // Note: PdfWriter.setMoreInfo() does not exist in OpenPDF 2.0.3
        // Use PdfWriter info methods available:
        // writer.getInfo() is internal — we can add custom XMP or use doc.addHeader() above

        doc.close();

        // Save to file
        byte[] pdfBytes = baos.toByteArray();
        try (FileOutputStream fos = new FileOutputStream(OUT_DIR + "java_s23_metadata.pdf")) {
            fos.write(pdfBytes);
        }
        System.out.println("S23 PDF saved: " + OUT_DIR + "java_s23_metadata.pdf");

        // Now read back and print all metadata
        PdfReader reader = new PdfReader(pdfBytes);
        System.out.println("\n=== Reading back metadata with PdfReader ===");
        System.out.println("Number of pages: " + reader.getNumberOfPages());
        System.out.println("Page size: " + reader.getPageSize(1));
        System.out.println("PDF version: " + reader.getPdfVersion());

        Map<String, String> info = reader.getInfo();
        System.out.println("\n--- Document Info Dictionary ---");
        for (Map.Entry<String, String> entry : info.entrySet()) {
            System.out.println("  " + entry.getKey() + " = " + entry.getValue());
        }

        reader.close();
        System.out.println("\nS23 done.");
    }
}
