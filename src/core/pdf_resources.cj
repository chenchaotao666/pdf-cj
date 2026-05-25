/**
 * PDF-CJ: PdfResources - PDF 资源字典
 * 管理页面资源（字体、图片等）
 */
package pdf_cj.core

import std.collection.HashMap
import std.collection.ArrayList
import pdf_cj.base.{PdfDictionary, PdfName, PdfObject, PdfIndirectReference, PdfArray}
import pdf_cj.text.BaseFont

/**
 * 字体资源包装
 */
public class FontResource {
    public let baseFont: BaseFont
    public let reference: PdfIndirectReference
    public let name: String

    public init(baseFont: BaseFont, reference: PdfIndirectReference, name: String) {
        this.baseFont = baseFont
        this.reference = reference
        this.name = name
    }
}

/**
 * PDF 资源字典
 */
public class PdfResources {
    private var fonts: HashMap<String, FontResource> = HashMap<String, FontResource>()
    private var fontNames: ArrayList<String> = ArrayList<String>()
    private var fontCounter: Int32 = 0

    private var xObjects: HashMap<String, PdfIndirectReference> = HashMap<String, PdfIndirectReference>()
    private var xObjectNames: ArrayList<String> = ArrayList<String>()
    private var xObjectCounter: Int32 = 0

    private var extGStates: HashMap<String, PdfIndirectReference> = HashMap<String, PdfIndirectReference>()
    private var extGStateNames: ArrayList<String> = ArrayList<String>()
    private var extGStateCounter: Int32 = 0

    private var patterns: HashMap<String, PdfIndirectReference> = HashMap<String, PdfIndirectReference>()
    private var patternNames: ArrayList<String> = ArrayList<String>()
    private var patternCounter: Int32 = 0

    private var shadings: HashMap<String, PdfIndirectReference> = HashMap<String, PdfIndirectReference>()
    private var shadingNames: ArrayList<String> = ArrayList<String>()
    private var shadingCounter: Int32 = 0

    public init() {}

    /**
     * 添加字体资源
     * @return 字体名称（用于内容流）
     */
    public func addFont(baseFont: BaseFont, reference: PdfIndirectReference): String {
        // 检查是否已存在
        let fontKey = baseFont.name
        match (fonts.get(fontKey)) {
            case Some(resource) => resource.name
            case None => createNewFont(fontKey, baseFont, reference)
        }
    }

    private func createNewFont(fontKey: String, baseFont: BaseFont, reference: PdfIndirectReference): String {
        fontCounter += 1
        let name = "F" + fontCounter.toString()
        let resource = FontResource(baseFont, reference, name)
        fonts[fontKey] = resource
        fontNames.add(fontKey)
        name
    }

    /**
     * 获取字体名称
     */
    public func getFontName(baseFont: BaseFont): ?String {
        match (fonts.get(baseFont.name)) {
            case Some(resource) => Some(resource.name)
            case None => None
        }
    }

    /**
     * 添加 XObject（图片等）
     * @return XObject 名称
     */
    public func addXObject(reference: PdfIndirectReference): String {
        xObjectCounter += 1
        let name = "Im" + xObjectCounter.toString()
        xObjects[name] = reference
        xObjectNames.add(name)
        name
    }

    /**
     * 添加扩展图形状态
     * @return ExtGState 名称（如 GS1）
     */
    public func addExtGState(reference: PdfIndirectReference): String {
        extGStateCounter += 1
        let name = "GS" + extGStateCounter.toString()
        extGStates[name] = reference
        extGStateNames.add(name)
        name
    }

    /**
     * 添加 Pattern 资源（渐变图案等）
     * @return Pattern 名称（如 P1）
     */
    public func addPattern(reference: PdfIndirectReference): String {
        patternCounter += 1
        let name = "P" + patternCounter.toString()
        patterns[name] = reference
        patternNames.add(name)
        name
    }

    /**
     * 添加 Shading 资源（供 sh 操作符直接使用）
     * @return Shading 名称（如 Sh1）
     */
    public func addShading(reference: PdfIndirectReference): String {
        shadingCounter += 1
        let name = "Sh" + shadingCounter.toString()
        shadings[name] = reference
        shadingNames.add(name)
        name
    }

    /**
     * 生成资源字典
     */
    public func toDictionary(): PdfDictionary {
        let dict = PdfDictionary()

        // 字体资源
        if (!fontNames.isEmpty()) {
            let fontDict = PdfDictionary()
            for (key in fontNames) {
                match (fonts.get(key)) {
                    case Some(resource) => fontDict.put(PdfName(resource.name), resource.reference)
                    case None => ()
                }
            }
            dict.put(PdfName.FONT, fontDict)
        }

        // XObject 资源
        if (!xObjectNames.isEmpty()) {
            let xobjectDict = PdfDictionary()
            for (name in xObjectNames) {
                match (xObjects.get(name)) {
                    case Some(reference) => xobjectDict.put(PdfName(name), reference)
                    case None => ()
                }
            }
            dict.put(PdfName.XOBJECT, xobjectDict)
        }

        // ExtGState 资源
        if (!extGStateNames.isEmpty()) {
            let gsDict = PdfDictionary()
            for (name in extGStateNames) {
                match (extGStates.get(name)) {
                    case Some(reference) => gsDict.put(PdfName(name), reference)
                    case None => ()
                }
            }
            dict.put(PdfName.EXTGSTATE, gsDict)
        }

        // Pattern 资源
        if (!patternNames.isEmpty()) {
            let patDict = PdfDictionary()
            for (name in patternNames) {
                match (patterns.get(name)) {
                    case Some(reference) => patDict.put(PdfName(name), reference)
                    case None => ()
                }
            }
            dict.put(PdfName.PATTERN, patDict)
        }

        // Shading 资源
        if (!shadingNames.isEmpty()) {
            let shDict = PdfDictionary()
            for (name in shadingNames) {
                match (shadings.get(name)) {
                    case Some(reference) => shDict.put(PdfName(name), reference)
                    case None => ()
                }
            }
            dict.put(PdfName.SHADING, shDict)
        }

        // ProcSet
        let procSet = PdfArray()
        procSet.add(PdfName.PDF)
        procSet.add(PdfName.TEXT)
        procSet.add(PdfName.IMAGEB)
        procSet.add(PdfName.IMAGEC)
        procSet.add(PdfName.IMAGEI)
        dict.put(PdfName.PROCSET, procSet)

        dict
    }

    /**
     * 检查是否有资源
     */
    public func hasResources(): Bool {
        !fontNames.isEmpty() || !xObjectNames.isEmpty() || !extGStateNames.isEmpty() ||
        !patternNames.isEmpty() || !shadingNames.isEmpty()
    }

    /**
     * 合并另一个资源字典
     */
    public func merge(other: PdfResources): Unit {
        // 合并字体
        for (key in other.fontNames) {
            match (other.fonts.get(key)) {
                case Some(resource) => mergeFontResource(key, resource)
                case None => ()
            }
        }

        // 合并 XObject
        for (name in other.xObjectNames) {
            match (other.xObjects.get(name)) {
                case Some(reference) => mergeXObject(name, reference)
                case None => ()
            }
        }

        // 合并 ExtGState
        for (name in other.extGStateNames) {
            match (other.extGStates.get(name)) {
                case Some(reference) => mergeExtGState(name, reference)
                case None => ()
            }
        }

        // 合并 Pattern
        for (name in other.patternNames) {
            match (other.patterns.get(name)) {
                case Some(reference) => mergePattern(name, reference)
                case None => ()
            }
        }

        // 合并 Shading
        for (name in other.shadingNames) {
            match (other.shadings.get(name)) {
                case Some(reference) => mergeShading(name, reference)
                case None => ()
            }
        }
    }

    private func mergeFontResource(key: String, resource: FontResource): Unit {
        if (!fonts.contains(key)) {
            fonts[key] = resource
            fontNames.add(key)
        }
    }

    private func mergeXObject(name: String, reference: PdfIndirectReference): Unit {
        if (!xObjects.contains(name)) {
            xObjects[name] = reference
            xObjectNames.add(name)
        }
    }

    private func mergeExtGState(name: String, reference: PdfIndirectReference): Unit {
        if (!extGStates.contains(name)) {
            extGStates[name] = reference
            extGStateNames.add(name)
        }
    }

    private func mergePattern(name: String, reference: PdfIndirectReference): Unit {
        if (!patterns.contains(name)) {
            patterns[name] = reference
            patternNames.add(name)
        }
    }

    private func mergeShading(name: String, reference: PdfIndirectReference): Unit {
        if (!shadings.contains(name)) {
            shadings[name] = reference
            shadingNames.add(name)
        }
    }
}
