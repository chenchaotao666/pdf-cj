/**
 * PDF-CJ 图形绘制示例
 * 演示 PdfContentByte 图形算子：路径、形状、颜色、文本定位
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.text.{BaseFont, Font, Color}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_BASE_FONT: BaseFont = BaseFont.createFont(NOTO_CJK_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)

func cjkFont(size: Float32): Font { Font(CJK_BASE_FONT, size) }

/**
 * 示例1：直线、矩形、圆角矩形、椭圆、弧线
 */
public func drawing1_shapes(): Unit {
    try {
        println("示例1：基本形状绘制...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_drawing_shapes.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        document.add(Paragraph("基本形状演示", cjkFont(16.0)))

        let cb = writer.getDirectContent()
        let pageH = PageSize.A4.height

        // 直线（细黑 + 粗蓝）
        cb.saveState()
        cb.setLineWidth(1.0)
        cb.setColorStroke(Color.BLACK)
        cb.moveTo(50.0, pageH - 100.0)
        cb.lineTo(250.0, pageH - 100.0)
        cb.stroke()
        cb.setLineWidth(3.0)
        cb.setColorStroke(Color(0, 100, 200))
        cb.moveTo(50.0, pageH - 120.0)
        cb.lineTo(250.0, pageH - 120.0)
        cb.stroke()
        cb.restoreState()

        // 填充矩形
        cb.saveState()
        cb.setLineWidth(1.5)
        cb.setColorStroke(Color.BLACK)
        cb.setColorFill(Color(173, 216, 230))
        cb.rectangle(50.0, pageH - 220.0, 120.0, 60.0)
        cb.fillStroke()
        cb.restoreState()

        // 圆角矩形
        cb.saveState()
        cb.setLineWidth(1.5)
        cb.setColorStroke(Color(100, 0, 150))
        cb.setColorFill(Color(230, 200, 255))
        cb.roundRectangle(200.0, pageH - 220.0, 120.0, 60.0, 12.0)
        cb.fillStroke()
        cb.restoreState()

        // 椭圆
        cb.saveState()
        cb.setLineWidth(1.0)
        cb.setColorStroke(Color(200, 0, 0))
        cb.setColorFill(Color(255, 220, 220))
        cb.ellipse(350.0, pageH - 220.0, 530.0, pageH - 160.0)
        cb.fillStroke()
        cb.restoreState()

        // 180° 半圆弧（仅描边）
        cb.saveState()
        cb.setLineWidth(2.0)
        cb.setColorStroke(Color(0, 150, 0))
        cb.arc(50.0, pageH - 310.0, 150.0, pageH - 250.0, 0.0, 180.0)
        cb.stroke()
        cb.restoreState()

        // 贝塞尔曲线
        cb.saveState()
        cb.setLineWidth(1.5)
        cb.setColorStroke(Color(255, 128, 0))
        cb.moveTo(180.0, pageH - 310.0)
        cb.curveTo(220.0, pageH - 245.0, 280.0, pageH - 350.0, 320.0, pageH - 265.0)
        cb.stroke()
        cb.restoreState()

        document.close()
        file.close()
        println("✓ 成功创建: output/example_drawing_shapes.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例2：虚线样式
 */
public func drawing2_dash(): Unit {
    try {
        println("示例2：虚线样式...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_drawing_dash.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        document.add(Paragraph("虚线样式演示", cjkFont(16.0)))

        let cb = writer.getDirectContent()
        let pageH = PageSize.A4.height

        cb.saveState()
        cb.setColorStroke(Color.BLACK)
        cb.setLineWidth(1.5)

        // 实线
        cb.setLineDash(0.0)
        cb.moveTo(50.0, pageH - 120.0)
        cb.lineTo(400.0, pageH - 120.0)
        cb.stroke()

        // 等长虚线 6-3
        cb.setLineDash(6.0, 3.0, 0.0)
        cb.moveTo(50.0, pageH - 145.0)
        cb.lineTo(400.0, pageH - 145.0)
        cb.stroke()

        // 等长虚线 2-4
        cb.setLineDash(2.0, 4.0, 0.0)
        cb.moveTo(50.0, pageH - 170.0)
        cb.lineTo(400.0, pageH - 170.0)
        cb.stroke()

        // 自定义虚线 [3 1 1 1]（点划线）
        cb.setLineDash([3.0, 1.0, 1.0, 1.0], 0.0)
        cb.moveTo(50.0, pageH - 195.0)
        cb.lineTo(400.0, pageH - 195.0)
        cb.stroke()

        cb.restoreState()

        document.close()
        file.close()
        println("✓ 成功创建: output/example_drawing_dash.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例3：颜色（RGB / CMYK / 灰度）
 */
public func drawing3_colors(): Unit {
    try {
        println("示例3：颜色空间...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_drawing_colors.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        document.add(Paragraph("颜色空间演示（RGB / CMYK / 灰度）", cjkFont(16.0)))

        let cb = writer.getDirectContent()
        let pageH = PageSize.A4.height

        // RGB 色块
        cb.saveState()
        cb.setLineWidth(0.5)
        cb.setColorStroke(Color.BLACK)
        cb.setColorFill(Color(255, 0, 0))
        cb.rectangle(50.0, pageH - 160.0, 60.0, 40.0)
        cb.fillStroke()
        cb.setColorFill(Color(0, 200, 0))
        cb.rectangle(120.0, pageH - 160.0, 60.0, 40.0)
        cb.fillStroke()
        cb.setColorFill(Color(0, 0, 255))
        cb.rectangle(190.0, pageH - 160.0, 60.0, 40.0)
        cb.fillStroke()
        cb.restoreState()

        // CMYK 色块
        cb.saveState()
        cb.setLineWidth(0.5)
        cb.setColorStroke(Color.BLACK)
        cb.setCMYKColorFill(1.0, 0.0, 0.0, 0.0)
        cb.rectangle(50.0, pageH - 220.0, 60.0, 40.0)
        cb.fillStroke()
        cb.setCMYKColorFill(0.0, 1.0, 0.0, 0.0)
        cb.rectangle(120.0, pageH - 220.0, 60.0, 40.0)
        cb.fillStroke()
        cb.setCMYKColorFill(0.0, 0.0, 1.0, 0.0)
        cb.rectangle(190.0, pageH - 220.0, 60.0, 40.0)
        cb.fillStroke()
        cb.setCMYKColorFill(0.0, 0.0, 0.0, 1.0)
        cb.rectangle(260.0, pageH - 220.0, 60.0, 40.0)
        cb.fillStroke()
        cb.restoreState()

        // 灰度色阶（白→黑5级）
        cb.saveState()
        cb.setLineWidth(0.0)
        var i = 0
        while (i < 5) {
            cb.setGrayFill(Float32(4 - i) / 4.0)
            cb.rectangle(50.0 + Float32(i) * 60.0, pageH - 280.0, 55.0, 40.0)
            cb.fill()
            i += 1
        }
        cb.restoreState()

        document.close()
        file.close()
        println("✓ 成功创建: output/example_drawing_colors.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例4：裁剪路径（clip）
 */
public func drawing4_clip(): Unit {
    try {
        println("示例4：裁剪路径...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_drawing_clip.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        document.add(Paragraph("裁剪路径演示", cjkFont(16.0)))

        let cb = writer.getDirectContent()
        let pageH = PageSize.A4.height

        // 圆形裁剪区域内绘制对角线网格
        cb.saveState()
        cb.ellipse(100.0, pageH - 300.0, 300.0, pageH - 150.0)
        cb.clip()
        cb.newPath()
        cb.setLineWidth(6.0)
        cb.setColorStroke(Color(255, 80, 80))
        var li = 0
        while (li < 15) {
            let offset = Float32(li) * 25.0
            cb.moveTo(100.0, pageH - 300.0 + offset)
            cb.lineTo(100.0 + offset, pageH - 150.0)
            cb.stroke()
            li += 1
        }
        cb.restoreState()

        // 绘制裁剪边框（在裁剪区域外，不受影响）
        cb.saveState()
        cb.setLineWidth(1.0)
        cb.setColorStroke(Color(100, 100, 100))
        cb.ellipse(100.0, pageH - 300.0, 300.0, pageH - 150.0)
        cb.stroke()
        cb.restoreState()

        document.close()
        file.close()
        println("✓ 成功创建: output/example_drawing_clip.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例5：文本绝对定位（showTextAligned）
 */
public func drawing5_textAligned(): Unit {
    try {
        println("示例5：文本绝对定位...")

        let document = Document(PageSize.A4)
        let file = File(Path("output/example_drawing_text.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        document.add(Paragraph("文本绝对定位演示", cjkFont(16.0)))

        let cb = writer.getDirectContent()
        let pageH = PageSize.A4.height
        let helv = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)

        // 参考线
        cb.saveState()
        cb.setLineWidth(0.3)
        cb.setColorStroke(Color(200, 200, 200))
        cb.moveTo(50.0, pageH - 150.0)
        cb.lineTo(500.0, pageH - 150.0)
        cb.stroke()
        cb.moveTo(200.0, pageH - 100.0)
        cb.lineTo(200.0, pageH - 200.0)
        cb.stroke()
        cb.moveTo(350.0, pageH - 100.0)
        cb.lineTo(350.0, pageH - 200.0)
        cb.stroke()
        cb.restoreState()

        // 三种对齐
        cb.beginText()
        cb.setFontAndSize(helv, "F-Helv", 12.0)
        cb.setColorFill(Color.BLACK)
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT,   "LEFT (x=50)",   50.0,  pageH - 150.0, 0.0)
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER, "CENTER (x=200)", 200.0, pageH - 170.0, 0.0)
        cb.showTextAligned(PdfContentByte.ALIGN_RIGHT,  "RIGHT (x=350)",  350.0, pageH - 190.0, 0.0)
        cb.endText()

        // 旋转文字
        cb.beginText()
        cb.setFontAndSize(helv, "F-Helv", 11.0)
        cb.setColorFill(Color(100, 0, 200))
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "Rotated 30 deg", 400.0, pageH - 250.0, 30.0)
        cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "Rotated 90 deg", 450.0, pageH - 350.0, 90.0)
        cb.endText()

        // 字符间距 + 字间距
        cb.beginText()
        cb.setFontAndSize("F-Helv", 10.0)
        cb.setColorFill(Color.BLACK)
        cb.setCharacterSpacing(2.5)
        cb.setWordSpacing(10.0)
        cb.setTextMatrix(50.0, pageH - 420.0)
        cb.showText("Character and word spacing")
        cb.setCharacterSpacing(0.0)
        cb.setWordSpacing(0.0)
        cb.endText()

        document.close()
        file.close()
        println("✓ 成功创建: output/example_drawing_text.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 主函数
 */
main(): Int64 {
    println("=== PDF-CJ 图形绘制功能验证 ===\n")

    drawing1_shapes()
    drawing2_dash()
    drawing3_colors()
    drawing4_clip()
    drawing5_textAligned()

    println("\n=== 验证完成 ===")
    println("请用 Adobe Reader / Chrome 打开 output/ 下的 PDF 文件进行视觉确认")
    println("")
    println("验收清单:")
    println("  example_drawing_shapes.pdf  - 直线/矩形/圆角矩形/椭圆/弧线/贝塞尔曲线")
    println("  example_drawing_dash.pdf    - 实线、6-3虚线、2-4虚线、点划线")
    println("  example_drawing_colors.pdf  - RGB/CMYK/灰度色块")
    println("  example_drawing_clip.pdf    - 圆形裁剪区域内的对角线网格")
    println("  example_drawing_text.pdf    - 左/中/右对齐、旋转文字、字符/字间距")

    0
}
