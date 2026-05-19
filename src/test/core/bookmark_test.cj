/**
 * PdfOutline / PdfOutlineTree 单元测试
 *
 * 策略：
 *   - 纯数据结构测试：验证树的构建、链接和字典构建
 *   - 集成测试：生成含书签的 PDF，验证不抛异常且能写出
 */
package pdf_cj.test.core

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.form.{PdfOutline, PdfOutlineTree, PdfDestination}
import pdf_cj.base.{PdfIndirectReference, PdfName}
import pdf_cj.text.{BaseFont, Font}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

func makeDest(objNum: Int32): PdfDestination {
    PdfDestination(PdfIndirectReference(objNum))
}

func makeFont2(): Font {
    let bf = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
    Font(bf, 12.0)
}

// ===== PdfOutlineTree 结构测试 =====

@Test
public class OutlineTreeStructureTests {

    @TestCase
    func testEmptyTreeHasRoot(): Unit {
        let tree = PdfOutlineTree()
        // root 是占位节点，标题为 "Outlines"
        @Expect(tree.getRoot().getTitle(), "Outlines")
    }

    @TestCase
    func testAddOneOutline(): Unit {
        let tree = PdfOutlineTree()
        let bm = PdfOutline("章节一", makeDest(10))
        tree.addOutline(bm)
        @Expect(tree.getRoot().getChildCount(), 1)
    }

    @TestCase
    func testAddMultipleOutlines(): Unit {
        let tree = PdfOutlineTree()
        tree.addOutline(PdfOutline("第一章", makeDest(10)))
        tree.addOutline(PdfOutline("第二章", makeDest(20)))
        tree.addOutline(PdfOutline("第三章", makeDest(30)))
        @Expect(tree.getRoot().getChildCount(), 3)
    }

    @TestCase
    func testGetAllOutlinesIncludesRoot(): Unit {
        let tree = PdfOutlineTree()
        tree.addOutline(PdfOutline("A", makeDest(10)))
        tree.addOutline(PdfOutline("B", makeDest(20)))
        // root + 2 bookmarks
        @Expect(tree.getAllOutlines().size, 3)
    }
}

// ===== PdfOutline 子节点测试 =====

@Test
public class OutlineChildTests {

    @TestCase
    func testAddChildToOutline(): Unit {
        let parent = PdfOutline("父节点", makeDest(10))
        let child = PdfOutline("子节点", makeDest(20))
        parent.addChild(child)
        @Expect(parent.getChildCount(), 1)
    }

    @TestCase
    func testChildTitlePreserved(): Unit {
        let parent = PdfOutline("父", makeDest(10))
        let child = PdfOutline("子标题", makeDest(20))
        parent.addChild(child)
        let got = parent.getChild(0)
        if (got.isSome()) {
            @Expect(got.getOrThrow().getTitle(), "子标题")
        } else {
            @Fail("Expected child at index 0")
        }
    }

    @TestCase
    func testNestedChildrenInTree(): Unit {
        let tree = PdfOutlineTree()
        let ch = PdfOutline("Chapter", makeDest(10))
        ch.addChild(PdfOutline("Section 1", makeDest(11)))
        ch.addChild(PdfOutline("Section 2", makeDest(12)))
        tree.addOutline(ch)
        // root + Chapter + 2 Sections = 4 (but getAllOutlines doesn't recurse through children added after addOutline)
        // Actually addOutline calls collectOutlines which recurses
        @Expect(tree.getAllOutlines().size, 4)
    }

    @TestCase
    func testGetChildOutOfBoundsReturnsNone(): Unit {
        let bm = PdfOutline("X", makeDest(10))
        let result = bm.getChild(0)
        @Expect(result.isNone(), true)
    }
}

// ===== PdfOutline 样式测试 =====

@Test
public class OutlineStyleTests {

    @TestCase
    func testBoldFlagSet(): Unit {
        let bm = PdfOutline("Bold BM", makeDest(10))
        bm.setBold(true)
        bm.setReference(PdfIndirectReference(1))
        bm.buildDictionary()
        let dict = bm.getDictionary()
        // 字典中应该有 "F" 键，值为 2（bold flag）
        @Expect(dict.contains(PdfName("F")), true)
    }

    @TestCase
    func testItalicFlagSet(): Unit {
        let bm = PdfOutline("Italic BM", makeDest(10))
        bm.setItalic(true)
        bm.setReference(PdfIndirectReference(1))
        bm.buildDictionary()
        let dict = bm.getDictionary()
        @Expect(dict.contains(PdfName("F")), true)
    }

    @TestCase
    func testColorSet(): Unit {
        let bm = PdfOutline("Color BM", makeDest(10))
        bm.setColor(1.0, 0.0, 0.0)
        bm.setReference(PdfIndirectReference(1))
        bm.buildDictionary()
        let dict = bm.getDictionary()
        @Expect(dict.contains(PdfName("C")), true)
    }

    @TestCase
    func testNoStyleFlagWhenNotSet(): Unit {
        let bm = PdfOutline("Plain BM", makeDest(10))
        bm.setReference(PdfIndirectReference(1))
        bm.buildDictionary()
        let dict = bm.getDictionary()
        @Expect(dict.contains(PdfName("F")), false)
    }
}

// ===== PdfOutline 字典构建测试 =====

@Test
public class OutlineDictionaryTests {

    @TestCase
    func testTitleInDictionary(): Unit {
        let bm = PdfOutline("My Title", makeDest(10))
        bm.setReference(PdfIndirectReference(1))
        bm.buildDictionary()
        let dict = bm.getDictionary()
        @Expect(dict.contains(PdfName("Title")), true)
    }

    @TestCase
    func testDestInDictionary(): Unit {
        let bm = PdfOutline("Dest BM", makeDest(10))
        bm.setReference(PdfIndirectReference(1))
        bm.buildDictionary()
        let dict = bm.getDictionary()
        @Expect(dict.contains(PdfName("Dest")), true)
    }

    @TestCase
    func testCountInDictionaryWhenHasChildren(): Unit {
        let parent = PdfOutline("Parent", makeDest(10))
        parent.addChild(PdfOutline("Child", makeDest(20)))
        parent.setReference(PdfIndirectReference(1))
        parent.getChild(0).getOrThrow().setReference(PdfIndirectReference(2))
        parent.buildDictionary()
        let dict = parent.getDictionary()
        @Expect(dict.contains(PdfName("Count")), true)
    }
}

// ===== PdfWriter.addOutline 便捷 API 测试 =====

@Test
public class WriterOutlineAPITests {

    @TestCase
    func testGetOutlineTreeCreatesTree(): Unit {
        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("/tmp/bm_tree_create.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        let tree = writer.getOutlineTree()
        @Expect(tree.getRoot().getTitle(), "Outlines")
        document.close()
        file.close()
    }

    @TestCase
    func testGetOutlineTreeReturnsSameInstance(): Unit {
        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("/tmp/bm_same_instance.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        let t1 = writer.getOutlineTree()
        let t2 = writer.getOutlineTree()
        // 两次调用返回同一棵树（根节点相同对象）
        t1.addOutline(PdfOutline("A", makeDest(10)))
        @Expect(t2.getRoot().getChildCount(), 1)
        document.close()
        file.close()
    }

    @TestCase
    func testAddOutlineViaWriterShortcut(): Unit {
        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("/tmp/bm_shortcut.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        let pageRef = writer.getCurrentPageReference()
        writer.addOutline("Chapter 1", PdfDestination(pageRef))
        writer.addOutline("Chapter 2", PdfDestination(pageRef))
        @Expect(writer.getOutlineTree().getRoot().getChildCount(), 2)
        document.close()
        file.close()
    }
}

// ===== 集成测试：生成含书签的 PDF =====

@Test
public class BookmarkIntegrationTests {

    @TestCase
    func testFlatBookmarksPdfGenerated(): Unit {
        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("/tmp/bm_flat.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        let font = makeFont2()

        let ref1 = writer.getCurrentPageReference()
        writer.addOutline("Page 1", PdfDestination(ref1))
        document.add(Paragraph("Page 1 content", font))

        document.newPage()
        let ref2 = writer.getCurrentPageReference()
        writer.addOutline("Page 2", PdfDestination(ref2))
        document.add(Paragraph("Page 2 content", font))

        document.close()
        file.close()
        @Expect(true, true)
    }

    @TestCase
    func testNestedBookmarksPdfGenerated(): Unit {
        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("/tmp/bm_nested.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        let font = makeFont2()

        let ref1 = writer.getCurrentPageReference()
        let ch = writer.addOutline("Chapter", PdfDestination(ref1))
        ch.addChild(PdfOutline("Section 1.1", PdfDestination(ref1)))
        ch.addChild(PdfOutline("Section 1.2", PdfDestination(ref1)))
        document.add(Paragraph("Chapter content", font))

        document.close()
        file.close()
        @Expect(true, true)
    }

    @TestCase
    func testStyledBookmarksPdfGenerated(): Unit {
        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("/tmp/bm_styled.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        let font = makeFont2()

        let ref1 = writer.getCurrentPageReference()
        let bm = PdfOutline("Bold Red", PdfDestination(ref1))
        bm.setBold(true)
        bm.setColor(0.8, 0.0, 0.0)
        writer.getOutlineTree().addOutline(bm)
        document.add(Paragraph("Content", font))

        document.close()
        file.close()
        @Expect(true, true)
    }

    @TestCase
    func testNoBookmarksPdfGeneratedNormally(): Unit {
        let document = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
        let file = File(Path("/tmp/bm_none.pdf"), OpenMode.Write)
        let writer = PdfWriter.getInstance(document, file)
        document.open()
        let font = makeFont2()
        document.add(Paragraph("No bookmarks", font))
        document.close()
        file.close()
        @Expect(true, true)
    }
}
