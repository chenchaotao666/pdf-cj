import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S14_Transparency {
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
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s14_transparency.pdf"));
        doc.open();

        PdfContentByte cb = writer.getDirectContent();

        // Title
        Paragraph title = new Paragraph("S14: Transparency & GState Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);

        // 1. Three overlapping rectangles with different fill opacity
        doc.add(new Paragraph("1. Three overlapping rectangles with different fill opacities:", helv(11)));
        doc.add(new Paragraph(" ", helv(6)));

        float baseY = 580;

        // Background rectangle (fully opaque)
        cb.saveState();
        cb.setColorFill(new Color(200, 200, 200));
        cb.rectangle(100, baseY, 300, 80);
        cb.fill();
        cb.restoreState();

        // Red rectangle at 80% opacity
        PdfGState gs1 = new PdfGState();
        gs1.setFillOpacity(0.8f);
        gs1.setStrokeOpacity(0.8f);
        cb.saveState();
        cb.setGState(gs1);
        cb.setColorFill(Color.RED);
        cb.rectangle(80, baseY + 20, 150, 100);
        cb.fill();
        cb.restoreState();

        // Green rectangle at 50% opacity (overlapping red)
        PdfGState gs2 = new PdfGState();
        gs2.setFillOpacity(0.5f);
        gs2.setStrokeOpacity(0.5f);
        cb.saveState();
        cb.setGState(gs2);
        cb.setColorFill(Color.GREEN);
        cb.rectangle(160, baseY + 30, 150, 100);
        cb.fill();
        cb.restoreState();

        // Blue rectangle at 30% opacity (overlapping both)
        PdfGState gs3 = new PdfGState();
        gs3.setFillOpacity(0.3f);
        gs3.setStrokeOpacity(0.3f);
        cb.saveState();
        cb.setGState(gs3);
        cb.setColorFill(Color.BLUE);
        cb.rectangle(240, baseY + 10, 150, 100);
        cb.fill();
        cb.restoreState();

        // Label
        cb.beginText();
        cb.setFontAndSize(HELV_BF, 9);
        cb.setColorFill(Color.BLACK);
        cb.setTextMatrix(80, baseY - 15);
        cb.showText("Red 80%");
        cb.setTextMatrix(185, baseY - 15);
        cb.showText("Green 50%");
        cb.setTextMatrix(290, baseY - 15);
        cb.showText("Blue 30%");
        cb.endText();

        // 2. Blend modes
        doc.add(new Paragraph(" ", helv(60)));
        doc.add(new Paragraph("2. Blend mode demonstrations:", helv(11)));

        float blendY = 430;
        String[] blendNames = {"Normal", "Multiply", "Screen", "Overlay", "Darken", "Lighten"};
        PdfName[] blendModes = {
            PdfGState.BM_NORMAL,
            PdfGState.BM_MULTIPLY,
            PdfGState.BM_SCREEN,
            PdfGState.BM_OVERLAY,
            PdfGState.BM_DARKEN,
            PdfGState.BM_LIGHTEN
        };

        for (int i = 0; i < blendModes.length; i++) {
            float bx = 72 + i * 82;

            // Background colored rectangle
            cb.saveState();
            cb.setColorFill(Color.ORANGE);
            cb.rectangle(bx, blendY, 70, 60);
            cb.fill();
            cb.restoreState();

            // Overlay with blend mode
            PdfGState gsBlend = new PdfGState();
            gsBlend.setFillOpacity(0.7f);
            gsBlend.setBlendMode(blendModes[i]);
            cb.saveState();
            cb.setGState(gsBlend);
            cb.setColorFill(Color.BLUE);
            cb.rectangle(bx + 15, blendY + 15, 50, 50);
            cb.fill();
            cb.restoreState();

            cb.beginText();
            cb.setFontAndSize(HELV_BF, 8);
            cb.setColorFill(Color.BLACK);
            cb.setTextMatrix(bx, blendY - 12);
            cb.showText(blendNames[i]);
            cb.endText();
        }

        // 3. Transparent text over image-like background
        doc.add(new Paragraph(" ", helv(60)));
        doc.add(new Paragraph("3. Transparent text over colored background:", helv(11)));

        float txtY = 270;

        // Colorful background stripes
        Color[] stripeColors = {Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.BLUE, Color.MAGENTA};
        for (int i = 0; i < stripeColors.length; i++) {
            cb.setColorFill(stripeColors[i]);
            cb.rectangle(72, txtY + i * 15, 450, 15);
            cb.fill();
        }

        // Semi-transparent text overlay
        PdfGState gsTxt = new PdfGState();
        gsTxt.setFillOpacity(0.85f);
        cb.saveState();
        cb.setGState(gsTxt);
        cb.beginText();
        cb.setFontAndSize(HELV_BF, 36);
        cb.setColorFill(Color.WHITE);
        cb.setTextMatrix(90, txtY + 25);
        cb.showText("TRANSPARENT TEXT");
        cb.endText();
        cb.restoreState();

        // 4. Stroke opacity
        doc.add(new Paragraph(" ", helv(40)));
        doc.add(new Paragraph("4. Varying stroke opacity on circles:", helv(11)));

        float circY = 160;
        for (int i = 0; i < 5; i++) {
            float opacity = 0.2f + i * 0.2f;
            PdfGState gsCircle = new PdfGState();
            gsCircle.setStrokeOpacity(opacity);
            cb.saveState();
            cb.setGState(gsCircle);
            cb.setColorStroke(Color.RED);
            cb.setLineWidth(4f);
            float cx = 100 + i * 90;
            cb.ellipse(cx - 35, circY - 30, cx + 35, circY + 30);
            cb.stroke();
            cb.restoreState();

            cb.beginText();
            cb.setFontAndSize(HELV_BF, 9);
            cb.setColorFill(Color.BLACK);
            cb.setTextMatrix(cx - 20, circY - 45);
            cb.showText(String.format("%.0f%%", opacity * 100));
            cb.endText();
        }

        doc.close();
        System.out.println("S14 done: " + OUT_DIR + "java_s14_transparency.pdf");
    }
}
