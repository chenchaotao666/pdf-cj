package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.text.{BaseFont, Font, FontStyle, Alignment}
import pdf_cj.util.{PageSize}
import std.fs.{File, OpenMode, Path}

let _s01_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s01_OUT  = "output/"

func s01_documentPage(): Unit {
    println("S01: Document & Page Demo")
    try {
        let cjkBf = BaseFont.createFont(_s01_FONT, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
        let helvBf = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)

        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s01_OUT + "cj_s01_document_page.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        // Page 1: show page size info and margins
        doc.addTitle("Document & Page Demo")
        let w = doc.pageSize.width
        let h = doc.pageSize.height
        let ml = doc.leftMargin
        let mr = doc.rightMargin
        let mt = doc.topMargin
        let mb = doc.bottomMargin

        var title = Paragraph("S01: Document & Page Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)

        doc.add(Paragraph("Page 1 — A4 Portrait", Font(helvBf, 14.0)))
        doc.add(Paragraph("Page size: ${w} x ${h} pt", Font(helvBf, 12.0)))
        doc.add(Paragraph("Margins — Left:${ml}  Right:${mr}  Top:${mt}  Bottom:${mb}", Font(helvBf, 12.0)))
        doc.add(Paragraph("Current page number: ${writer.pageNumber}", Font(helvBf, 12.0)))
        doc.add(Paragraph("中文文字测试 — CJK text on Page 1", Font(cjkBf, 14.0)))

        // Page 2: A4 rotated (landscape)
        doc.newPage()
        doc.add(Paragraph("Page 2 — A4 Rotated (Landscape)", Font(helvBf, 14.0)))
        let w2 = doc.pageSize.width
        let h2 = doc.pageSize.height
        doc.add(Paragraph("Page size: ${w2} x ${h2} pt", Font(helvBf, 12.0)))
        doc.add(Paragraph("Page number: ${writer.pageNumber}", Font(helvBf, 12.0)))
        doc.add(Paragraph("横向页面 — Landscape page", Font(cjkBf, 14.0)))

        // Page 3: back to A4 portrait
        doc.newPage()
        doc.add(Paragraph("Page 3 — Back to A4 Portrait", Font(helvBf, 14.0)))
        let w3 = doc.pageSize.width
        let h3 = doc.pageSize.height
        doc.add(Paragraph("Page size: ${w3} x ${h3} pt", Font(helvBf, 12.0)))
        doc.add(Paragraph("Page number: ${writer.pageNumber}", Font(helvBf, 12.0)))

        // Reset page count demo
        doc.resetPageCount()
        doc.add(Paragraph("After resetPageCount(), page number: ${writer.pageNumber}", Font(helvBf, 12.0)))
        doc.add(Paragraph("第三页 — Page 3 (A4竖向)", Font(cjkBf, 14.0)))

        doc.close()
        println("  S01 done: ${_s01_OUT}cj_s01_document_page.pdf")
    } catch (e: Exception) {
        println("  ✗ S01: ${e.message}")
    }
}
