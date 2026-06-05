import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.io.*;

/**
 * S25：预置 CMap 的命名 CJK 字体（不嵌入字形，字宽来自打包的 Adobe 度量）。
 * 这是 OpenPDF/iText-Asian 的传统方案：CMap 资源需位于 classpath 的
 * com/lowagie/text/pdf/fonts/cmaps/ 下（本工程已在 src/main/resources 打包）。
 */
public class S25_CJKCMap {
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
        PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s25_cjk_cmap.pdf"));
        doc.open();

        doc.add(new Paragraph("S25: Predefined-CMap CJK fonts (non-embedded)", new Font(HELV_BF, 16, Font.BOLD)));
        doc.add(new Paragraph("No font file; only a named font + predefined CMap. Widths from bundled Adobe metrics.", helv(11)));

        // 中日韩四语，各用对应的命名字体与预定义 CMap（NOT_EMBEDDED）
        BaseFont sc = BaseFont.createFont("STSong-Light",       "UniGB-UCS2-H",  BaseFont.NOT_EMBEDDED);
        BaseFont tc = BaseFont.createFont("MSung-Light",        "UniCNS-UCS2-H", BaseFont.NOT_EMBEDDED);
        BaseFont jp = BaseFont.createFont("KozMinPro-Regular",  "UniJIS-UCS2-H", BaseFont.NOT_EMBEDDED);
        BaseFont kr = BaseFont.createFont("HYSMyeongJo-Medium", "UniKS-UCS2-H",  BaseFont.NOT_EMBEDDED);

        doc.add(new Paragraph("简体 STSong-Light / UniGB-UCS2-H: 你好，世界！ABC 123", new Font(sc, 15)));
        doc.add(new Paragraph("繁體 MSung-Light / UniCNS-UCS2-H: 妳好，世界！漢字測試", new Font(tc, 15)));
        doc.add(new Paragraph("日本語 KozMinPro-Regular / UniJIS-UCS2-H: こんにちは世界、漢字テスト", new Font(jp, 15)));
        doc.add(new Paragraph("한국어 HYSMyeongJo-Medium / UniKS-UCS2-H: 안녕하세요 세계 한자", new Font(kr, 15)));

        doc.close();
        System.out.println("S25 done: " + OUT_DIR + "java_s25_cjk_cmap.pdf （未嵌入字体，体积应很小）");
    }
}
