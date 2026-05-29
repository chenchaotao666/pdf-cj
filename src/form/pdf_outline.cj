/**
 * PDF-CJ: PdfOutline - PDF 大纲/书签
 * 创建文档的导航树结构
 */
package pdf_cj.form

import pdf_cj.base.*
import pdf_cj.util.PdfException
import std.collection.ArrayList

/**
 * PDF 大纲/书签
 * 表示文档导航树中的一个节点
 */
public class PdfOutline {
    private var title: String
    private var dictionary: PdfDictionary

    // 树结构
    private var parent: ?PdfOutline = None
    private var first: ?PdfOutline = None  // 第一个子节点
    private var last: ?PdfOutline = None   // 最后一个子节点
    private var prev: ?PdfOutline = None   // 前一个兄弟节点
    private var next: ?PdfOutline = None   // 下一个兄弟节点

    // 子节点列表
    private var children: ArrayList<PdfOutline> = ArrayList<PdfOutline>()

    // 引用
    private var reference: ?PdfIndirectReference = None

    // 属性
    private var destination: ?PdfDestination = None
    private var action: ?PdfAction = None
    private var open: Bool = true

    // 样式
    private var bold: Bool = false
    private var italic: Bool = false
    private var color: ?Array<Float32> = None

    /**
     * 构造函数
     * @param title 书签标题
     */
    public init(title: String) {
        this.title = title
        this.dictionary = PdfDictionary()
    }

    /**
     * 构造函数（带目标）
     * @param title 书签标题
     * @param destination 目标位置
     */
    public init(title: String, destination: PdfDestination) {
        this.title = title
        this.dictionary = PdfDictionary()
        this.destination = Some(destination)
    }

    /**
     * 构造函数（带动作）
     * @param title 书签标题
     * @param action 动作
     */
    public init(title: String, action: PdfAction) {
        this.title = title
        this.dictionary = PdfDictionary()
        this.action = Some(action)
    }

    /**
     * 添加子书签
     */
    public func addChild(child: PdfOutline): Unit {
        child.parent = Some(this)

        if (children.size == 0) {
            // 第一个子节点
            this.first = Some(child)
            this.last = Some(child)
        } else {
            // 链接到最后一个子节点
            match (last) {
                case Some(lastChild) =>
                    lastChild.next = Some(child)
                    child.prev = Some(lastChild)
                case None => ()
            }
            this.last = Some(child)
        }

        children.add(child)
    }

    /**
     * 设置目标位置
     */
    public func setDestination(dest: PdfDestination): Unit {
        this.destination = Some(dest)
    }

    /**
     * 设置动作
     */
    public func setAction(act: PdfAction): Unit {
        this.action = Some(act)
    }

    /**
     * 设置是否展开
     */
    public func setOpen(isOpen: Bool): Unit {
        this.open = isOpen
    }

    /**
     * 设置粗体
     */
    public func setBold(isBold: Bool): Unit {
        this.bold = isBold
    }

    /**
     * 设置斜体
     */
    public func setItalic(isItalic: Bool): Unit {
        this.italic = isItalic
    }

    /**
     * 设置颜色
     */
    public func setColor(r: Float32, g: Float32, b: Float32): Unit {
        let arr = Array<Float32>(3, repeat: 0.0)
        arr[0] = r
        arr[1] = g
        arr[2] = b
        this.color = Some(arr)
    }

    /**
     * 获取标题
     */
    public func getTitle(): String {
        title
    }

    /**
     * 获取字典
     */
    public func getDictionary(): PdfDictionary {
        dictionary
    }

    /**
     * 设置引用
     */
    public func setReference(ref: PdfIndirectReference): Unit {
        this.reference = Some(ref)
    }

    /**
     * 获取引用
     */
    public func getReference(): ?PdfIndirectReference {
        reference
    }

    /**
     * 构建字典
     * 将书签信息写入字典
     */
    public func buildDictionary(): Unit {
        // 设置标题
        dictionary.put(PdfName("Title"), PdfString(title))

        // 设置父节点
        match (parent) {
            case Some(p) =>
                match (p.getReference()) {
                    case Some(ref) =>
                        dictionary.put(PdfName("Parent"), ref)
                    case None => ()
                }
            case None => ()
        }

        // 设置第一个子节点
        match (first) {
            case Some(f) =>
                match (f.getReference()) {
                    case Some(ref) =>
                        dictionary.put(PdfName("First"), ref)
                    case None => ()
                }
            case None => ()
        }

        // 设置最后一个子节点
        match (last) {
            case Some(l) =>
                match (l.getReference()) {
                    case Some(ref) =>
                        dictionary.put(PdfName("Last"), ref)
                    case None => ()
                }
            case None => ()
        }

        // 设置前一个兄弟
        match (prev) {
            case Some(p) =>
                match (p.getReference()) {
                    case Some(ref) =>
                        dictionary.put(PdfName("Prev"), ref)
                    case None => ()
                }
            case None => ()
        }

        // 设置下一个兄弟
        match (next) {
            case Some(n) =>
                match (n.getReference()) {
                    case Some(ref) =>
                        dictionary.put(PdfName("Next"), ref)
                    case None => ()
                }
            case None => ()
        }

        // 设置目标或动作
        match (destination) {
            case Some(dest) =>
                dictionary.put(PdfName("Dest"), dest.getArray())
            case None =>
                match (action) {
                    case Some(act) =>
                        dictionary.put(PdfName("A"), act.getDictionary())
                    case None => ()
                }
        }

        // 设置Count（子节点数量，负数表示折叠）
        let count = children.size
        if (count > 0) {
            let countValue = if (open) { Int32(count) } else { -Int32(count) }
            dictionary.put(PdfName("Count"), PdfNumber(countValue))
        }

        // 设置样式标志（PDF spec：bit0=italic=1，bit1=bold=2）
        var flags: Int32 = 0
        if (italic) { flags = flags | 1 }
        if (bold) { flags = flags | 2 }
        if (flags != 0) {
            dictionary.put(PdfName("F"), PdfNumber(flags))
        }

        // 设置颜色
        match (color) {
            case Some(c) =>
                let colorArray = PdfArray()
                colorArray.add(PdfNumber(c[0]))
                colorArray.add(PdfNumber(c[1]))
                colorArray.add(PdfNumber(c[2]))
                dictionary.put(PdfName("C"), colorArray)
            case None => ()
        }
    }

    /**
     * 获取子节点数量
     */
    public func getChildCount(): Int64 {
        children.size
    }

    /**
     * 获取子节点
     */
    public func getChild(index: Int64): ?PdfOutline {
        if (index >= 0 && index < children.size) {
            return Some(children[index])
        }
        None
    }

    /**
     * 获取所有子节点
     */
    public func getChildren(): ArrayList<PdfOutline> {
        children
    }
}

/**
 * PDF 大纲树
 * 管理整个文档的书签结构
 */
public class PdfOutlineTree {
    private var root: PdfOutline
    private var allOutlines: ArrayList<PdfOutline> = ArrayList<PdfOutline>()

    /**
     * 构造函数
     */
    public init() {
        // 创建根节点（Outlines字典）
        this.root = PdfOutline("Outlines")
        allOutlines.add(root)
    }

    /**
     * 添加根级书签
     */
    public func addOutline(outline: PdfOutline): Unit {
        root.addChild(outline)
        collectOutlines(outline)
    }

    /**
     * 递归收集所有书签
     */
    private func collectOutlines(outline: PdfOutline): Unit {
        allOutlines.add(outline)
        let children = outline.getChildren()
        for (i in 0..children.size) {
            collectOutlines(children[i])
        }
    }

    /**
     * 获取根节点
     */
    public func getRoot(): PdfOutline {
        root
    }

    /**
     * 获取所有书签
     */
    public func getAllOutlines(): ArrayList<PdfOutline> {
        allOutlines
    }

    /**
     * 分配引用
     * 为所有书签分配对象引用
     */
    public func allocateReferences(startObjNum: Int32): Int32 {
        var objNum = startObjNum

        for (i in 0..allOutlines.size) {
            let outline = allOutlines[i]
            outline.setReference(PdfIndirectReference(objNum))
            objNum += 1
        }

        objNum
    }

    /**
     * 构建所有字典
     */
    public func buildAllDictionaries(): Unit {
        for (i in 0..allOutlines.size) {
            allOutlines[i].buildDictionary()
        }
    }

    /**
     * 获取书签数量
     */
    public func getOutlineCount(): Int64 {
        allOutlines.size
    }
}

/**
 * 书签构建器
 * 提供便捷的书签创建方法
 */
public class PdfOutlineBuilder {
    private var tree: PdfOutlineTree
    private var currentOutline: ?PdfOutline = None

    /**
     * 构造函数
     */
    public init() {
        this.tree = PdfOutlineTree()
    }

    /**
     * 添加根级书签
     */
    public func addRootOutline(title: String, destination: PdfDestination): PdfOutlineBuilder {
        let outline = PdfOutline(title, destination)
        tree.addOutline(outline)
        this.currentOutline = Some(outline)
        this
    }

    /**
     * 为当前书签添加子书签
     */
    public func addChildOutline(title: String, destination: PdfDestination): PdfOutlineBuilder {
        match (currentOutline) {
            case Some(parent) =>
                let child = PdfOutline(title, destination)
                parent.addChild(child)
            case None =>
                throw PdfException("No current outline to add child to")
        }
        this
    }

    /**
     * 移动到父书签
     */
    public func moveToParent(): PdfOutlineBuilder {
        // 简化实现：不支持
        this
    }

    /**
     * 设置当前书签样式
     */
    public func setStyle(bold: Bool, italic: Bool): PdfOutlineBuilder {
        match (currentOutline) {
            case Some(outline) =>
                outline.setBold(bold)
                outline.setItalic(italic)
            case None => ()
        }
        this
    }

    /**
     * 设置当前书签颜色
     */
    public func setColor(r: Float32, g: Float32, b: Float32): PdfOutlineBuilder {
        match (currentOutline) {
            case Some(outline) =>
                outline.setColor(r, g, b)
            case None => ()
        }
        this
    }

    /**
     * 构建书签树
     */
    public func build(): PdfOutlineTree {
        tree
    }
}
