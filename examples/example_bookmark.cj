/**
 * PDF-CJ 书签示例
 * 演示 PdfOutline / PdfDestination：平铺书签、嵌套书签、带样式书签。
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.form.{PdfOutline, PdfOutlineTree, PdfDestination}
import pdf_cj.text.{BaseFont, Font, FontStyle}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let NOTO_CJK_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let CJK_BASE_BM: BaseFont = BaseFont.createFont(NOTO_CJK_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)

func cjkFont(size: Float32): Font { Font(CJK_BASE_BM, size) }
func cjkBold(size: Float32): Font { Font(CJK_BASE_BM, size, FontStyle.Bold) }

// ─────────────────────────────────────────────────────────────────────────────
// 示例1：平铺书签
//   每页对应一条根级书签，点击直接跳转到对应页。
// ─────────────────────────────────────────────────────────────────────────────

public func bookmark1_flat(): Unit {
    try {
        println("示例1：平铺书签...")

        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("output/example_bookmark_flat.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let titles = ["第一章  绪论", "第二章  核心特性", "第三章  类型系统", "第四章  并发模型"]
        let bodyFont = cjkFont(12.0)

        var i = 0
        while (i < titles.size) {
            // 记录当前页引用，再添加书签
            let pageRef = writer.getCurrentPageReference()
            let dest = PdfDestination(pageRef)
            writer.addOutline(titles[i], dest)

            document.add(Paragraph(titles[i], cjkBold(18.0)))
            var j = 0
            while (j < 6) {
                document.add(Paragraph(
                    "段落 ${j + 1}：仓颉语言是华为推出的面向全场景应用的通用编程语言。",
                    bodyFont))
                j += 1
            }
            i += 1
            if (i < titles.size) {
                document.newPage()
            }
        }

        document.close()
        file.close()
        println("✓ 成功创建: output/example_bookmark_flat.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 示例2：嵌套书签（两级层次）
//   章级书签展开后显示小节书签。
// ─────────────────────────────────────────────────────────────────────────────

public func bookmark2_nested(): Unit {
    try {
        println("示例2：嵌套书签...")

        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("output/example_bookmark_nested.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let bodyFont = cjkFont(12.0)

        // 第一章
        let ch1Ref = writer.getCurrentPageReference()
        let ch1 = writer.addOutline("第一章  仓颉简介", PdfDestination(ch1Ref))

        document.add(Paragraph("第一章  仓颉简介", cjkBold(18.0)))
        document.add(Paragraph("1.1  背景", cjkBold(14.0)))
        let sec11Ref = writer.getCurrentPageReference()
        ch1.addChild(PdfOutline("1.1  背景", PdfDestination(sec11Ref)))
        document.add(Paragraph("仓颉是华为发布的新一代编程语言，面向全场景智能终端。", bodyFont))

        document.add(Paragraph("1.2  设计目标", cjkBold(14.0)))
        let sec12Ref = writer.getCurrentPageReference()
        ch1.addChild(PdfOutline("1.2  设计目标", PdfDestination(sec12Ref)))
        document.add(Paragraph("目标是让开发者用更少的代码实现更强的功能。", bodyFont))

        document.newPage()

        // 第二章
        let ch2Ref = writer.getCurrentPageReference()
        let ch2 = writer.addOutline("第二章  类型系统", PdfDestination(ch2Ref))

        document.add(Paragraph("第二章  类型系统", cjkBold(18.0)))
        document.add(Paragraph("2.1  静态强类型", cjkBold(14.0)))
        let sec21Ref = writer.getCurrentPageReference()
        ch2.addChild(PdfOutline("2.1  静态强类型", PdfDestination(sec21Ref)))
        document.add(Paragraph("仓颉采用静态强类型，在编译期捕获类型错误。", bodyFont))

        document.add(Paragraph("2.2  类型推断", cjkBold(14.0)))
        let sec22Ref = writer.getCurrentPageReference()
        ch2.addChild(PdfOutline("2.2  类型推断", PdfDestination(sec22Ref)))
        document.add(Paragraph("编译器可从上下文推断变量类型，减少冗余声明。", bodyFont))

        document.add(Paragraph("2.3  泛型", cjkBold(14.0)))
        let sec23Ref = writer.getCurrentPageReference()
        ch2.addChild(PdfOutline("2.3  泛型", PdfDestination(sec23Ref)))
        document.add(Paragraph("支持泛型类、泛型函数以及带约束的泛型。", bodyFont))

        document.close()
        file.close()
        println("✓ 成功创建: output/example_bookmark_nested.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 示例3：带样式书签（粗体、斜体、彩色）
// ─────────────────────────────────────────────────────────────────────────────

public func bookmark3_styled(): Unit {
    try {
        println("示例3：带样式书签...")

        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("output/example_bookmark_styled.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()

        let bodyFont = cjkFont(12.0)

        // 普通书签
        let ref1 = writer.getCurrentPageReference()
        writer.addOutline("普通书签（默认样式）", PdfDestination(ref1))
        document.add(Paragraph("第一页：普通书签", cjkBold(16.0)))
        document.add(Paragraph("普通样式，无特殊修饰。", bodyFont))
        document.newPage()

        // 粗体书签
        let ref2 = writer.getCurrentPageReference()
        let boldBm = PdfOutline("粗体书签（Bold）", PdfDestination(ref2))
        boldBm.setBold(true)
        getOutlineTree(writer).addOutline(boldBm)
        document.add(Paragraph("第二页：粗体书签", cjkBold(16.0)))
        document.add(Paragraph("书签标题在导航面板中以粗体显示。", bodyFont))
        document.newPage()

        // 斜体书签
        let ref3 = writer.getCurrentPageReference()
        let italicBm = PdfOutline("斜体书签（Italic）", PdfDestination(ref3))
        italicBm.setItalic(true)
        getOutlineTree(writer).addOutline(italicBm)
        document.add(Paragraph("第三页：斜体书签", cjkBold(16.0)))
        document.add(Paragraph("书签标题在导航面板中以斜体显示。", bodyFont))
        document.newPage()

        // 彩色书签（红色）
        let ref4 = writer.getCurrentPageReference()
        let colorBm = PdfOutline("彩色书签（红色）", PdfDestination(ref4))
        colorBm.setColor(0.8, 0.0, 0.0)
        getOutlineTree(writer).addOutline(colorBm)
        document.add(Paragraph("第四页：红色书签", cjkBold(16.0)))
        document.add(Paragraph("书签标题在导航面板中以红色显示。", bodyFont))
        document.newPage()

        // 粗体 + 彩色书签（蓝色）
        let ref5 = writer.getCurrentPageReference()
        let comboOm = PdfOutline("粗体蓝色书签", PdfDestination(ref5))
        comboOm.setBold(true)
        comboOm.setColor(0.0, 0.2, 0.8)
        getOutlineTree(writer).addOutline(comboOm)
        document.add(Paragraph("第五页：粗体蓝色书签", cjkBold(16.0)))
        document.add(Paragraph("粗体 + 彩色组合样式。", bodyFont))

        document.close()
        file.close()
        println("✓ 成功创建: output/example_bookmark_styled.pdf")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

// 避免重复调用 getOutlineTree 的小帮手
func getOutlineTree(writer: PdfWriter): PdfOutlineTree {
    writer.getOutlineTree()
}

// ─────────────────────────────────────────────────────────────────────────────
// 主函数
// ─────────────────────────────────────────────────────────────────────────────

main(): Int64 {
    println("=== PDF-CJ 书签功能验证 ===\n")

    bookmark1_flat()
    bookmark2_nested()
    bookmark3_styled()

    println("\n=== 验证完成 ===")
    println("请在 PDF 阅读器中打开以下文件并查看左侧书签面板:")
    println("  output/example_bookmark_flat.pdf   - 平铺书签（4章）")
    println("  output/example_bookmark_nested.pdf - 两级嵌套书签")
    println("  output/example_bookmark_styled.pdf - 粗体/斜体/彩色书签")
    0
}
