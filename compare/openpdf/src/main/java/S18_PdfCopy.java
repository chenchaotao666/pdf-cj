import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S18_PdfCopy {
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

    static byte[] createPdfA() throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter.getInstance(doc, baos);
        doc.open();
        for (int i = 1; i <= 3; i++) {
            if (i > 1) doc.newPage();
            Paragraph p = new Paragraph("PDF-A: Page " + i, new Font(HELV_BF, 20, Font.BOLD));
            p.setAlignment(Element.ALIGN_CENTER);
            doc.add(p);
            doc.add(new Paragraph("Document A, page " + i + " of 3.", new Font(HELV_BF, 12)));
            doc.add(new Paragraph("Content: The quick brown fox jumps over the lazy dog.", new Font(HELV_BF, 11)));
            // Add an image on page 1 (will be deduped by PdfSmartCopy)
            if (i == 1) {
                try {
                    Image img = Image.getInstance(IMG_DIR + "mountain.png");
                    img.scaleAbsolute(100, 70);
                    doc.add(img);
                } catch (Exception e) {}
            }
        }
        doc.close();
        return baos.toByteArray();
    }

    static byte[] createPdfB() throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter.getInstance(doc, baos);
        doc.open();
        for (int i = 1; i <= 2; i++) {
            if (i > 1) doc.newPage();
            Paragraph p = new Paragraph("PDF-B: Page " + i, new Font(HELV_BF, 20, Font.BOLD, Color.BLUE));
            p.setAlignment(Element.ALIGN_CENTER);
            doc.add(p);
            doc.add(new Paragraph("Document B, page " + i + " of 2.", new Font(HELV_BF, 12)));
            doc.add(new Paragraph("CJK: 这是文档B第" + i + "页。", new Font(CJK_BF, 12)));
            if (i == 1) {
                try {
                    Image img = Image.getInstance(IMG_DIR + "mountain.png");
                    img.scaleAbsolute(100, 70);
                    doc.add(img);
                } catch (Exception e) {}
            }
        }
        doc.close();
        return baos.toByteArray();
    }

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();

        byte[] pdfA = createPdfA();
        byte[] pdfB = createPdfB();

        System.out.println("  PDF-A: " + pdfA.length + " bytes, " +
                new PdfReader(pdfA).getNumberOfPages() + " pages");
        System.out.println("  PDF-B: " + pdfB.length + " bytes, " +
                new PdfReader(pdfB).getNumberOfPages() + " pages");

        // ---- Part 1: Merge all pages with PdfCopy (page by page) ----
        {
            Document mergedDoc = new Document();
            PdfCopy copy = new PdfCopy(mergedDoc,
                    new FileOutputStream(OUT_DIR + "java_s18_copy_merged.pdf"));
            mergedDoc.open();

            PdfReader readerA = new PdfReader(pdfA);
            int pagesA = readerA.getNumberOfPages();
            for (int p = 1; p <= pagesA; p++) {
                copy.addPage(copy.getImportedPage(readerA, p));
            }
            System.out.println("  Added PDF-A: " + pagesA + " pages");
            readerA.close();

            PdfReader readerB = new PdfReader(pdfB);
            int pagesB = readerB.getNumberOfPages();
            for (int p = 1; p <= pagesB; p++) {
                copy.addPage(copy.getImportedPage(readerB, p));
            }
            System.out.println("  Added PDF-B: " + pagesB + " pages");
            readerB.close();

            mergedDoc.close();
            System.out.println("  Merged PDF: " + OUT_DIR + "java_s18_copy_merged.pdf (" + (pagesA + pagesB) + " pages)");
        }

        // ---- Part 2: Page selection (pages 1,3 from A) ----
        {
            Document selDoc = new Document();
            ByteArrayOutputStream selBaos = new ByteArrayOutputStream();
            PdfCopy selCopy = new PdfCopy(selDoc, selBaos);
            selDoc.open();

            PdfReader readerA = new PdfReader(pdfA);
            // Select pages 1 and 3 via selectPages then copy all remaining pages
            readerA.selectPages("1,3");
            int selPages = readerA.getNumberOfPages();
            for (int p = 1; p <= selPages; p++) {
                selCopy.addPage(selCopy.getImportedPage(readerA, p));
            }
            readerA.close();

            selDoc.close();
            // Write to file
            try (FileOutputStream fos = new FileOutputStream(OUT_DIR + "java_s18_selected_pages.pdf")) {
                fos.write(selBaos.toByteArray());
            }
            System.out.println("  Selected pages (1,3) of PDF-A: " + OUT_DIR + "java_s18_selected_pages.pdf");
        }

        // ---- Part 3: PdfSmartCopy (dedup resources) ----
        {
            Document smartDoc = new Document();
            PdfSmartCopy smartCopy = new PdfSmartCopy(smartDoc,
                    new FileOutputStream(OUT_DIR + "java_s18_smart_copy.pdf"));
            smartDoc.open();

            PdfReader readerA2 = new PdfReader(pdfA);
            int spA = readerA2.getNumberOfPages();
            for (int p = 1; p <= spA; p++) {
                smartCopy.addPage(smartCopy.getImportedPage(readerA2, p));
            }
            readerA2.close();

            PdfReader readerB2 = new PdfReader(pdfB);
            int spB = readerB2.getNumberOfPages();
            for (int p = 1; p <= spB; p++) {
                smartCopy.addPage(smartCopy.getImportedPage(readerB2, p));
            }
            readerB2.close();

            smartDoc.close();
            System.out.println("  Smart copy PDF: " + OUT_DIR + "java_s18_smart_copy.pdf");
        }

        // ---- Part 4: Copy individual pages ----
        {
            PdfReader readerA3 = new PdfReader(pdfA);
            Document indivDoc = new Document();
            PdfCopy indivCopy = new PdfCopy(indivDoc,
                    new FileOutputStream(OUT_DIR + "java_s18_individual_pages.pdf"));
            indivDoc.open();

            // Copy page 2 from A, page 1 from B, page 3 from A
            PdfReader readerB3 = new PdfReader(pdfB);
            indivCopy.addPage(indivCopy.getImportedPage(readerA3, 2));
            indivCopy.addPage(indivCopy.getImportedPage(readerB3, 1));
            indivCopy.addPage(indivCopy.getImportedPage(readerA3, 3));

            readerA3.close();
            readerB3.close();
            indivDoc.close();
            System.out.println("  Individual pages copy: " + OUT_DIR + "java_s18_individual_pages.pdf");
        }

        System.out.println("S18 done.");
    }
}
