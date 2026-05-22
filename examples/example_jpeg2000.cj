/**
 * PDF-CJ JPEG2000 图片嵌入示例（Phase 5.2）
 *
 * 演示三种使用场景：
 *   1. JP2 容器格式（.jp2）嵌入
 *   2. J2K 裸码流格式（.j2k）嵌入
 *   3. 批量嵌入多格式图片对比
 *
 * 图片使用 JPXDecode 直接流内嵌（无需解压缩）。
 * 测试图片由 examples/images/ 中的 test_gray.jp2、test_rgb.jp2、
 * test_gray.j2k、test_rgb.j2k 提供。
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.image.{Image, Jp2Parser}
import pdf_cj.text.{BaseFont, Font, FontStyle}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_JP2 = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let BASE_FONT_JP2: BaseFont = BaseFont.createFont(NOTO_CJK_JP2, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)

func jpFont(size: Float32): Font { Font(BASE_FONT_JP2, size) }
func jpBold(size: Float32): Font { Font(BASE_FONT_JP2, size, FontStyle.Bold) }

// ─── 场景 1：JP2 容器格式 ────────────────────────────────────────────────────

public func exampleJp2Container(): Unit {
    println("\n场景 1：JP2 容器格式...")
    try {
        let doc = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_jp2_container.pdf"), OpenMode.Write)
        PdfWriter.getInstance(doc, file)
        doc.open()

        doc.add(Paragraph("JP2 容器格式嵌入", jpBold(16.0)))
        doc.add(Paragraph(" ", jpFont(6.0)))
        doc.add(Paragraph("JP2（JPEG 2000 Part 1）是完整容器格式，包含文件类型框、图片头框（jp2h）和码流框（jp2c）。", jpFont(11.0)))
        doc.add(Paragraph(" ", jpFont(8.0)))

        // 灰度 JP2（100×80）
        doc.add(Paragraph("灰度 JP2（100×80，DeviceGray）：", jpFont(12.0)))
        doc.add(Paragraph(" ", jpFont(4.0)))
        let grayImg = Image.getInstance("images/test_gray.jp2")
        grayImg.scaleAbsolute(100.0, 80.0)
        doc.add(grayImg)
        doc.add(Paragraph(" ", jpFont(4.0)))
        let grayMeta = if (let Some(data) <- grayImg.rawData) {
            match (Jp2Parser.parse(data)) {
                case Some(info) => "${info.width}×${info.height} px，${info.components} 通道，${info.bitsPerComponent} bpc，${info.colorSpace}"
                case None => "元数据解析失败"
            }
        } else { "无原始数据" }
        doc.add(Paragraph("  元数据：${grayMeta}", jpFont(10.0)))
        doc.add(Paragraph(" ", jpFont(8.0)))

        // RGB JP2（120×90）
        doc.add(Paragraph("RGB JP2（120×90，DeviceRGB）：", jpFont(12.0)))
        doc.add(Paragraph(" ", jpFont(4.0)))
        let rgbImg = Image.getInstance("images/test_rgb.jp2")
        rgbImg.scaleAbsolute(120.0, 90.0)
        doc.add(rgbImg)
        doc.add(Paragraph(" ", jpFont(4.0)))
        let rgbMeta = if (let Some(data) <- rgbImg.rawData) {
            match (Jp2Parser.parse(data)) {
                case Some(info) => "${info.width}×${info.height} px，${info.components} 通道，${info.bitsPerComponent} bpc，${info.colorSpace}"
                case None => "元数据解析失败"
            }
        } else { "无原始数据" }
        doc.add(Paragraph("  元数据：${rgbMeta}", jpFont(10.0)))

        doc.close()
        file.close()
        println("✓ 场景 1 完成 → output/example_jp2_container.pdf")
    } catch (e: Exception) {
        println("✗ 场景 1 错误: ${e.message}")
    }
}

// ─── 场景 2：J2K 裸码流格式 ──────────────────────────────────────────────────

public func exampleJ2kStream(): Unit {
    println("\n场景 2：J2K 裸码流格式...")
    try {
        let doc = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_j2k_stream.pdf"), OpenMode.Write)
        PdfWriter.getInstance(doc, file)
        doc.open()

        doc.add(Paragraph("J2K 裸码流格式嵌入", jpBold(16.0)))
        doc.add(Paragraph(" ", jpFont(6.0)))
        doc.add(Paragraph("J2K（JPEG 2000 codestream）是原始码流，以 SOC 标记（FF 4F）开头，直接包含 SIZ、COD 等标记段。", jpFont(11.0)))
        doc.add(Paragraph(" ", jpFont(8.0)))

        // 灰度 J2K
        doc.add(Paragraph("灰度 J2K（100×80，DeviceGray）：", jpFont(12.0)))
        doc.add(Paragraph(" ", jpFont(4.0)))
        let grayImg = Image.getInstance("images/test_gray.j2k")
        grayImg.scaleAbsolute(100.0, 80.0)
        doc.add(grayImg)
        doc.add(Paragraph(" ", jpFont(4.0)))
        let grayMeta = if (let Some(data) <- grayImg.rawData) {
            match (Jp2Parser.parse(data)) {
                case Some(info) => "${info.width}×${info.height} px，${info.components} 通道，${info.bitsPerComponent} bpc，${info.colorSpace}"
                case None => "元数据解析失败"
            }
        } else { "无原始数据" }
        doc.add(Paragraph("  元数据：${grayMeta}", jpFont(10.0)))
        doc.add(Paragraph(" ", jpFont(8.0)))

        // RGB J2K
        doc.add(Paragraph("RGB J2K（120×90，DeviceRGB）：", jpFont(12.0)))
        doc.add(Paragraph(" ", jpFont(4.0)))
        let rgbImg = Image.getInstance("images/test_rgb.j2k")
        rgbImg.scaleAbsolute(120.0, 90.0)
        doc.add(rgbImg)
        doc.add(Paragraph(" ", jpFont(4.0)))
        let rgbMeta = if (let Some(data) <- rgbImg.rawData) {
            match (Jp2Parser.parse(data)) {
                case Some(info) => "${info.width}×${info.height} px，${info.components} 通道，${info.bitsPerComponent} bpc，${info.colorSpace}"
                case None => "元数据解析失败"
            }
        } else { "无原始数据" }
        doc.add(Paragraph("  元数据：${rgbMeta}", jpFont(10.0)))

        doc.close()
        file.close()
        println("✓ 场景 2 完成 → output/example_j2k_stream.pdf")
    } catch (e: Exception) {
        println("✗ 场景 2 错误: ${e.message}")
    }
}

// ─── 场景 3：多格式图片批量嵌入 ─────────────────────────────────────────────

public func exampleJp2MultiFormat(): Unit {
    println("\n场景 3：多格式图片批量嵌入...")
    try {
        let doc = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_jp2_multi.pdf"), OpenMode.Write)
        PdfWriter.getInstance(doc, file)
        doc.open()

        doc.add(Paragraph("JPEG2000 多格式图片对比", jpBold(16.0)))
        doc.add(Paragraph(" ", jpFont(6.0)))
        doc.add(Paragraph("PDF-CJ 支持将 JP2 容器和 J2K 裸码流统一使用 JPXDecode 过滤器内嵌到 PDF，无需预解码。", jpFont(11.0)))
        doc.add(Paragraph(" ", jpFont(10.0)))

        // JP2 灰度
        doc.add(Paragraph("JP2 灰度（100×80 pt）：", jpFont(12.0)))
        doc.add(Paragraph(" ", jpFont(3.0)))
        let img1 = Image.getInstance("images/test_gray.jp2")
        img1.scaleAbsolute(100.0, 80.0)
        doc.add(img1)
        doc.add(Paragraph(" ", jpFont(8.0)))

        // JP2 RGB
        doc.add(Paragraph("JP2 RGB（120×90 pt）：", jpFont(12.0)))
        doc.add(Paragraph(" ", jpFont(3.0)))
        let img2 = Image.getInstance("images/test_rgb.jp2")
        img2.scaleAbsolute(120.0, 90.0)
        doc.add(img2)
        doc.add(Paragraph(" ", jpFont(8.0)))

        // J2K 灰度
        doc.add(Paragraph("J2K 灰度（100×80 pt）：", jpFont(12.0)))
        doc.add(Paragraph(" ", jpFont(3.0)))
        let img3 = Image.getInstance("images/test_gray.j2k")
        img3.scaleAbsolute(100.0, 80.0)
        doc.add(img3)
        doc.add(Paragraph(" ", jpFont(8.0)))

        // J2K RGB
        doc.add(Paragraph("J2K RGB（120×90 pt）：", jpFont(12.0)))
        doc.add(Paragraph(" ", jpFont(3.0)))
        let img4 = Image.getInstance("images/test_rgb.j2k")
        img4.scaleAbsolute(120.0, 90.0)
        doc.add(img4)
        doc.add(Paragraph(" ", jpFont(8.0)))

        doc.add(Paragraph(" ", jpFont(6.0)))
        doc.add(Paragraph("全部图片均使用 /Filter /JPXDecode 内嵌，由 PDF 阅读器在渲染时解码。", jpFont(10.0)))

        doc.close()
        file.close()
        println("✓ 场景 3 完成 → output/example_jp2_multi.pdf")
    } catch (e: Exception) {
        println("✗ 场景 3 错误: ${e.message}")
    }
}

// ─── 主函数 ─────────────────────────────────────────────────────────────────

main(): Int64 {
    println("=== PDF-CJ JPEG2000 图片示例 ===")

    exampleJp2Container()
    exampleJ2kStream()
    exampleJp2MultiFormat()

    println("\n=== 完成 ===")
    println("请检查 output/ 目录：")
    println("  example_jp2_container.pdf — JP2 容器格式（灰度 + RGB）")
    println("  example_j2k_stream.pdf    — J2K 裸码流格式（灰度 + RGB）")
    println("  example_jp2_multi.pdf     — 四种格式对比")
    0
}
