/**
 * PDF-CJ PdfCopy / PdfSmartCopy 示例
 * 演示如何合并多个 PDF 文件，以及按页面范围选取页面
 */
package pdf_cj_examples

import std.fs.{File, OpenMode, Path}
import pdf_cj.api.Document
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.reader.{PdfReader, PdfCopy, PdfSmartCopy}
import pdf_cj.base.PdfFileOutputStream

// 创建一个单页源 PDF，在页面中写入指定文字
func createSourcePage(outputPath: String, text: String, pageLabel: String): Unit {
    let document = Document()
    let file = File(Path(outputPath), OpenMode.Write)
    let writer = PdfWriter.getInstance(document, file)
    document.open()

    let cb = writer.getDirectContent()
    cb.beginText()
    cb.setFontAndSize("Helvetica-Bold", 36.0)
    cb.setTextMatrix(100.0, 700.0)
    cb.showText(text)
    cb.endText()

    cb.beginText()
    cb.setFontAndSize("Helvetica", 14.0)
    cb.setTextMatrix(100.0, 650.0)
    cb.showText(pageLabel)
    cb.endText()

    document.close()
    println("  已创建：${outputPath}")
}

// 示例1：合并两个单页 PDF 为一个双页 PDF
func example_copy_merge(): Unit {
    println("\n--- 示例1：合并 PDF ---")

    createSourcePage("output/copy_src_a.pdf", "Document A", "Page 1 of source A")
    createSourcePage("output/copy_src_b.pdf", "Document B", "Page 1 of source B")

    let readerA = PdfReader("output/copy_src_a.pdf")
    let readerB = PdfReader("output/copy_src_b.pdf")

    let outFile = File(Path("output/copy_merged.pdf"), OpenMode.Write)
    let os = PdfFileOutputStream(outFile)
    let copy = PdfCopy(Document(), os)

    copy.addDocument(readerA)
    copy.addDocument(readerB)
    println("  合并页数：${copy.getPageCount()}")

    copy.close()
    println("  已生成：output/copy_merged.pdf")
    readerA.close()
    readerB.close()
}

// 示例2：按页面范围选取（从3页 PDF 中取第1、3页）
func example_copy_select_pages(): Unit {
    println("\n--- 示例2：按范围选取页面 ---")

    // 创建一个三页文档（分三次调用 PdfCopy 生成）
    let r1 = PdfReader("output/copy_src_a.pdf")
    let r2 = PdfReader("output/copy_src_b.pdf")
    let r3 = PdfReader("output/copy_src_a.pdf")  // 复用，第3页

    // 先合并成3页
    let tmpFile = File(Path("output/copy_three_pages.pdf"), OpenMode.Write)
    let tmpOs = PdfFileOutputStream(tmpFile)
    let tmp = PdfCopy(Document(), tmpOs)
    tmp.addDocument(r1)
    tmp.addDocument(r2)
    tmp.addDocument(r3)
    tmp.close()
    r1.close()
    r2.close()
    r3.close()

    // 从3页 PDF 中选取第1和第3页
    let src = PdfReader("output/copy_three_pages.pdf")
    let selFile = File(Path("output/copy_selected.pdf"), OpenMode.Write)
    let selOs = PdfFileOutputStream(selFile)
    let sel = PdfCopy(Document(), selOs)
    sel.selectPages(src, "2,3")
    println("  选取页数：${sel.getPageCount()}")
    sel.close()
    src.close()
    println("  已生成：output/copy_selected.pdf")
}

// 示例3：parseRanges 工具方法
func example_copy_parse_ranges(): Unit {
    println("\n--- 示例3：parseRanges ---")
    let pages = PdfCopy.parseRanges("1-3,5,7-9")
    var s = ""
    for (i in 0..pages.size) {
        if (i > 0) { s += ", " }
        s += "${pages[i]}"
    }
    println("  \"1-3,5,7-9\" → [${s}]")
}

// 示例4：PdfSmartCopy 去重合并（相同内容流只写一次）
func example_smart_copy(): Unit {
    println("\n--- 示例4：PdfSmartCopy 智能去重 ---")

    let ra = PdfReader("output/copy_src_a.pdf")
    let rb = PdfReader("output/copy_src_a.pdf")  // 与 ra 内容相同

    let smartFile = File(Path("output/copy_smart.pdf"), OpenMode.Write)
    let smartOs = PdfFileOutputStream(smartFile)
    let smart = PdfSmartCopy(Document(), smartOs)

    smart.addDocument(ra)
    smart.addDocument(rb)
    println("  合并页数：${smart.getPageCount()}")
    println("  去重后内容流数：${smart.getDedupedContentCount()} (相同内容只写一次)")

    smart.close()
    ra.close()
    rb.close()
    println("  已生成：output/copy_smart.pdf")
}

main(): Int64 {
    println("=== PdfCopy / PdfSmartCopy 示例 ===")

    try {
        example_copy_merge()
        example_copy_select_pages()
        example_copy_parse_ranges()
        example_smart_copy()
        println("\n示例全部完成！")
    } catch (e: Exception) {
        println("示例执行出错：${e.message}")
    }
    0
}
