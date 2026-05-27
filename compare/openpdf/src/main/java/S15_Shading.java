import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S15_Shading {
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
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s15_shading.pdf"));
        doc.open();

        PdfContentByte cb = writer.getDirectContent();

        // Title
        Paragraph title = new Paragraph("S15: Shading & Gradient Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);

        // 1. Axial (linear) gradient — horizontal
        doc.add(new Paragraph("1. Axial (Linear) Gradient — Horizontal (Red → Blue):", helv(11)));
        doc.add(new Paragraph(" ", helv(4)));

        PdfShading axial1 = PdfShading.simpleAxial(writer,
                72, 680, 450, 680,   // x0,y0 to x1,y1 (horizontal line)
                Color.RED, Color.BLUE);
        PdfShadingPattern axialPattern1 = new PdfShadingPattern(axial1);
        cb.setShadingFill(axialPattern1);
        cb.rectangle(72, 650, 378, 60);
        cb.fill();

        // 2. Axial gradient — vertical
        doc.add(new Paragraph(" ", helv(22)));
        doc.add(new Paragraph("2. Axial Gradient — Vertical (Yellow → Green):", helv(11)));
        doc.add(new Paragraph(" ", helv(4)));

        PdfShading axial2 = PdfShading.simpleAxial(writer,
                72, 610, 72, 570,   // x0,y0 to x1,y1 (vertical line)
                Color.YELLOW, Color.GREEN);
        PdfShadingPattern axialPattern2 = new PdfShadingPattern(axial2);
        cb.setShadingFill(axialPattern2);
        cb.rectangle(72, 570, 378, 60);
        cb.fill();

        // 3. Axial gradient — diagonal
        doc.add(new Paragraph(" ", helv(22)));
        doc.add(new Paragraph("3. Axial Gradient — Diagonal (Cyan → Magenta):", helv(11)));
        doc.add(new Paragraph(" ", helv(4)));

        PdfShading axial3 = PdfShading.simpleAxial(writer,
                72, 530, 450, 490,   // diagonal from bottom-left to top-right
                Color.CYAN, Color.MAGENTA);
        PdfShadingPattern axialPattern3 = new PdfShadingPattern(axial3);
        cb.setShadingFill(axialPattern3);
        cb.rectangle(72, 490, 378, 60);
        cb.fill();

        // 4. Radial gradient — circle
        doc.add(new Paragraph(" ", helv(22)));
        doc.add(new Paragraph("4. Radial Gradient — Orange center → White:", helv(11)));
        doc.add(new Paragraph(" ", helv(4)));

        PdfShading radial1 = PdfShading.simpleRadial(writer,
                261, 420, 0f,      // cx0, cy0, r0 (inner circle)
                261, 420, 80f,     // cx1, cy1, r1 (outer circle)
                new Color(255, 140, 0), Color.WHITE,
                true, true);       // extend1, extend2
        PdfShadingPattern radialPattern1 = new PdfShadingPattern(radial1);
        cb.setShadingFill(radialPattern1);
        cb.ellipse(181, 370, 341, 460);
        cb.fill();

        // 5. Radial gradient — off-center for 3D sphere effect
        doc.add(new Paragraph(" ", helv(50)));
        doc.add(new Paragraph("5. Radial Gradient — 3D Sphere Effect:", helv(11)));
        doc.add(new Paragraph(" ", helv(4)));

        PdfShading radial2 = PdfShading.simpleRadial(writer,
                305, 305, 10f,     // inner center slightly off-center + top-left
                261, 275, 60f,     // outer center
                Color.WHITE, new Color(0, 0, 180),
                false, true);
        PdfShadingPattern radialPattern2 = new PdfShadingPattern(radial2);
        cb.setShadingFill(radialPattern2);
        cb.ellipse(200, 240, 322, 322);
        cb.fill();

        // 6. Multiple gradients side by side
        doc.add(new Paragraph(" ", helv(30)));
        doc.add(new Paragraph("6. Multiple Gradient Bars:", helv(11)));
        doc.add(new Paragraph(" ", helv(4)));

        Color[][] gradColors = {
            {Color.RED, Color.YELLOW},
            {Color.YELLOW, Color.GREEN},
            {Color.GREEN, Color.CYAN},
            {Color.CYAN, Color.BLUE},
            {Color.BLUE, Color.MAGENTA},
            {Color.MAGENTA, Color.RED}
        };

        for (int i = 0; i < gradColors.length; i++) {
            float bx = 72 + i * 63;
            PdfShading barShading = PdfShading.simpleAxial(writer,
                    bx, 160, bx + 63, 160,
                    gradColors[i][0], gradColors[i][1]);
            PdfShadingPattern barPattern = new PdfShadingPattern(barShading);
            cb.setShadingFill(barPattern);
            cb.rectangle(bx, 130, 63, 50);
            cb.fill();
        }

        doc.close();
        System.out.println("S15 done: " + OUT_DIR + "java_s15_shading.pdf");
    }
}
