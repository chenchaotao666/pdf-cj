package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.text.{Font, BaseFont, FontStyle}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let _s25_OUT = "output/"

// S25：预置 CMap 的命名 CJK 字体（不嵌入字形、依赖阅读器自带 CJK 字体，字宽来自打包的
// Adobe 度量），对标 OpenPDF 的 iText-Asian 方案。生成的 PDF 不含字体程序，体积极小。
func s25_cjkCMap(): Unit {
    println("S25: CJK Predefined CMap (non-embedded) Demo")
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s25_OUT + "cj_s25_cjk_cmap.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()
        let helvBf = newHelvBf()

        doc.add(Paragraph("S25: Predefined-CMap CJK fonts (non-embedded)", Font(helvBf, 16.0, FontStyle.Bold)))
        doc.add(Paragraph("No font file; only a named font + predefined CMap. Widths from bundled Adobe metrics.",
            Font(helvBf, 11.0)))

        // 中日韩四语，各用对应的命名字体与预定义 CMap
        let sc = BaseFont.createFontCJK("STSong-Light", "UniGB-UCS2-H")        // 简体 (Adobe-GB1)
        let tc = BaseFont.createFontCJK("MSung-Light", "UniCNS-UCS2-H")        // 繁体 (Adobe-CNS1)
        let jp = BaseFont.createFontCJK("KozMinPro-Regular", "UniJIS-UCS2-H")  // 日文 (Adobe-Japan1)
        let kr = BaseFont.createFontCJK("HYSMyeongJo-Medium", "UniKS-UCS2-H")  // 韩文 (Adobe-Korea1)

        doc.add(Paragraph("简体 STSong-Light / UniGB-UCS2-H: 你好，世界！ABC 123", Font(sc, 15.0)))
        doc.add(Paragraph("繁體 MSung-Light / UniCNS-UCS2-H: 妳好，世界！漢字測試", Font(tc, 15.0)))
        doc.add(Paragraph("日本語 KozMinPro-Regular / UniJIS-UCS2-H: こんにちは世界、漢字テスト", Font(jp, 15.0)))
        doc.add(Paragraph("한국어 HYSMyeongJo-Medium / UniKS-UCS2-H: 안녕하세요 세계 한자", Font(kr, 15.0)))

        doc.close()
        println("  S25 done: ${_s25_OUT}cj_s25_cjk_cmap.pdf （未嵌入字体，体积应很小）")
    } catch (e: Exception) {
        println("  ✗ S25: ${e.message}")
    }
}
