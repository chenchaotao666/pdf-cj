/**
 * PdfPTable / PdfPCell 单元测试
 * 覆盖：列宽计算、单元格高度（换行估算）、行构建、colspan/rowspan 追踪
 */
package pdf_cj.test.table

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.table.{PdfPTable, PdfPCell, PdfPRow}
import pdf_cj.api.{Phrase, Paragraph}
import pdf_cj.text.{BaseFont, Font}

// ===== 列宽计算 =====

@Test
public class ColumnWidthTests {

    @TestCase
    func testEqualWidths(): Unit {
        let t = PdfPTable(3)
        let ws = t.getAbsoluteColumnWidths(300.0)
        @Expect(ws.size, 3)
        @Expect(ws[0], 100.0)
        @Expect(ws[1], 100.0)
        @Expect(ws[2], 100.0)
    }

    @TestCase
    func testRelativeWidths(): Unit {
        // 权重 [1, 2, 1] → 比例 25%, 50%, 25%
        let t = PdfPTable([1.0, 2.0, 1.0])
        let ws = t.getAbsoluteColumnWidths(400.0)
        @Expect(ws.size, 3)
        @Expect(ws[0], 100.0)
        @Expect(ws[1], 200.0)
        @Expect(ws[2], 100.0)
    }

    @TestCase
    func testAbsoluteWidths(): Unit {
        let t = PdfPTable(3)
        t.setTotalWidth([80.0, 120.0, 60.0])
        let ws = t.getAbsoluteColumnWidths(999.0)   // totalWidth 应被忽略
        @Expect(ws.size, 3)
        @Expect(ws[0], 80.0)
        @Expect(ws[1], 120.0)
        @Expect(ws[2], 60.0)
    }

    @TestCase
    func testSetWidths(): Unit {
        let t = PdfPTable(2)
        t.setWidths([3.0, 1.0])
        let ws = t.getAbsoluteColumnWidths(200.0)
        @Expect(ws[0], 150.0)
        @Expect(ws[1], 50.0)
    }
}

// ===== 单元格高度 =====

@Test
public class CellHeightTests {

    @TestCase
    func testFixedHeightOverrides(): Unit {
        let cell = PdfPCell()
        cell.setFixedHeight(50.0)
        // 无论 cellWidth 是什么，固定高度优先
        @Expect(cell.calculateHeight(200.0), 50.0)
    }

    @TestCase
    func testMinimumHeightEnforced(): Unit {
        let cell = PdfPCell()
        cell.setMinimumHeight(30.0)
        // 空单元格内容高度 < 30，应取 minimumHeight
        let h = cell.calculateHeight(200.0)
        @Expect(h >= 30.0, true)
    }

    @TestCase
    func testEmptyCellMinHeight(): Unit {
        let cell = PdfPCell()
        let h = cell.calculateHeight(200.0)
        @Expect(h >= 14.0, true)
    }

    @TestCase
    func testSingleLinePhrase(): Unit {
        let bf = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
        let font = Font(bf, 12.0)
        let cell = PdfPCell(Phrase("Hello", font))
        cell.setPadding(0.0)
        let h = cell.calculateHeight(500.0)   // 足够宽，一行
        // 高度 ≈ leading（约 14.4）+ padding（0）
        @Expect(h >= 12.0, true)
        @Expect(h < 40.0, true)
    }

    @TestCase
    func testLongTextWraps(): Unit {
        let bf = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
        let font = Font(bf, 12.0)
        // 很长的文本，在窄格中应产生多行
        let longText = "ABCDEFGHIJKLMNOPQRSTUVWXYZ ABCDEFGHIJKLMNOPQRSTUVWXYZ ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let cell = PdfPCell(Phrase(longText, font))
        cell.setPadding(0.0)
        let hNarrow = cell.calculateHeight(50.0)
        let hWide = cell.calculateHeight(2000.0)
        @Expect(hNarrow > hWide, true)
    }

    @TestCase
    func testPaddingAdded(): Unit {
        let cell = PdfPCell()
        cell.setPadding(10.0)
        let h = cell.calculateHeight(200.0)
        // paddingTop(10) + paddingBottom(10) = 20, and content contributes 0
        @Expect(h >= 20.0, true)
    }
}

// ===== 行构建与列位置 =====

@Test
public class RowBuildingTests {

    @TestCase
    func testBasicRowCompletion(): Unit {
        let t = PdfPTable(3)
        t.addCell(Phrase("A"))
        t.addCell(Phrase("B"))
        t.addCell(Phrase("C"))
        @Expect(t.rowCount, 1)
    }

    @TestCase
    func testAutoNewRowOnFull(): Unit {
        let t = PdfPTable(2)
        t.addCell(Phrase("A"))
        t.addCell(Phrase("B"))
        t.addCell(Phrase("C"))
        t.addCell(Phrase("D"))
        @Expect(t.rowCount, 2)
    }

    @TestCase
    func testColspanFillsColumns(): Unit {
        // colspan=2 + 1 cell = 3 columns → 1 row
        let t = PdfPTable(3)
        let wide = PdfPCell(Phrase("Wide"))
        wide.setColspan(2)
        t.addCell(wide)
        t.addCell(Phrase("Right"))
        @Expect(t.rowCount, 1)
    }

    @TestCase
    func testColumnPositionsBasic(): Unit {
        let t = PdfPTable(3)
        t.addCell(Phrase("A"))
        t.addCell(Phrase("B"))
        t.addCell(Phrase("C"))
        let rowOpt0 = t.getRow(0)
        if (rowOpt0.isSome()) {
            let row = rowOpt0.getOrThrow()
            @Expect(row.getColumnPosition(0), 0)
            @Expect(row.getColumnPosition(1), 1)
            @Expect(row.getColumnPosition(2), 2)
        }
    }

    @TestCase
    func testColumnPositionsWithColspan(): Unit {
        // colspan=2 at col 0 → next cell at col 2
        let t = PdfPTable(3)
        let wide = PdfPCell(Phrase("Wide"))
        wide.setColspan(2)
        t.addCell(wide)
        t.addCell(Phrase("Right"))
        let rowOpt0b = t.getRow(0)
        if (rowOpt0b.isSome()) {
            let row = rowOpt0b.getOrThrow()
            @Expect(row.getColumnPosition(0), 0)
            @Expect(row.getColumnPosition(1), 2)
        }
    }
}

// ===== Rowspan 追踪 =====

@Test
public class RowspanTests {

    @TestCase
    func testRowspan2NeedsFewerCellsInNextRow(): Unit {
        // 3 列：[A(rowspan=2), B, C] → 行1只需 2 个单元格
        let t = PdfPTable(3)
        let a = PdfPCell(Phrase("A"))
        a.setRowspan(2)
        t.addCell(a)
        t.addCell(Phrase("B"))
        t.addCell(Phrase("C"))
        // 现在行0完成，下一行只需填 col1 和 col2
        t.addCell(Phrase("D"))
        t.addCell(Phrase("E"))
        @Expect(t.rowCount, 2)
    }

    @TestCase
    func testRowspanCellCountInRow1(): Unit {
        // 行1中，col0 被 rowspan 占用，所以行1只有 2 个实际单元格
        let t = PdfPTable(3)
        let a = PdfPCell(Phrase("A"))
        a.setRowspan(2)
        t.addCell(a)
        t.addCell(Phrase("B"))
        t.addCell(Phrase("C"))
        t.addCell(Phrase("D"))
        t.addCell(Phrase("E"))
        let row1OptA = t.getRow(1)
        if (row1OptA.isSome()) {
            let row1 = row1OptA.getOrThrow()
            @Expect(row1.cellCount, 2)
        }
    }

    @TestCase
    func testRowspanColumnPositions(): Unit {
        // 行1: D 在 col1, E 在 col2（col0 被 A 的 rowspan 占用）
        let t = PdfPTable(3)
        let a = PdfPCell(Phrase("A"))
        a.setRowspan(2)
        t.addCell(a)
        t.addCell(Phrase("B"))
        t.addCell(Phrase("C"))
        t.addCell(Phrase("D"))
        t.addCell(Phrase("E"))
        let row1OptB = t.getRow(1)
        if (row1OptB.isSome()) {
            let row1 = row1OptB.getOrThrow()
            @Expect(row1.getColumnPosition(0), 1)
            @Expect(row1.getColumnPosition(1), 2)
        }
    }

    @TestCase
    func testMiddleColumnRowspan(): Unit {
        // 行0: [A, B(rowspan=2), C] → 行1: [D 在col0, E 在col2]
        let t = PdfPTable(3)
        t.addCell(Phrase("A"))
        let b = PdfPCell(Phrase("B"))
        b.setRowspan(2)
        t.addCell(b)
        t.addCell(Phrase("C"))
        t.addCell(Phrase("D"))
        t.addCell(Phrase("E"))
        @Expect(t.rowCount, 2)
        let row1OptC = t.getRow(1)
        if (row1OptC.isSome()) {
            let row1 = row1OptC.getOrThrow()
            @Expect(row1.cellCount, 2)
            @Expect(row1.getColumnPosition(0), 0)
            @Expect(row1.getColumnPosition(1), 2)
        }
    }

    @TestCase
    func testRowspan3SpansThreeRows(): Unit {
        let t = PdfPTable(2)
        let tall = PdfPCell(Phrase("Tall"))
        tall.setRowspan(3)
        t.addCell(tall)
        t.addCell(Phrase("R0"))
        t.addCell(Phrase("R1"))
        t.addCell(Phrase("R2"))
        @Expect(t.rowCount, 3)
        // 每行只有 1 个实际单元格（另一列被 rowspan 占用）
        let r1Opt = t.getRow(1)
        if (r1Opt.isSome()) {
            @Expect(r1Opt.getOrThrow().cellCount, 1)
        }
        let r2Opt = t.getRow(2)
        if (r2Opt.isSome()) {
            @Expect(r2Opt.getOrThrow().cellCount, 1)
        }
    }

    @TestCase
    func testColspanAndRowspan(): Unit {
        // 4列: [A(colspan=2,rowspan=2), B, C] 行0
        //       [D, E]                          行1 (col0,1 被 A 占用)
        let t = PdfPTable(4)
        let a = PdfPCell(Phrase("A"))
        a.setColspan(2)
        a.setRowspan(2)
        t.addCell(a)
        t.addCell(Phrase("B"))
        t.addCell(Phrase("C"))
        t.addCell(Phrase("D"))
        t.addCell(Phrase("E"))
        @Expect(t.rowCount, 2)
        let row1OptD = t.getRow(1)
        if (row1OptD.isSome()) {
            let row1 = row1OptD.getOrThrow()
            @Expect(row1.cellCount, 2)
            @Expect(row1.getColumnPosition(0), 2)
            @Expect(row1.getColumnPosition(1), 3)
        }
    }
}
