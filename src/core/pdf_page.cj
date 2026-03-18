/**
 * PDF-CJ: PdfPage - 单个 PDF 页面
 */
package pdf_cj.core

import pdf_cj.base.{PdfDictionary, PdfName, PdfIndirectReference, PdfArray, PdfNumber, PdfStream}
import pdf_cj.util.Rectangle

/**
 * PDF 页面
 */
public class PdfPage {
    private var _dictionary: PdfDictionary = PdfDictionary(PdfName.PAGE)
    private var _mediaBox: Rectangle
    private var _cropBox: ?Rectangle = None
    private var _resources: ?PdfIndirectReference = None
    private var _contents: ?PdfIndirectReference = None
    private var _parent: ?PdfIndirectReference = None
    private var _rotation: Int32 = 0

    public init(mediaBox: Rectangle) {
        this._mediaBox = mediaBox
        updateMediaBox()
    }

    /**
     * 设置父页面树
     */
    public func setParent(parent: PdfIndirectReference): Unit {
        this._parent = Some(parent)
        _dictionary.put(PdfName.PARENT, parent)
    }

    /**
     * 设置资源
     */
    public func setResources(resources: PdfIndirectReference): Unit {
        this._resources = Some(resources)
        _dictionary.put(PdfName.RESOURCES, resources)
    }

    /**
     * 设置资源（直接字典）
     */
    public func setResources(resources: PdfDictionary): Unit {
        _dictionary.put(PdfName.RESOURCES, resources)
    }

    /**
     * 设置内容流
     */
    public func setContents(contents: PdfIndirectReference): Unit {
        this._contents = Some(contents)
        _dictionary.put(PdfName.CONTENTS, contents)
    }

    /**
     * 设置内容流数组
     */
    public func setContents(contents: PdfArray): Unit {
        _dictionary.put(PdfName.CONTENTS, contents)
    }

    /**
     * 设置裁剪框
     */
    public func setCropBox(cropBox: Rectangle): Unit {
        this._cropBox = Some(cropBox)
        let arr = PdfArray()
        arr.add(cropBox.left)
        arr.add(cropBox.bottom)
        arr.add(cropBox.right)
        arr.add(cropBox.top)
        _dictionary.put(PdfName.CROPBOX, arr)
    }

    /**
     * 设置旋转角度
     */
    public func setRotation(rotation: Int32): Unit {
        this._rotation = rotation
        if (rotation != 0) {
            _dictionary.put(PdfName.ROTATE, PdfNumber(rotation))
        }
    }

    /**
     * 更新 MediaBox
     */
    private func updateMediaBox(): Unit {
        let arr = PdfArray()
        arr.add(_mediaBox.left)
        arr.add(_mediaBox.bottom)
        arr.add(_mediaBox.right)
        arr.add(_mediaBox.top)
        _dictionary.put(PdfName.MEDIABOX, arr)
    }

    /**
     * 获取页面字典
     */
    public prop dictionary: PdfDictionary {
        get() { _dictionary }
    }

    /**
     * 获取 MediaBox
     */
    public prop mediaBox: Rectangle {
        get() { _mediaBox }
    }

    /**
     * 获取旋转角度
     */
    public prop rotation: Int32 {
        get() { _rotation }
    }
}
