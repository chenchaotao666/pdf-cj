/**
 * PDF-CJ 基本示例
 * 演示如何创建一个简单的 PDF 文档
 */
package pdf_cj_examples

import pdf_cj.api.*
import pdf_cj.core.PdfWriter
import pdf_cj.text.{BaseFont, Font}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"

// BaseFont 加载一次后复用，避免每次调用都把整个 TTC 文件（~20MB）读入内存
let CJK_BASE_FONT: BaseFont = BaseFont.createFont(NOTO_CJK_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)

func cjkFont(size: Float32): Font {
    Font(CJK_BASE_FONT, size)
}

/**
 * 示例1：创建基本 PDF
 */
public func example1_createBasicPdf(): Unit {
    try {
        println("示例1：创建基本 PDF...")

        // 创建文档
        let document = Document(PageSize.A4)

        // 创建输出文件
        let outputPath = Path("output/example_basic_hello.pdf")
        let file = File(outputPath, OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)

        // 打开文档
        document.open()

        let cnFont = cjkFont(12.0)

        // 添加段落
        try {
            println("添加第一个段落...")
            document.add(Paragraph("Hello, PDF-CJ!"))
            println("添加第二个段落...")
            document.add(Paragraph("这是一个用仓颉语言生成的 PDF 文档。", cnFont))
            println("添加第三个段落...")
            document.add(Paragraph("PDF-CJ 支持中文显示。", cnFont))
        } catch (e: Exception) {
            println("添加段落时出错: ${e}")
            throw e
        }

        // 关闭文档
        document.close()
        file.close()

        println("✓ 成功创建: output/example_basic_hello.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e}")
        println("✗ 消息: ${e.message}")
    }
}

/**
 * 示例2：使用不同字体
 */
public func example2_fonts(): Unit {
    try {
        println("\n示例2：字体示例...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_basic_fonts.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)

        document.open()

        // 使用不同字体大小
        document.add(Paragraph("标题文字", cjkFont(24.0)))
        document.add(Paragraph("正文文字", cjkFont(12.0)))
        document.add(Paragraph("小字文本", cjkFont(8.0)))

        document.close()
        file.close()

        println("✓ 成功创建: output/example_basic_fonts.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例3：添加多个页面
 */
public func example3_multiPages(): Unit {
    try {
        println("\n示例3：多页面文档...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_basic_pages.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)

        document.open()

        let cnFont = cjkFont(12.0)

        // 第一页
        document.add(Paragraph("第一页内容", cnFont))
        document.newPage()

        // 第二页
        document.add(Paragraph("第二页内容", cnFont))
        document.newPage()

        // 第三页
        document.add(Paragraph("第三页内容", cnFont))

        document.close()
        file.close()

        println("✓ 成功创建: output/example_basic_pages.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 主函数
 */
main(): Int64 {
    println("=== PDF-CJ 基本功能验证 ===\n")

    // 创建输出目录
    try {
        // 简化：假设目录已存在
    } catch (e: Exception) {
        println("注意: 请确保 output/ 目录存在")
    }

    // 运行示例
    example1_createBasicPdf()
    example2_fonts()
    example3_multiPages()

    println("\n=== 验证完成 ===")
    println("请检查 output/ 目录中的 PDF 文件")

    0
}
