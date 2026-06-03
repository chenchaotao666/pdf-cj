/**
 * pdf-cj 示例入口（调度器）
 *
 * 用法：
 *   cjpm run                       # 运行全部 23 个 Section
 *   cjpm run --run-args "all"      # 运行全部
 *   cjpm run --run-args "7"        # 只运行 S07
 *   cjpm run --run-args "07"       # 同上
 *
 * 输出目录：output/   图片资源：images/
 */
package pdf_cj_examples

import std.convert.*
import std.fs.{Directory, exists}

func ensureOutputDir(): Unit {
    if (!exists("output")) {
        Directory.create("output", recursive: true)
    }
}

let SECTIONS: Array<(String, () -> Unit)> = [
    ("S01_DocumentPage",   { => s01_documentPage() }),
    ("S02_FontText",       { => s02_fontText() }),
    ("S03_Chunk",          { => s03_chunk() }),
    ("S04_Phrase",         { => s04_phrase() }),
    ("S05_Paragraph",      { => s05_paragraph() }),
    ("S06_Anchor",         { => s06_anchor() }),
    ("S07_Table",          { => s07_table() }),
    ("S08_Image",          { => s08_image() }),
    ("S09_Drawing",        { => s09_drawing() }),
    ("S10_PageEvent",      { => s10_pageEvent() }),
    ("S11_Bookmark",       { => s11_bookmark() }),
    ("S12_Annotation",     { => s12_annotation() }),
    ("S13_FormField",      { => s13_formField() }),
    ("S14_Transparency",   { => s14_transparency() }),
    ("S15_Shading",        { => s15_shading() }),
    ("S16_Barcode",        { => s16_barcode() }),
    ("S17_ReaderStamper",  { => s17_readerStamper() }),
    ("S18_PdfCopy",        { => s18_pdfCopy() }),
    ("S19_TextExtract",    { => s19_textExtract() }),
    ("S20_Security",       { => s20_security() }),
    ("S21_ColumnText",     { => s21_columnText() }),
    ("S22_Chapter",        { => s22_chapter() }),
    ("S23_Metadata",       { => s23_metadata() })
]

func runOne(name: String, run: () -> Unit): Bool {
    println("--- ${name} ---")
    try {
        run()
        println("  [OK] ${name}")
        println()
        return true
    } catch (e: Exception) {
        println("  [FAIL] ${name}: ${e.message}")
        println()
        return false
    }
}

func runAll(): Int64 {
    println("========================================")
    println("  运行所有 pdf-cj Section 示例")
    println("========================================")
    println()
    var passed: Int64 = 0
    var failed: Int64 = 0
    for ((name, run) in SECTIONS) {
        if (runOne(name, run)) { passed += 1 } else { failed += 1 }
    }
    println("========================================")
    println("  完成: ${passed} 成功, ${failed} 失败")
    println("  输出目录: output/")
    println("========================================")
    if (failed > 0) { 1 } else { 0 }
}

func printHelp(): Unit {
    println("""
用法: cjpm run --run-args "<参数>"

参数：
  (无)         运行全部 23 个 Section
  all          运行全部 23 个 Section
  1..23        只运行指定 Section（如 7 或 07）

示例：
  cjpm run --run-args "all"
  cjpm run --run-args "7"
""")
}

main(args: Array<String>): Int64 {
    let arg = if (args.size > 0) { args[0] } else { "all" }

    if (arg == "-h" || arg == "--help") {
        printHelp()
        return 0
    }

    ensureOutputDir()

    if (arg == "all" || arg == "") {
        return runAll()
    }

    // 解析 section 编号（支持前导零，如 "07"）
    let n = try {
        Int64.parse(arg)
    } catch (_: Exception) {
        println("无法识别的参数: ${arg}")
        printHelp()
        return 1
    }
    if (n < 1 || n > SECTIONS.size) {
        println("section 编号超出范围: ${n}（有效 1..${SECTIONS.size}）")
        return 1
    }
    let (name, run) = SECTIONS[n - 1]
    if (runOne(name, run)) { 0 } else { 1 }
}
