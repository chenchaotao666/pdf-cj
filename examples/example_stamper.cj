/**
 * PDF-CJ PdfStamper 示例
 * 演示如何在现有 PDF 上叠加文字水印和修改文档元数据
 */
package pdf_cj_examples

import std.fs.{File, OpenMode, Path}
import std.collection.HashMap
import pdf_cj.api.Document
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.reader.{PdfReader, PdfStamper}
import pdf_cj.base.PdfFileOutputStream
import pdf_cj.util.PageSize

/**
 * 步骤1：创建源 PDF（供后续盖章用）
 */
func createSourcePdfForStamper(outputPath: String): Unit {
    let document = Document(PageSize.A4)
    let file = File(Path(outputPath), OpenMode.Write)
    let writer = PdfWriter.getInstance(document, file)
    document.open()

    let cb = writer.getDirectContent()
    cb.beginText()
    cb.setFontAndSize("Helvetica", 24.0)
    cb.setTextMatrix(100.0, 700.0)
    cb.showText("Original PDF Document")
    cb.endText()

    cb.beginText()
    cb.setFontAndSize("Helvetica", 12.0)
    cb.setTextMatrix(100.0, 650.0)
    cb.showText("This page will be stamped with additional content.")
    cb.endText()

    document.close()
    println("  源 PDF 已创建：${outputPath}")
}

/**
 * 步骤2：用 PdfStamper 在源 PDF 上叠加水印文字
 */
func stampPdf(sourcePath: String, outputPath: String): Unit {
    let reader = PdfReader(sourcePath)
    println("  源 PDF 页数：${reader.getNumberOfPages()}")

    let outFile = File(Path(outputPath), OpenMode.Write)
    let os = PdfFileOutputStream(outFile)
    let stamper = PdfStamper(reader, os)

    // 在第1页上层写"DRAFT"水印
    let over = stamper.getOverContent(1)
    over.saveState()
    over.setGrayFill(0.7)
    over.beginText()
    over.setFontAndSize("Helvetica-Bold", 60.0)
    over.showTextAligned(PdfContentByte.ALIGN_CENTER, "DRAFT", 297.0, 421.0, 45.0)
    over.endText()
    over.restoreState()

    // 在第1页下层写页脚
    let under = stamper.getUnderContent(1)
    under.beginText()
    under.setFontAndSize("Helvetica", 8.0)
    under.setTextMatrix(36.0, 20.0)
    under.showText("Confidential - Internal Use Only")
    under.endText()

    // 更新文档元数据
    let info = HashMap<String, String>()
    info["Title"] = "Stamped Document"
    info["Author"] = "PDF-CJ Stamper Example"
    info["Keywords"] = "draft, stamped, watermark"
    stamper.setMoreInfo(info)

    stamper.close()
    println("  已盖章的 PDF 已写入：${outputPath}")
}

main(): Int64 {
    println("=== PdfStamper 示例 ===")

    let sourcePath = "output/stamper_source.pdf"
    let outputPath = "output/stamper_output.pdf"

    try {
        println("步骤1：创建源 PDF...")
        createSourcePdfForStamper(sourcePath)

        println("步骤2：在源 PDF 上叠加水印...")
        stampPdf(sourcePath, outputPath)

        println("示例完成！输出文件：${outputPath}")
    } catch (e: Exception) {
        println("示例执行出错：${e.message}")
    }
    0
}
