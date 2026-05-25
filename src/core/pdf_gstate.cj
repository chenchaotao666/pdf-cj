/**
 * PDF-CJ: PdfGState - 扩展图形状态
 * 封装透明度（/ca fill alpha、/CA stroke alpha）和混合模式（/BM）
 */
package pdf_cj.core

import pdf_cj.base.{PdfDictionary, PdfName, PdfNumber}

/**
 * PDF 混合模式常量
 */
public class BlendMode {
    public static let NORMAL      = "Normal"
    public static let MULTIPLY    = "Multiply"
    public static let SCREEN      = "Screen"
    public static let OVERLAY     = "Overlay"
    public static let DARKEN      = "Darken"
    public static let LIGHTEN     = "Lighten"
    public static let COLOR_DODGE = "ColorDodge"
    public static let COLOR_BURN  = "ColorBurn"
    public static let HARD_LIGHT  = "HardLight"
    public static let SOFT_LIGHT  = "SoftLight"
    public static let DIFFERENCE  = "Difference"
    public static let EXCLUSION   = "Exclusion"
}

/**
 * 扩展图形状态（ExtGState）
 *
 * 使用方法：
 *   let gs = PdfGState()
 *   gs.setFillAlpha(0.5)
 *   gs.setStrokeAlpha(0.8)
 *   gs.setBlendMode(BlendMode.MULTIPLY)
 *   let gsName = writer.addGState(gs)
 *   cb.saveState()
 *   cb.setExtGState(gsName)
 *   ...draw...
 *   cb.restoreState()
 */
public class PdfGState {
    private var _fillAlpha: Float32 = 1.0
    private var _strokeAlpha: Float32 = 1.0
    private var _blendMode: String = "Normal"
    private var _hasFillAlpha: Bool = false
    private var _hasStrokeAlpha: Bool = false
    private var _hasBlendMode: Bool = false

    public init() {}

    public func setFillAlpha(alpha: Float32): Unit {
        _fillAlpha   = alpha
        _hasFillAlpha = true
    }

    public func setStrokeAlpha(alpha: Float32): Unit {
        _strokeAlpha   = alpha
        _hasStrokeAlpha = true
    }

    public func setBlendMode(mode: String): Unit {
        _blendMode   = mode
        _hasBlendMode = true
    }

    public prop fillAlpha: Float32   { get() { _fillAlpha } }
    public prop strokeAlpha: Float32 { get() { _strokeAlpha } }
    public prop blendMode: String    { get() { _blendMode } }

    public func toDictionary(): PdfDictionary {
        let dict = PdfDictionary()
        dict.put(PdfName.TYPE, PdfName("ExtGState"))
        if (_hasFillAlpha)   { dict.put(PdfName.ca, PdfNumber(_fillAlpha)) }
        if (_hasStrokeAlpha) { dict.put(PdfName.CA, PdfNumber(_strokeAlpha)) }
        if (_hasBlendMode)   { dict.put(PdfName.BM, PdfName(_blendMode)) }
        dict
    }
}
