/**
 * PDF-CJ: FontDetails - 字体详情管理
 * 管理字体在 PDF 中的嵌入详情
 */
package pdf_cj.text

import std.collection.{HashMap, ArrayList}
import pdf_cj.base.{PdfIndirectReference, PdfDictionary, PdfName}

/**
 * 字体详情类
 * 管理字体的 PDF 对象引用和使用情况
 */
public class FontDetails {
    private var fontName: String
    private var baseFont: BaseFont
    private var fontReference: ?PdfIndirectReference = None
    private var fontDescriptorRef: ?PdfIndirectReference = None
    private var fontFileRef: ?PdfIndirectReference = None

    // 字体使用跟踪
    private var usedGlyphs: HashMap<UInt16, Bool> = HashMap<UInt16, Bool>()
    private var usedChars: HashMap<UInt32, Bool> = HashMap<UInt32, Bool>()

    // 子集化状态
    private var subset: Bool = false
    private var subsetPrefix: String = ""

    // 字体字典
    private var fontDictionary: ?PdfDictionary = None

    /**
     * 构造函数
     * @param fontName 字体名称
     * @param font 基础字体对象
     * @param subset 是否进行子集化
     */
    public init(fontName: String, font: BaseFont, subset: Bool) {
        this.fontName = fontName
        this.baseFont = font
        this.subset = subset

        if (subset) {
            // 生成子集前缀（简化：使用固定前缀）
            this.subsetPrefix = generateSubsetPrefix()
        }
    }

    /**
     * 生成子集前缀
     * 应该生成 6 个大写字母的随机前缀
     */
    private func generateSubsetPrefix(): String {
        // 简化实现：使用固定前缀
        // 实际应该生成随机的 6 个字母，如 "ABCDEF"
        "SUBSET"
    }

    /**
     * 获取字体名称（包含子集前缀）
     */
    public func getFontName(): String {
        if (subset && subsetPrefix.size > 0) {
            return "${subsetPrefix}+${fontName}"
        }
        fontName
    }

    /**
     * 获取原始字体名称（不含子集前缀）
     */
    public func getBaseFontName(): String {
        fontName
    }

    /**
     * 获取基础字体对象
     */
    public func getBaseFont(): BaseFont {
        baseFont
    }

    /**
     * 设置字体引用
     */
    public func setFontReference(ref: PdfIndirectReference): Unit {
        this.fontReference = Some(ref)
    }

    /**
     * 获取字体引用
     */
    public func getFontReference(): ?PdfIndirectReference {
        fontReference
    }

    /**
     * 设置字体描述符引用
     */
    public func setFontDescriptorReference(ref: PdfIndirectReference): Unit {
        this.fontDescriptorRef = Some(ref)
    }

    /**
     * 获取字体描述符引用
     */
    public func getFontDescriptorReference(): ?PdfIndirectReference {
        fontDescriptorRef
    }

    /**
     * 设置字体文件引用
     */
    public func setFontFileReference(ref: PdfIndirectReference): Unit {
        this.fontFileRef = Some(ref)
    }

    /**
     * 获取字体文件引用
     */
    public func getFontFileReference(): ?PdfIndirectReference {
        fontFileRef
    }

    /**
     * 标记字形为已使用
     * @param glyphId 字形 ID
     */
    public func markGlyphUsed(glyphId: UInt16): Unit {
        usedGlyphs[glyphId] = true

        // 如果基础字体支持子集化，同时标记
        baseFont.markGlyphUsed(glyphId)
    }

    /**
     * 标记字符为已使用
     * @param unicode Unicode 码点
     */
    public func markCharUsed(unicode: UInt32): Unit {
        usedChars[unicode] = true

        // 标记对应的字形
        let glyphId = baseFont.getGlyphId(unicode)
        if (glyphId != 0) {
            markGlyphUsed(glyphId)
        }

        // 如果基础字体支持子集化，同时标记
        baseFont.markCharUsed(unicode)
    }

    /**
     * 标记字符串中的所有字符为已使用
     * @param text 文本字符串
     */
    public func markStringUsed(text: String): Unit {
        for (ch in text) {
            let unicode = UInt32(Int64(ch))
            markCharUsed(unicode)
        }
    }

    /**
     * 检查字形是否被使用
     * @param glyphId 字形 ID
     * @return 是否被使用
     */
    public func isGlyphUsed(glyphId: UInt16): Bool {
        match (usedGlyphs.get(glyphId)) {
            case Some(_) => true
            case None => false
        }
    }

    /**
     * 检查字符是否被使用
     * @param unicode Unicode 码点
     * @return 是否被使用
     */
    public func isCharUsed(unicode: UInt32): Bool {
        match (usedChars.get(unicode)) {
            case Some(_) => true
            case None => false
        }
    }

    /**
     * 获取使用的字形数量
     */
    public func getUsedGlyphCount(): Int64 {
        usedGlyphs.size
    }

    /**
     * 获取使用的字符数量
     */
    public func getUsedCharCount(): Int64 {
        usedChars.size
    }

    /**
     * 是否进行子集化
     */
    public func isSubset(): Bool {
        subset
    }

    /**
     * 设置字体字典
     */
    public func setFontDictionary(dict: PdfDictionary): Unit {
        this.fontDictionary = Some(dict)
    }

    /**
     * 获取字体字典
     */
    public func getFontDictionary(): ?PdfDictionary {
        fontDictionary
    }

    /**
     * 获取所有使用的字形 ID 列表
     */
    public func getUsedGlyphIds(): Array<UInt16> {
        let result = ArrayList<UInt16>()
        for ((gid, _) in usedGlyphs) {
            result.add(gid)
        }

        // 排序
        for (i in 0..result.size) {
            for (j in 0..(result.size - i - 1)) {
                if (result[j] > result[j + 1]) {
                    let temp = result[j]
                    result[j] = result[j + 1]
                    result[j + 1] = temp
                }
            }
        }

        // 转换为数组
        let arr = Array<UInt16>(result.size, repeat: UInt16(0))
        for (i in 0..result.size) {
            arr[i] = result[i]
        }
        arr
    }

    /**
     * 获取所有使用的 Unicode 字符列表
     */
    public func getUsedChars(): Array<UInt32> {
        let result = ArrayList<UInt32>()
        for ((unicode, _) in usedChars) {
            result.add(unicode)
        }

        // 排序
        for (i in 0..result.size) {
            for (j in 0..(result.size - i - 1)) {
                if (result[j] > result[j + 1]) {
                    let temp = result[j]
                    result[j] = result[j + 1]
                    result[j + 1] = temp
                }
            }
        }

        // 转换为数组
        let arr = Array<UInt32>(result.size, repeat: UInt32(0))
        for (i in 0..result.size) {
            arr[i] = result[i]
        }
        arr
    }

    /**
     * 获取字体详情信息（用于调试）
     */
    public func getInfo(): String {
        var info = "Font Details:\n"
        info = "${info}  Name: ${getFontName()}\n"
        info = "${info}  Subset: ${subset}\n"
        info = "${info}  Used Glyphs: ${usedGlyphs.size}\n"
        info = "${info}  Used Chars: ${usedChars.size}\n"

        match (fontReference) {
            case Some(ref) => info = "${info}  Reference: (object reference)\n"
            case None => info = "${info}  Reference: None\n"
        }

        info
    }
}

/**
 * 字体详情管理器
 * 管理文档中所有字体的详情
 */
public class FontDetailsManager {
    private var fontDetails: HashMap<String, FontDetails> = HashMap<String, FontDetails>()

    /**
     * 添加字体详情
     * @param name 字体名称
     * @param details 字体详情
     */
    public func addFont(name: String, details: FontDetails): Unit {
        fontDetails[name] = details
    }

    /**
     * 获取字体详情
     * @param name 字体名称
     * @return 字体详情，如果不存在返回 None
     */
    public func getFont(name: String): ?FontDetails {
        fontDetails.get(name)
    }

    /**
     * 检查字体是否存在
     * @param name 字体名称
     * @return 是否存在
     */
    public func hasFont(name: String): Bool {
        fontDetails.contains(name)
    }

    /**
     * 获取所有字体名称
     */
    public func getFontNames(): Array<String> {
        let result = ArrayList<String>()
        for ((name, _) in fontDetails) {
            result.add(name)
        }

        let arr = Array<String>(result.size, repeat: "")
        for (i in 0..result.size) {
            arr[i] = result[i]
        }
        arr
    }

    /**
     * 获取字体数量
     */
    public func getFontCount(): Int64 {
        fontDetails.size
    }

    /**
     * 清空所有字体
     */
    public func clear(): Unit {
        fontDetails.clear()
    }
}
