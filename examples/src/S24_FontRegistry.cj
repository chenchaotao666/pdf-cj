package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.text.{Font, BaseFont, FontFactory, FontStyle}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let _s24_OUT = "output/"

// S24：FontFactory.registerDirectories —— 扫描系统字体目录后「按字体名」加载（不给路径），
// 对标 OpenPDF 的 FontFactory.registerDirectories()。
func s24_fontRegistry(): Unit {
    println("S24: Font Registry (registerDirectories) Demo")
    try {
        let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path(_s24_OUT + "cj_s24_font_registry.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(doc, file)
        doc.open()
        let helvBf = newHelvBf()

        doc.add(Paragraph("S24: FontFactory.registerDirectories", Font(helvBf, 16.0, FontStyle.Bold)))
        doc.add(Paragraph("Scan system font directories, then load a font by NAME (no path needed).", Font(helvBf, 11.0)))

        // 扫描系统字体目录（Linux/macOS/Windows）
        FontFactory.registerDirectories()
        doc.add(Paragraph("Registered font names: ${FontFactory.getRegisteredFontCount()}", Font(helvBf, 11.0)))

        // 额外注册本示例打包的 CJK 字体，使按名命中与其它 section 相同的字体路径，
        // 从而复用已加载的字体程序（避免在「运行全部」时重复加载大字体）。
        FontFactory.register(resolveCjkFont())

        // 按字体名加载嵌入字体（命中第一个存在的候选名）
        let candidates = ["Noto Sans CJK SC", "Noto Sans CJK JP", "Noto Sans CJK KR",
                          "WenQuanYi Zen Hei", "WenQuanYi Micro Hei", "Source Han Sans SC"]
        var done = false
        for (name in candidates) {
            if (FontFactory.isRegistered(name)) {
                let bf = BaseFont.createFont(name, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
                doc.add(Paragraph("用字体名 '${name}' 加载（嵌入）：中文测试 你好，世界！Hello 123",
                    Font(bf, 16.0)))
                println("  按名解析: ${name} -> 已嵌入渲染")
                done = true
                break
            }
        }
        if (!done) {
            doc.add(Paragraph("(系统未注册到候选 CJK 字体名，跳过按名渲染)", Font(helvBf, 10.0)))
        }

        doc.close()
        println("  S24 done: ${_s24_OUT}cj_s24_font_registry.pdf")
    } catch (e: Exception) {
        println("  ✗ S24: ${e.message}")
    }
}
