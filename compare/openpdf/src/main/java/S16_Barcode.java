import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S16_Barcode {
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
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s16_barcode.pdf"));
        doc.open();

        PdfContentByte cb = writer.getDirectContent();

        // Title
        Paragraph title = new Paragraph("S16: Barcode Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);

        // 1. DataMatrix (BarcodeQRCode not available in OpenPDF 2.0.3 core jar)
        try {
            doc.add(new Paragraph("1. DataMatrix Barcode (BarcodeDatamatrix):", helv(12)));
            BarcodeDatamatrix dm = new BarcodeDatamatrix();
            dm.generate("OpenPDF 2.0.3");
            Image dmImg = dm.createImage();
            dmImg.scaleAbsolute(100, 100);
            dmImg.setAlignment(Image.LEFT);
            dmImg.setSpacingBefore(4);
            dmImg.setSpacingAfter(10);
            doc.add(dmImg);
        } catch (Exception e) {
            doc.add(new Paragraph("1. DataMatrix error: " + e.getMessage(), helv(10)));
        }

        // 2. Code-128
        try {
            doc.add(new Paragraph("2. Code-128:", helv(12)));
            Barcode128 code128 = new Barcode128();
            code128.setCode("OpenPDF-2.0.3");
            code128.setBarHeight(40f);
            Image c128Img = code128.createImageWithBarcode(cb, null, null);
            c128Img.setAlignment(Image.LEFT);
            c128Img.setSpacingBefore(4);
            c128Img.setSpacingAfter(10);
            doc.add(c128Img);
        } catch (Exception e) {
            doc.add(new Paragraph("2. Code-128 error: " + e.getMessage(), helv(10)));
        }

        // 3. Code-39
        try {
            doc.add(new Paragraph("3. Code-39:", helv(12)));
            Barcode39 code39 = new Barcode39();
            code39.setCode("OPENPDF");
            code39.setBarHeight(40f);
            Image c39Img = code39.createImageWithBarcode(cb, null, null);
            c39Img.setAlignment(Image.LEFT);
            c39Img.setSpacingBefore(4);
            c39Img.setSpacingAfter(10);
            doc.add(c39Img);
        } catch (Exception e) {
            doc.add(new Paragraph("3. Code-39 error: " + e.getMessage(), helv(10)));
        }

        // 4. EAN-13
        try {
            doc.add(new Paragraph("4. EAN-13:", helv(12)));
            BarcodeEAN ean = new BarcodeEAN();
            ean.setCodeType(Barcode.EAN13);
            ean.setCode("9781234567897");
            ean.setBarHeight(60f);
            Image eanImg = ean.createImageWithBarcode(cb, null, null);
            eanImg.setAlignment(Image.LEFT);
            eanImg.setSpacingBefore(4);
            eanImg.setSpacingAfter(10);
            doc.add(eanImg);
        } catch (Exception e) {
            doc.add(new Paragraph("4. EAN-13 error: " + e.getMessage(), helv(10)));
        }

        // 5. EAN-8
        try {
            doc.add(new Paragraph("5. EAN-8:", helv(12)));
            BarcodeEAN ean8 = new BarcodeEAN();
            ean8.setCodeType(Barcode.EAN8);
            ean8.setCode("12345670");
            ean8.setBarHeight(50f);
            Image ean8Img = ean8.createImageWithBarcode(cb, null, null);
            ean8Img.setAlignment(Image.LEFT);
            ean8Img.setSpacingBefore(4);
            ean8Img.setSpacingAfter(10);
            doc.add(ean8Img);
        } catch (Exception e) {
            doc.add(new Paragraph("5. EAN-8 error: " + e.getMessage(), helv(10)));
        }

        // 6. PDF417
        try {
            doc.add(new Paragraph("6. PDF417:", helv(12)));
            BarcodePDF417 pdf417 = new BarcodePDF417();
            pdf417.setText("OpenPDF 2.0.3 PDF417 barcode demonstration");
            Image pdf417Img = pdf417.getImage();
            pdf417Img.scaleAbsolute(300, 80);
            pdf417Img.setAlignment(Image.LEFT);
            pdf417Img.setSpacingBefore(4);
            pdf417Img.setSpacingAfter(10);
            doc.add(pdf417Img);
        } catch (Exception e) {
            doc.add(new Paragraph("6. PDF417 error: " + e.getMessage(), helv(10)));
        }

        // 7. Barcode with custom colors
        try {
            doc.add(new Paragraph("7. Code-128 with custom colors (blue bars, red text):", helv(12)));
            Barcode128 colorBarcode = new Barcode128();
            colorBarcode.setCode("COLOR-DEMO");
            colorBarcode.setBarHeight(40f);
            Image colorImg = colorBarcode.createImageWithBarcode(cb, Color.BLUE, Color.RED);
            colorImg.setAlignment(Image.LEFT);
            colorImg.setSpacingBefore(4);
            colorImg.setSpacingAfter(10);
            doc.add(colorImg);
        } catch (Exception e) {
            doc.add(new Paragraph("7. Colored barcode error: " + e.getMessage(), helv(10)));
        }

        // 8. UPC-A
        try {
            doc.add(new Paragraph("8. UPC-A:", helv(12)));
            BarcodeEAN upca = new BarcodeEAN();
            upca.setCodeType(Barcode.UPCA);
            upca.setCode("012345678905");
            upca.setBarHeight(60f);
            Image upcaImg = upca.createImageWithBarcode(cb, null, null);
            upcaImg.setAlignment(Image.LEFT);
            upcaImg.setSpacingBefore(4);
            upcaImg.setSpacingAfter(10);
            doc.add(upcaImg);
        } catch (Exception e) {
            doc.add(new Paragraph("8. UPC-A error: " + e.getMessage(), helv(10)));
        }

        doc.close();
        System.out.println("S16 done: " + OUT_DIR + "java_s16_barcode.pdf");
    }
}
