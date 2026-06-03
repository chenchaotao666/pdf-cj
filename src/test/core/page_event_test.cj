/**
 * PdfPageEvent 单元测试
 *
 * 策略：用一个跟踪事件类记录 hook 调用顺序（逗号分隔字符串）和计数，
 * 然后断言与预期一致。
 */
package pdf_cj.test.core

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.{PdfWriter, PdfPageEvent, PdfPageEventHelper}
import pdf_cj.text.{BaseFont, Font}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

// 跟踪所有 hook 调用，用逗号分隔的字符串记录顺序
class TrackingEvent <: PdfPageEventHelper {
    public var callLog: String = ""
    public var paragraphCount: Int32 = 0
    public var paragraphEndCount: Int32 = 0
    public var startPageCount: Int32 = 0
    public var endPageCount: Int32 = 0
    public var lastParagraphY: Float32 = 0.0
    public var openCalled: Bool = false
    public var closeCalled: Bool = false

    private func record(name: String): Unit {
        if (callLog == "") {
            callLog = name
        } else {
            callLog = callLog + "," + name
        }
    }

    public override func onOpenDocument(writer: PdfWriter, document: Document): Unit {
        openCalled = true
        record("open")
    }

    public override func onCloseDocument(writer: PdfWriter, document: Document): Unit {
        closeCalled = true
        record("close")
    }

    public override func onStartPage(writer: PdfWriter, document: Document): Unit {
        startPageCount += 1
        record("startPage")
    }

    public override func onEndPage(writer: PdfWriter, document: Document): Unit {
        endPageCount += 1
        record("endPage")
    }

    public override func onParagraph(writer: PdfWriter, document: Document, paragraphPosition: Float32): Unit {
        paragraphCount += 1
        record("para")
    }

    public override func onParagraphEnd(writer: PdfWriter, document: Document, paragraphPosition: Float32): Unit {
        paragraphEndCount += 1
        lastParagraphY = paragraphPosition
        record("paraEnd")
    }
}

func makeHelvetica(): Font {
    let bf = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
    Font(bf, 12.0)
}

func openTrackedDoc(path: String, tracker: PdfPageEvent): (Document, File) {
    let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
    let file = File(Path(path), OpenMode.Write)
    let writer = PdfWriter.getInstance(document, file)
    writer.setPageEvent(tracker)
    document.open()
    (document, file)
}

// ===== 基本生命周期 =====

@Test
public class PageEventLifecycleTests {

    @TestCase
    func testOpenDocumentFired(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_open.pdf", tracker)
        document.close()
        file.close()
        @Expect(tracker.openCalled, true)
    }

    @TestCase
    func testCloseDocumentFired(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_close.pdf", tracker)
        document.close()
        file.close()
        @Expect(tracker.closeCalled, true)
    }

    @TestCase
    func testStartPageFiresOnDocumentOpen(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_startpage.pdf", tracker)
        document.close()
        file.close()
        @Expect(tracker.startPageCount >= 1, true)
    }

    @TestCase
    func testEndPageFiresOnDocumentClose(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_endpage.pdf", tracker)
        document.close()
        file.close()
        @Expect(tracker.endPageCount >= 1, true)
    }

    @TestCase
    func testOpenFiresBeforeStartPage(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_order.pdf", tracker)
        document.close()
        file.close()
        // callLog starts with "open,startPage"
        @Expect(tracker.callLog.startsWith("open,startPage"), true)
    }

    @TestCase
    func testCloseFiresAfterEndPage(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_closeorder.pdf", tracker)
        document.close()
        file.close()
        // callLog ends with "endPage,close"
        @Expect(tracker.callLog.endsWith("endPage,close"), true)
    }
}

// ===== 多页事件 =====

@Test
public class PageEventMultiPageTests {

    @TestCase
    func testStartPageFiresForEachPage(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_multistart.pdf", tracker)
        let font = makeHelvetica()
        // 每页需有内容才会真正换页（空页 newPage 与 OpenPDF 一致会被跳过）
        document.add(Paragraph("Page 1", font))
        document.newPage()
        document.add(Paragraph("Page 2", font))
        document.newPage()
        document.add(Paragraph("Page 3", font))
        document.close()
        file.close()
        // 初始页 + 2 次有效 newPage = 3 页
        @Expect(tracker.startPageCount, 3)
    }

    @TestCase
    func testEndPageFiresForEachPage(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_multiend.pdf", tracker)
        let font = makeHelvetica()
        document.add(Paragraph("Page 1", font))
        document.newPage()
        document.add(Paragraph("Page 2", font))
        document.newPage()
        document.add(Paragraph("Page 3", font))
        document.close()
        file.close()
        @Expect(tracker.endPageCount, 3)
    }

    @TestCase
    func testStartAndEndPageCountsMatch(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_match.pdf", tracker)
        let font = makeHelvetica()
        document.add(Paragraph("Page 1", font))
        document.newPage()
        document.add(Paragraph("Page 2", font))
        document.close()
        file.close()
        @Expect(tracker.startPageCount, tracker.endPageCount)
    }

    @TestCase
    func testEmptyNewPageIsSkipped(): Unit {
        // 空白页 newPage 应被跳过（不产生空白页、不触发额外事件），与 OpenPDF 行为一致
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_emptyskip.pdf", tracker)
        document.newPage()
        document.newPage()
        document.close()
        file.close()
        // 只有初始页：start=1, end=1
        @Expect(tracker.startPageCount, 1)
        @Expect(tracker.endPageCount, 1)
    }
}

// ===== 段落事件 =====

@Test
public class PageEventParagraphTests {

    @TestCase
    func testParagraphEventFires(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_para.pdf", tracker)
        let font = makeHelvetica()
        document.add(Paragraph("Hello", font))
        document.add(Paragraph("World", font))
        document.close()
        file.close()
        @Expect(tracker.paragraphCount, 2)
    }

    @TestCase
    func testParagraphEndEventFires(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_paraend.pdf", tracker)
        let font = makeHelvetica()
        document.add(Paragraph("A", font))
        document.add(Paragraph("B", font))
        document.add(Paragraph("C", font))
        document.close()
        file.close()
        @Expect(tracker.paragraphEndCount, 3)
    }

    @TestCase
    func testParagraphAndEndCountsMatch(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_para_match.pdf", tracker)
        let font = makeHelvetica()
        var n = 0
        while (n < 5) {
            document.add(Paragraph("Para ${n}", font))
            n += 1
        }
        document.close()
        file.close()
        @Expect(tracker.paragraphCount, tracker.paragraphEndCount)
    }

    @TestCase
    func testParagraphFiresBeforeParagraphEnd(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_para_order.pdf", tracker)
        let font = makeHelvetica()
        document.add(Paragraph("Test paragraph", font))
        document.close()
        file.close()
        // 日志中 para 出现在 paraEnd 之前
        @Expect(tracker.callLog.contains("para,paraEnd"), true)
    }

    @TestCase
    func testLastParagraphYIsInPageBounds(): Unit {
        let tracker = TrackingEvent()
        let (document, file) = openTrackedDoc("/tmp/pe_para_y.pdf", tracker)
        let font = makeHelvetica()
        document.add(Paragraph("Only paragraph", font))
        document.close()
        file.close()
        // A4 高度约 842pt，Y 坐标应在页面范围内
        @Expect(tracker.lastParagraphY > 0.0, true)
        @Expect(tracker.lastParagraphY < 842.0, true)
    }
}

// ===== PdfPageEventHelper 默认实现 =====

@Test
public class PageEventHelperDefaultTests {

    @TestCase
    func testHelperNoopDoesNotThrow(): Unit {
        // 使用默认空实现，不应抛出异常
        let helper = PdfPageEventHelper()
        let (document, file) = openTrackedDoc("/tmp/pe_noop.pdf", helper)
        let font = makeHelvetica()
        document.add(Paragraph("Default helper", font))
        document.newPage()
        document.close()
        file.close()
        @Expect(true, true)
    }
}
