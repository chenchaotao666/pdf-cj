import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S12_Annotation {
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
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s12_annotation.pdf"));
        doc.open();

        PdfContentByte cb = writer.getDirectContent();

        // Title
        Paragraph title = new Paragraph("S12: Annotation Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);
        doc.add(new Paragraph("Various PDF annotation types are shown on this page.", helv(11)));
        doc.add(new Paragraph("Some annotations are interactive — open in a PDF viewer to see them.", helv(11)));

        // Need to add some text content first so the page has content
        doc.add(new Paragraph(" ", helv(20)));

        // 1. Text (sticky note) annotation
        try {
            Rectangle rect1 = new Rectangle(72, 700, 100, 720);
            PdfAnnotation ann1 = PdfAnnotation.createText(writer, rect1,
                    "Note Title", "This is a sticky note annotation.", true, "Note");
            ann1.setColor(Color.YELLOW);
            writer.addAnnotation(ann1);
            doc.add(new Paragraph("1. Sticky note annotation at top-left (yellow icon)", helv(11)));
        } catch (Exception e) {
            doc.add(new Paragraph("1. Sticky note: " + e.getMessage(), helv(11)));
        }

        // 2. Link annotation with URL action
        try {
            Rectangle rect2 = new Rectangle(72, 660, 300, 678);
            PdfAction urlAction = new PdfAction("https://github.com/LibrePDF/OpenPDF");
            PdfAnnotation ann2 = PdfAnnotation.createLink(writer, rect2,
                    PdfAnnotation.HIGHLIGHT_INVERT, urlAction);
            writer.addAnnotation(ann2);
            doc.add(new Paragraph("2. [Link annotation — URL to OpenPDF GitHub]", new Font(HELV_BF, 11, Font.UNDERLINE, Color.BLUE)));
        } catch (Exception e) {
            doc.add(new Paragraph("2. Link annotation: " + e.getMessage(), helv(11)));
        }

        // 3. Markup — Highlight annotation
        try {
            doc.add(new Paragraph("3. This text has a HIGHLIGHT markup annotation overlaid.", helv(11)));
            // Quad points: 4 corners of text area (x1,y1, x2,y2, x3,y3, x4,y4)
            Rectangle rect3 = new Rectangle(72, 628, 400, 644);
            float[] quadPoints = {
                72, 644, 400, 644,   // top-left, top-right
                72, 628, 400, 628    // bottom-left, bottom-right
            };
            PdfAnnotation ann3 = PdfAnnotation.createMarkup(writer, rect3,
                    "Highlighted text", PdfAnnotation.MARKUP_HIGHLIGHT, quadPoints);
            ann3.setColor(new Color(255, 255, 0));
            writer.addAnnotation(ann3);
        } catch (Exception e) {
            doc.add(new Paragraph("3. Highlight markup: " + e.getMessage(), helv(11)));
        }

        // 4. Markup — Underline annotation
        try {
            doc.add(new Paragraph("4. This text has an UNDERLINE markup annotation.", helv(11)));
            Rectangle rect4 = new Rectangle(72, 608, 350, 624);
            float[] quadPoints4 = {
                72, 624, 350, 624,
                72, 608, 350, 608
            };
            PdfAnnotation ann4 = PdfAnnotation.createMarkup(writer, rect4,
                    "Underlined", PdfAnnotation.MARKUP_UNDERLINE, quadPoints4);
            ann4.setColor(Color.BLUE);
            writer.addAnnotation(ann4);
        } catch (Exception e) {
            doc.add(new Paragraph("4. Underline markup: " + e.getMessage(), helv(11)));
        }

        // 5. Markup — Strikeout annotation
        try {
            doc.add(new Paragraph("5. This text has a STRIKEOUT markup annotation.", helv(11)));
            Rectangle rect5 = new Rectangle(72, 588, 340, 604);
            float[] quadPoints5 = {
                72, 604, 340, 604,
                72, 588, 340, 588
            };
            PdfAnnotation ann5 = PdfAnnotation.createMarkup(writer, rect5,
                    "Strikeout", PdfAnnotation.MARKUP_STRIKEOUT, quadPoints5);
            ann5.setColor(Color.RED);
            writer.addAnnotation(ann5);
        } catch (Exception e) {
            doc.add(new Paragraph("5. Strikeout markup: " + e.getMessage(), helv(11)));
        }

        // 6. Free text annotation
        try {
            doc.add(new Paragraph(" ", helv(8)));
            Rectangle rect6 = new Rectangle(72, 540, 300, 572);
            PdfAnnotation ann6 = PdfAnnotation.createFreeText(writer, rect6,
                    "6. Free text annotation: This floats on the page!", cb);
            ann6.setColor(new Color(200, 230, 255));
            writer.addAnnotation(ann6);
            doc.add(new Paragraph("6. Free text annotation box above", helv(11)));
        } catch (Exception e) {
            doc.add(new Paragraph("6. Free text: " + e.getMessage(), helv(11)));
        }

        // 7. Square/Circle annotation (try createSquare, else stamp)
        try {
            Rectangle rect7 = new Rectangle(72, 490, 172, 530);
            PdfAnnotation ann7;
            try {
                // Try createSquare
                ann7 = PdfAnnotation.createSquareCircle(writer, rect7, "Square annotation", true);
            } catch (Exception e2) {
                ann7 = PdfAnnotation.createStamp(writer, rect7, "Square area", "TopSecret");
            }
            ann7.setColor(Color.GREEN);
            writer.addAnnotation(ann7);
            doc.add(new Paragraph("7. Square/stamp annotation", helv(11)));
        } catch (Exception e) {
            doc.add(new Paragraph("7. Square/stamp: " + e.getMessage(), helv(11)));
        }

        // 8. Circle annotation
        try {
            Rectangle rect8 = new Rectangle(200, 490, 320, 530);
            PdfAnnotation ann8;
            try {
                ann8 = PdfAnnotation.createSquareCircle(writer, rect8, "Circle annotation", false);
            } catch (Exception e2) {
                ann8 = PdfAnnotation.createStamp(writer, rect8, "Circle area", "Approved");
            }
            ann8.setColor(Color.ORANGE);
            writer.addAnnotation(ann8);
            doc.add(new Paragraph("8. Circle/stamp annotation", helv(11)));
        } catch (Exception e) {
            doc.add(new Paragraph("8. Circle: " + e.getMessage(), helv(11)));
        }

        // 9. Annotation with opacity (setOpacity)
        try {
            Rectangle rect9 = new Rectangle(72, 440, 200, 470);
            PdfAnnotation ann9 = PdfAnnotation.createText(writer, rect9,
                    "Opacity Note", "This note has 50% opacity set.", false, "Comment");
            ann9.setColor(Color.CYAN);
            // setOpacity may not exist in all versions — try reflection
            try {
                ann9.getClass().getMethod("setOpacity", float.class).invoke(ann9, 0.5f);
            } catch (NoSuchMethodException ex) {
                // Not supported in this version
            }
            ann9.setFlags(PdfAnnotation.FLAGS_PRINT);
            writer.addAnnotation(ann9);
            doc.add(new Paragraph("9. Annotation with FLAGS_PRINT set", helv(11)));
        } catch (Exception e) {
            doc.add(new Paragraph("9. Opacity annotation: " + e.getMessage(), helv(11)));
        }

        doc.close();
        System.out.println("S12 done: " + OUT_DIR + "java_s12_annotation.pdf");
    }
}
