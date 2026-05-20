/**
 * PDF-CJ ColumnText 示例
 *
 * 演示三种场景：
 *   1. 单列排版  — 将一段长文本排入指定矩形区域
 *   2. 双列排版  — 同一文章分两列显示
 *   3. 跨列溢出  — go() 返回 NO_MORE_COLUMN 后切换到下一列继续排版
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.{PdfWriter, PdfContentByte, ColumnText}
import pdf_cj.text.{BaseFont, Font, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_COL: String = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_BASE_COL: BaseFont = BaseFont.createFont(NOTO_CJK_COL, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
let HELV_BASE_COL: BaseFont = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)

func cjkFont(size: Float32): Font { Font(CJK_BASE_COL, size) }
func helvFont(size: Float32): Font { Font(HELV_BASE_COL, size) }

// 长中文段落（用于测试换行和溢出）
let LONG_TEXT: String = "仓颉编程语言是华为开发的面向全场景智能应用的原生静态强类型语言，" +
    "设计目标是高效、安全、简洁。它支持函数式、面向对象和面向过程等多种编程范式，" +
    "提供了丰富的语言特性，包括代数数据类型、模式匹配、泛型、闭包等，" +
    "同时提供了完善的包管理与构建工具 cjpm，让开发者能够快速上手并构建复杂的应用程序。"

// ─────────────────────────────────────────────────────
// 示例1：单列排版
// ─────────────────────────────────────────────────────
public func column1_single(): Unit {
    try {
        println("示例1：单列排版...")
        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_column_single.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        // 页面标题
        document.add(Paragraph("ColumnText 单列示例", cjkFont(16.0)))

        let cb = writer.getDirectContent()
        let ct = ColumnText(cb)

        // 列区域：ury=668，留出 12pt ascent 空间，使文字视觉上不超出边框顶(680)
        ct.setSimpleColumn(80.0, 350.0, 515.0, 668.0)

        let para = Paragraph(LONG_TEXT, cjkFont(11.0))
        para.setLeading(18.0)
        para.setSpacingAfter(10.0)
        ct.addElement(para)

        // 再加一段英文段落
        let para2 = Paragraph(
            "Cangjie is a statically typed programming language developed by Huawei. " +
            "It supports multiple paradigms including functional, object-oriented, and procedural styles. " +
            "The language provides rich features like algebraic data types, pattern matching, generics, and closures.",
            helvFont(11.0)
        )
        para2.setLeading(16.0)
        ct.addElement(para2)

        let status = ct.go()
        if (status == ColumnText.NO_MORE_TEXT) {
            println("  所有内容已排完")
        } else {
            println("  列空间已满，尚有内容未排")
        }

        // 在列区域画边框以直观显示列边界
        cb.saveState()
        cb.setColorStroke(Color(180, 180, 200))
        cb.setLineWidth(0.5)
        cb.rectangle(80.0, 350.0, 435.0, 330.0)
        cb.stroke()
        cb.restoreState()

        document.close()
        file.close()
        println("✓ 成功创建: output/example_column_single.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────
// 示例2：双列排版
// ─────────────────────────────────────────────────────
public func column2_double(): Unit {
    try {
        println("示例2：双列排版...")
        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_column_double.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        document.add(Paragraph("ColumnText 双列示例", cjkFont(16.0)))

        let cb = writer.getDirectContent()

        // 左列：x=50~280，右列：x=295~525
        // colTop 为可视边框顶，实际文字起始 Y = colTop - 10 (留 ascent 空间)
        let colTop:    Float32 = 680.0
        let colTextTop: Float32 = 668.0   // 668 = 680 - 12，避免首行 ascent 超出边框
        let colBottom: Float32 = 100.0

        let text = LONG_TEXT + LONG_TEXT + LONG_TEXT + LONG_TEXT + LONG_TEXT + LONG_TEXT + LONG_TEXT + LONG_TEXT + LONG_TEXT + LONG_TEXT   // 加倍文本以确保需要两列

        // 左列
        let ctLeft = ColumnText(cb)
        ctLeft.setSimpleColumn(50.0, colBottom, 280.0, colTextTop)
        let paraLeft = Paragraph(text, cjkFont(10.0))
        paraLeft.setLeading(16.0)
        ctLeft.addElement(paraLeft)
        let leftStatus = ctLeft.go()

        // 若左列未排完，右列继续
        if (leftStatus == ColumnText.NO_MORE_COLUMN && ctLeft.hasMoreText()) {
            let ctRight = ColumnText(cb)
            ctRight.setSimpleColumn(300.0, colBottom, 545.0, colTextTop)
            // 将左列剩余元素转移到右列（重新添加相同内容的剩余段落）
            // 注：此处直接新建相同内容以演示双列效果
            let paraRight = Paragraph(
                "（右列续）" + LONG_TEXT,
                cjkFont(10.0)
            )
            paraRight.setLeading(16.0)
            ctRight.addElement(paraRight)
            ctRight.go()
        }

        // 画列分隔线
        cb.saveState()
        cb.setColorStroke(Color(200, 200, 200))
        cb.setLineWidth(0.5)
        cb.moveTo(290.0, colTop)
        cb.lineTo(290.0, colBottom)
        cb.stroke()
        cb.restoreState()

        document.close()
        file.close()
        println("✓ 成功创建: output/example_column_double.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────
// 示例3：跨列溢出（addSimpleColumn 接口）
// ─────────────────────────────────────────────────────
public func column3_overflow(): Unit {
    try {
        println("示例3：跨列溢出...")
        let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
        let file = File(Path("output/example_column_overflow.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        document.add(Paragraph("ColumnText 溢出处理示例", cjkFont(16.0)))

        let cb = writer.getDirectContent()
        let ct = ColumnText(cb)

        // 使用 addSimpleColumn (left, right, bottom, top) 接口
        // top=648，留 12pt ascent 空间（边框顶在 660）
        ct.addSimpleColumn(50.0, 280.0, 400.0, 648.0)

        // 添加多段文字以确保第一列溢出
        for (i in 1..5) {
            let p = Paragraph("第 ${i} 段：" + LONG_TEXT, cjkFont(10.0))
            p.setLeading(16.0)
            p.setSpacingAfter(8.0)
            ct.addElement(p)
        }

        let status1 = ct.go()
        println("  第一列状态: ${if (status1 == ColumnText.NO_MORE_COLUMN) { "NO_MORE_COLUMN" } else { "NO_MORE_TEXT" }}")

        // 第一列满后，切换到第二列继续
        if (status1 == ColumnText.NO_MORE_COLUMN) {
            ct.addSimpleColumn(300.0, 545.0, 400.0, 648.0)
            let status2 = ct.go()
            println("  第二列状态: ${if (status2 == ColumnText.NO_MORE_COLUMN) { "NO_MORE_COLUMN" } else { "NO_MORE_TEXT" }}")
        }

        // 画两列边框
        cb.saveState()
        cb.setColorStroke(Color(150, 150, 200))
        cb.setLineWidth(0.5)
        cb.rectangle(50.0, 400.0, 230.0, 260.0)
        cb.stroke()
        cb.rectangle(300.0, 400.0, 245.0, 260.0)
        cb.stroke()
        cb.restoreState()

        document.close()
        file.close()
        println("✓ 成功创建: output/example_column_overflow.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────
// 主函数
// ─────────────────────────────────────────────────────
main(): Int64 {
    println("=== PDF-CJ ColumnText 验证 ===\n")
    column1_single()
    column2_double()
    column3_overflow()
    println("\n=== 验证完成 ===")
    println("请检查 output/ 目录：")
    println("  example_column_single.pdf   - 单列排版")
    println("  example_column_double.pdf   - 双列排版")
    println("  example_column_overflow.pdf - 跨列溢出处理")
    0
}
