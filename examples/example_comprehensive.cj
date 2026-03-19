/**
 * PDF-CJ 综合示例
 * 展示库的所有核心功能
 */

import std.fs.*
import pdf_cj.*

main() {
    println("开始创建 PDF 文档...")

    // 1. 创建文档和输出流
    let output = File(Path("example_comprehensive.pdf"), OpenMode.Write)
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

    let introImagePara = Paragraph("PDF-CJ 支持 PNG 和 JPEG 格式的图片，下面展示不同格式和缩放方式。", normalFont)
    introImagePara.setSpacingAfter(20.0)
    document.add(introImagePara)

    // 计算可用页面宽度（A4 纸张宽度 595，减去左右边距各 50）
    let availableWidth = 595.0 - 50.0 - 50.0  // 495 points

    // 11.1 PNG 图片 - 山景
    let pngPara = Paragraph("11.1 PNG 格式图片 - 山景 (1280×720)", boldFont)
    pngPara.setSpacingAfter(10.0)
    document.add(pngPara)

    let pngDescPara = Paragraph("原始尺寸缩放至页面宽度的 80%", normalFont)
    pngDescPara.setSpacingAfter(5.0)
    document.add(pngDescPara)

    let mountainImage = Image.getInstance("images/mountain.png")
    mountainImage.scaleToFit(Float32(availableWidth * 0.8), 300.0)
    mountainImage.setAlignment(Alignment.Center)
    document.add(mountainImage)

    // 11.2 JPEG 图片 - 河流
    document.newPage()
    let jpegPara = Paragraph("11.2 JPG 格式图片 - 河流 (1920×1200)", boldFont)
    jpegPara.setSpacingAfter(10.0)
    document.add(jpegPara)

    let jpegDescPara = Paragraph("高分辨率照片，缩放至适合页面", normalFont)
    jpegDescPara.setSpacingAfter(5.0)
    document.add(jpegDescPara)

    let riverImage = Image.getInstance("images/river.jpg")
    riverImage.scaleToFit(Float32(availableWidth * 0.9), 400.0)
    riverImage.setAlignment(Alignment.Center)
    document.add(riverImage)

    // 11.3 JPEG 图片 - 节点图 (nodes)
    let nodesPara = Paragraph("11.3 JPEG 格式图片 - 节点图 (500×500)", boldFont)
    nodesPara.setSpacingBefore(20.0)
    nodesPara.setSpacingAfter(10.0)
    document.add(nodesPara)

    let nodesDescPara = Paragraph("正方形图片，展示网络节点关系", normalFont)
    nodesDescPara.setSpacingAfter(5.0)
    document.add(nodesDescPara)

    let nodesImage = Image.getInstance("images/nodes.jpeg")
    nodesImage.scaleToFit(300.0, 300.0)
    nodesImage.setAlignment(Alignment.Center)
    document.add(nodesImage)

    // 11.4 图片缩放对比
    document.newPage()
    let scalePara = Paragraph("11.4 图片缩放方式对比（使用 nodes.jpeg）", boldFont)
    scalePara.setSpacingAfter(15.0)
    document.add(scalePara)

    // 方式1：百分比缩放
    let scale1Para = Paragraph("方式 1：百分比缩放 (40%)", normalFont)
    document.add(scale1Para)
    let scaleImage1 = Image.getInstance("images/nodes.jpeg")
    scaleImage1.scalePercent(40.0)
    scaleImage1.setAlignment(Alignment.Center)
    document.add(scaleImage1)

    // 方式2：固定宽度
    let scale2Para = Paragraph("方式 2：固定宽度 (400×225)", normalFont)
    scale2Para.setSpacingBefore(15.0)
    document.add(scale2Para)
    let scaleImage2 = Image.getInstance("images/nodes.jpeg")
    scaleImage2.scaleAbsolute(400.0, 225.0)
    scaleImage2.setAlignment(Alignment.Center)
    document.add(scaleImage2)

    // 方式3：等比缩放至最大尺寸
    let scale3Para = Paragraph("方式 3：适应最大尺寸 (保持宽高比)", normalFont)
    scale3Para.setSpacingBefore(15.0)
    document.add(scale3Para)
    let scaleImage3 = Image.getInstance("images/nodes.jpeg")
    scaleImage3.scaleToFit(350.0, 200.0)
    scaleImage3.setAlignment(Alignment.Center)
    document.add(scaleImage3)

    // 11.4 图片对齐方式
    document.newPage()
    let alignPara = Paragraph("11.5 图片对齐方式", boldFont)
    alignPara.setSpacingAfter(15.0)
    document.add(alignPara)

    // 左对齐
    let leftAlignPara = Paragraph("左对齐：", normalFont)
    document.add(leftAlignPara)
    let leftImage = Image.getInstance("images/nodes.jpeg")
    leftImage.scalePercent(15.0)
    leftImage.setAlignment(Alignment.Left)
    document.add(leftImage)

    // 居中对齐
    let centerAlignPara = Paragraph("居中对齐：", normalFont)
    centerAlignPara.setSpacingBefore(10.0)
    document.add(centerAlignPara)
    let centerImage = Image.getInstance("images/nodes.jpeg")
    centerImage.scalePercent(15.0)
    centerImage.setAlignment(Alignment.Center)
    document.add(centerImage)

    // 右对齐
    let rightAlignPara = Paragraph("右对齐：", normalFont)
    rightAlignPara.setSpacingBefore(10.0)
    document.add(rightAlignPara)
    let rightImage = Image.getInstance("images/nodes.jpeg")
    rightImage.scalePercent(15.0)
    rightImage.setAlignment(Alignment.Right)
    document.add(rightImage)

    // 11.6 GIF 和 BMP 格式支持
    document.newPage()
    let gifBmpPara = Paragraph("11.6 GIF 和 BMP 格式支持", boldFont)
    gifBmpPara.setSpacingAfter(15.0)
    document.add(gifBmpPara)

    // GIF 图片
    let gifDescPara = Paragraph("GIF 格式（40x40 像素）：", normalFont)
    gifDescPara.setSpacingAfter(5.0)
    document.add(gifDescPara)
    let gifNote = Paragraph("注意：当前 GIF 支持适用于简单的静态 GIF，复杂动画 GIF 建议转换为 PNG", normalFont)
    gifNote.setSpacingAfter(10.0)
    document.add(gifNote)
    let gifImage = Image.getInstance("images/square.gif")
    gifImage.scalePercent(500.0)  // 放大到 200x200
    gifImage.setAlignment(Alignment.Center)
    document.add(gifImage)

    // BMP 图片
    let bmpPara = Paragraph("BMP 格式（448x448 像素，16位色深）：", normalFont)
    bmpPara.setSpacingBefore(20.0)
    bmpPara.setSpacingAfter(5.0)
    document.add(bmpPara)
    let bmpImage = Image.getInstance("images/guest.bmp")
    bmpImage.scalePercent(50.0)  // 缩小到 224x224
    bmpImage.setAlignment(Alignment.Center)
    document.add(bmpImage)

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
        ["图片支持", "✓ PNG/JPEG/GIF/BMP"],
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

    println("PDF 文档创建完成：example_comprehensive.pdf")
    println("✓ 已演示：文本、段落、表格、图片、编码、页眉页脚等功能")
}
