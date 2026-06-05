/**
 * RunAllSections — OpenPDF 对照示例统一入口（调度器）。
 *
 * 用法（Fat JAR 的 Main-Class，故用 java -jar 传参）:
 *   java -jar target/pdf-compare-1.0-SNAPSHOT-jar-with-dependencies.jar         # 运行全部
 *   java -jar target/pdf-compare-1.0-SNAPSHOT-jar-with-dependencies.jar all     # 运行全部
 *   java -jar target/pdf-compare-1.0-SNAPSHOT-jar-with-dependencies.jar 7       # 只运行 S07
 *   java -jar target/pdf-compare-1.0-SNAPSHOT-jar-with-dependencies.jar 07      # 同上
 */
public class RunAllSections {

    @FunctionalInterface
    interface ThrowingRunnable {
        void run() throws Exception;
    }

    static final class Section {
        final String name;
        final ThrowingRunnable task;
        Section(String name, ThrowingRunnable task) { this.name = name; this.task = task; }
    }

    public static void main(String[] args) throws Exception {
        final String[] empty = new String[0];
        Section[] sections = new Section[] {
            new Section("S01_DocumentPage",  () -> S01_DocumentPage.main(empty)),
            new Section("S02_FontText",      () -> S02_FontText.main(empty)),
            new Section("S03_Chunk",         () -> S03_Chunk.main(empty)),
            new Section("S04_Phrase",        () -> S04_Phrase.main(empty)),
            new Section("S05_Paragraph",     () -> S05_Paragraph.main(empty)),
            new Section("S06_Anchor",        () -> S06_Anchor.main(empty)),
            new Section("S07_Table",         () -> S07_Table.main(empty)),
            new Section("S08_Image",         () -> S08_Image.main(empty)),
            new Section("S09_Drawing",       () -> S09_Drawing.main(empty)),
            new Section("S10_PageEvent",     () -> S10_PageEvent.main(empty)),
            new Section("S11_Bookmark",      () -> S11_Bookmark.main(empty)),
            new Section("S12_Annotation",    () -> S12_Annotation.main(empty)),
            new Section("S13_FormField",     () -> S13_FormField.main(empty)),
            new Section("S14_Transparency",  () -> S14_Transparency.main(empty)),
            new Section("S15_Shading",       () -> S15_Shading.main(empty)),
            new Section("S16_Barcode",       () -> S16_Barcode.main(empty)),
            new Section("S17_ReaderStamper", () -> S17_ReaderStamper.main(empty)),
            new Section("S18_PdfCopy",       () -> S18_PdfCopy.main(empty)),
            new Section("S19_TextExtract",   () -> S19_TextExtract.main(empty)),
            new Section("S20_Security",      () -> S20_Security.main(empty)),
            new Section("S21_ColumnText",    () -> S21_ColumnText.main(empty)),
            new Section("S22_Chapter",       () -> S22_Chapter.main(empty)),
            new Section("S23_Metadata",      () -> S23_Metadata.main(empty)),
            new Section("S24_FontRegistry",  () -> S24_FontRegistry.main(empty)),
            new Section("S25_CJKCMap",       () -> S25_CJKCMap.main(empty)),
        };

        // 解析参数：无参 / "all" → 全部；数字 → 单个 section
        String arg = (args.length > 0) ? args[0].trim() : "all";

        if (arg.equalsIgnoreCase("all")) {
            runAll(sections);
            return;
        }

        int idx;
        try {
            idx = Integer.parseInt(arg);   // "7" / "07" 均可
        } catch (NumberFormatException e) {
            System.out.println("无法识别的参数: " + arg);
            System.out.println("用法: all（默认）| 1..23（如 7 或 07）");
            return;
        }
        if (idx < 1 || idx > sections.length) {
            System.out.println("section 编号超出范围: " + idx + "（有效 1.." + sections.length + "）");
            return;
        }
        run(sections[idx - 1]);
    }

    static void runAll(Section[] sections) {
        System.out.println("========================================");
        System.out.println("  Running all OpenPDF section demos");
        System.out.println("========================================");
        for (Section s : sections) {
            run(s);
        }
        System.out.println("\n========================================");
        System.out.println("  All sections complete.");
        System.out.println("  Output PDFs are in: output/");
        System.out.println("========================================");
    }

    static void run(Section s) {
        System.out.println("\n--- " + s.name + " ---");
        long start = System.currentTimeMillis();
        try {
            s.task.run();
            long elapsed = System.currentTimeMillis() - start;
            System.out.println("  [OK] " + s.name + " completed in " + elapsed + "ms");
        } catch (Throwable e) {
            System.out.println("  [FAIL] " + s.name + " threw: "
                + e.getClass().getSimpleName() + ": " + e.getMessage());
            e.printStackTrace(System.out);
        }
    }
}
