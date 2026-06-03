import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S08_Image {
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

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();

        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s08_image.pdf"));
        doc.open();

        // Title
        Paragraph title = new Paragraph("S08: Image Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);

        // 1. Image.getInstance(path)
        doc.add(new Paragraph("1. river.jpg — original size:", helv(11)));
        Image img1 = Image.getInstance(IMG_DIR + "river.jpg");
        doc.add(new Paragraph("   Original: " + img1.getWidth() + " x " + img1.getHeight() + " px", helv(10)));

        // scaleAbsolute(w, h)
        img1.scaleAbsolute(150, 100);
        img1.setAlignment(Image.LEFT);
        img1.setSpacingBefore(4);
        img1.setSpacingAfter(8);
        doc.add(img1);

        // 2. mountain.png — scalePercent(p)
        doc.add(new Paragraph("2. mountain.png — scalePercent(30%):", helv(11)));
        Image img2 = Image.getInstance(IMG_DIR + "mountain.png");
        img2.scalePercent(30);
        img2.setAlignment(Image.MIDDLE);
        img2.setSpacingBefore(4);
        img2.setSpacingAfter(8);
        doc.add(img2);

        // 3. nodes.jpeg — scalePercent(px, py) different x/y scale
        doc.add(new Paragraph("3. nodes.jpeg — scalePercent(50%, 30%):", helv(11)));
        Image img3 = Image.getInstance(IMG_DIR + "nodes.jpeg");
        img3.scalePercent(50, 30);
        img3.setAlignment(Image.RIGHT);
        img3.setSpacingBefore(4);
        img3.setSpacingAfter(8);
        doc.add(img3);

        // 4. scaleToFit(w, h)
        doc.add(new Paragraph("4. river.jpg — scaleToFit(200, 120):", helv(11)));
        Image img4 = Image.getInstance(IMG_DIR + "river.jpg");
        img4.scaleToFit(200, 120);
        img4.setAlignment(Image.MIDDLE);
        img4.setSpacingBefore(4);
        img4.setSpacingAfter(8);
        doc.add(img4);

        // 5. Alignment options
        doc.add(new Paragraph("5. mountain.png — ALIGN_LEFT:", helv(11)));
        Image img5 = Image.getInstance(IMG_DIR + "mountain.png");
        img5.scaleAbsolute(120, 80);
        img5.setAlignment(Image.LEFT);
        doc.add(img5);

        doc.add(new Paragraph("6. mountain.png — ALIGN_MIDDLE:", helv(11)));
        Image img6 = Image.getInstance(IMG_DIR + "mountain.png");
        img6.scaleAbsolute(120, 80);
        img6.setAlignment(Image.MIDDLE);
        doc.add(img6);

        doc.add(new Paragraph("7. mountain.png — ALIGN_RIGHT:", helv(11)));
        Image img7 = Image.getInstance(IMG_DIR + "mountain.png");
        img7.scaleAbsolute(120, 80);
        img7.setAlignment(Image.RIGHT);
        doc.add(img7);

        // 8. setRotationDegrees
        doc.newPage();
        doc.add(new Paragraph("8. river.jpg — setRotationDegrees(15):", helv(11)));
        Image img8 = Image.getInstance(IMG_DIR + "river.jpg");
        img8.scaleAbsolute(200, 130);
        img8.setRotationDegrees(15f);
        img8.setAlignment(Image.MIDDLE);
        img8.setSpacingBefore(10);
        img8.setSpacingAfter(10);
        doc.add(img8);

        // 9. setRotation (radians)
        doc.add(new Paragraph("9. nodes.jpeg — setRotation(0.3 rad):", helv(11)));
        Image img9 = Image.getInstance(IMG_DIR + "nodes.jpeg");
        img9.scaleToFit(180, 120);
        img9.setRotation(0.3f);
        img9.setAlignment(Image.MIDDLE);
        img9.setSpacingBefore(10);
        img9.setSpacingAfter(10);
        doc.add(img9);

        // 10. setAbsolutePosition — placed at absolute coordinates
        doc.add(new Paragraph("10. river.jpg — absolute position (300, 200):", helv(11)));
        Image img10 = Image.getInstance(IMG_DIR + "river.jpg");
        img10.scaleAbsolute(150, 100);
        img10.setAbsolutePosition(300, 200);
        doc.add(img10);  // When absolute position is set, image is placed absolutely

        // Force some space
        doc.add(new Paragraph(" ", helv(60)));  // spacer

        // 11. Wrapping text around image — use alignment with text wrap
        doc.add(new Paragraph("11. Wrap text around image (ALIGN_LEFT | TEXTWRAP):", helv(11)));
        Image img11 = Image.getInstance(IMG_DIR + "mountain.png");
        img11.scaleAbsolute(120, 80);
        img11.setAlignment(Image.LEFT | Image.TEXTWRAP);
        img11.setIndentationLeft(10);
        img11.setSpacingBefore(6);
        img11.setSpacingAfter(6);
        doc.add(img11);
        doc.add(new Paragraph("This text should wrap around the image on the right side. " +
                "The image is aligned to the left with TEXTWRAP flag. " +
                "More text to demonstrate the wrapping behavior in OpenPDF. " +
                "Keep going to ensure we have enough text to wrap.", helv(11)));

        doc.close();
        System.out.println("S08 done: " + OUT_DIR + "java_s08_image.pdf");
    }
}
