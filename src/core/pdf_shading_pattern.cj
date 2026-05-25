/**
 * PDF-CJ: PdfShadingPattern - 渐变填充图案（PatternType 2）
 * 将 PdfShading 封装为 Pattern 资源，供 /Pattern cs + /Pn scn 使用。
 */
package pdf_cj.core

import pdf_cj.base.{PdfDictionary, PdfArray, PdfName, PdfNumber}

/**
 * 渐变填充图案（Pattern Type 2）
 *
 * 使用方法：
 *   let shading = PdfAxialShading(...)
 *   let pattern = PdfShadingPattern(shading)
 *   let patName = writer.addShadingPattern(pattern)
 *   cb.saveState()
 *   cb.setColorFillPattern(patName)
 *   cb.rectangle(...)
 *   cb.fill()
 *   cb.restoreState()
 */
public class PdfShadingPattern {
    private var _shading: PdfShading
    // 变换矩阵，默认为单位矩阵
    private var _matrix: Array<Float32> = [1.0, 0.0, 0.0, 1.0, 0.0, 0.0]

    public init(shading: PdfShading) {
        _shading = shading
    }

    public func setMatrix(a: Float32, b: Float32, c: Float32,
                          d: Float32, e: Float32, f: Float32): Unit {
        _matrix = [a, b, c, d, e, f]
    }

    public func toDictionary(): PdfDictionary {
        let dict = PdfDictionary()
        dict.put(PdfName.TYPE, PdfName.PATTERN)
        dict.put(PdfName.PATTERNTYPE, PdfNumber(2))
        dict.put(PdfName.SHADING, _shading.toDictionary())

        let m = PdfArray()
        var i: Int64 = 0
        while (i < 6) {
            m.add(_matrix[i])
            i += 1
        }
        dict.put(PdfName.MATRIX, m)
        dict
    }
}
