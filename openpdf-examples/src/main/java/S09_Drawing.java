import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S09_Drawing {
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

        Document doc = new Document(PageSize.A4, 50, 50, 50, 50);
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s09_drawing.pdf"));
        doc.open();

        PdfContentByte cb = writer.getDirectContent();

        // Page 1: Lines, curves, shapes
        // Label
        cb.beginText();
        cb.setFontAndSize(HELV_BF, 16);
        cb.setTextMatrix(50, 800);
        cb.showText("S09: PdfContentByte Drawing Demo — Page 1");
        cb.endText();

        // 1. Basic line with saveState/restoreState
        cb.saveState();
        cb.setLineWidth(2f);
        cb.setColorStroke(Color.RED);
        cb.moveTo(50, 770);
        cb.lineTo(300, 770);
        cb.stroke();
        cb.restoreState();

        // 2. Line cap styles
        cb.saveState();
        cb.setLineWidth(8f);
        String[] capNames = {"LINEECAP_BUTT", "LINEECAP_ROUND", "LINEECAP_PROJECTING_SQUARE"};
        int[] caps = {PdfContentByte.LINE_CAP_BUTT, PdfContentByte.LINE_CAP_ROUND, PdfContentByte.LINE_CAP_PROJECTING_SQUARE};
        for (int i = 0; i < 3; i++) {
            cb.setLineCap(caps[i]);
            cb.setColorStroke(new Color(0, 0, 180 - i * 40));
            cb.moveTo(50 + i * 120, 750);
            cb.lineTo(120 + i * 120, 750);
            cb.stroke();
        }
        cb.restoreState();

        // 3. Line join styles
        cb.saveState();
        cb.setLineWidth(4f);
        int[] joins = {PdfContentByte.LINE_JOIN_MITER, PdfContentByte.LINE_JOIN_ROUND, PdfContentByte.LINE_JOIN_BEVEL};
        for (int i = 0; i < 3; i++) {
            cb.setLineJoin(joins[i]);
            cb.setColorStroke(new Color(180 - i * 40, 0, 0));
            cb.moveTo(50 + i * 150, 710);
            cb.lineTo(100 + i * 150, 730);
            cb.lineTo(150 + i * 150, 710);
            cb.stroke();
        }
        cb.restoreState();

        // 4. Dash patterns
        cb.saveState();
        cb.setLineWidth(2f);
        cb.setColorStroke(Color.BLACK);

        cb.setLineDash(5f);  // setLineDash(phase)
        cb.moveTo(50, 680); cb.lineTo(250, 680); cb.stroke();

        cb.setLineDash(8f, 4f, 0f);  // setLineDash(on, off, phase)
        cb.moveTo(50, 665); cb.lineTo(250, 665); cb.stroke();

        cb.setLineDash(new float[]{10f, 3f, 3f, 3f}, 0f);  // setLineDash(float[], phase)
        cb.moveTo(50, 650); cb.lineTo(250, 650); cb.stroke();
        cb.restoreState();

        // 5. Curves (curveTo)
        cb.saveState();
        cb.setLineWidth(2f);
        cb.setColorStroke(new Color(0, 150, 0));
        cb.moveTo(50, 620);
        cb.curveTo(100, 640, 200, 600, 250, 620);
        cb.stroke();
        cb.restoreState();

        // 6. Fill and stroke operations
        cb.saveState();
        // Rectangle fill
        cb.setColorFill(new Color(255, 200, 100));
        cb.setColorStroke(new Color(200, 100, 0));
        cb.setLineWidth(2f);
        cb.rectangle(50, 550, 80, 50);
        cb.fillStroke();

        // Ellipse fill
        cb.setColorFill(new Color(150, 200, 255));
        cb.setColorStroke(new Color(0, 100, 200));
        cb.ellipse(150, 550, 250, 600);
        cb.fillStroke();

        // Rounded rectangle
        cb.setColorFill(new Color(200, 255, 150));
        cb.setColorStroke(new Color(100, 200, 0));
        cb.roundRectangle(270, 550, 80, 50, 10f);
        cb.fillStroke();
        cb.restoreState();

        // 7. Arc
        cb.saveState();
        cb.setColorStroke(Color.MAGENTA);
        cb.setLineWidth(2f);
        cb.arc(50, 490, 150, 540, 0, 270);
        cb.stroke();
        cb.restoreState();

        // 8. eoFill (Even-Odd Rule) — star shape
        cb.saveState();
        cb.setColorFill(new Color(255, 100, 100));
        // Draw a simple star-like shape using moveTo/lineTo
        float cx = 430, cy = 560, r1 = 40, r2 = 20;
        cb.moveTo(cx, cy + r1);
        for (int i = 1; i < 10; i++) {
            double angle = Math.PI / 2 + i * Math.PI / 5;
            float r = (i % 2 == 0) ? r1 : r2;
            cb.lineTo(cx + (float)(r * Math.cos(angle)), cy + (float)(r * Math.sin(angle)));
        }
        cb.closePath();
        cb.eoFill();
        cb.restoreState();

        // 9. Gray fill
        cb.saveState();
        cb.setGrayFill(0.7f);
        cb.setGrayStroke(0.3f);
        cb.setLineWidth(1.5f);
        cb.rectangle(370, 490, 80, 40);
        cb.fillStroke();
        cb.restoreState();

        // 10. CMYK color (int 0-255 in OpenPDF 2.x)
        cb.saveState();
        cb.setCMYKColorFill(0, 255, 255, 0);    // yellow in CMYK
        cb.setCMYKColorStroke(255, 0, 0, 0);     // cyan stroke
        cb.setLineWidth(2f);
        cb.rectangle(370, 440, 80, 40);
        cb.fillStroke();
        cb.restoreState();

        // 11. clip region
        cb.saveState();
        // Set clip to a rectangle
        cb.rectangle(50, 420, 100, 40);
        cb.clip();
        cb.newPath();
        // Draw something larger that gets clipped
        cb.setColorFill(Color.ORANGE);
        cb.rectangle(30, 410, 150, 60);
        cb.fill();
        cb.restoreState();

        // 12. eoClip
        cb.saveState();
        cb.moveTo(200, 460);
        cb.lineTo(300, 460);
        cb.lineTo(250, 420);
        cb.closePath();
        cb.eoClip();
        cb.newPath();
        cb.setColorFill(new Color(0, 200, 200));
        cb.rectangle(190, 410, 130, 60);
        cb.fill();
        cb.restoreState();

        // 13. concatCTM — coordinate transform
        cb.saveState();
        cb.concatCTM(1f, 0.2f, 0.2f, 1f, 0f, 0f);  // shear transform
        cb.setColorFill(new Color(255, 150, 200));
        cb.rectangle(50, 380, 80, 30);
        cb.fill();
        cb.restoreState();

        // Page 2: Text operations
        doc.newPage();
        cb = writer.getDirectContent();

        cb.beginText();
        cb.setFontAndSize(HELV_BF, 16);
        cb.setTextMatrix(50, 800);
        cb.showText("S09: PdfContentByte Text Operations — Page 2");
        cb.endText();

        // 14. showText and showTextAligned
        cb.beginText();
        cb.setFontAndSize(HELV_BF, 12);
        cb.setTextMatrix(50, 770);
        cb.showText("14. showText at (50, 770)");
        cb.endText();

        // showTextAligned: 0=LEFT, 1=CENTER, 2=RIGHT
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "15. showTextAligned LEFT at (50,750)", 50, 750, 0);
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER, "16. showTextAligned CENTER at (297,730)", 297, 730, 0);
        cb.showTextAligned(PdfContentByte.ALIGN_RIGHT, "17. showTextAligned RIGHT at (545,710)", 545, 710, 0);

        // 15. Rotated text via showTextAligned
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "18. Rotated 45 deg", 50, 680, 45);

        // 16. Character spacing, word spacing, horizontal scaling
        cb.beginText();
        cb.setFontAndSize(HELV_BF, 12);
        cb.setCharacterSpacing(3f);
        cb.setTextMatrix(50, 640);
        cb.showText("19. charSpacing=3: Hello World");
        cb.endText();

        cb.beginText();
        cb.setFontAndSize(HELV_BF, 12);
        cb.setWordSpacing(8f);
        cb.setTextMatrix(50, 620);
        cb.showText("20. wordSpacing=8: Hello World Text");
        cb.endText();

        cb.beginText();
        cb.setFontAndSize(HELV_BF, 12);
        cb.setHorizontalScaling(150f);
        cb.setTextMatrix(50, 600);
        cb.showText("21. hScaling=150%: Wide");
        cb.endText();

        // 17. Text rendering modes
        String[] modes = {"Fill", "Stroke", "FillStroke", "Invisible", "FillClip"};
        int[] modeVals = {
            PdfContentByte.TEXT_RENDER_MODE_FILL,
            PdfContentByte.TEXT_RENDER_MODE_STROKE,
            PdfContentByte.TEXT_RENDER_MODE_FILL_STROKE,
            PdfContentByte.TEXT_RENDER_MODE_INVISIBLE,
            PdfContentByte.TEXT_RENDER_MODE_FILL_CLIP
        };
        for (int i = 0; i < modeVals.length; i++) {
            cb.beginText();
            cb.setFontAndSize(HELV_BF, 14);
            cb.setTextRenderingMode(modeVals[i]);
            cb.setColorFill(Color.BLACK);
            cb.setColorStroke(Color.RED);
            cb.setLineWidth(0.5f);
            cb.setTextMatrix(50, 570 - i * 22);
            cb.showText("22." + i + " TextRenderMode: " + modes[i]);
            cb.endText();
        }

        // 18. Text rise (superscript effect)
        cb.beginText();
        cb.setFontAndSize(HELV_BF, 12);
        cb.setTextRenderingMode(PdfContentByte.TEXT_RENDER_MODE_FILL);
        cb.setColorFill(Color.BLACK);
        cb.setTextMatrix(50, 450);
        cb.showText("23. Normal");
        cb.setTextRise(6f);
        cb.showText("superscript");
        cb.setTextRise(0f);
        cb.showText("back to normal");
        cb.endText();

        // 19. moveText and newlineText
        cb.beginText();
        cb.setFontAndSize(HELV_BF, 12);
        cb.setLeading(18f);
        cb.setTextMatrix(50, 420);
        cb.showText("24a. Line 1 via setTextMatrix");
        cb.newlineText();
        cb.showText("24b. Line 2 via newlineText()");
        cb.moveText(0, -20);
        cb.showText("24c. Line 3 via moveText(0,-20)");
        cb.endText();

        // 20. CJK text on canvas
        cb.beginText();
        cb.setFontAndSize(CJK_BF, 14);
        cb.setTextMatrix(50, 370);
        cb.showText("25. CJK直接绘制: 这是画布上的中文文字");
        cb.endText();

        doc.close();
        System.out.println("S09 done: " + OUT_DIR + "java_s09_drawing.pdf");
    }
}
