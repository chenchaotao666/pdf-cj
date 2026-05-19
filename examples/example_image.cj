/**
 * PDF-CJ 图片功能示例
 * 演示 PNG、JPEG、GIF、BMP 图片嵌入，以及缩放和对齐方式。
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.image.Image
import pdf_cj.text.{BaseFont, Font, FontStyle, Alignment}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_BASE_FONT: BaseFont = BaseFont.createFont(NOTO_CJK_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)

func cjkFont(size: Float32): Font { Font(CJK_BASE_FONT, size) }
func cjkBold(size: Float32): Font { Font(CJK_BASE_FONT, size, FontStyle.Bold) }

let AVAIL_W: Float32 = 495.0   // A4 宽度 - 左右各 50pt 边距

/**
 * 示例1：PNG 图片嵌入与缩放
 */
public func image1_png(): Unit {
    try {
        println("示例1：PNG 图片...")

        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_image_png.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        document.add(Paragraph("PNG 图片嵌入演示", cjkBold(16.0)))
        document.add(Paragraph(" ", cjkFont(6.0)))

        document.add(Paragraph("缩放至页宽 80%（mountain.png）：", cjkFont(12.0)))
        let img = Image.getInstance("images/mountain.png")
        img.scaleToFit(AVAIL_W * 0.8, 300.0)
        img.setAlignment(Alignment.Center)
        document.add(img)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_image_png.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例2：JPEG 图片嵌入与缩放
 */
public func image2_jpeg(): Unit {
    try {
        println("示例2：JPEG 图片...")

        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_image_jpeg.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        document.add(Paragraph("JPEG 图片嵌入演示", cjkBold(16.0)))
        document.add(Paragraph(" ", cjkFont(6.0)))

        document.add(Paragraph("缩放至页宽 90%（river.jpg）：", cjkFont(12.0)))
        let img = Image.getInstance("images/river.jpg")
        img.scaleToFit(AVAIL_W * 0.9, 400.0)
        img.setAlignment(Alignment.Center)
        document.add(img)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_image_jpeg.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例3：三种缩放方式对比
 */
public func image3_scale(): Unit {
    try {
        println("示例3：缩放方式对比...")

        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_image_scale.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        document.add(Paragraph("图片缩放方式对比（nodes.jpeg）", cjkBold(16.0)))
        document.add(Paragraph(" ", cjkFont(6.0)))

        document.add(Paragraph("① 百分比缩放 40%（scalePercent）：", cjkFont(12.0)))
        let img1 = Image.getInstance("images/nodes.jpeg")
        img1.scalePercent(40.0)
        img1.setAlignment(Alignment.Center)
        document.add(img1)

        document.add(Paragraph(" ", cjkFont(8.0)))
        document.add(Paragraph("② 固定尺寸 200×200（scaleAbsolute）：", cjkFont(12.0)))
        let img2 = Image.getInstance("images/nodes.jpeg")
        img2.scaleAbsolute(200.0, 200.0)
        img2.setAlignment(Alignment.Center)
        document.add(img2)

        document.add(Paragraph(" ", cjkFont(8.0)))
        document.add(Paragraph("③ 适配页宽 60% × 高度上限 150pt（scaleToFit）：", cjkFont(12.0)))
        let img3 = Image.getInstance("images/nodes.jpeg")
        img3.scaleToFit(AVAIL_W * 0.6, 150.0)
        img3.setAlignment(Alignment.Center)
        document.add(img3)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_image_scale.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例4：对齐方式
 */
public func image4_alignment(): Unit {
    try {
        println("示例4：对齐方式...")

        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_image_alignment.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        document.add(Paragraph("图片对齐方式（nodes.jpeg，15%）", cjkBold(16.0)))
        document.add(Paragraph(" ", cjkFont(6.0)))

        for ((label, align) in [
            ("左对齐（Alignment.Left）",   Alignment.Left),
            ("居中（Alignment.Center）",   Alignment.Center),
            ("右对齐（Alignment.Right）",  Alignment.Right)
        ]) {
            document.add(Paragraph(label + "：", cjkFont(12.0)))
            let img = Image.getInstance("images/nodes.jpeg")
            img.scalePercent(15.0)
            img.setAlignment(align)
            document.add(img)
            document.add(Paragraph(" ", cjkFont(8.0)))
        }

        document.close()
        file.close()
        println("✓ 成功创建: output/example_image_alignment.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例5：GIF 与 BMP 格式
 */
public func image5_gif_bmp(): Unit {
    try {
        println("示例5：GIF 与 BMP 格式...")

        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_image_gif_bmp.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        document.add(Paragraph("GIF 与 BMP 格式图片演示", cjkBold(16.0)))
        document.add(Paragraph(" ", cjkFont(6.0)))

        document.add(Paragraph("GIF（square.gif，500%）：", cjkFont(12.0)))
        let gifImg = Image.getInstance("images/square.gif")
        gifImg.scalePercent(100.0)
        gifImg.setAlignment(Alignment.Center)
        document.add(gifImg)

        document.add(Paragraph(" ", cjkFont(8.0)))
        document.add(Paragraph("GIF（cooking.gif，100%）：", cjkFont(12.0)))
        let gifImg2 = Image.getInstance("images/cooking.gif")
        gifImg2.scalePercent(100.0)
        gifImg2.setAlignment(Alignment.Center)
        document.add(gifImg2)

        document.add(Paragraph(" ", cjkFont(8.0)))
        document.add(Paragraph("BMP（guest.bmp，50%）：", cjkFont(12.0)))
        let bmpImg = Image.getInstance("images/guest.bmp")
        bmpImg.scalePercent(50.0)
        bmpImg.setAlignment(Alignment.Center)
        document.add(bmpImg)

        document.close()
        file.close()
        println("✓ 成功创建: output/example_image_gif_bmp.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 主函数
 */
main(): Int64 {
    println("=== PDF-CJ 图片功能验证 ===\n")

    image1_png()
    image2_jpeg()
    image3_scale()
    image4_alignment()
    image5_gif_bmp()

    println("\n=== 验证完成 ===")
    println("请检查 output/ 目录中的 PDF 文件")
    println("")
    println("验收清单:")
    println("  example_image_png.pdf       - PNG 图片嵌入与缩放")
    println("  example_image_jpeg.pdf      - JPEG 图片嵌入与缩放")
    println("  example_image_scale.pdf     - scalePercent / scaleAbsolute / scaleToFit 对比")
    println("  example_image_alignment.pdf - 左/居中/右对齐")
    println("  example_image_gif_bmp.pdf   - GIF 与 BMP 格式")
    0
}
