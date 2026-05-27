/**
 * RunAllSections — Runs all S01 through S23 section demos in sequence.
 * Usage: java -cp <fat-jar> RunAllSections
 * Or via Maven: mvn exec:java -Dexec.mainClass=RunAllSections
 */
public class RunAllSections {

    public static void main(String[] args) throws Exception {
        System.out.println("========================================");
        System.out.println("  Running all OpenPDF section demos");
        System.out.println("========================================\n");

        run("S01_DocumentPage", () -> S01_DocumentPage.main(args));
        run("S02_FontText",     () -> S02_FontText.main(args));
        run("S03_Chunk",        () -> S03_Chunk.main(args));
        run("S04_Phrase",       () -> S04_Phrase.main(args));
        run("S05_Paragraph",    () -> S05_Paragraph.main(args));
        run("S06_Anchor",       () -> S06_Anchor.main(args));
        run("S07_Table",        () -> S07_Table.main(args));
        run("S08_Image",        () -> S08_Image.main(args));
        run("S09_Drawing",      () -> S09_Drawing.main(args));
        run("S10_PageEvent",    () -> S10_PageEvent.main(args));
        run("S11_Bookmark",     () -> S11_Bookmark.main(args));
        run("S12_Annotation",   () -> S12_Annotation.main(args));
        run("S13_FormField",    () -> S13_FormField.main(args));
        run("S14_Transparency", () -> S14_Transparency.main(args));
        run("S15_Shading",      () -> S15_Shading.main(args));
        run("S16_Barcode",      () -> S16_Barcode.main(args));
        run("S17_ReaderStamper",() -> S17_ReaderStamper.main(args));
        run("S18_PdfCopy",      () -> S18_PdfCopy.main(args));
        run("S19_TextExtract",  () -> S19_TextExtract.main(args));
        run("S20_Security",     () -> S20_Security.main(args));
        run("S21_ColumnText",   () -> S21_ColumnText.main(args));
        run("S22_Chapter",      () -> S22_Chapter.main(args));
        run("S23_Metadata",     () -> S23_Metadata.main(args));

        System.out.println("\n========================================");
        System.out.println("  All sections complete.");
        System.out.println("  Output PDFs are in: output/");
        System.out.println("========================================");
    }

    @FunctionalInterface
    interface ThrowingRunnable {
        void run() throws Exception;
    }

    static void run(String name, ThrowingRunnable task) {
        System.out.println("\n--- " + name + " ---");
        long start = System.currentTimeMillis();
        try {
            task.run();
            long elapsed = System.currentTimeMillis() - start;
            System.out.println("  [OK] " + name + " completed in " + elapsed + "ms");
        } catch (Throwable e) {
            System.out.println("  [FAIL] " + name + " threw: " + e.getClass().getSimpleName() + ": " + e.getMessage());
            e.printStackTrace(System.out);
        }
    }
}
