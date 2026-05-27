import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S20_Security {
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

    static void addContent(Document doc, String title, String encType) throws Exception {
        Paragraph titlePara = new Paragraph(title, new Font(HELV_BF, 18, Font.BOLD));
        titlePara.setAlignment(Element.ALIGN_CENTER);
        titlePara.setSpacingAfter(20);
        doc.add(titlePara);

        doc.add(new Paragraph("Encryption type: " + encType, new Font(HELV_BF, 12)));
        doc.add(new Paragraph("This PDF is encrypted. Open with appropriate password.", new Font(HELV_BF, 11)));
        doc.add(new Paragraph("User password: 'user123'", new Font(HELV_BF, 11)));
        doc.add(new Paragraph("Owner password: 'owner456'", new Font(HELV_BF, 11)));
        doc.add(new Paragraph("Permissions reflect the allowed operations.", new Font(HELV_BF, 11)));
        doc.add(new Paragraph("CJK: 这是加密的PDF文档，需要密码才能访问。", new Font(CJK_BF, 12)));
    }

    // Create a PDF without encryption but with security info documented
    static void createFallbackPdf(String filename, String title, String note) throws Exception {
        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + filename));
        doc.open();
        doc.add(new Paragraph(title, new Font(HELV_BF, 18, Font.BOLD)));
        doc.add(new Paragraph(note, helv(11)));
        doc.add(new Paragraph("Note: Encryption requires BouncyCastle on classpath.", helv(11)));
        doc.add(new Paragraph("Add dependency: org.bouncycastle:bcprov-jdk15on:1.70", helv(11)));
        doc.add(new Paragraph("示意：加密功能需要BouncyCastle依赖库。", new Font(CJK_BF, 11)));
        doc.close();
    }

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();

        byte[] userPass  = "user123".getBytes("UTF-8");
        byte[] ownerPass = "owner456".getBytes("UTF-8");

        // ---- 1. AES-128, print-only permissions ----
        try {
            Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
            PdfWriter writer = PdfWriter.getInstance(doc,
                    new FileOutputStream(OUT_DIR + "java_s20_encrypted_aes128.pdf"));

            int permissions = PdfWriter.ALLOW_PRINTING;
            writer.setEncryption(userPass, ownerPass, permissions, PdfWriter.ENCRYPTION_AES_128);

            doc.open();
            addContent(doc, "S20: AES-128 Encrypted PDF (Print Only)", "ENCRYPTION_AES_128");
            doc.add(new Paragraph("Permissions: ALLOW_PRINTING only", helv(11)));
            doc.add(new Paragraph("Cannot copy, modify, or annotate.", helv(11)));
            doc.close();
            System.out.println("  AES-128 encrypted: " + OUT_DIR + "java_s20_encrypted_aes128.pdf");
        } catch (Exception e) {
            System.out.println("  AES-128 encryption failed (BouncyCastle missing?): " + e.getMessage());
            createFallbackPdf("java_s20_encrypted_aes128.pdf",
                "S20: AES-128 Security Demo (no-encrypt fallback)", "ENCRYPTION_AES_128 requires BouncyCastle.");
        }

        // ---- 2. AES-256 (if supported), all permissions ----
        try {
            Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
            PdfWriter writer = PdfWriter.getInstance(doc,
                    new FileOutputStream(OUT_DIR + "java_s20_encrypted_aes256.pdf"));

            int allPerms = PdfWriter.ALLOW_PRINTING
                    | PdfWriter.ALLOW_COPY
                    | PdfWriter.ALLOW_MODIFY_CONTENTS
                    | PdfWriter.ALLOW_MODIFY_ANNOTATIONS;

            // Try AES_256 constant — may not exist in all versions
            int encType;
            try {
                encType = PdfWriter.class.getField("ENCRYPTION_AES_256").getInt(null);
            } catch (NoSuchFieldException e) {
                encType = PdfWriter.ENCRYPTION_AES_128;
                System.out.println("  ENCRYPTION_AES_256 not available, using AES_128 for second file");
            }

            writer.setEncryption(userPass, ownerPass, allPerms, encType);

            doc.open();
            addContent(doc, "S20: AES-256 Encrypted PDF (All Permissions)", "ENCRYPTION_AES_256");
            doc.add(new Paragraph("Permissions: ALLOW_PRINTING | ALLOW_COPY | ALLOW_MODIFY_CONTENTS | ALLOW_MODIFY_ANNOTATIONS", helv(11)));
            doc.close();
            System.out.println("  AES-256 encrypted: " + OUT_DIR + "java_s20_encrypted_aes256.pdf");
        } catch (Exception e) {
            System.out.println("  AES-256 encryption failed: " + e.getMessage());
            createFallbackPdf("java_s20_encrypted_aes256.pdf",
                "S20: AES-256 Security Demo (no-encrypt fallback)", "ENCRYPTION_AES_256 requires BouncyCastle.");
        }

        // ---- 3. Standard 128-bit encryption, copy only ----
        try {
            Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
            PdfWriter writer = PdfWriter.getInstance(doc,
                    new FileOutputStream(OUT_DIR + "java_s20_encrypted_std128.pdf"));

            writer.setEncryption(userPass, ownerPass,
                    PdfWriter.ALLOW_PRINTING | PdfWriter.ALLOW_COPY,
                    PdfWriter.STANDARD_ENCRYPTION_128);

            doc.open();
            addContent(doc, "S20: Standard-128 Encrypted PDF", "STANDARD_ENCRYPTION_128");
            doc.add(new Paragraph("Permissions: ALLOW_PRINTING | ALLOW_COPY", helv(11)));
            doc.close();
            System.out.println("  Standard-128 encrypted: " + OUT_DIR + "java_s20_encrypted_std128.pdf");
        } catch (Exception e) {
            System.out.println("  Standard-128 encryption failed: " + e.getMessage());
            createFallbackPdf("java_s20_encrypted_std128.pdf",
                "S20: Standard-128 Security Demo (no-encrypt fallback)", "STANDARD_ENCRYPTION_128 requires BouncyCastle.");
        }

        System.out.println("S20 done.");
    }
}
