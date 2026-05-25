/**
 * PdfCompare.java  —  OpenPDF 2.0.3 API 演示
 *
 * 与 examples/compare_main.cj 生成完全相同内容的测试文档，
 * 便于逐行对比两套 API 的差异。
 *
 * ════ 主要 API 差异一览 ════════════════════════════════════════════════════
 *  #  | OpenPDF (Java)                          | pdf-cj (Cangjie)
 * ----+-----------------------------------------+---------------------------
 *  1  | new Document(...)                       | Document(...)
 *  2  | new FileOutputStream("f.pdf")           | File(Path("f.pdf"), OpenMode.Write)
 *  3  | Element.ALIGN_CENTER  (int 1)           | Alignment.Center  (enum)
 *  4  | Font.BOLD             (int 1)           | FontStyle.Bold    (enum)
 *  5  | new Color(r, g, b)  java.awt.Color      | Color(r, g, b)  pdf_cj.text.Color
 *  6  | float / int 参数                         | Float32 参数（所有尺寸/坐标）
 *  7  | new Font(bf, 12, Font.BOLD, color)      | Font(bf, 12.0, FontStyle.Bold)（无内联color）
 *  8  | chunk.setUnderline(0.5f, -2f)           | ✗ pdf-cj Chunk 不支持下划线装饰
 *  9  | Chunk.NEWLINE                           | Paragraph("") 或 setSpacingAfter
 * 10  | 匿名内部类实现 PageEventHelper           | 必须定义命名类 <: PdfPageEventHelper
 * 11  | checked exception: DocumentException    | 全部 unchecked exception
 * 12  | FileOutputStream 写流                   | File 对象（实现了 OutputStream 接口）
 * 13  | new PdfOutline(root, dest, title)       | writer.addOutline(title, dest)
 * 14  | table.setWidths(new float[]{1,2,2})     | table.setWidths([1.0, 2.0, 2.0])
 * 15  | img.setAlignment(Image.MIDDLE)          | img.setAlignment(Alignment.Center)
 * 16  | setCMYKColorFill(int,int,int,int) 0-255 | setCMYKColorFill(Float32…) 0.0-1.0（1.x兼容）
 * 17  | Chunk.setStrikethrough 已在2.x移除       | ✗ pdf-cj Chunk 同样无此方法
 * 18  | PdfPCell.clone() protected 不可用        | 两侧都需手动创建每个单元格
 * 19  | TTC 字体路径须加 ",0": "font.ttc,0"     | pdf-cj 直接传路径，无需索引后缀
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 生成文件（输出到 compare/output/）:
 *   java_s1_text.pdf         S1 文本与字体
 *   java_s2_table.pdf        S2 表格
 *   java_s3_image.pdf        S3 图片
 *   java_s4_drawing.pdf      S4 底层绘图
 *   java_s5_pagevent.pdf     S5 页面事件（页眉/页脚/页码）
 *   java_s6_bookmark.pdf     S6 书签与超链接注释
 */

import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class PdfCompare {

    // ── 常量 ─────────────────────────────────────────────────────────────────
    // ★ OpenPDF 2.x 加载 TTC 字体必须在路径末尾加 ",index" 指定字体槽位
    // ★ OpenPDF 1.x / pdf-cj 直接传路径即可
    static final String FONT_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc,0";
    static final String IMG_DIR   = "../../examples/images/";   // 相对于 compare/openpdf/ 的路径
    static final String OUT_DIR   = "../output/";               // compare/output/

    // ── 字体（模块级静态初始化，对应 Cangjie 的模块级 let） ──────────────────
    static BaseFont CJK_BF;
    static BaseFont HELVETICA;
    static BaseFont TIMES;
    static BaseFont COURIER;

    static {
        try {
            // Cangjie: let CJK_BF = BaseFont.createFont(FONT_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
            CJK_BF    = BaseFont.createFont(FONT_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
            HELVETICA = BaseFont.createFont(BaseFont.HELVETICA,   BaseFont.WINANSI, BaseFont.NOT_EMBEDDED);
            TIMES     = BaseFont.createFont(BaseFont.TIMES_ROMAN, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED);
            COURIER   = BaseFont.createFont(BaseFont.COURIER,     BaseFont.WINANSI, BaseFont.NOT_EMBEDDED);
        } catch (Exception e) { throw new RuntimeException(e); }
    }

    // ── 字体辅助（对应 Cangjie 的 func cjkFont / cjkBold） ─────────────────
    // Java: new Font(bf, size)          vs  Cangjie: Font(bf, size)
    // Java: new Font(bf, size, BOLD)    vs  Cangjie: Font(bf, size, FontStyle.Bold)
    static Font cjk(float size)       { return new Font(CJK_BF, size); }
    static Font cjkBold(float size)   { return new Font(CJK_BF, size, Font.BOLD); }
    static Font cjkItalic(float size) { return new Font(CJK_BF, size, Font.ITALIC); }
    static Font helv(float size)      { return new Font(HELVETICA, size); }

    // ══════════════════════════════════════════════════════════════════════════
    public static void main(String[] args) throws Exception {
        Files.createDirectories(Paths.get(OUT_DIR));
        section1_text();
        section2_table();
        section3_image();
        section4_drawing();
        section5_pageEvent();
        section6_bookmark();
        System.out.println("\n全部生成完毕 → " + OUT_DIR);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // S1  文本与字体
    // ══════════════════════════════════════════════════════════════════════════
    static void section1_text() throws Exception {
        System.out.println("S1: 文本与字体...");

        // ── 文档创建 ──────────────────────────────────────────────────────────
        // Java:    new Document(PageSize.A4, left, right, top, bottom)  -- 参数为 float
        // Cangjie: Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)       -- 参数为 Float32
        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);

        // Java:    PdfWriter.getInstance(doc, new FileOutputStream("f.pdf"))
        // Cangjie: PdfWriter.getInstance(doc, File(Path("f.pdf"), OpenMode.Write))
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s1_text.pdf"));

        // ── 文档元数据（两侧 API 完全相同） ───────────────────────────────────
        doc.addTitle("PDF Compare S1 - Text");
        doc.addAuthor("PdfCompare");
        doc.addSubject("Text and font comparison");
        // Java 专有：addCreator 写入 Producer 字段
        doc.addCreator("OpenPDF " + Document.getVersion());
        // Cangjie 中用 document.addCreator("pdf-cj x.y")

        doc.open();

        // ── 标题段落 ──────────────────────────────────────────────────────────
        // Java:    new Paragraph("text", font)
        // Cangjie: Paragraph("text", font)
        Paragraph title = new Paragraph("S1: PDF 文本与字体对比测试", cjkBold(20));
        // Java:    Element.ALIGN_CENTER (int 常量)
        // Cangjie: Alignment.Center    (枚举值)
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(16);
        doc.add(title);

        // ── 普通中文段落 ──────────────────────────────────────────────────────
        Paragraph body = new Paragraph(
            "普通中文段落：这是使用 NotoSansCJK 嵌入字体渲染的中文正文。" +
            "两端对齐排版，行距 20pt，首行缩进 24pt。", cjk(12));
        // Java:    Element.ALIGN_JUSTIFIED
        // Cangjie: Alignment.Justified（如果支持）或 Alignment.Left
        body.setAlignment(Element.ALIGN_JUSTIFIED);
        body.setLeading(20);               // Cangjie: p.setMultipliedLeading(1.5f) 或直接 setLeading 不存在
        body.setFirstLineIndent(24);
        body.setSpacingAfter(10);
        doc.add(body);

        // ── Chunk 样式（Java 支持丰富，pdf-cj 仅支持颜色） ───────────────────
        // Java: Chunk 支持 setUnderline / setStrikethrough / setBackground / setTextRise
        // pdf-cj Cangjie: Chunk.setColor(Color) — 仅颜色，无下划线/删除线等装饰
        Phrase decorated = new Phrase();
        Chunk normal = new Chunk("默认  ", cjk(12));
        Chunk bold   = new Chunk("粗体  ", cjkBold(12));

        // ★ Java 专有：字体构造时直接传颜色
        // new Font(bf, size, style, color)
        // Cangjie 需要: val c = Chunk("text"); c.setColor(Color(200,0,0))
        Chunk colored = new Chunk("彩色  ", new Font(CJK_BF, 12, Font.NORMAL, new Color(200, 0, 0)));

        // ★ Java 专有：setUnderline
        // pdf-cj 无等价方法
        Chunk underline = new Chunk("下划线  ", cjk(12));
        underline.setUnderline(0.6f, -2f);   // thickness, yPosition

        // ★ Java 专有：setStrikethrough（OpenPDF 1.x 有；2.x 已移除）
        // OpenPDF 1.x: strike.setStrikethrough(0.6f, 3f)
        // OpenPDF 2.x: 可用 setUnderline 配合正 y 值模拟，或用 PdfContentByte 手动画线
        Chunk strike = new Chunk("删除线  ", cjk(12));
        strike.setUnderline(0.6f, 4f);   // 用中间高度的下划线近似模拟删除线效果

        // ★ Java 专有：setBackground
        Chunk bgHighlight = new Chunk("高亮背景", cjk(12));
        bgHighlight.setBackground(new Color(255, 255, 0), 1, 1, 1, 1);

        decorated.add(normal);
        decorated.add(bold);
        decorated.add(colored);
        decorated.add(underline);
        decorated.add(strike);
        decorated.add(bgHighlight);
        doc.add(new Paragraph(decorated));

        // ── Chunk.NEWLINE（Java 专有换行符 Chunk） ─────────────────────────
        // Cangjie 中没有 Chunk.NEWLINE，通常用 Paragraph("") 或 setSpacingAfter
        doc.add(Chunk.NEWLINE);
        doc.add(Chunk.NEWLINE);

        // ── 字体大小对比 ──────────────────────────────────────────────────────
        doc.add(new Paragraph("字体大小对比：", cjkBold(12)));
        for (int size : new int[]{8, 10, 12, 14, 18, 24}) {
            // Java: int 参数 size
            // Cangjie: Float32(size) 需要显式转换或写 12.0
            doc.add(new Paragraph(size + "pt: 中文示例 ABC 123", cjk(size)));
        }

        // ── 行距控制 ──────────────────────────────────────────────────────────
        Paragraph leadingDemo = new Paragraph(
            "自定义行距（leading=28）：这段文字使用了更宽松的行距，" +
            "改善长文本的阅读体验。段落延续三行以上才能明显看出效果。" +
            "第二句，第三句。", cjk(12));
        leadingDemo.setLeading(28);
        leadingDemo.setSpacingBefore(6);
        leadingDemo.setSpacingAfter(12);
        doc.add(leadingDemo);

        // ── 对齐方式对比 ──────────────────────────────────────────────────────
        // Java: Element.ALIGN_LEFT / ALIGN_CENTER / ALIGN_RIGHT / ALIGN_JUSTIFIED
        // Cangjie: Alignment.Left / .Center / .Right（Justified 视实现而定）
        String[] labels = {"左对齐", "居中对齐", "右对齐"};
        int[] aligns    = {Element.ALIGN_LEFT, Element.ALIGN_CENTER, Element.ALIGN_RIGHT};
        for (int i = 0; i < 3; i++) {
            Paragraph ap = new Paragraph(labels[i] + "：示例文字 Demo Text 123", cjk(11));
            ap.setAlignment(aligns[i]);
            doc.add(ap);
        }

        // ── 第 2 页：内置拉丁字体 ─────────────────────────────────────────────
        // Java / pdf-cj 两侧 BaseFont.HELVETICA 常量名完全一致
        doc.newPage();
        doc.add(new Paragraph("P2: 内置拉丁字体（Not Embedded）", cjkBold(14)));
        doc.add(Chunk.NEWLINE);
        doc.add(new Paragraph("Helvetica: The quick brown fox jumps over the lazy dog. 0123456789",   helv(12)));
        doc.add(new Paragraph("Times:     The quick brown fox jumps over the lazy dog. 0123456789",   new Font(TIMES,   12)));
        doc.add(new Paragraph("Courier:   The quick brown fox jumps over the lazy dog. 0123456789",   new Font(COURIER, 12)));
        // ★ Java：Font.ITALIC、Font.BOLDITALIC 整数常量
        // Cangjie：FontStyle.Italic、FontStyle.BoldItalic 枚举
        doc.add(new Paragraph("Helvetica Bold Italic: 12pt sample", new Font(HELVETICA, 12, Font.BOLDITALIC)));

        doc.close();
        System.out.println("  -> java_s1_text.pdf");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // S2  表格
    // ══════════════════════════════════════════════════════════════════════════
    static void section2_table() throws Exception {
        System.out.println("S2: 表格...");
        Document doc = new Document(PageSize.A4, 50, 50, 60, 50);
        PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s2_table.pdf"));
        doc.addTitle("PDF Compare S2 - Table");
        doc.open();

        doc.add(new Paragraph("S2: 表格功能对比测试", cjkBold(18)));
        doc.add(Chunk.NEWLINE);

        // ── 2-A: 基础表格 ─────────────────────────────────────────────────────
        doc.add(new Paragraph("2-A: 基础三列表格（setWidthPercentage + setWidths）", cjkBold(12)));

        // Java:    new PdfPTable(numColumns)
        // Cangjie: PdfPTable(numColumns)
        PdfPTable t1 = new PdfPTable(3);
        t1.setWidthPercentage(80);
        // Java:    setWidths(float[])
        // Cangjie: setWidths(Array<Float32>)
        t1.setWidths(new float[]{1f, 2f, 1f});
        t1.setSpacingBefore(6);
        t1.setSpacingAfter(16);

        for (String h : new String[]{"姓名", "电子邮件", "年龄"}) {
            // Java:    new PdfPCell(new Phrase(...))
            // Cangjie: PdfPCell(Phrase(...))
            PdfPCell cell = new PdfPCell(new Phrase(h, cjkBold(11)));
            // Java:    new Color(r,g,b)  java.awt.Color
            // Cangjie: Color(r,g,b)     pdf_cj.text.Color
            cell.setBackgroundColor(new Color(66, 139, 202));
            // Java:    Element.ALIGN_CENTER
            // Cangjie: Alignment.Center
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setPadding(6);
            t1.addCell(cell);
        }
        String[][] rows1 = {{"张三", "zhang@example.com", "25"}, {"李四", "li@example.com", "30"}};
        for (String[] row : rows1) {
            for (String v : row) {
                PdfPCell c = new PdfPCell(new Phrase(v, cjk(11)));
                c.setPadding(5);
                t1.addCell(c);
            }
        }
        doc.add(t1);

        // ── 2-B: Colspan 表格 ─────────────────────────────────────────────────
        doc.add(new Paragraph("2-B: Colspan（跨列）", cjkBold(12)));
        PdfPTable t2 = new PdfPTable(4);
        t2.setWidthPercentage(100);
        t2.setSpacingBefore(6);
        t2.setSpacingAfter(16);

        // 跨 4 列标题行
        PdfPCell topCell = new PdfPCell(new Phrase("2024 年度销售报表", cjkBold(13)));
        topCell.setColspan(4);   // Java/Cangjie: 方法名完全相同
        topCell.setHorizontalAlignment(Element.ALIGN_CENTER);
        topCell.setBackgroundColor(new Color(52, 152, 219));
        topCell.setPadding(10);
        t2.addCell(topCell);

        for (String h : new String[]{"区域", "Q1", "Q2", "Q3"}) {
            PdfPCell c = new PdfPCell(new Phrase(h, cjkBold(11)));
            c.setBackgroundColor(new Color(189, 195, 199));
            c.setHorizontalAlignment(Element.ALIGN_CENTER);
            c.setPadding(6);
            t2.addCell(c);
        }
        String[][] rows2 = {{"华北","1200","1350","1480"}, {"华东","1500","1620","1750"}, {"华南","980","1050","1180"}};
        for (String[] row : rows2) {
            for (int i = 0; i < row.length; i++) {
                PdfPCell c = new PdfPCell(new Phrase(row[i], cjk(11)));
                c.setHorizontalAlignment(i == 0 ? Element.ALIGN_LEFT : Element.ALIGN_CENTER);
                c.setPadding(5);
                t2.addCell(c);
            }
        }
        // 跨 3 列合计标签
        PdfPCell sumLabel = new PdfPCell(new Phrase("合计", cjkBold(11)));
        sumLabel.setColspan(3);
        sumLabel.setHorizontalAlignment(Element.ALIGN_RIGHT);
        sumLabel.setPadding(6);
        t2.addCell(sumLabel);
        PdfPCell sumVal = new PdfPCell(new Phrase("4130", cjkBold(11)));
        sumVal.setHorizontalAlignment(Element.ALIGN_CENTER);
        sumVal.setPadding(6);
        t2.addCell(sumVal);
        doc.add(t2);

        // ── 2-C: Rowspan + 嵌套 Paragraph ────────────────────────────────────
        doc.add(new Paragraph("2-C: Rowspan + 单元格内嵌段落", cjkBold(12)));
        PdfPTable t3 = new PdfPTable(3);
        t3.setWidthPercentage(100);
        t3.setSpacingBefore(6);
        t3.setSpacingAfter(16);
        t3.setWidths(new float[]{1f, 3f, 2f});

        // 表头
        for (String h : new String[]{"分组", "描述", "状态"}) {
            PdfPCell c = new PdfPCell(new Phrase(h, cjkBold(11)));
            c.setBackgroundColor(new Color(149, 165, 166));
            c.setHorizontalAlignment(Element.ALIGN_CENTER);
            c.setPadding(6);
            t3.addCell(c);
        }

        // ★ Rowspan：Java/Cangjie 方法名完全相同
        PdfPCell groupA = new PdfPCell(new Phrase("A 组", cjkBold(11)));
        groupA.setRowspan(2);    // 跨 2 行
        groupA.setVerticalAlignment(Element.ALIGN_MIDDLE);
        groupA.setHorizontalAlignment(Element.ALIGN_CENTER);
        groupA.setBackgroundColor(new Color(236, 240, 241));
        groupA.setPadding(6);
        t3.addCell(groupA);

        // ★ 单元格内嵌 Paragraph（Java/Cangjie 都用 cell.addElement(paragraph)）
        PdfPCell descA1 = new PdfPCell();
        Paragraph pA1 = new Paragraph("功能模块 A1", cjkBold(11));
        pA1.setSpacingAfter(4);
        descA1.addElement(pA1);
        descA1.addElement(new Paragraph("负责核心数据处理逻辑，支持多线程并发。", cjk(10)));
        descA1.setPadding(6);
        t3.addCell(descA1);

        PdfPCell statusA1 = new PdfPCell(new Phrase("✓ 完成", cjk(11)));
        statusA1.setHorizontalAlignment(Element.ALIGN_CENTER);
        statusA1.setBackgroundColor(new Color(212, 239, 223));
        statusA1.setPadding(6);
        t3.addCell(statusA1);

        // 第 2 行（groupA rowspan 占用 col0）
        PdfPCell descA2 = new PdfPCell(new Paragraph("功能模块 A2：UI 层，依赖 A1 提供的接口。", cjk(11)));
        descA2.setPadding(6);
        t3.addCell(descA2);
        PdfPCell statusA2 = new PdfPCell(new Phrase("进行中", cjk(11)));
        statusA2.setHorizontalAlignment(Element.ALIGN_CENTER);
        statusA2.setBackgroundColor(new Color(253, 235, 208));
        statusA2.setPadding(6);
        t3.addCell(statusA2);

        // 独立行（无 rowspan）
        PdfPCell groupB = new PdfPCell(new Phrase("B 组", cjkBold(11)));
        groupB.setHorizontalAlignment(Element.ALIGN_CENTER);
        groupB.setBackgroundColor(new Color(236, 240, 241));
        groupB.setPadding(6);
        t3.addCell(groupB);
        t3.addCell(new PdfPCell(new Phrase("功能模块 B1：独立服务，对外暴露 REST API。", cjk(11))));
        PdfPCell statusB = new PdfPCell(new Phrase("待开始", cjk(11)));
        statusB.setHorizontalAlignment(Element.ALIGN_CENTER);
        statusB.setBackgroundColor(new Color(235, 222, 240));
        statusB.setPadding(6);
        t3.addCell(statusB);

        doc.add(t3);

        // ── 2-D: headerRows（重复表头） ───────────────────────────────────────
        doc.add(new Paragraph("2-D: 重复表头（headerRows=1，自动换页后会重复首行）", cjkBold(12)));
        PdfPTable t4 = new PdfPTable(3);
        t4.setWidthPercentage(100);
        t4.setSpacingBefore(6);
        // Java / Cangjie: setHeaderRows(n) 方法名相同
        t4.setHeaderRows(1);
        // ★ OpenPDF PdfPCell.clone() 是 protected，不能直接使用；需手动复制构造
        // Cangjie 中同样没有 clone() — 都要手动构建每个单元格
        for (String hLabel : new String[]{"列 1", "列 2", "列 3"}) {
            PdfPCell hc = new PdfPCell(new Phrase(hLabel, cjkBold(11)));
            hc.setBackgroundColor(new Color(52, 73, 94));
            hc.setHorizontalAlignment(Element.ALIGN_CENTER);
            hc.setPadding(6);
            t4.addCell(hc);
        }
        for (int r = 1; r <= 5; r++) {
            for (int c = 1; c <= 3; c++) {
                t4.addCell(new PdfPCell(new Phrase("行" + r + "列" + c, cjk(10))));
            }
        }
        doc.add(t4);

        doc.close();
        System.out.println("  -> java_s2_table.pdf");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // S3  图片
    // ══════════════════════════════════════════════════════════════════════════
    static void section3_image() throws Exception {
        System.out.println("S3: 图片...");
        Document doc = new Document(PageSize.A4, 50, 50, 60, 50);
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s3_image.pdf"));
        doc.addTitle("PDF Compare S3 - Image");
        doc.open();

        doc.add(new Paragraph("S3: 图片嵌入与缩放对比", cjkBold(18)));
        doc.add(Chunk.NEWLINE);

        float availW = doc.getPageSize().getWidth() - 100;   // 页宽 - 左右边距

        // ── 3-A: JPEG 嵌入 ─────────────────────────────────────────────────
        doc.add(new Paragraph("3-A: JPEG 嵌入（river.jpg，scaleToFit）", cjkBold(12)));
        // Java:    Image.getInstance(path)  -- 静态工厂方法，两侧完全相同
        // Cangjie: Image.getInstance(path)
        Image img1 = Image.getInstance(IMG_DIR + "river.jpg");
        img1.scaleToFit(availW * 0.8f, 200);   // Java: float 参数  Cangjie: Float32
        // Java:    Image.MIDDLE (int)         Cangjie: Alignment.Center (enum)
        img1.setAlignment(Image.MIDDLE);
        img1.setSpacingBefore(6);
        img1.setSpacingAfter(14);
        doc.add(img1);

        // ── 3-B: PNG 嵌入（scalePercent） ─────────────────────────────────
        doc.add(new Paragraph("3-B: PNG 嵌入（mountain.png，scalePercent 30%）", cjkBold(12)));
        Image img2 = Image.getInstance(IMG_DIR + "mountain.png");
        // Java / Cangjie: scalePercent(float) 方法名相同
        img2.scalePercent(30);
        img2.setAlignment(Image.MIDDLE);
        img2.setSpacingBefore(6);
        img2.setSpacingAfter(14);
        doc.add(img2);

        // ── 3-C: 三种缩放方式 ──────────────────────────────────────────────
        doc.add(new Paragraph("3-C: 三种缩放方式（nodes.jpeg）", cjkBold(12)));
        for (String label : new String[]{"左对齐（Image.LEFT）", "居中（Image.MIDDLE）", "右对齐（Image.RIGHT）"}) {
            doc.add(new Paragraph(label + "，scalePercent 15%：", cjk(11)));
            Image imgX = Image.getInstance(IMG_DIR + "nodes.jpeg");
            imgX.scalePercent(15);
            // Java: Image.LEFT / Image.MIDDLE / Image.RIGHT  整数常量
            // Cangjie: Alignment.Left / .Center / .Right     枚举
            if (label.startsWith("左")) imgX.setAlignment(Image.LEFT);
            else if (label.startsWith("居")) imgX.setAlignment(Image.MIDDLE);
            else imgX.setAlignment(Image.RIGHT);
            imgX.setSpacingAfter(8);
            doc.add(imgX);
        }

        // ── 3-D: scaleAbsolute 固定尺寸 ────────────────────────────────────
        doc.add(new Paragraph("3-D: scaleAbsolute（固定 150×100）", cjkBold(12)));
        Image img3 = Image.getInstance(IMG_DIR + "nodes.jpeg");
        // Java:    scaleAbsolute(float w, float h)
        // Cangjie: scaleAbsolute(Float32, Float32)  -- 完全相同签名
        img3.scaleAbsolute(150, 100);
        img3.setAlignment(Image.MIDDLE);
        doc.add(img3);

        // ── 3-E: 绝对定位（setAbsolutePosition） ──────────────────────────
        doc.newPage();
        doc.add(new Paragraph("3-E: 绝对定位（setAbsolutePosition）", cjkBold(12)));
        doc.add(new Paragraph("图片直接放置在 PDF 坐标系 (60, 500) 处，不受文档流影响：", cjk(11)));
        Image img4 = Image.getInstance(IMG_DIR + "nodes.jpeg");
        img4.scaleAbsolute(180, 120);
        // Java / Cangjie: setAbsolutePosition(x, y) 方法名相同
        img4.setAbsolutePosition(60, 500);
        doc.add(img4);

        doc.close();
        System.out.println("  -> java_s3_image.pdf");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // S4  底层绘图（PdfContentByte）
    // ══════════════════════════════════════════════════════════════════════════
    static void section4_drawing() throws Exception {
        System.out.println("S4: 底层绘图...");
        Document doc = new Document(PageSize.A4, 50, 50, 60, 50);
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s4_drawing.pdf"));
        doc.addTitle("PDF Compare S4 - Drawing");
        doc.open();

        doc.add(new Paragraph("S4: 底层绘图（PdfContentByte）", cjkBold(18)));
        // Java / Cangjie: writer.getDirectContent() 完全相同
        PdfContentByte cb = writer.getDirectContent();
        float pH = doc.getPageSize().getHeight();

        // ── 4-A: 基本形状 ─────────────────────────────────────────────────
        // Java / Cangjie: saveState / restoreState / setLineWidth / setColorFill 完全相同
        cb.saveState();
        cb.setLineWidth(1.5f);
        cb.setColorFill(new Color(173, 216, 230));
        cb.setColorStroke(Color.BLACK);
        cb.rectangle(60, pH - 160, 100, 50);
        cb.fillStroke();

        cb.setColorFill(new Color(255, 220, 220));
        cb.setColorStroke(new Color(180, 0, 0));
        cb.roundRectangle(180, pH - 160, 100, 50, 10);
        cb.fillStroke();

        cb.setColorFill(new Color(220, 255, 220));
        cb.setColorStroke(new Color(0, 150, 0));
        cb.ellipse(300, pH - 160, 440, pH - 110);
        cb.fillStroke();
        cb.restoreState();

        // ── 4-B: 虚线样式 ──────────────────────────────────────────────────
        cb.saveState();
        cb.setColorStroke(Color.DARK_GRAY);
        cb.setLineWidth(1.5f);
        // Java / Cangjie: setLineDash 签名相同
        cb.setLineDash(0f);            // 实线 -- Cangjie: cb.setLineDash(0.0)
        cb.moveTo(60, pH - 200); cb.lineTo(480, pH - 200); cb.stroke();

        cb.setLineDash(8f, 3f, 0f);   // 8-3 虚线
        cb.moveTo(60, pH - 220); cb.lineTo(480, pH - 220); cb.stroke();

        cb.setLineDash(new float[]{3f, 2f, 1f, 2f}, 0f);  // 点划线
        // Cangjie: cb.setLineDash([3.0, 2.0, 1.0, 2.0], 0.0)  — Array 语法不同
        cb.moveTo(60, pH - 240); cb.lineTo(480, pH - 240); cb.stroke();
        cb.restoreState();

        // ── 4-C: CMYK 颜色 ────────────────────────────────────────────────
        // ★ OpenPDF 2.x setCMYKColorFill 参数类型改为 int(0-255)
        //   OpenPDF 1.x: setCMYKColorFill(float c, float m, float y, float k) — 0.0~1.0
        //   OpenPDF 2.x: setCMYKColorFill(int c, int m, int y, int k)         — 0~255
        // Cangjie: setCMYKColorFill(Float32, Float32, Float32, Float32)       — 0.0~1.0（同 1.x）
        cb.saveState();
        cb.setLineWidth(0.5f);
        // 纯 CMYK 色：0~255 范围
        int[][] cmyk = {{255,0,0,0}, {0,255,0,0}, {0,0,255,0}, {0,0,0,255}};
        for (int i = 0; i < 4; i++) {
            cb.setCMYKColorFill(cmyk[i][0], cmyk[i][1], cmyk[i][2], cmyk[i][3]);
            cb.rectangle(60 + i * 70, pH - 290, 60, 35);
            cb.fill();
        }
        cb.restoreState();

        // ── 4-D: 路径与贝塞尔曲线 ─────────────────────────────────────────
        cb.saveState();
        cb.setLineWidth(2f);
        cb.setColorStroke(new Color(255, 128, 0));
        cb.moveTo(60, pH - 360);
        // Java / Cangjie: curveTo(cp1x,cp1y, cp2x,cp2y, x,y) 完全相同
        cb.curveTo(130, pH - 310, 200, pH - 420, 270, pH - 340);
        cb.curveTo(340, pH - 270, 420, pH - 400, 480, pH - 330);
        cb.stroke();
        cb.restoreState();

        // ── 4-E: 裁剪路径（clip） ─────────────────────────────────────────
        cb.saveState();
        cb.ellipse(60, pH - 470, 240, pH - 380);
        cb.clip();
        cb.newPath();
        cb.setLineWidth(8f);
        cb.setColorStroke(new Color(255, 80, 80));
        for (int li = 0; li < 12; li++) {
            float off = li * 20;
            cb.moveTo(60, pH - 470 + off);
            cb.lineTo(60 + off, pH - 380);
            cb.stroke();
        }
        cb.restoreState();
        cb.saveState();
        cb.setLineWidth(1f);
        cb.setColorStroke(new Color(100, 100, 100));
        cb.ellipse(60, pH - 470, 240, pH - 380);
        cb.stroke();
        cb.restoreState();

        // ── 4-F: 文字绝对定位（beginText / endText / showTextAligned） ──────
        // Java / Cangjie: beginText / endText / showTextAligned 完全相同
        cb.beginText();
        cb.setFontAndSize(HELVETICA, 12);
        cb.setColorFill(Color.BLACK);
        // Java:    PdfContentByte.ALIGN_LEFT / ALIGN_CENTER / ALIGN_RIGHT (int)
        // Cangjie: PdfContentByte.ALIGN_LEFT / ALIGN_CENTER / ALIGN_RIGHT (Int64)
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT,   "Left  @ (280, " + (pH-400) + ")", 280, pH - 400, 0);
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER, "Center@ (380, " + (pH-420) + ")", 380, pH - 420, 0);
        cb.showTextAligned(PdfContentByte.ALIGN_RIGHT,  "Right @ (480, " + (pH-440) + ")", 480, pH - 440, 0);
        // 旋转文字
        cb.setColorFill(new Color(100, 0, 200));
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "Rotated 45 deg", 300, pH - 500, 45);
        cb.endText();

        // ── 4-G: 灰度填充（setGrayFill / setGrayStroke） ─────────────────
        // Java / Cangjie: setGrayFill(float) 完全相同
        cb.saveState();
        cb.setLineWidth(0);
        for (int i = 0; i < 5; i++) {
            cb.setGrayFill((float)(4 - i) / 4f);
            cb.rectangle(280 + i * 45, pH - 490, 40, 30);
            cb.fill();
        }
        cb.restoreState();

        doc.close();
        System.out.println("  -> java_s4_drawing.pdf");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // S5  页面事件（页眉 / 页脚 / 页码）
    // ★ 关键差异：Java 使用匿名内部类，Cangjie 必须定义命名类
    // ══════════════════════════════════════════════════════════════════════════
    static void section5_pageEvent() throws Exception {
        System.out.println("S5: 页面事件...");
        Document doc = new Document(PageSize.A4, 72, 72, 80, 60);
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s5_pagevent.pdf"));
        doc.addTitle("PDF Compare S5 - PageEvent");

        // ★ Java: 匿名内部类（直接 new PdfPageEventHelper() { ... }）
        // ★ Cangjie: 必须先定义 class HeaderFooter <: PdfPageEventHelper { ... }
        //            然后 writer.setPageEvent(HeaderFooter())
        writer.setPageEvent(new PdfPageEventHelper() {

            @Override
            public void onStartPage(PdfWriter w, Document d) {
                // onStartPage：在每页内容写入之前执行
                PdfContentByte cb = w.getDirectContent();
                float pW = d.getPageSize().getWidth();
                float pH = d.getPageSize().getHeight();
                // 页眉线
                cb.saveState();
                cb.setColorStroke(new Color(66, 139, 202));
                cb.setLineWidth(1.5f);
                cb.moveTo(50, pH - 50);
                cb.lineTo(pW - 50, pH - 50);
                cb.stroke();
                // 页眉文字
                cb.beginText();
                cb.setFontAndSize(HELVETICA, 9);
                cb.setColorFill(new Color(100, 100, 100));
                cb.showTextAligned(PdfContentByte.ALIGN_LEFT,  "PDF Compare S5 — Page Event Demo", 52, pH - 44, 0);
                cb.showTextAligned(PdfContentByte.ALIGN_RIGHT, "OpenPDF 2.0.3", pW - 52, pH - 44, 0);
                cb.endText();
                cb.restoreState();
            }

            @Override
            public void onEndPage(PdfWriter w, Document d) {
                // onEndPage：在每页内容写完后执行
                PdfContentByte cb = w.getDirectContent();
                float pW = d.getPageSize().getWidth();
                // 页脚线
                cb.saveState();
                cb.setColorStroke(new Color(180, 180, 180));
                cb.setLineWidth(0.5f);
                cb.moveTo(50, 45);
                cb.lineTo(pW - 50, 45);
                cb.stroke();
                // 页码居中
                cb.beginText();
                cb.setFontAndSize(HELVETICA, 9);
                cb.setColorFill(new Color(120, 120, 120));
                cb.showTextAligned(PdfContentByte.ALIGN_CENTER,
                    "第 " + w.getPageNumber() + " 页", pW / 2, 32, 0);
                cb.endText();
                cb.restoreState();
            }
        });

        doc.open();

        // 生成多页内容验证页眉/页脚重复
        for (int pg = 1; pg <= 3; pg++) {
            doc.add(new Paragraph("第 " + pg + " 页内容", cjkBold(16)));
            doc.add(Chunk.NEWLINE);
            for (int i = 1; i <= 8; i++) {
                doc.add(new Paragraph("第 " + pg + " 页 · 第 " + i + " 段：" +
                    "这是用于测试页眉页脚重复渲染的内容文字，确保每页都有完整的页眉线和页码。", cjk(12)));
            }
            if (pg < 3) doc.newPage();
        }

        doc.close();
        System.out.println("  -> java_s5_pagevent.pdf");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // S6  书签（Outline）与超链接注释
    // ══════════════════════════════════════════════════════════════════════════
    static void section6_bookmark() throws Exception {
        System.out.println("S6: 书签与注释...");
        Document doc = new Document(PageSize.A4, 72, 72, 72, 60);
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s6_bookmark.pdf"));
        doc.addTitle("PDF Compare S6 - Bookmark & Annotation");

        // ── 书签（Outline）────────────────────────────────────────────────
        // Java:    通过 cb.getRootOutline() 获取根节点，然后 new PdfOutline(parent, dest, title)
        // Cangjie: writer.addOutline(title, dest) 返回 PdfOutline，
        //          outline.addChild(PdfOutline(title, dest))
        // ★ 差异：Java 构造 PdfOutline 时直接传 parent；Cangjie 先创建再 addChild
        doc.open();

        PdfContentByte cb = writer.getDirectContent();
        PdfOutline root = cb.getRootOutline();

        // 第 1 章
        cb.localDestination("ch1", new PdfDestination(PdfDestination.FITH));
        // Java: new PdfOutline(parent, dest, title)
        PdfOutline bm1 = new PdfOutline(root,
            new PdfDestination(PdfDestination.FITH), "第 1 章：文档基础");

        doc.add(new Paragraph("第 1 章：文档基础", cjkBold(18)));
        doc.add(Chunk.NEWLINE);
        doc.add(new Paragraph("1.1 文档生命周期", cjkBold(13)));
        cb.localDestination("s11", new PdfDestination(PdfDestination.FITH));
        // 嵌套书签
        new PdfOutline(bm1, new PdfDestination(PdfDestination.FITH), "1.1 文档生命周期");
        doc.add(new Paragraph("Document 对象管理 PDF 的页面布局、元数据和内容流。" +
            "通过 open() 开启写入，close() 完成所有对象的序列化。", cjk(12)));
        doc.add(Chunk.NEWLINE);

        doc.add(new Paragraph("1.2 PdfWriter 与流", cjkBold(13)));
        cb.localDestination("s12", new PdfDestination(PdfDestination.FITH));
        new PdfOutline(bm1, new PdfDestination(PdfDestination.FITH), "1.2 PdfWriter 与流");
        doc.add(new Paragraph("PdfWriter 负责将 Document 的内容写入 OutputStream（Java）或 File（Cangjie）。", cjk(12)));

        // 第 2 章（新页）
        doc.newPage();
        cb.localDestination("ch2", new PdfDestination(PdfDestination.FITH));
        PdfOutline bm2 = new PdfOutline(root,
            new PdfDestination(PdfDestination.FITH), "第 2 章：字体与排版");
        doc.add(new Paragraph("第 2 章：字体与排版", cjkBold(18)));
        doc.add(Chunk.NEWLINE);

        new PdfOutline(bm2, new PdfDestination(PdfDestination.FITH), "2.1 字体嵌入与子集化");
        doc.add(new Paragraph("2.1 字体嵌入与子集化", cjkBold(13)));
        doc.add(new Paragraph("两侧均支持 TrueType / OpenType 字体子集化嵌入，" +
            "生成的 PDF 字体名称格式为 ABCDEF+FontName。", cjk(12)));

        // ── 超链接注释 ────────────────────────────────────────────────────
        doc.add(Chunk.NEWLINE);
        doc.add(new Paragraph("超链接注释（URI Annotation）：", cjkBold(13)));

        // ★ Java：Anchor 类（高层 API）可以在文档流中直接创建超链接
        // ★ Cangjie：使用低层 PdfAnnotationFactory.createLink(rect, dest) API
        Anchor anchor = new Anchor("← 点击访问 OpenPDF 项目主页", cjk(12));
        // Anchor 的 reference 即链接目标 URI
        anchor.setReference("https://github.com/LibrePDF/OpenPDF");
        doc.add(new Paragraph(anchor));

        // Java 也可以用低层 API，与 Cangjie 更相似：
        // PdfAnnotation link = PdfAnnotation.createLink(writer, rect, PdfAnnotation.HIGHLIGHT_INVERT,
        //                          new PdfAction("https://..."));
        // writer.addAnnotation(link);

        doc.close();
        System.out.println("  -> java_s6_bookmark.pdf");
    }
}
