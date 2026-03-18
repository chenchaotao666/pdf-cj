/**
 * PDF-CJ 表格示例
 * 展示各种表格功能和样式
 */

import std.fs.*
import pdf_cj.*

main() {
    println("创建表格示例 PDF...")

    let output = File(Path("table_demo.pdf"), OpenMode.Write)
    let document = Document()
    let writer = PdfWriter.getInstance(document, output)

    document.addTitle("PDF-CJ 表格示例")
    document.open()

    // 创建中文字体（嵌入 NotoSansCJK）
    // 只使用一个字体文件以减少内存使用
    let chineseBaseFont = BaseFont.createFont(
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        BaseFont.IDENTITY_H,
        BaseFont.EMBEDDED
    )
    let chineseBoldBaseFont = chineseBaseFont  // 使用相同字体，通过 FontStyle 控制样式

    // 标题
    let titleFont = Font(chineseBoldBaseFont, 20.0, FontStyle.Bold)
    let title = Paragraph("表格功能演示", titleFont)
    title.setAlignment(Alignment.Center)
    title.setSpacingAfter(30.0)
    document.add(title)

    // ===== 示例 1: 简单表格 =====

    let subtitle1 = Paragraph("1. 基础表格", Font(chineseBoldBaseFont, 14.0, FontStyle.Bold))
    subtitle1.setSpacingBefore(20.0)
    subtitle1.setSpacingAfter(10.0)
    document.add(subtitle1)

    let simpleTable = PdfPTable(3)
    simpleTable.setWidthPercentage(80.0)

    // 创建表格字体
    let tableFont = Font(chineseBaseFont, 10.0, FontStyle.Normal)

    // 添加简单数据
    for (text in ["姓名", "年龄", "城市"]) {
        simpleTable.addCell(Phrase(text, tableFont))
    }

    for (text in ["张三", "25", "北京"]) {
        simpleTable.addCell(Phrase(text, tableFont))
    }

    for (text in ["李四", "30", "上海"]) {
        simpleTable.addCell(Phrase(text, tableFont))
    }
    
    document.add(simpleTable)

    // ===== 示例 2: 带样式的表格 =====

    let subtitle2 = Paragraph("2. 带样式的表格", Font(chineseBoldBaseFont, 14.0, FontStyle.Bold))
    subtitle2.setSpacingBefore(30.0)
    subtitle2.setSpacingAfter(10.0)
    document.add(subtitle2)

    let styledTable = PdfPTable(4)
    styledTable.setWidthPercentage(100.0)
    
    // 表头样式
    let headerFont = Font(chineseBoldBaseFont, 11.0, FontStyle.Bold)
    for (text in ["产品", "单价", "数量", "总价"]) {
        let cell = PdfPCell(Phrase(text, headerFont))
        cell.setHorizontalAlignment(Alignment.Center)
        cell.setBackgroundColor(Color(66, 139, 202))  // 蓝色背景
        cell.setPadding(8.0)
        cell.setBorderWidth(2.0)
        styledTable.addCell(cell)
    }
    
    // 数据行
    let dataFont = Font(chineseBaseFont, 10.0, FontStyle.Normal)
    let products = [
        ["MacBook Pro", "¥12,999", "2", "¥25,998"],
        ["iPad Air", "¥4,799", "3", "¥14,397"],
        ["AirPods", "¥1,299", "5", "¥6,495"]
    ]
    
    var rowIndex: Int64 = 0
    for (row in products) {
        var colIndex: Int64 = 0
        for (text in row) {
            let cell = PdfPCell(Phrase(text, dataFont))
            cell.setPadding(6.0)
            if (colIndex == 0) {
                cell.setHorizontalAlignment(Alignment.Left)
            } else {
                cell.setHorizontalAlignment(Alignment.Right)
            }
            // 交替行颜色
            if (rowIndex % 2 == 1) {
                cell.setBackgroundColor(Color(245, 245, 245))
            }
            styledTable.addCell(cell)
            colIndex = colIndex + 1
        }
        rowIndex = rowIndex + 1
    }
    
    // 合计行
    let totalCell = PdfPCell(Phrase("合计", Font(chineseBoldBaseFont, 11.0, FontStyle.Bold)))
    totalCell.setColspan(3)
    totalCell.setHorizontalAlignment(Alignment.Right)
    totalCell.setPadding(8.0)
    totalCell.setBackgroundColor(Color(240, 240, 240))
    styledTable.addCell(totalCell)
    
    let sumCell = PdfPCell(Phrase("¥46,890", Font(chineseBoldBaseFont, 11.0, FontStyle.Bold)))
    sumCell.setHorizontalAlignment(Alignment.Right)
    sumCell.setPadding(8.0)
    sumCell.setBackgroundColor(Color(240, 240, 240))
    styledTable.addCell(sumCell)
    
    document.add(styledTable)

    // ===== 示例 3: 跨行跨列表格 =====
    
    document.newPage()
    
    let subtitle3 = Paragraph("3. 跨行跨列表格", Font(chineseBoldBaseFont, 14.0, FontStyle.Bold))
    subtitle3.setSpacingAfter(10.0)
    document.add(subtitle3)

    let complexTable = PdfPTable(5)
    complexTable.setWidthPercentage(100.0)
    
    // 大标题（跨5列）
    let titleCell = PdfPCell(Phrase("2024年度销售报表", Font(chineseBoldBaseFont, 14.0, FontStyle.Bold)))
    titleCell.setColspan(5)
    titleCell.setHorizontalAlignment(Alignment.Center)
    titleCell.setBackgroundColor(Color(52, 152, 219))
    titleCell.setPadding(12.0)
    complexTable.addCell(titleCell)
    
    // 表头
    let headers = ["区域", "Q1", "Q2", "Q3", "Q4"]
    for (header in headers) {
        let cell = PdfPCell(Phrase(header, headerFont))
        cell.setHorizontalAlignment(Alignment.Center)
        cell.setBackgroundColor(Color(149, 165, 166))
        cell.setPadding(6.0)
        complexTable.addCell(cell)
    }
    
    // 数据（简化版，实际可以用跨行）
    let regions = [
        ["华北", "1200", "1350", "1480", "1600"],
        ["华东", "1500", "1620", "1750", "1850"],
        ["华南", "980", "1050", "1180", "1280"],
        ["西部", "750", "820", "900", "980"]
    ]
    
    for (row in regions) {
        var colIndex: Int64 = 0
        for (text in row) {
            let cell = PdfPCell(Phrase(text, dataFont))
            cell.setPadding(5.0)
            cell.setHorizontalAlignment(if (colIndex == 0) { Alignment.Left } else { Alignment.Center })
            complexTable.addCell(cell)
            colIndex = colIndex + 1
        }
    }
    
    document.add(complexTable)

    // ===== 示例 4: 嵌套内容表格 =====
    
    let subtitle4 = Paragraph("4. 包含复杂内容的表格", Font(chineseBoldBaseFont, 14.0, FontStyle.Bold))
    subtitle4.setSpacingBefore(30.0)
    subtitle4.setSpacingAfter(10.0)
    document.add(subtitle4)

    let nestedTable = PdfPTable(2)
    nestedTable.setWidthPercentage(90.0)
    
    // 左侧单元格 - 包含段落
    let leftCell = PdfPCell()
    let leftPara1 = Paragraph("标题", Font(chineseBoldBaseFont, 12.0, FontStyle.Bold))
    leftPara1.setSpacingAfter(5.0)
    leftCell.addElement(leftPara1)
    
    let leftPara2 = Paragraph("这个单元格包含多个段落，展示表格单元格可以包含复杂的内容结构。", dataFont)
    leftCell.addElement(leftPara2)
    leftCell.setPadding(10.0)
    leftCell.setVerticalAlignment(VerticalAlignment.Top)
    nestedTable.addCell(leftCell)
    
    // 右侧单元格 - 包含列表
    let rightCell = PdfPCell()
    let rightTitle = Paragraph("特性列表", Font(chineseBoldBaseFont, 12.0, FontStyle.Bold))
    rightTitle.setSpacingAfter(5.0)
    rightCell.addElement(rightTitle)
    
    for (item in ["支持多种字体", "灵活的布局", "丰富的样式", "易于使用"]) {
        let itemPara = Paragraph("• " + item, dataFont)
        itemPara.setSpacingAfter(3.0)
        rightCell.addElement(itemPara)
    }
    rightCell.setPadding(10.0)
    rightCell.setBackgroundColor(Color(250, 250, 250))
    nestedTable.addCell(rightCell)
    
    document.add(nestedTable)

    // 结束
    let footer = Paragraph("表格示例完成", Font(chineseBaseFont, 10.0, FontStyle.Italic))
    footer.setAlignment(Alignment.Center)
    footer.setSpacingBefore(40.0)
    document.add(footer)

    document.close()
    output.close()

    println("✓ 成功创建：table_demo.pdf")
    println("  演示了 4 种表格样式")
}
