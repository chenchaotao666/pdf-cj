/**
 * PDF-CJ 透明度与渐变示例（Phase 5.3）
 *
 * 演示三种使用场景：
 *   1. PdfGState 透明度（fill alpha、stroke alpha、blend mode）
 *   2. PdfAxialShading 轴向（线性）渐变填充
 *   3. PdfRadialShading 径向渐变填充
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.{PdfWriter, PdfGState, BlendMode, PdfAxialShading, PdfRadialShading, PdfShadingPattern}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let NOTO_TG = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let BASE_FONT_TG: BaseFont = BaseFont.createFont(NOTO_TG, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)

func tgFont(size: Float32): Font { Font(BASE_FONT_TG, size) }
func tgBold(size: Float32): Font { Font(BASE_FONT_TG, size, FontStyle.Bold) }

// ─── 场景 1：透明度（PdfGState）────────────────────────────────────────────

public func exampleTransparency(): Unit {
    println("\n场景 1：透明度...")
    try {
        let doc = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_transparency.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        doc.add(Paragraph("透明度示例（PdfGState）", tgBold(16.0)))
        doc.add(Paragraph(" ", tgFont(6.0)))
        doc.add(Paragraph("使用 /ExtGState 的 /ca（填充透明度）控制矩形叠加效果：", tgFont(11.0)))
        doc.add(Paragraph(" ", tgFont(8.0)))

        let cb = writer.getDirectContent()

        // 底层：不透明红色矩形
        let baseY: Float32 = 560.0
        cb.saveState()
        cb.setColorFill(Color.RED)
        cb.rectangle(80.0, baseY, 200.0, 80.0)
        cb.fill()
        cb.restoreState()

        // 50% 透明蓝色矩形（与红色叠加）
        let gs50 = PdfGState()
        gs50.setFillAlpha(0.5)
        let gsName50 = writer.addGState(gs50)

        cb.saveState()
        cb.setExtGState(gsName50)
        cb.setColorFill(Color.BLUE)
        cb.rectangle(160.0, baseY, 200.0, 80.0)
        cb.fill()
        cb.restoreState()

        doc.add(Paragraph(" ", tgFont(60.0)))
        doc.add(Paragraph("  红色（不透明）+ 蓝色（50% 透明）→ 叠加区呈紫色", tgFont(10.0)))
        doc.add(Paragraph(" ", tgFont(12.0)))

        // 不同透明度的橙色矩形
        doc.add(Paragraph("填充透明度梯度（25% → 100%）：", tgFont(11.0)))
        doc.add(Paragraph(" ", tgFont(8.0)))

        let alphaY: Float32 = 440.0
        let alphas: Array<Float32> = [0.25, 0.50, 0.75, 1.00]
        var xi: Int64 = 0
        while (xi < 4) {
            let gs = PdfGState()
            gs.setFillAlpha(alphas[xi])
            let gn = writer.addGState(gs)
            cb.saveState()
            cb.setExtGState(gn)
            cb.setColorFill(Color(0u8, 100u8, 200u8))
            cb.rectangle(80.0 + Float32(xi) * 110.0, alphaY, 90.0, 60.0)
            cb.fill()
            cb.restoreState()
            xi += 1
        }
        doc.add(Paragraph(" ", tgFont(45.0)))
        doc.add(Paragraph("  透明度：25%    50%    75%    100%", tgFont(10.0)))
        doc.add(Paragraph(" ", tgFont(12.0)))

        // Multiply 混合模式
        doc.add(Paragraph("混合模式 Multiply（背景黄色 × 前景蓝色）：", tgFont(11.0)))
        doc.add(Paragraph(" ", tgFont(8.0)))

        let mulY: Float32 = 320.0
        // 底层黄色
        cb.saveState()
        cb.setColorFill(Color.YELLOW)
        cb.rectangle(80.0, mulY, 250.0, 60.0)
        cb.fill()
        cb.restoreState()

        // Multiply 混合蓝色
        let gsMul = PdfGState()
        gsMul.setBlendMode(BlendMode.MULTIPLY)
        let gsMulName = writer.addGState(gsMul)

        cb.saveState()
        cb.setExtGState(gsMulName)
        cb.setColorFill(Color.BLUE)
        cb.rectangle(160.0, mulY, 250.0, 60.0)
        cb.fill()
        cb.restoreState()

        doc.add(Paragraph(" ", tgFont(45.0)))
        doc.add(Paragraph("  黄色背景与蓝色前景（Multiply）→ 叠加区呈深绿色", tgFont(10.0)))

        doc.close()
        file.close()
        println("✓ 场景 1 完成 → output/example_transparency.pdf")
    } catch (e: Exception) {
        println("✗ 场景 1 错误: ${e.message}")
    }
}

// ─── 场景 2：轴向渐变（PdfAxialShading）────────────────────────────────────

public func exampleAxialGradient(): Unit {
    println("\n场景 2：轴向渐变...")
    try {
        let doc = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_axial_gradient.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        doc.add(Paragraph("轴向（线性）渐变示例", tgBold(16.0)))
        doc.add(Paragraph(" ", tgFont(6.0)))
        doc.add(Paragraph("使用 PdfAxialShading（ShadingType 2）+ ShadingPattern 实现渐变填充：", tgFont(11.0)))
        doc.add(Paragraph(" ", tgFont(8.0)))

        let cb = writer.getDirectContent()

        // ── 横向渐变：红→蓝 ───────────────────────────────────────────────
        doc.add(Paragraph("横向渐变（红→蓝）：", tgFont(12.0)))
        doc.add(Paragraph(" ", tgFont(4.0)))

        let hY: Float32 = 595.0
        let sh1 = PdfAxialShading(80.0, hY, Color.RED, 450.0, hY, Color.BLUE)
        let pat1 = PdfShadingPattern(sh1)
        let patName1 = writer.addShadingPattern(pat1)

        cb.saveState()
        cb.setColorFillPattern(patName1)
        cb.rectangle(80.0, hY - 10.0, 370.0, 70.0)
        cb.fill()
        cb.restoreState()

        doc.add(Paragraph(" ", tgFont(55.0)))
        doc.add(Paragraph(" ", tgFont(8.0)))

        // ── 纵向渐变：黄→绿 ───────────────────────────────────────────────
        doc.add(Paragraph("纵向渐变（黄→绿）：", tgFont(12.0)))
        doc.add(Paragraph(" ", tgFont(4.0)))

        let vTopY: Float32 = 490.0
        let vBotY: Float32 = 410.0
        let sh2 = PdfAxialShading(80.0, vTopY, Color.YELLOW, 80.0, vBotY, Color.GREEN)
        let pat2 = PdfShadingPattern(sh2)
        let patName2 = writer.addShadingPattern(pat2)

        cb.saveState()
        cb.setColorFillPattern(patName2)
        cb.rectangle(80.0, vBotY, 370.0, 80.0)
        cb.fill()
        cb.restoreState()

        doc.add(Paragraph(" ", tgFont(65.0)))
        doc.add(Paragraph(" ", tgFont(8.0)))

        // ── 斜向渐变：白→深蓝 ─────────────────────────────────────────────
        doc.add(Paragraph("斜向渐变（白→深蓝）：", tgFont(12.0)))
        doc.add(Paragraph(" ", tgFont(4.0)))

        let dY1: Float32 = 380.0
        let dY2: Float32 = 300.0
        let darkBlue = Color(0u8, 0u8, 128u8)
        let sh3 = PdfAxialShading(80.0, dY1, Color.WHITE, 450.0, dY2, darkBlue)
        let pat3 = PdfShadingPattern(sh3)
        let patName3 = writer.addShadingPattern(pat3)

        cb.saveState()
        cb.setColorFillPattern(patName3)
        cb.rectangle(80.0, dY2, 370.0, 80.0)
        cb.fill()
        cb.restoreState()

        doc.add(Paragraph(" ", tgFont(65.0)))
        doc.add(Paragraph(" ", tgFont(8.0)))

        // ── 直接渐变（sh 操作符，限裁剪区域）─────────────────────────────
        doc.add(Paragraph("直接渐变绘制（sh 操作符 + 矩形裁剪）：", tgFont(12.0)))
        doc.add(Paragraph(" ", tgFont(4.0)))

        let shY: Float32 = 270.0
        let shName = writer.addShading(
            PdfAxialShading(80.0, shY, Color.MAGENTA, 450.0, shY, Color.CYAN)
        )

        cb.saveState()
        cb.rectangle(80.0, shY - 40.0, 370.0, 80.0)
        cb.clip()
        cb.newPath()
        cb.paintShading(shName)
        cb.restoreState()

        doc.add(Paragraph(" ", tgFont(65.0)))

        doc.close()
        file.close()
        println("✓ 场景 2 完成 → output/example_axial_gradient.pdf")
    } catch (e: Exception) {
        println("✗ 场景 2 错误: ${e.message}")
    }
}

// ─── 场景 3：径向渐变（PdfRadialShading）────────────────────────────────────

public func exampleRadialGradient(): Unit {
    println("\n场景 3：径向渐变...")
    try {
        let doc = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_radial_gradient.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()

        doc.add(Paragraph("径向渐变示例", tgBold(16.0)))
        doc.add(Paragraph(" ", tgFont(6.0)))
        doc.add(Paragraph("使用 PdfRadialShading（ShadingType 3）实现从中心向外扩散的渐变：", tgFont(11.0)))
        doc.add(Paragraph(" ", tgFont(8.0)))

        let cb = writer.getDirectContent()

        // ── 圆形径向渐变：白→蓝 ─────────────────────────────────────────
        doc.add(Paragraph("从中心（白）向外（蓝）扩散：", tgFont(12.0)))
        doc.add(Paragraph(" ", tgFont(4.0)))

        let c1x: Float32 = 200.0; let c1y: Float32 = 580.0; let c1r: Float32 = 80.0
        let sh1 = PdfRadialShading(c1x, c1y, 0.0, Color.WHITE,
                                   c1x, c1y, c1r, Color.BLUE)
        let p1 = PdfShadingPattern(sh1)
        let pn1 = writer.addShadingPattern(p1)

        cb.saveState()
        cb.setColorFillPattern(pn1)
        // 用圆弧路径裁剪并填充
        let kappa: Float32 = 0.5523
        let r: Float32 = c1r
        cb.moveTo(c1x + r, c1y)
        cb.curveTo(c1x + r, c1y + r * kappa, c1x + r * kappa, c1y + r, c1x, c1y + r)
        cb.curveTo(c1x - r * kappa, c1y + r, c1x - r, c1y + r * kappa, c1x - r, c1y)
        cb.curveTo(c1x - r, c1y - r * kappa, c1x - r * kappa, c1y - r, c1x, c1y - r)
        cb.curveTo(c1x + r * kappa, c1y - r, c1x + r, c1y - r * kappa, c1x + r, c1y)
        cb.closePath()
        cb.fill()
        cb.restoreState()

        doc.add(Paragraph(" ", tgFont(120.0)))

        // ── 偏心径向渐变：红→透明（球形光晕效果）─────────────────────────
        doc.add(Paragraph("偏心径向渐变（光晕效果，小圆偏移至右上角）：", tgFont(12.0)))
        doc.add(Paragraph(" ", tgFont(4.0)))

        let c2x: Float32 = 265.0; let c2y: Float32 = 420.0; let c2r: Float32 = 90.0
        let sh2 = PdfRadialShading(
            c2x + 30.0, c2y + 30.0, 5.0, Color(255u8, 200u8, 50u8),  // 小圆偏右上
            c2x, c2y, c2r, Color(180u8, 60u8, 0u8)                     // 大圆
        )
        let p2 = PdfShadingPattern(sh2)
        let pn2 = writer.addShadingPattern(p2)

        cb.saveState()
        cb.setColorFillPattern(pn2)
        cb.moveTo(c2x + c2r, c2y)
        cb.curveTo(c2x + c2r, c2y + c2r * kappa, c2x + c2r * kappa, c2y + c2r, c2x, c2y + c2r)
        cb.curveTo(c2x - c2r * kappa, c2y + c2r, c2x - c2r, c2y + c2r * kappa, c2x - c2r, c2y)
        cb.curveTo(c2x - c2r, c2y - c2r * kappa, c2x - c2r * kappa, c2y - c2r, c2x, c2y - c2r)
        cb.curveTo(c2x + c2r * kappa, c2y - c2r, c2x + c2r, c2y - c2r * kappa, c2x + c2r, c2y)
        cb.closePath()
        cb.fill()
        cb.restoreState()

        doc.add(Paragraph(" ", tgFont(130.0)))

        // ── 矩形内的径向渐变 ─────────────────────────────────────────────
        doc.add(Paragraph("矩形内的径向渐变（中心绿→边缘黑）：", tgFont(12.0)))
        doc.add(Paragraph(" ", tgFont(4.0)))

        let c3x: Float32 = 265.0; let c3y: Float32 = 260.0
        let sh3 = PdfRadialShading(c3x, c3y, 0.0, Color.GREEN,
                                   c3x, c3y, 120.0, Color.BLACK)
        let shName3 = writer.addShading(sh3)

        cb.saveState()
        cb.rectangle(80.0, c3y - 60.0, 370.0, 120.0)
        cb.clip()
        cb.newPath()
        cb.paintShading(shName3)
        cb.restoreState()

        doc.add(Paragraph(" ", tgFont(95.0)))

        doc.close()
        file.close()
        println("✓ 场景 3 完成 → output/example_radial_gradient.pdf")
    } catch (e: Exception) {
        println("✗ 场景 3 错误: ${e.message}")
    }
}

// ─── 主函数 ─────────────────────────────────────────────────────────────────

main(): Int64 {
    println("=== PDF-CJ 透明度与渐变示例 ===")

    exampleTransparency()
    exampleAxialGradient()
    exampleRadialGradient()

    println("\n=== 完成 ===")
    println("请检查 output/ 目录：")
    println("  example_transparency.pdf     — fill alpha、stroke alpha、blend mode")
    println("  example_axial_gradient.pdf   — 轴向渐变（横/纵/斜/sh 操作符）")
    println("  example_radial_gradient.pdf  — 径向渐变（同心/偏心/矩形裁剪）")
    0
}
