import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.io.*;

/**
 * S24：FontFactory.registerDirectories —— 扫描系统字体目录后「按字体名」加载（不给路径）。
 */
public class S24_FontRegistry {
    static final String OUT_DIR = "output/";

    static BaseFont HELV_BF;
    static {
        try {
            HELV_BF = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED);
        } catch (Exception e) { throw new RuntimeException(e); }
    }
    static Font helv(float s) { return new Font(HELV_BF, s); }

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();
        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s24_font_registry.pdf"));
        doc.open();

        doc.add(new Paragraph("S24: FontFactory.registerDirectories", new Font(HELV_BF, 16, Font.BOLD)));
        doc.add(new Paragraph("Scan system font directories, then load a font by NAME (no path needed).", helv(11)));

        // 扫描系统字体目录
        FontFactory.registerDirectories();
        doc.add(new Paragraph("Registered font names: " + FontFactory.getRegisteredFonts().size(), helv(11)));

        // 按字体名加载嵌入字体（命中第一个已注册的候选名）
        String[] candidates = {
            "Noto Sans CJK SC", "Noto Sans CJK JP", "Noto Sans CJK KR",
            "WenQuanYi Zen Hei", "WenQuanYi Micro Hei", "Source Han Sans SC"
        };
        boolean done = false;
        for (String name : candidates) {
            if (FontFactory.isRegistered(name.toLowerCase())) {
                Font f = FontFactory.getFont(name, BaseFont.IDENTITY_H, BaseFont.EMBEDDED, 16);
                doc.add(new Paragraph("用字体名 '" + name + "' 加载（嵌入）：中文测试 你好，世界！Hello 123", f));
                System.out.println("  按名解析: " + name + " -> 已嵌入渲染");
                done = true;
                break;
            }
        }
        if (!done) {
            doc.add(new Paragraph("(系统未注册到候选 CJK 字体名，跳过按名渲染)", helv(10)));
        }

        doc.close();
        System.out.println("S24 done: " + OUT_DIR + "java_s24_font_registry.pdf");
    }
}
