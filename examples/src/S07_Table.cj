package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.PdfWriter
import pdf_cj.table.{PdfPTable, PdfPCell}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment, VerticalAlignment, Border}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let _s07_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s07_OUT  = "output/"



func s07HdrCell(text: String): PdfPCell {
    let helvBf = newHelvBf()
    let cell = PdfPCell(Phrase(text, Font(helvBf, 11.0, FontStyle.Bold, Color(255, 255, 255))))
    cell.setBackgroundColor(Color(50, 50, 150))
    cell.setHorizontalAlignment(Alignment.Center)
    cell.setVerticalAlignment(VerticalAlignment.Middle)
    cell.setPadding(6.0)
    cell
}

func s07DataCell(text: String): PdfPCell {
    let helvBf = newHelvBf()
    let cell = PdfPCell(Phrase(text, Font(helvBf, 10.0)))
    cell.setHorizontalAlignment(Alignment.Left)
    cell.setVerticalAlignment(VerticalAlignment.Middle)
    cell.setPadding(5.0)
    cell
}

func s07_table(): Unit {
    println("S07: PdfPTable Demo")
    let cjkBf = newCjkBf()
    let helvBf = newHelvBf()
    try {
        let doc = Document(PageSize.A4, 50.0, 50.0, 72.0, 72.0)
        let file = File(Path(_s07_OUT + "cj_s07_table.pdf"), OpenMode.Write)
        PdfWriter.getInstance(doc, file)
        doc.open()

        var title = Paragraph("S07: PdfPTable Demo", Font(cjkBf, 18.0, FontStyle.Bold))
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        doc.add(title)

        // ---- Table 1: Basic cell properties ----
        doc.add(Paragraph("Table 1: Basic Cell Properties", Font(helvBf, 13.0, FontStyle.Bold)))
        let t1 = PdfPTable(4)
        t1.setWidthPercentage(100.0)
        t1.setWidths([Float32(2.0), Float32(2.0), Float32(2.0), Float32(2.0)])
        t1.setSpacingBefore(8.0)
        t1.setSpacingAfter(16.0)

        // Header row
        let headers1 = ["Column A", "Column B", "Column C", "Column D"]
        for (h in headers1) {
            t1.addCell(s07HdrCell(h))
        }

        // Row with different paddings
        let c1 = PdfPCell(Phrase("PaddingLeft=20", Font(helvBf, 10.0)))
        c1.setPaddingLeft(20.0)
        t1.addCell(c1)

        let c2 = PdfPCell(Phrase("PaddingTop=15", Font(helvBf, 10.0)))
        c2.setPaddingTop(15.0)
        t1.addCell(c2)

        let c3 = PdfPCell(Phrase("PaddingRight=20", Font(helvBf, 10.0)))
        c3.setPaddingRight(20.0)
        t1.addCell(c3)

        let c4 = PdfPCell(Phrase("PaddingBottom=15", Font(helvBf, 10.0)))
        c4.setPaddingBottom(15.0)
        t1.addCell(c4)

        // Row with background color
        let bg1 = s07DataCell("Yellow BG")
        bg1.setBackgroundColor(Color(255, 255, 0))
        t1.addCell(bg1)

        let bg2 = s07DataCell("Cyan BG")
        bg2.setBackgroundColor(Color(0, 255, 255))
        t1.addCell(bg2)

        let bg3 = s07DataCell("Pink BG")
        bg3.setBackgroundColor(Color(255, 200, 200))
        t1.addCell(bg3)

        let bg4 = s07DataCell("Green BG")
        bg4.setBackgroundColor(Color(200, 255, 200))
        t1.addCell(bg4)

        // Row with borders
        let noBorder = s07DataCell("No border")
        noBorder.setBorder(Border.NO_BORDER)
        t1.addCell(noBorder)

        let topBorder = s07DataCell("Top only")
        topBorder.setBorder(Border.TOP)
        topBorder.setBorderWidth(2.0)
        t1.addCell(topBorder)

        let thickBorder = s07DataCell("Thick border")
        thickBorder.setBorderWidth(3.0)
        t1.addCell(thickBorder)

        let noWrap = s07DataCell("NoWrap=true content here")
        noWrap.setNoWrap(true)
        t1.addCell(noWrap)

        // Row with fixed height
        let fixedH = s07DataCell("fixedHeight=40")
        fixedH.setFixedHeight(40.0)
        t1.addCell(fixedH)

        let minH = s07DataCell("minHeight=30")
        minH.setMinimumHeight(30.0)
        t1.addCell(minH)

        // addElement demo
        let elemCell = PdfPCell()
        var elemPara = Paragraph("addElement(Para)", Font(helvBf, 10.0))
        elemPara.setAlignment(Alignment.Center)
        elemCell.addElement(elemPara)
        t1.addCell(elemCell)

        // setPhrase demo
        let phraseCell = PdfPCell()
        phraseCell.setPhrase(Phrase("setPhrase()", Font(helvBf, 10.0)))
        t1.addCell(phraseCell)

        doc.add(t1)

        // ---- Table 2: Colspan and Rowspan ----
        doc.add(Paragraph("Table 2: Colspan and Rowspan", Font(helvBf, 13.0, FontStyle.Bold)))
        let t2 = PdfPTable(4)
        t2.setWidthPercentage(100.0)
        t2.setSpacingBefore(8.0)
        t2.setSpacingAfter(16.0)

        // Row 1: colspan=4 header
        let topSpan = s07HdrCell("Full Width Header (colspan=4)")
        topSpan.setColspan(4)
        t2.addCell(topSpan)

        // Row 2: colspan=2 + 2 normal cells
        let span2 = PdfPCell(Phrase("colspan=2", Font(helvBf, 10.0)))
        span2.setColspan(2)
        span2.setBackgroundColor(Color(200, 220, 255))
        span2.setPadding(6.0)
        t2.addCell(span2)
        t2.addCell(s07DataCell("Cell 3"))
        t2.addCell(s07DataCell("Cell 4"))

        // Row 3: rowspan=2 on first cell + 3 normal cells
        let rowSpan = PdfPCell(Phrase("rowspan=2", Font(helvBf, 10.0)))
        rowSpan.setRowspan(2)
        rowSpan.setBackgroundColor(Color(255, 220, 200))
        rowSpan.setVerticalAlignment(VerticalAlignment.Middle)
        rowSpan.setHorizontalAlignment(Alignment.Center)
        rowSpan.setPadding(6.0)
        t2.addCell(rowSpan)
        t2.addCell(s07DataCell("R3-C2"))
        t2.addCell(s07DataCell("R3-C3"))
        t2.addCell(s07DataCell("R3-C4"))

        // Row 4: 3 cells (rowspan cell spans row 3 and 4)
        t2.addCell(s07DataCell("R4-C2"))
        t2.addCell(s07DataCell("R4-C3"))
        t2.addCell(s07DataCell("R4-C4"))

        // Row 5: colspan=2 x2
        let span2a = PdfPCell(Phrase("Bottom Left (colspan=2)", Font(helvBf, 10.0)))
        span2a.setColspan(2)
        span2a.setBackgroundColor(Color(230, 255, 230))
        span2a.setPadding(6.0)
        t2.addCell(span2a)

        let span2b = PdfPCell(Phrase("Bottom Right (colspan=2)", Font(helvBf, 10.0)))
        span2b.setColspan(2)
        span2b.setBackgroundColor(Color(255, 230, 255))
        span2b.setPadding(6.0)
        t2.addCell(span2b)

        doc.add(t2)

        // ---- Table 3: Long table with header/footer rows spanning pages ----
        doc.add(Paragraph("Table 3: Long Table with Header Rows (spans to page 2)", Font(helvBf, 13.0, FontStyle.Bold)))
        let t3 = PdfPTable(5)
        t3.setWidthPercentage(100.0)
        t3.setWidths([Float32(1.0), Float32(2.0), Float32(2.0), Float32(2.0), Float32(1.0)])
        t3.setSpacingBefore(8.0)
        t3.setSpacingAfter(16.0)
        t3.setHeaderRows(2)
        t3.setFooterRows(1)

        // Header row 1
        let headers3 = ["#", "Name", "Description", "Value", "Status"]
        for (h in headers3) {
            t3.addCell(s07HdrCell(h))
        }
        // Footer row
        let footerCell = PdfPCell(Phrase("Footer — repeated on each page", Font(helvBf, 9.0)))
        footerCell.setColspan(5)
        footerCell.setBackgroundColor(Color(200, 200, 200))
        footerCell.setHorizontalAlignment(Alignment.Center)
        footerCell.setPadding(4.0)
        t3.addCell(footerCell)

        // Add 40 data rows
        let statuses = ["OK", "WARN", "ERROR", "INFO"]
        let statusColors = [Color(200, 255, 200), Color(255, 255, 200), Color(255, 200, 200), Color(200, 230, 255)]
        for (i in 1..41) {
            t3.addCell(s07DataCell("${i}"))
            t3.addCell(s07DataCell("Item ${i}"))
            t3.addCell(s07DataCell("Description for row ${i}"))
            let cents = i * 999
            let rem = cents % 100
            let valStr = if (rem < 10) { "${cents / 100}.0${rem}" } else { "${cents / 100}.${rem}" }
            t3.addCell(s07DataCell("$${valStr}"))
            let idx = i % 4
            let statusCell = s07DataCell(statuses[idx])
            statusCell.setBackgroundColor(statusColors[idx])
            statusCell.setHorizontalAlignment(Alignment.Center)
            t3.addCell(statusCell)
        }
        doc.add(t3)

        // ---- Table 4: Total Width Locked + disableBorderSide ----
        doc.add(Paragraph("Table 4: Total Width Locked + disableBorderSide", Font(helvBf, 13.0, FontStyle.Bold)))
        let t4 = PdfPTable(3)
        t4.setTotalWidth(350.0)
        t4.setLockedWidth(true)
        t4.setSpacingBefore(8.0)
        t4.setSpacingAfter(16.0)

        for (h in ["Col 1", "Col 2", "Col 3"]) {
            t4.addCell(s07HdrCell(h))
        }

        for (row in 0..3) {
            for (col in 0..3) {
                let cell = s07DataCell("R${row + 1}C${col + 1}")
                if (col == 0) { cell.disableBorderSide(Border.LEFT) }
                if (col == 2) { cell.disableBorderSide(Border.RIGHT) }
                t4.addCell(cell)
            }
        }
        doc.add(t4)

        doc.close()
        println("  S07 done: ${_s07_OUT}cj_s07_table.pdf")
    } catch (e: Exception) {
        println("  ✗ S07: ${e.message}")
    }
}
