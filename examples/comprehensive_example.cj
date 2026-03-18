/**
 * PDF-CJ 综合示例
 * 展示库的所有核心功能
 */

import std.fs.*
import pdf_cj.*

main() {
    println("开始创建 PDF 文档...")

    // 1. 创建文档和输出流
    let output = File(Path("comprehensive_demo.pdf"), OpenMode.Write)
    let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
    let writer = PdfWriter.getInstance(document, output)

    // 2. 设置文档元数据
    document.addTitle("PDF-CJ 综合功能演示")
    document.addAuthor("仓颉开发者")
    document.addSubject("展示 PDF-CJ 库的所有核心功能")
    document.addKeywords("PDF, 仓颉, 表格, 图片, 编码")
    document.addCreator("PDF-CJ Library")

    // 3. 创建中文字体（需要在设置页眉页脚之前创建）
    println("正在加载字体...")
    // 加载 Regular 字体
    let chineseBaseFont = BaseFont.createFont(
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        BaseFont.IDENTITY_H,
        BaseFont.EMBEDDED
    )
    println("✓ 字体加载成功")

    // 使用程序模拟粗体（fake bold），避免加载两个大字体导致内存溢出
    // 当使用 FontStyle.Bold 时，会自动通过重复绘制模拟粗体效果
    let chineseBoldBaseFont = chineseBaseFont

    // 4. 设置页眉和页脚
    // 使用中文字体避免乱码
    let headerFont = Font(chineseBaseFont, 10.0, FontStyle.Normal)
    let headerPhrase = Phrase("PDF-CJ 综合功能演示", headerFont)
    let header = HeaderFooter(headerPhrase, false)
    header.setAlignment(Alignment.Right)
    document.setHeader(header)

    let footerPhrase = Phrase("第 ", headerFont)
    let footer = HeaderFooter(footerPhrase, true)  // true 表示显示页码
    let afterPhrase = Phrase(" 页", headerFont)
    let footerWithPage = HeaderFooter(footerPhrase, true, afterPhrase)
    footerWithPage.setAlignment(Alignment.Center)
    document.setFooter(footerWithPage)

    // 打开文档
    document.open()
    println("文档已打开")

    // ===== 第一章：文本和段落 =====

    // 5. 创建标题
    let titleFont = Font(chineseBoldBaseFont, 24.0, FontStyle.Bold)
    let title = Paragraph("第一章：文本和段落功能", titleFont)
    title.setAlignment(Alignment.Center)
    title.setSpacingAfter(20.0)
    document.add(title)

    // 6. 添加不同样式的段落
    let normalFont = Font(chineseBaseFont, 12.0, FontStyle.Normal)
    let boldFont = Font(chineseBoldBaseFont, 12.0, FontStyle.Bold)
    let italicFont = Font(chineseBaseFont, 12.0, FontStyle.Italic)

    let para1 = Paragraph("这是一个普通段落，使用 Times Roman 字体。", normalFont)
    para1.setAlignment(Alignment.Left)
    para1.setSpacingAfter(10.0)
    document.add(para1)

    let para2 = Paragraph("这是一个粗体段落，展示粗体效果。", boldFont)
    para2.setAlignment(Alignment.Center)
    para2.setSpacingAfter(10.0)
    document.add(para2)

    let para3 = Paragraph("这是一个斜体段落，展示斜体效果。", italicFont)
    para3.setAlignment(Alignment.Right)
    para3.setSpacingAfter(20.0)
    document.add(para3)

    // 7. 使用 Chunk 和 Phrase 组合
    let mixedPara = Paragraph()
    mixedPara.add(Chunk("这个段落包含", normalFont))
    mixedPara.add(Chunk("混合样式", boldFont))
    mixedPara.add(Chunk("的文本，", normalFont))
    mixedPara.add(Chunk("非常灵活", italicFont))
    mixedPara.add(Chunk("！", normalFont))
    mixedPara.setSpacingAfter(20.0)
    document.add(mixedPara)

    // 8. 使用颜色
    let redFont = Font(chineseBoldBaseFont, 14.0, FontStyle.Bold)
    let redChunk = Chunk("这是红色文本", redFont)
    redChunk.setColor(Color.RED)  // 设置红色
    let colorPara = Paragraph()
    colorPara.add(redChunk)
    colorPara.setSpacingAfter(30.0)
    document.add(colorPara)

    // ===== 第二章：表格功能 =====

    document.newPage()

    let chapter2Title = Paragraph("第二章：表格功能", titleFont)
    chapter2Title.setAlignment(Alignment.Center)
    chapter2Title.setSpacingAfter(20.0)
    document.add(chapter2Title)

    // 9. 创建简单表格
    let simpleTable = PdfPTable(3)
    simpleTable.setWidthPercentage(100.0)
    simpleTable.setSpacingBefore(10.0)
    simpleTable.setSpacingAfter(20.0)

    // 添加表头
    let headerCellFont = Font(chineseBoldBaseFont, 12.0, FontStyle.Bold)
    for (text in ["产品", "数量", "价格"]) {
        let cell = PdfPCell(Phrase(text, headerCellFont))
        cell.setHorizontalAlignment(Alignment.Center)
        cell.setBackgroundColor(Color(200, 200, 200))  // 灰色背景
        cell.setPadding(5.0)
        simpleTable.addCell(cell)
    }

    // 添加数据行
    let dataFont = Font(chineseBaseFont, 11.0, FontStyle.Normal)
    let products = [
        ["苹果", "10", "¥50.00"],
        ["香蕉", "20", "¥30.00"],
        ["橙子", "15", "¥45.00"]
    ]

    for (row in products) {
        for (text in row) {
            let cell = PdfPCell(Phrase(text, dataFont))
            cell.setPadding(5.0)
            if (text == row[0]) {
                cell.setHorizontalAlignment(Alignment.Left)
            } else {
                cell.setHorizontalAlignment(Alignment.Right)
            }
            simpleTable.addCell(cell)
        }
    }

    document.add(simpleTable)

    // 10. 创建复杂表格（带跨行跨列）
    let complexTable = PdfPTable(4)
    complexTable.setWidthPercentage(100.0)
    complexTable.setSpacingBefore(20.0)
    complexTable.setSpacingAfter(20.0)

    // 跨列单元格
    let titleCell = PdfPCell(Phrase("销售报表", headerCellFont))
    titleCell.setColspan(4)
    titleCell.setHorizontalAlignment(Alignment.Center)
    titleCell.setBackgroundColor(Color(100, 150, 200))
    titleCell.setPadding(10.0)
    complexTable.addCell(titleCell)

    // 普通单元格
    for (header in ["区域", "Q1", "Q2", "Q3"]) {
        let cell = PdfPCell(Phrase(header, headerCellFont))
        cell.setHorizontalAlignment(Alignment.Center)
        cell.setBackgroundColor(Color(220, 220, 220))
        cell.setPadding(5.0)
        complexTable.addCell(cell)
    }

    // 数据
    let salesData = [
        ["北京", "100", "120", "150"],
        ["上海", "110", "130", "140"],
        ["广州", "90", "100", "110"]
    ]

    for (row in salesData) {
        for (text in row) {
            let cell = PdfPCell(Phrase(text, dataFont))
            cell.setPadding(5.0)
            cell.setHorizontalAlignment(Alignment.Center)
            complexTable.addCell(cell)
        }
    }

    document.add(complexTable)

    // ===== 第三章：图片功能 =====

    document.newPage()

    let chapter3Title = Paragraph("第三章：图片功能", titleFont)
    chapter3Title.setAlignment(Alignment.Center)
    chapter3Title.setSpacingAfter(20.0)
    document.add(chapter3Title)

    // 11. 插入图片（各种缩放方式）
    let imagePara = Paragraph("11.1 Debian Logo - 原始大小", normalFont)
    imagePara.setSpacingAfter(10.0)
    document.add(imagePara)

    println("正在加载图片...")
    let image1 = Image.getInstance("debian-logo.png")
    image1.setAlignment(Alignment.Center)
    document.add(image1)

    let imagePara2 = Paragraph("11.2 Debian Logo - 缩放到 50%", normalFont)
    imagePara2.setSpacingBefore(20.0)
    imagePara2.setSpacingAfter(10.0)
    document.add(imagePara2)

    let image2 = Image.getInstance("debian-logo.png")
    image2.scalePercent(50.0)
    image2.setAlignment(Alignment.Center)
    document.add(image2)

    let imagePara3 = Paragraph("11.3 Debian Logo - 固定 100x100 像素", normalFont)
    imagePara3.setSpacingBefore(20.0)
    imagePara3.setSpacingAfter(10.0)
    document.add(imagePara3)

    let image3 = Image.getInstance("debian-logo.png")
    image3.scaleAbsolute(100.0, 100.0)
    image3.setAlignment(Alignment.Center)
    document.add(image3)

    // ===== 第四章：编码功能 =====

    document.newPage()

    let chapter4Title = Paragraph("第四章：编码和压缩功能", titleFont)
    chapter4Title.setAlignment(Alignment.Center)
    chapter4Title.setSpacingAfter(20.0)
    document.add(chapter4Title)

    // 12. 演示编码功能
    let codecPara = Paragraph("PDF-CJ 支持多种编码和压缩算法：", normalFont)
    codecPara.setSpacingAfter(15.0)
    document.add(codecPara)

    // ASCII Hex 编码示例
    let originalData: Array<UInt8> = [
        UInt8(0x48), UInt8(0x65), UInt8(0x6C), UInt8(0x6C), UInt8(0x6F)  // "Hello"
    ]
    let hexEncoded = ASCIIHexEncoder.encode(originalData)

    let hexPara = Paragraph()
    hexPara.add(Chunk("ASCII Hex 编码：", boldFont))
    hexPara.add(Chunk(hexEncoded, normalFont))
    hexPara.setSpacingAfter(10.0)
    document.add(hexPara)

    // ASCII85 编码示例
    let ascii85Encoded = ASCII85Encoder.encode(originalData)

    let ascii85Para = Paragraph()
    ascii85Para.add(Chunk("ASCII85 编码：", boldFont))
    ascii85Para.add(Chunk(ascii85Encoded, normalFont))
    ascii85Para.setSpacingAfter(10.0)
    document.add(ascii85Para)

    // Flate 压缩示例
    let compressedData = FlateEncoder.encode(originalData)

    let flatePara = Paragraph()
    flatePara.add(Chunk("Flate 压缩：", boldFont))
    flatePara.add(Chunk("已压缩 (内部使用)", normalFont))
    flatePara.setSpacingAfter(30.0)
    document.add(flatePara)

    // ===== 第五章：高级功能 =====

    document.newPage()

    let chapter5Title = Paragraph("第五章：高级功能", titleFont)
    chapter5Title.setAlignment(Alignment.Center)
    chapter5Title.setSpacingAfter(20.0)
    document.add(chapter5Title)

    // 13. 使用 Chapter 和 Section
    let chapterObj = Chapter("自动章节编号", 1)
    let section1 = chapterObj.addSection("第一节")
    section1.add(Paragraph("这是第一节的内容。", normalFont))

    let section2 = chapterObj.addSection("第二节")
    section2.add(Paragraph("这是第二节的内容。", normalFont))

    // document.add(chapterObj)  // 注意：需要 PdfWriter 支持 Chapter

    // 14. 段落高级格式
    let advancedPara = Paragraph("这是一个高级格式段落，展示缩进和间距控制。", normalFont)
    advancedPara.setFirstLineIndent(20.0)
    advancedPara.setIndentationLeft(30.0)
    advancedPara.setIndentationRight(30.0)
    advancedPara.setSpacingBefore(20.0)
    advancedPara.setSpacingAfter(20.0)
    advancedPara.setLeading(18.0)
    document.add(advancedPara)

    // 15. 直接内容绘制（高级用户）
    let canvas = writer.getDirectContent()
    // canvas.beginText()
    // canvas.setFontAndSize("Helvetica", 12.0)
    // canvas.setTextMatrix(100.0, 700.0)
    // canvas.showText("直接绘制的文本")
    // canvas.endText()

    // ===== 总结页 =====

    document.newPage()

    let summaryTitle = Paragraph("功能总结", titleFont)
    summaryTitle.setAlignment(Alignment.Center)
    summaryTitle.setSpacingAfter(30.0)
    document.add(summaryTitle)

    let summaryTable = PdfPTable(2)
    summaryTable.setWidthPercentage(90.0)
    summaryTable.setHorizontalAlignment(Alignment.Center)

    let features = [
        ["文本处理", "✓ 多种字体和样式"],
        ["段落控制", "✓ 对齐、缩进、间距"],
        ["表格功能", "✓ 复杂布局、跨行列"],
        ["图片支持", "✓ 多格式、多种缩放"],
        ["编码压缩", "✓ Flate、Hex、Base85"],
        ["页面控制", "✓ 页眉页脚、分页"],
        ["颜色支持", "✓ RGB 颜色"],
        ["元数据", "✓ 标题、作者、关键词"]
    ]

    for (feature in features) {
        let nameCell = PdfPCell(Phrase(feature[0], boldFont))
        nameCell.setPadding(8.0)
        nameCell.setBackgroundColor(Color(240, 240, 240))
        summaryTable.addCell(nameCell)

        let valueCell = PdfPCell(Phrase(feature[1], normalFont))
        valueCell.setPadding(8.0)
        summaryTable.addCell(valueCell)
    }

    document.add(summaryTable)

    // 添加结束语
    let finalPara = Paragraph(
        "以上展示了 PDF-CJ 库的核心功能。更多高级用法请参考 API 文档。",
        italicFont
    )
    finalPara.setAlignment(Alignment.Center)
    finalPara.setSpacingBefore(30.0)
    document.add(finalPara)

    // 关闭文档
    document.close()
    output.close()

    println("PDF 文档创建完成：comprehensive_demo.pdf")
    println("✓ 已演示：文本、段落、表格、图片、编码、页眉页脚等功能")
}
