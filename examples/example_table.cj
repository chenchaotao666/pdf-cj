/**
 * PDF-CJ 表格示例
 * 展示各种表格功能和样式
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase}
import pdf_cj.core.PdfWriter
import pdf_cj.table.{PdfPTable, PdfPCell}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment, VerticalAlignment}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_BASE_FONT: BaseFont = BaseFont.createFont(NOTO_CJK_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)

func cjkFont(size: Float32): Font { Font(CJK_BASE_FONT, size) }
func cjkBold(size: Float32): Font { Font(CJK_BASE_FONT, size, FontStyle.Bold) }

/**
 * 示例1：基础表格
 */
public func exampleTableBasic(): Unit {
    try {
        println("示例1：基础表格...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_table_basic.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.addTitle("PDF-CJ 基础表格")
        document.open()

        let titleFont = cjkBold(16.0)
        let tableFont = cjkFont(11.0)

        let title = Paragraph("基础表格演示", titleFont)
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        document.add(title)

        let table = PdfPTable(3)
        table.setWidthPercentage(80.0)
        table.setSpacingBefore(10.0)

        for (text in ["姓名", "年龄", "城市"]) {
            table.addCell(Phrase(text, tableFont))
        }
        for (text in ["张三", "25", "北京"]) {
            table.addCell(Phrase(text, tableFont))
        }
        for (text in ["李四", "30", "上海"]) {
            table.addCell(Phrase(text, tableFont))
        }
        for (text in ["王五", "28", "深圳"]) {
            table.addCell(Phrase(text, tableFont))
        }

        document.add(table)
        document.close()
        file.close()
        println("✓ 成功创建: output/example_table_basic.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例2：带样式的表格（表头、交替行色、合并列）
 */
public func exampleTableStyled(): Unit {
    try {
        println("示例2：带样式的表格...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_table_styled.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.addTitle("PDF-CJ 样式表格")
        document.open()

        let titleFont  = cjkBold(16.0)
        let headerFont = cjkBold(11.0)
        let dataFont   = cjkFont(10.0)

        let title = Paragraph("样式表格演示", titleFont)
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        document.add(title)

        let table = PdfPTable(4)
        table.setWidthPercentage(100.0)
        table.setSpacingBefore(10.0)
        table.setSpacingAfter(20.0)

        // 表头
        for (text in ["产品", "单价", "数量", "总价"]) {
            let cell = PdfPCell(Phrase(text, headerFont))
            cell.setHorizontalAlignment(Alignment.Center)
            cell.setBackgroundColor(Color(66, 139, 202))
            cell.setPadding(8.0)
            cell.setBorderWidth(2.0)
            table.addCell(cell)
        }

        // 数据行（交替底色）
        let products = [
            ["MacBook Pro", "¥12,999", "2", "¥25,998"],
            ["iPad Air",    "¥4,799",  "3", "¥14,397"],
            ["AirPods",     "¥1,299",  "5", "¥6,495"]
        ]
        var rowIdx: Int64 = 0
        for (row in products) {
            var colIdx: Int64 = 0
            for (text in row) {
                let cell = PdfPCell(Phrase(text, dataFont))
                cell.setPadding(6.0)
                cell.setHorizontalAlignment(if (colIdx == 0) { Alignment.Left } else { Alignment.Right })
                if (rowIdx % 2 == 1) {
                    cell.setBackgroundColor(Color(245, 245, 245))
                }
                table.addCell(cell)
                colIdx += 1
            }
            rowIdx += 1
        }

        // 合计行（跨3列）
        let totalLabel = PdfPCell(Phrase("合计", headerFont))
        totalLabel.setColspan(3)
        totalLabel.setHorizontalAlignment(Alignment.Right)
        totalLabel.setPadding(8.0)
        totalLabel.setBackgroundColor(Color(240, 240, 240))
        table.addCell(totalLabel)

        let totalValue = PdfPCell(Phrase("¥46,890", headerFont))
        totalValue.setHorizontalAlignment(Alignment.Right)
        totalValue.setPadding(8.0)
        totalValue.setBackgroundColor(Color(240, 240, 240))
        table.addCell(totalValue)

        document.add(table)
        document.close()
        file.close()
        println("✓ 成功创建: output/example_table_styled.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例3：跨列大标题表格
 */
public func exampleTableComplex(): Unit {
    try {
        println("示例3：跨列表格...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_table_complex.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.addTitle("PDF-CJ 跨列表格")
        document.open()

        let titleFont  = cjkBold(16.0)
        let headerFont = cjkBold(11.0)
        let dataFont   = cjkFont(10.0)

        let title = Paragraph("跨列表格演示", titleFont)
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        document.add(title)

        let table = PdfPTable(5)
        table.setWidthPercentage(100.0)
        table.setSpacingBefore(10.0)

        // 大标题跨 5 列
        let topCell = PdfPCell(Phrase("2024年度销售报表", cjkBold(14.0)))
        topCell.setColspan(5)
        topCell.setHorizontalAlignment(Alignment.Center)
        topCell.setBackgroundColor(Color(52, 152, 219))
        topCell.setPadding(12.0)
        table.addCell(topCell)

        // 表头行
        for (h in ["区域", "Q1", "Q2", "Q3", "Q4"]) {
            let cell = PdfPCell(Phrase(h, headerFont))
            cell.setHorizontalAlignment(Alignment.Center)
            cell.setBackgroundColor(Color(149, 165, 166))
            cell.setPadding(6.0)
            table.addCell(cell)
        }

        // 数据行
        let rows = [
            ["华北", "1,200", "1,350", "1,480", "1,600"],
            ["华东", "1,500", "1,620", "1,750", "1,850"],
            ["华南", "980",   "1,050", "1,180", "1,280"],
            ["西部", "750",   "820",   "900",   "980"]
        ]
        for (row in rows) {
            var ci: Int64 = 0
            for (text in row) {
                let cell = PdfPCell(Phrase(text, dataFont))
                cell.setPadding(5.0)
                cell.setHorizontalAlignment(if (ci == 0) { Alignment.Left } else { Alignment.Center })
                table.addCell(cell)
                ci += 1
            }
        }

        document.add(table)
        document.close()
        file.close()
        println("✓ 成功创建: output/example_table_complex.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例4：单元格内嵌多段落
 */
public func exampleTableNested(): Unit {
    try {
        println("示例4：嵌套内容表格...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_table_nested.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.addTitle("PDF-CJ 嵌套内容表格")
        document.open()

        let titleFont = cjkBold(16.0)
        let boldFont  = cjkBold(12.0)
        let dataFont  = cjkFont(11.0)

        let title = Paragraph("嵌套内容表格演示", titleFont)
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        document.add(title)

        let table = PdfPTable(2)
        table.setWidthPercentage(90.0)
        table.setSpacingBefore(10.0)

        // 左格：多段落
        let leftCell = PdfPCell()
        let lp1 = Paragraph("标题", boldFont)
        lp1.setSpacingAfter(5.0)
        leftCell.addElement(lp1)
        leftCell.addElement(Paragraph("这个单元格包含多个段落，展示表格单元格可以包含复杂的内容结构。", dataFont))
        leftCell.setPadding(10.0)
        leftCell.setVerticalAlignment(VerticalAlignment.Top)
        table.addCell(leftCell)

        // 右格：列表
        let rightCell = PdfPCell()
        let rp1 = Paragraph("特性列表", boldFont)
        rp1.setSpacingAfter(5.0)
        rightCell.addElement(rp1)
        for (item in ["支持多种字体", "灵活的布局", "丰富的样式", "易于使用"]) {
            let p = Paragraph("• " + item, dataFont)
            p.setSpacingAfter(3.0)
            rightCell.addElement(p)
        }
        rightCell.setPadding(10.0)
        rightCell.setBackgroundColor(Color(250, 250, 250))
        table.addCell(rightCell)

        document.add(table)

        let footer = Paragraph("表格示例完成", Font(CJK_BASE_FONT, 10.0, FontStyle.Italic))
        footer.setAlignment(Alignment.Center)
        footer.setSpacingBefore(30.0)
        document.add(footer)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_table_nested.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例5：跨行表格（rowspan）
 */
public func exampleTableRowspan(): Unit {
    try {
        println("示例5：跨行表格...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_table_rowspan.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.addTitle("PDF-CJ 跨行表格")
        document.open()

        let titleFont  = cjkBold(16.0)
        let headerFont = cjkBold(11.0)
        let dataFont   = cjkFont(10.0)

        let title = Paragraph("跨行表格演示（Rowspan + Colspan）", titleFont)
        title.setAlignment(Alignment.Center)
        title.setSpacingAfter(20.0)
        document.add(title)

        // 4 列：季度 | 华北 | 华东 | 华南
        let table = PdfPTable(4)
        table.setWidthPercentage(100.0)
        table.setSpacingBefore(10.0)

        // 大标题行（colspan=4）
        let topCell = PdfPCell(Phrase("2024年度区域销售报表", cjkBold(13.0)))
        topCell.setColspan(4)
        topCell.setHorizontalAlignment(Alignment.Center)
        topCell.setBackgroundColor(Color(52, 152, 219))
        topCell.setPadding(10.0)
        table.addCell(topCell)

        // 表头行
        for (h in ["季度", "华北", "华东", "华南"]) {
            let cell = PdfPCell(Phrase(h, headerFont))
            cell.setHorizontalAlignment(Alignment.Center)
            cell.setBackgroundColor(Color(189, 195, 199))
            cell.setPadding(6.0)
            table.addCell(cell)
        }

        // 上半年（rowspan=2 跨 Q1/Q2）
        let h1Cell = PdfPCell(Phrase("上半年", headerFont))
        h1Cell.setRowspan(2)
        h1Cell.setHorizontalAlignment(Alignment.Center)
        h1Cell.setVerticalAlignment(VerticalAlignment.Middle)
        h1Cell.setBackgroundColor(Color(236, 240, 241))
        h1Cell.setPadding(6.0)
        table.addCell(h1Cell)

        // Q1 数据
        for (v in ["1,200", "1,500", "980"]) {
            let cell = PdfPCell(Phrase(v, dataFont))
            cell.setHorizontalAlignment(Alignment.Center)
            cell.setPadding(5.0)
            table.addCell(cell)
        }
        // Q2 数据（紧接 rowspan 单元格后填充，col0 被占用）
        for (v in ["1,350", "1,620", "1,050"]) {
            let cell = PdfPCell(Phrase(v, dataFont))
            cell.setHorizontalAlignment(Alignment.Center)
            cell.setBackgroundColor(Color(249, 249, 249))
            cell.setPadding(5.0)
            table.addCell(cell)
        }

        // 下半年（rowspan=2 跨 Q3/Q4）
        let h2Cell = PdfPCell(Phrase("下半年", headerFont))
        h2Cell.setRowspan(2)
        h2Cell.setHorizontalAlignment(Alignment.Center)
        h2Cell.setVerticalAlignment(VerticalAlignment.Middle)
        h2Cell.setBackgroundColor(Color(236, 240, 241))
        h2Cell.setPadding(6.0)
        table.addCell(h2Cell)

        // Q3 数据
        for (v in ["1,480", "1,750", "1,180"]) {
            let cell = PdfPCell(Phrase(v, dataFont))
            cell.setHorizontalAlignment(Alignment.Center)
            cell.setPadding(5.0)
            table.addCell(cell)
        }
        // Q4 数据
        for (v in ["1,600", "1,850", "1,280"]) {
            let cell = PdfPCell(Phrase(v, dataFont))
            cell.setHorizontalAlignment(Alignment.Center)
            cell.setBackgroundColor(Color(249, 249, 249))
            cell.setPadding(5.0)
            table.addCell(cell)
        }

        // 年合计行（colspan=4）
        let totalCell = PdfPCell(Phrase("年合计：华北 5,630 | 华东 6,720 | 华南 4,490", headerFont))
        totalCell.setColspan(4)
        totalCell.setHorizontalAlignment(Alignment.Center)
        totalCell.setBackgroundColor(Color(236, 240, 241))
        totalCell.setPadding(8.0)
        table.addCell(totalCell)

        document.add(table)
        document.close()
        file.close()
        println("✓ 成功创建: output/example_table_rowspan.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 主函数
 */
main(): Int64 {
    println("=== PDF-CJ 表格功能验证 ===\n")

    exampleTableBasic()
    exampleTableStyled()
    exampleTableComplex()
    exampleTableNested()
    exampleTableRowspan()

    println("\n=== 验证完成 ===")
    println("请检查 output/ 目录中的 PDF 文件")
    0
}
