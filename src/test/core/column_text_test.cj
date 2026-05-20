/**
 * ColumnText 单元测试
 *
 * 策略：
 *   - 使用 goSimulate() 避免实际绘制（无需 PdfWriter）
 *   - 测试 addSimpleColumn / setSimpleColumn 边界设置
 *   - 测试 go()/goSimulate() 的返回值
 *   - 测试 hasMoreText() 状态
 *   - 测试 yLine 推进和 getFilledHeight
 */
package pdf_cj.test.core

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.core.{PdfContentByte, ColumnText}
import pdf_cj.api.{Paragraph, Phrase}
import pdf_cj.text.{BaseFont, Font, Alignment}

// 无 PdfWriter 的 canvas（仅用于 goSimulate，不触发实际绘制）
func makeCb(): PdfContentByte { PdfContentByte() }

func helvFont12(): Font {
    let bf = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
    Font(bf, 12.0)
}

func makePara(text: String): Paragraph {
    let p = Paragraph(text, helvFont12())
    p.setLeading(14.0)
    p
}

// ===== 列边界设置 =====

@Test
public class ColumnBoundTests {

    @TestCase
    func testSetSimpleColumnSetsYLine(): Unit {
        let ct = ColumnText(makeCb())
        ct.setSimpleColumn(50.0, 100.0, 400.0, 700.0)
        @Expect(ct.yLine, 700.0)
    }

    @TestCase
    func testAddSimpleColumnSetsYLine(): Unit {
        let ct = ColumnText(makeCb())
        // addSimpleColumn(left, right, bottom, top)
        ct.addSimpleColumn(50.0, 400.0, 100.0, 700.0)
        @Expect(ct.yLine, 700.0)
    }

    @TestCase
    func testSetYLine(): Unit {
        let ct = ColumnText(makeCb())
        ct.setSimpleColumn(50.0, 100.0, 400.0, 700.0)
        ct.setYLine(500.0)
        @Expect(ct.yLine, 500.0)
    }

    @TestCase
    func testGetFilledHeight(): Unit {
        let ct = ColumnText(makeCb())
        ct.setSimpleColumn(50.0, 100.0, 400.0, 700.0)
        // 未排版，填充高度为 0
        @Expect(ct.getFilledHeight(), 0.0)
    }
}

// ===== 内容管理 =====

@Test
public class ContentManagementTests {

    @TestCase
    func testHasMoreTextFalseInitially(): Unit {
        let ct = ColumnText(makeCb())
        @Expect(ct.hasMoreText(), false)
    }

    @TestCase
    func testHasMoreTextTrueAfterAddElement(): Unit {
        let ct = ColumnText(makeCb())
        ct.addElement(makePara("hello"))
        @Expect(ct.hasMoreText(), true)
    }

    @TestCase
    func testAddElementAddsToQueue(): Unit {
        let ct = ColumnText(makeCb())
        ct.addElement(makePara("first"))
        ct.addElement(makePara("second"))
        @Expect(ct.hasMoreText(), true)
    }

    @TestCase
    func testSetTextClearsAndSets(): Unit {
        let ct = ColumnText(makeCb())
        ct.addElement(makePara("old"))
        ct.setText(Phrase("new phrase"))
        @Expect(ct.hasMoreText(), true)
    }
}

// ===== go() / goSimulate() 返回值 =====

@Test
public class GoReturnValueTests {

    @TestCase
    func testNoMoreTextWhenEmpty(): Unit {
        let ct = ColumnText(makeCb())
        ct.setSimpleColumn(50.0, 100.0, 400.0, 700.0)
        @Expect(ct.goSimulate(), ColumnText.NO_MORE_TEXT)
    }

    @TestCase
    func testNoMoreTextAfterSmallParagraph(): Unit {
        let ct = ColumnText(makeCb())
        // 列高度 300pt，段落只有一行(14pt)，足够放下
        ct.setSimpleColumn(50.0, 100.0, 400.0, 700.0)
        ct.addElement(makePara("Hi"))
        @Expect(ct.goSimulate(), ColumnText.NO_MORE_TEXT)
    }

    @TestCase
    func testHasMoreTextFalseAfterNoMoreText(): Unit {
        let ct = ColumnText(makeCb())
        ct.setSimpleColumn(50.0, 100.0, 400.0, 700.0)
        ct.addElement(makePara("Hi"))
        ct.goSimulate()
        @Expect(ct.hasMoreText(), false)
    }

    @TestCase
    func testNoMoreColumnWhenNoSpace(): Unit {
        let ct = ColumnText(makeCb())
        // 列高度仅 5pt，一行 14pt 放不下
        ct.setSimpleColumn(50.0, 695.0, 400.0, 700.0)
        ct.addElement(makePara("This line cannot fit"))
        @Expect(ct.goSimulate(), ColumnText.NO_MORE_COLUMN)
    }

    @TestCase
    func testHasMoreTextTrueAfterNoMoreColumn(): Unit {
        let ct = ColumnText(makeCb())
        ct.setSimpleColumn(50.0, 695.0, 400.0, 700.0)
        ct.addElement(makePara("overflow"))
        ct.goSimulate()
        @Expect(ct.hasMoreText(), true)
    }

    @TestCase
    func testMultipleElementsAllFit(): Unit {
        let ct = ColumnText(makeCb())
        // 列高 300pt，3 段 × 14pt = 42pt，全部放得下
        ct.setSimpleColumn(50.0, 100.0, 400.0, 700.0)
        ct.addElement(makePara("Para 1"))
        ct.addElement(makePara("Para 2"))
        ct.addElement(makePara("Para 3"))
        @Expect(ct.goSimulate(), ColumnText.NO_MORE_TEXT)
        @Expect(ct.hasMoreText(), false)
    }

    @TestCase
    func testYLineDecreasesAfterGo(): Unit {
        let ct = ColumnText(makeCb())
        ct.setSimpleColumn(50.0, 100.0, 400.0, 700.0)
        ct.addElement(makePara("A line"))
        ct.goSimulate()
        // Y 应该下降了 leading(14)
        @Expect(ct.yLine < 700.0, true)
    }
}

// ===== 属性访问器 =====

@Test
public class PropertyTests {

    @TestCase
    func testDefaultAlignment(): Unit {
        let ct = ColumnText(makeCb())
        @Expect(ct.alignment.toInt(), Alignment.Left.toInt())
    }

    @TestCase
    func testSetAlignment(): Unit {
        let ct = ColumnText(makeCb())
        ct.setAlignment(Alignment.Center)
        @Expect(ct.alignment.toInt(), Alignment.Center.toInt())
    }

    @TestCase
    func testSetLeading(): Unit {
        let ct = ColumnText(makeCb())
        ct.setLeading(20.0)
        @Expect(ct.leading, 20.0)
    }

    @TestCase
    func testSetIndent(): Unit {
        let ct = ColumnText(makeCb())
        ct.setIndent(10.0)
        @Expect(ct.indent, 10.0)
    }

    @TestCase
    func testSetRightIndent(): Unit {
        let ct = ColumnText(makeCb())
        ct.setRightIndent(15.0)
        @Expect(ct.rightIndent, 15.0)
    }
}
