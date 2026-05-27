import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S22_Chapter {
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

    static final String BODY_TEXT =
        "This is a body paragraph demonstrating the Chapter/Section structure in OpenPDF. " +
        "The high-level document structure API allows you to create well-organized documents " +
        "with proper chapter and section numbering. ";

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();

        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s22_chapter.pdf"));
        doc.open();

        // Document title (not a Chapter object, just a styled paragraph)
        Paragraph docTitle = new Paragraph("S22: Chapter & Section Demo", cjkBold(20));
        docTitle.setAlignment(Element.ALIGN_CENTER);
        docTitle.setSpacingAfter(30);
        doc.add(docTitle);

        // ---- Chapter 1: with chapter number shown ----
        Paragraph ch1TitlePara = new Paragraph("Chapter 1: Introduction", new Font(HELV_BF, 18, Font.BOLD, new Color(0, 0, 150)));
        Chapter chapter1 = new Chapter(ch1TitlePara, 1);
        // setNumberDepth(n): n=0 means no chapter number prefix, n=1 shows "1 Title", etc.
        chapter1.setNumberDepth(1);

        Paragraph ch1Body = new Paragraph(BODY_TEXT, helv(11));
        ch1Body.setSpacingBefore(8);
        ch1Body.setSpacingAfter(8);
        chapter1.add(ch1Body);

        chapter1.add(new Paragraph("第一章：介绍 — 这是第一章的中文内容。", cjk(11)));

        // Section 1.1
        Paragraph sec11Para = new Paragraph("1.1 Getting Started", new Font(HELV_BF, 14, Font.BOLD));
        Section section11 = chapter1.addSection(sec11Para);
        section11.setIndentationLeft(20f);
        section11.setNumberDepth(2);

        Paragraph sec11Body = new Paragraph("Section 1.1 discusses the basics of getting started with OpenPDF. " + BODY_TEXT, helv(11));
        sec11Body.setSpacingBefore(6);
        sec11Body.setSpacingAfter(6);
        section11.add(sec11Body);
        section11.add(new Paragraph("1.1 入门指南：快速开始使用OpenPDF。", cjk(11)));

        // Section 1.2
        Paragraph sec12Para = new Paragraph("1.2 Basic Concepts", new Font(HELV_BF, 14, Font.BOLD));
        Section section12 = chapter1.addSection(sec12Para);
        section12.setIndentationLeft(20f);
        section12.setNumberDepth(2);

        section12.add(new Paragraph("Section 1.2 explains basic concepts. " + BODY_TEXT, helv(11)));
        section12.add(new Paragraph("1.2 基本概念：PDF文档的核心概念。", cjk(11)));

        // Nested section 1.2.1
        Paragraph sec121Para = new Paragraph("1.2.1 Document Structure", new Font(HELV_BF, 12, Font.BOLD | Font.ITALIC));
        Section section121 = section12.addSection(sec121Para);
        section121.setIndentationLeft(40f);
        section121.setNumberDepth(3);
        section121.add(new Paragraph("Nested section content: Documents consist of pages, which contain text and graphics.", helv(11)));
        section121.add(new Paragraph("嵌套章节内容：文档由页面组成，页面包含文字和图形。", cjk(11)));

        // Nested section 1.2.2
        Paragraph sec122Para = new Paragraph("1.2.2 Content Elements", new Font(HELV_BF, 12, Font.BOLD | Font.ITALIC));
        Section section122 = section12.addSection(sec122Para);
        section122.setIndentationLeft(40f);
        section122.setNumberDepth(3);
        section122.add(new Paragraph("Content elements include Chunk, Phrase, Paragraph, Table, Image, etc.", helv(11)));

        // Section 1.3
        Paragraph sec13Para = new Paragraph("1.3 Hello World Example", new Font(HELV_BF, 14, Font.BOLD));
        Section section13 = chapter1.addSection(sec13Para);
        section13.setIndentationLeft(20f);
        section13.setNumberDepth(2);
        section13.add(new Paragraph("A simple Hello World example demonstrates the basic document creation flow.", helv(11)));

        doc.add(chapter1);

        // ---- Chapter 2: hidden numbering (setNumberDepth(0)) ----
        doc.newPage();

        Paragraph ch2TitlePara = new Paragraph("Chapter 2: Advanced Topics", new Font(HELV_BF, 18, Font.BOLD, new Color(0, 100, 0)));
        Chapter chapter2 = new Chapter(ch2TitlePara, 2);
        chapter2.setNumberDepth(0);  // hide chapter number prefix

        chapter2.add(new Paragraph("This chapter has setNumberDepth(0) — no automatic number prefix.", helv(11)));
        chapter2.add(new Paragraph("第二章：高级主题 — 编号深度为0，不显示章节编号前缀。", cjk(11)));
        chapter2.add(new Paragraph(BODY_TEXT + BODY_TEXT, helv(11)));

        // Section 2.1
        Section section21 = chapter2.addSection(new Paragraph("2.1 Fonts and Typography", new Font(HELV_BF, 14, Font.BOLD)));
        section21.setIndentationLeft(20f);
        section21.setNumberDepth(0);  // also hide section numbering
        section21.add(new Paragraph("Fonts and typography are critical for professional PDFs. " + BODY_TEXT, helv(11)));
        section21.add(new Paragraph("2.1 字体与排版：专业PDF中字体非常重要。", cjk(11)));

        // Section 2.2
        Section section22 = chapter2.addSection(new Paragraph("2.2 Tables and Layouts", new Font(HELV_BF, 14, Font.BOLD)));
        section22.setIndentationLeft(20f);
        section22.setNumberDepth(0);
        section22.add(new Paragraph("Tables provide structured data presentation. " + BODY_TEXT, helv(11)));

        // Nested 2.2.1
        Section section221 = section22.addSection(new Paragraph("2.2.1 PdfPTable", new Font(HELV_BF, 12, Font.ITALIC)));
        section221.setIndentationLeft(40f);
        section221.add(new Paragraph("PdfPTable is the primary table class in OpenPDF.", helv(11)));

        // Section 2.3
        Section section23 = chapter2.addSection(new Paragraph("2.3 Images and Graphics", new Font(HELV_BF, 14, Font.BOLD)));
        section23.setIndentationLeft(20f);
        section23.setNumberDepth(0);
        section23.add(new Paragraph("Images and vector graphics enhance document appearance. " + BODY_TEXT, helv(11)));

        doc.add(chapter2);

        doc.close();
        System.out.println("S22 done: " + OUT_DIR + "java_s22_chapter.pdf");
    }
}
