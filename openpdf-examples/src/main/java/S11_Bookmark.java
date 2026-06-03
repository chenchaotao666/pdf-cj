import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S11_Bookmark {
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
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s11_bookmark.pdf"));
        writer.setViewerPreferences(PdfWriter.PageModeUseOutlines);  // show bookmarks panel
        doc.open();

        PdfContentByte cb = writer.getDirectContent();

        // Title
        Paragraph title = new Paragraph("S11: Bookmark & Outline Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);
        doc.add(new Paragraph("Open the bookmarks panel to see the outline hierarchy.", helv(11)));
        doc.add(new Paragraph("Click bookmarks to navigate; internal links also work inline.", helv(11)));

        // ---- Chapter 1 ----
        // Create a named destination for Chapter 1
        String ch1Dest = "chapter1";
        // Add a local destination marker on the page
        cb.localDestination(ch1Dest, new PdfDestination(PdfDestination.FITH, 750));

        doc.add(new Paragraph(" ", helv(4)));
        Paragraph ch1Title = new Paragraph("Chapter 1: Introduction", cjkBold(16));
        ch1Title.setSpacingBefore(10);
        doc.add(ch1Title);
        doc.add(new Paragraph("This is the introduction chapter. It covers basics.", helv(12)));
        doc.add(new Paragraph("第一章：介绍 — 基础内容。", cjk(12)));

        String sec11Dest = "sec1.1";
        cb.localDestination(sec11Dest, new PdfDestination(PdfDestination.FITH, 650));

        Paragraph sec11Title = new Paragraph("  1.1 Getting Started", new Font(HELV_BF, 13, Font.BOLD));
        sec11Title.setSpacingBefore(12);
        doc.add(sec11Title);
        doc.add(new Paragraph("  Section 1.1 content: Getting started with OpenPDF.", helv(11)));
        doc.add(new Paragraph("  入门内容：如何开始使用OpenPDF。", cjk(11)));

        String sec12Dest = "sec1.2";
        cb.localDestination(sec12Dest, new PdfDestination(PdfDestination.XYZ, 72, 560, 0));

        Paragraph sec12Title = new Paragraph("  1.2 Basic Concepts", new Font(HELV_BF, 13, Font.BOLD));
        sec12Title.setSpacingBefore(12);
        doc.add(sec12Title);
        doc.add(new Paragraph("  Section 1.2 content: Basic concepts in PDF generation.", helv(11)));

        // Nested section 1.2.1
        String sec121Dest = "sec1.2.1";
        cb.localDestination(sec121Dest, new PdfDestination(PdfDestination.FIT));
        Paragraph sec121Title = new Paragraph("    1.2.1 Documents and Pages", new Font(HELV_BF, 12, Font.ITALIC));
        sec121Title.setSpacingBefore(8);
        doc.add(sec121Title);
        doc.add(new Paragraph("    Deep nested section content.", helv(11)));

        // ---- Chapter 2 on page 2 ----
        doc.newPage();

        String ch2Dest = "chapter2";
        cb.localDestination(ch2Dest, new PdfDestination(PdfDestination.FITH, 780));

        Paragraph ch2Title = new Paragraph("Chapter 2: Advanced Topics", cjkBold(16));
        ch2Title.setSpacingBefore(10);
        doc.add(ch2Title);
        doc.add(new Paragraph("This chapter covers advanced PDF features.", helv(12)));
        doc.add(new Paragraph("第二章：高级主题。", cjk(12)));

        String sec21Dest = "sec2.1";
        cb.localDestination(sec21Dest, new PdfDestination(PdfDestination.FITH, 700));
        Paragraph sec21Title = new Paragraph("  2.1 Fonts and Typography", new Font(HELV_BF, 13, Font.BOLD));
        sec21Title.setSpacingBefore(12);
        doc.add(sec21Title);
        doc.add(new Paragraph("  Content about fonts and typography in PDF.", helv(11)));

        String sec22Dest = "sec2.2";
        cb.localDestination(sec22Dest, new PdfDestination(PdfDestination.XYZ, 72, 600, 0));
        Paragraph sec22Title = new Paragraph("  2.2 Images and Graphics", new Font(HELV_BF, 13, Font.BOLD));
        sec22Title.setSpacingBefore(12);
        doc.add(sec22Title);
        doc.add(new Paragraph("  Content about images and graphics.", helv(11)));

        // Internal links in document body
        doc.add(new Paragraph(" ", helv(8)));
        doc.add(new Paragraph("Internal navigation links:", new Font(HELV_BF, 11, Font.BOLD)));

        Paragraph p1 = new Paragraph();
        Chunk link1 = new Chunk("→ Jump to Chapter 1", new Font(HELV_BF, 11, Font.UNDERLINE, Color.BLUE));
        link1.setLocalGoto(ch1Dest);
        p1.add(link1);
        doc.add(p1);

        Paragraph p2 = new Paragraph();
        Chunk link2 = new Chunk("→ Jump to Section 1.2", new Font(HELV_BF, 11, Font.UNDERLINE, Color.BLUE));
        link2.setLocalGoto(sec12Dest);
        p2.add(link2);
        doc.add(p2);

        // ---- Build the outline hierarchy ----
        // Root outline
        PdfOutline root = cb.getRootOutline();

        // Chapter 1 outline - bold (style: 0=normal,1=italic,2=bold,3=bolditalic)
        PdfOutline ch1Outline = new PdfOutline(root,
                new PdfDestination(PdfDestination.FITH),
                "Chapter 1: Introduction");
        ch1Outline.setStyle(2);  // bold
        ch1Outline.setColor(new Color(0, 0, 150));

        // Section 1.1 outline
        PdfOutline sec11Outline = new PdfOutline(ch1Outline,
                new PdfDestination(PdfDestination.FITH),
                "1.1 Getting Started");

        // Section 1.2 outline
        PdfOutline sec12Outline = new PdfOutline(ch1Outline,
                new PdfDestination(PdfDestination.FITH),
                "1.2 Basic Concepts");

        // Section 1.2.1 (nested under 1.2)
        PdfOutline sec121Outline = new PdfOutline(sec12Outline,
                new PdfDestination(PdfDestination.FIT),
                "1.2.1 Documents and Pages");
        sec121Outline.setStyle(1);  // italic

        // Chapter 2 outline - bold
        PdfOutline ch2Outline = new PdfOutline(root,
                new PdfDestination(PdfDestination.FITH),
                "Chapter 2: Advanced Topics");
        ch2Outline.setStyle(2);  // bold
        ch2Outline.setColor(new Color(0, 100, 0));

        // Section 2.1 outline
        new PdfOutline(ch2Outline,
                new PdfDestination(PdfDestination.FITH),
                "2.1 Fonts and Typography");

        // Section 2.2 outline
        new PdfOutline(ch2Outline,
                new PdfDestination(PdfDestination.FITH),
                "2.2 Images and Graphics");

        doc.close();
        System.out.println("S11 done: " + OUT_DIR + "java_s11_bookmark.pdf");
    }
}
