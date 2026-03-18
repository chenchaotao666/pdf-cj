/**
 * PDF-CJ: 中文字体示例
 * 演示如何使用中文字体创建 PDF 文档
 */

import std.fs.*
import pdf_cj.*

main() {
    println("PDF-CJ: 中文字体示例")
    println("=" * 50)

    // 创建输出文件
    let outputPath = "chinese_example.pdf"
    let output = File(Path(outputPath), OpenMode.Write)

    // 创建文档
    let document = Document(PageSize.A4)

    // 创建 PdfWriter 并关联文档
    let writer = PdfWriter.getInstance(document, output)

    // 设置文档元数据
    document.addTitle("中文字体示例")
    document.addAuthor("PDF-CJ")
    document.addCreator("PDF-CJ Chinese Example")

    // 打开文档
    document.open()

    // 创建中文字体
    // 注意：需要指定系统中实际存在的中文字体文件路径
    // 常见路径：
    // - Linux: /usr/share/fonts/truetype/
    // - Windows: C:/Windows/Fonts/
    // - macOS: /System/Library/Fonts/

    // 使用 NotoSansCJK 字体文件（嵌入模式）
    // 这确保了中文能在任何系统上正确显示
    let chineseBaseFont = BaseFont.createFont(
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        BaseFont.IDENTITY_H,
        BaseFont.EMBEDDED
    )
    let titleFont = Font(chineseBaseFont, 18.0, FontStyle.Bold)
    let bodyFont = Font(chineseBaseFont, 12.0, FontStyle.Normal)

    // 添加标题
    let title = Paragraph("你好，PDF-CJ！", titleFont)
    title.setAlignment(Alignment.Center)
    title.setSpacingAfter(20.0)
    document.add(title)

    // 添加正文
    let body1 = Paragraph("这是使用 PDF-CJ 库创建的中文 PDF 文档示例。", bodyFont)
    body1.setSpacingAfter(10.0)
    document.add(body1)

    // 添加另一段
    let body2 = Paragraph("PDF-CJ 是用仓颉语言编写的原生 PDF 库，支持创建和编辑 PDF 文件。", bodyFont)
    body2.setSpacingAfter(10.0)
    document.add(body2)

    // 添加功能说明
    let body3 = Paragraph("主要特性包括：", bodyFont)
    body3.setSpacingAfter(5.0)
    document.add(body3)

    let feature1 = Paragraph("• 支持 Unicode 编码的中文字体", bodyFont)
    feature1.setIndentationLeft(20.0)
    document.add(feature1)

    let feature2 = Paragraph("• 支持 TrueType 和 OpenType 字体", bodyFont)
    feature2.setIndentationLeft(20.0)
    document.add(feature2)

    let feature3 = Paragraph("• 完整的文本、表格、图片支持", bodyFont)
    feature3.setIndentationLeft(20.0)
    document.add(feature3)

    // 关闭文档
    document.close()
    output.close()

    println("✓ PDF 创建成功: ${outputPath}")
    println("  文档包含中文内容和格式化文本")
    println("")
    println("注意事项：")
    println("  1. 如果出现乱码，请检查系统是否安装了 SimSun 字体")
    println("  2. 可以修改代码使用其他中文字体，如：")
    println("     - /usr/share/fonts/truetype/wqy/wqy-microhei.ttc (文泉驿微米黑)")
    println("     - /usr/share/fonts/truetype/arphic/uming.ttc (文鼎明体)")
    println("  3. 使用字体文件时，记得设置 IDENTITY_H 编码")
}
