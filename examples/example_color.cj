/**
 * PDF-CJ 颜色空间示例
 * 演示 RGB、CMYK、灰度三种颜色空间的填充与描边用法。
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.text.{BaseFont, Font, Color, CMYKColor, GrayColor}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_COLOR: String = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_COLOR: BaseFont  = BaseFont.createFont(NOTO_CJK_COLOR, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
let HELV_COLOR: BaseFont = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)

func label(cb: PdfContentByte, name: String, fontName: String, x: Float32, y: Float32): Unit {
    cb.setColorFill(Color(40, 40, 40))
    cb.beginText()
    cb.setFontAndSize(fontName, 9.0)
    cb.showTextAligned(PdfContentByte.ALIGN_LEFT, name, x, y, 0.0)
    cb.endText()
}

// ─────────────────────────────────────────────────────
// 示例1：RGB 颜色空间
// ─────────────────────────────────────────────────────
public func color1_rgb(): Unit {
    try {
        println("示例1：RGB 颜色空间...")
        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_color_rgb.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = Font(CJK_COLOR, 14.0)
        document.add(Paragraph("RGB 颜色空间示例", font))

        let cb = writer.getDirectContent()
        let fn = writer.addFont(HELV_COLOR)
        cb.saveState()

        let colors: Array<(Color, String)> = [
            (Color(220, 50,  50),  "Red   (220,50,50)"),
            (Color(50,  180, 50),  "Green (50,180,50)"),
            (Color(50,  100, 220), "Blue  (50,100,220)"),
            (Color(240, 160, 0),   "Orange (240,160,0)"),
            (Color(140, 60,  180), "Purple (140,60,180)"),
            (Color(0,   190, 190), "Cyan   (0,190,190)")
        ]

        let startX: Float32 = 50.0
        let startY: Float32 = 700.0
        let boxW:   Float32 = 80.0
        let boxH:   Float32 = 50.0
        let gap:    Float32 = 90.0

        for (i in 0..colors.size) {
            let (c, name) = colors[i]
            let x = startX + Float32(i) * gap
            cb.setColorFill(c)
            cb.setColorStroke(Color(60, 60, 60))
            cb.setLineWidth(0.5)
            cb.rectangle(x, startY, boxW, boxH)
            cb.fillStroke()
            label(cb, name, fn, x, startY - 14.0)
        }

        cb.restoreState()
        document.close()
        file.close()
        println("✓ 成功创建: output/example_color_rgb.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────
// 示例2：CMYK 颜色空间
// ─────────────────────────────────────────────────────
public func color2_cmyk(): Unit {
    try {
        println("示例2：CMYK 颜色空间...")
        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_color_cmyk.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = Font(CJK_COLOR, 14.0)
        document.add(Paragraph("CMYK 颜色空间示例", font))

        let cb = writer.getDirectContent()
        let fn = writer.addFont(HELV_COLOR)
        cb.saveState()

        let colors: Array<(CMYKColor, String)> = [
            (CMYKColor.CYAN,    "Cyan    (1,0,0,0)"),
            (CMYKColor.MAGENTA, "Magenta (0,1,0,0)"),
            (CMYKColor.YELLOW,  "Yellow  (0,0,1,0)"),
            (CMYKColor.BLACK,   "Black   (0,0,0,1)"),
            (CMYKColor(0.0, 0.5, 1.0, 0.0), "Orange  (0,.5,1,0)"),
            (CMYKColor(0.3, 0.0, 0.0, 0.2), "Sky     (.3,0,0,.2)")
        ]

        let startX: Float32 = 50.0
        let startY: Float32 = 700.0
        let boxW:   Float32 = 80.0
        let boxH:   Float32 = 50.0
        let gap:    Float32 = 90.0

        for (i in 0..colors.size) {
            let (c, name) = colors[i]
            let x = startX + Float32(i) * gap
            cb.setColorFill(c)
            cb.setColorStroke(GrayColor(0.3))
            cb.setLineWidth(0.5)
            cb.rectangle(x, startY, boxW, boxH)
            cb.fillStroke()
            label(cb, name, fn, x, startY - 14.0)
        }

        cb.restoreState()
        document.close()
        file.close()
        println("✓ 成功创建: output/example_color_cmyk.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────
// 示例3：灰度颜色空间
// ─────────────────────────────────────────────────────
public func color3_gray(): Unit {
    try {
        println("示例3：灰度颜色空间...")
        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_color_gray.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = Font(CJK_COLOR, 14.0)
        document.add(Paragraph("灰度颜色空间示例", font))

        let cb = writer.getDirectContent()
        let fn = writer.addFont(HELV_COLOR)
        cb.saveState()

        // 从黑到白的 6 级灰度梯度
        let levels: Array<Float32> = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
        let startX: Float32 = 50.0
        let startY: Float32 = 700.0
        let boxW:   Float32 = 80.0
        let boxH:   Float32 = 50.0
        let gap:    Float32 = 90.0

        for (i in 0..levels.size) {
            let g = levels[i]
            let x = startX + Float32(i) * gap
            cb.setColorFill(GrayColor(g))
            cb.setColorStroke(GrayColor(0.5))
            cb.setLineWidth(0.5)
            cb.rectangle(x, startY, boxW, boxH)
            cb.fillStroke()
            label(cb, "gray=${g}", fn, x, startY - 14.0)
        }

        // 用灰度描边：不同粗细的灰色线条
        let lineY: Float32 = 630.0
        let lineWidths: Array<Float32> = [0.5, 1.0, 2.0, 3.0, 5.0]
        let lineGrays:  Array<Float32> = [0.0, 0.25, 0.5, 0.75, 0.9]
        for (i in 0..lineWidths.size) {
            cb.setColorStroke(GrayColor(lineGrays[i]))
            cb.setLineWidth(lineWidths[i])
            cb.moveTo(50.0, lineY - Float32(i) * 18.0)
            cb.lineTo(495.0, lineY - Float32(i) * 18.0)
            cb.stroke()
            label(cb, "stroke gray=${lineGrays[i]} width=${lineWidths[i]}", fn,
                  50.0, lineY - Float32(i) * 18.0 + 3.0)
        }

        cb.restoreState()
        document.close()
        file.close()
        println("✓ 成功创建: output/example_color_gray.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────
// 示例4：混合颜色空间（同一页面使用三种颜色空间）
// ─────────────────────────────────────────────────────
public func color4_mixed(): Unit {
    try {
        println("示例4：混合颜色空间...")
        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_color_mixed.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let font = Font(CJK_COLOR, 14.0)
        document.add(Paragraph("混合颜色空间：同一页面使用 RGB / CMYK / Gray", font))

        let cb = writer.getDirectContent()
        let fn = writer.addFont(HELV_COLOR)
        cb.saveState()

        // RGB 填充的圆（用 ellipse 画正圆）
        cb.setColorFill(Color(220, 80, 80))
        cb.setColorStroke(Color(160, 0, 0))
        cb.setLineWidth(1.5)
        cb.ellipse(80.0, 640.0, 160.0, 720.0)
        cb.fillStroke()
        label(cb, "RGB fill", fn, 95.0, 628.0)

        // CMYK 填充的圆
        cb.setColorFill(CMYKColor(1.0, 0.0, 0.0, 0.0))
        cb.setColorStroke(CMYKColor(1.0, 0.0, 0.0, 0.3))
        cb.setLineWidth(1.5)
        cb.ellipse(220.0, 640.0, 300.0, 720.0)
        cb.fillStroke()
        label(cb, "CMYK fill", fn, 232.0, 628.0)

        // 灰度填充的圆
        cb.setColorFill(GrayColor(0.5))
        cb.setColorStroke(GrayColor(0.2))
        cb.setLineWidth(1.5)
        cb.ellipse(360.0, 640.0, 440.0, 720.0)
        cb.fillStroke()
        label(cb, "Gray fill", fn, 375.0, 628.0)

        // 同一行标注三种颜色空间的 PDF 算子
        cb.setColorFill(GrayColor(0.3))
        cb.beginText()
        cb.setFontAndSize(fn, 10.0)
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT,
            "RGB -> rg/RG    CMYK -> k/K    Gray -> g/G",
            50.0, 580.0, 0.0)
        cb.endText()

        cb.restoreState()
        document.close()
        file.close()
        println("✓ 成功创建: output/example_color_mixed.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────
// 主函数
// ─────────────────────────────────────────────────────
main(): Int64 {
    println("=== PDF-CJ 颜色扩展验证 ===\n")
    color1_rgb()
    color2_cmyk()
    color3_gray()
    color4_mixed()
    println("\n=== 验证完成 ===")
    println("请检查 output/ 目录：")
    println("  example_color_rgb.pdf   - RGB 色块")
    println("  example_color_cmyk.pdf  - CMYK 色块")
    println("  example_color_gray.pdf  - 灰度梯度 + 线条")
    println("  example_color_mixed.pdf - 三种颜色空间混用")
    0
}
