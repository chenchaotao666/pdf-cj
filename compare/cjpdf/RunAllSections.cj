package pdf_cj_examples

main(): Int64 {
    println("========================================")
    println("  运行所有 pdf-cj Section 示例")
    println("========================================")
    println()

    let sections: Array<(String, () -> Unit)> = [
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

    var passed: Int64 = 0
    var failed: Int64 = 0

    for ((name, run) in sections) {
        println("--- ${name} ---")
        try {
            run()
            println("  [OK] ${name}")
            passed += 1
        } catch (e: Exception) {
            println("  [FAIL] ${name}: ${e.message}")
            failed += 1
        }
        println()
    }

    println("========================================")
    println("  完成: ${passed} 成功, ${failed} 失败")
    println("  输出目录: output/")
    println("========================================")
    0
}
