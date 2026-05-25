/**
 * PDF-CJ: PdfShading - 渐变（轴向 / 径向）
 * Type 2 = Axial（线性渐变）
 * Type 3 = Radial（径向渐变）
 * 颜色插值函数使用 FunctionType 2（指数型，N=1 即线性）
 */
package pdf_cj.core

import pdf_cj.base.{PdfDictionary, PdfArray, PdfName, PdfNumber, PdfBoolean}
import pdf_cj.text.Color

// ── 辅助：构建 Type 2 颜色插值函数字典 ─────────────────────────────────────

func makeShadingColorFunction(color0: Color, color1: Color): PdfDictionary {
    let fn = PdfDictionary()
    fn.put(PdfName.FUNCTIONTYPE, PdfNumber(2))

    let domain = PdfArray()
    domain.add(0.0)
    domain.add(1.0)
    fn.put(PdfName.DOMAIN, domain)

    let c0 = PdfArray()
    c0.add(Float32(color0.red) / 255.0)
    c0.add(Float32(color0.green) / 255.0)
    c0.add(Float32(color0.blue) / 255.0)
    fn.put(PdfName.C0, c0)

    let c1 = PdfArray()
    c1.add(Float32(color1.red) / 255.0)
    c1.add(Float32(color1.green) / 255.0)
    c1.add(Float32(color1.blue) / 255.0)
    fn.put(PdfName.C1, c1)

    fn.put(PdfName.N, PdfNumber(1))
    fn
}

// ── 基类 ──────────────────────────────────────────────────────────────────────

open public class PdfShading {
    public open func toDictionary(): PdfDictionary {
        PdfDictionary()
    }
}

// ── PdfAxialShading (Type 2) ─────────────────────────────────────────────────

/**
 * 轴向（线性）渐变
 *
 * 从点 (x0, y0) 的 color0 线性过渡到点 (x1, y1) 的 color1。
 * 坐标为 PDF 用户空间坐标系（左下角为原点，单位 pt）。
 *
 * 示例：
 *   let shading = PdfAxialShading(100.0, 400.0, Color.RED, 300.0, 400.0, Color.BLUE)
 */
public class PdfAxialShading <: PdfShading {
    public var x0: Float32 = 0.0
    public var y0: Float32 = 0.0
    public var color0: Color = Color.BLACK

    public var x1: Float32 = 100.0
    public var y1: Float32 = 0.0
    public var color1: Color = Color.WHITE

    public var extendBoth: Bool = true

    public init() {}

    public init(x0: Float32, y0: Float32, color0: Color,
                x1: Float32, y1: Float32, color1: Color) {
        this.x0 = x0; this.y0 = y0; this.color0 = color0
        this.x1 = x1; this.y1 = y1; this.color1 = color1
    }

    public override func toDictionary(): PdfDictionary {
        let dict = PdfDictionary()
        dict.put(PdfName.SHADINGTYPE, PdfNumber(2))
        dict.put(PdfName.COLORSPACE, PdfName.DEVICERGB)

        let coords = PdfArray()
        coords.add(x0); coords.add(y0)
        coords.add(x1); coords.add(y1)
        dict.put(PdfName.COORDS, coords)

        dict.put(PdfName.FUNCTION, makeShadingColorFunction(color0, color1))

        let ext = PdfArray()
        ext.add(PdfBoolean(extendBoth))
        ext.add(PdfBoolean(extendBoth))
        dict.put(PdfName.EXTEND, ext)

        dict
    }
}

// ── PdfRadialShading (Type 3) ─────────────────────────────────────────────────

/**
 * 径向渐变
 *
 * 从圆 (cx0, cy0, r0) 的 color0 过渡到圆 (cx1, cy1, r1) 的 color1。
 * 典型用法：cx0==cx1, cy0==cy1, r0==0 形成从中心向外扩散的效果。
 *
 * 示例：
 *   let shading = PdfRadialShading(200.0, 500.0, 0.0, Color.WHITE,
 *                                  200.0, 500.0, 80.0, Color.BLUE)
 */
public class PdfRadialShading <: PdfShading {
    public var cx0: Float32 = 0.0
    public var cy0: Float32 = 0.0
    public var r0: Float32 = 0.0
    public var color0: Color = Color.WHITE

    public var cx1: Float32 = 100.0
    public var cy1: Float32 = 0.0
    public var r1: Float32 = 50.0
    public var color1: Color = Color.BLACK

    public var extendBoth: Bool = true

    public init() {}

    public init(cx0: Float32, cy0: Float32, r0: Float32, color0: Color,
                cx1: Float32, cy1: Float32, r1: Float32, color1: Color) {
        this.cx0 = cx0; this.cy0 = cy0; this.r0 = r0; this.color0 = color0
        this.cx1 = cx1; this.cy1 = cy1; this.r1 = r1; this.color1 = color1
    }

    public override func toDictionary(): PdfDictionary {
        let dict = PdfDictionary()
        dict.put(PdfName.SHADINGTYPE, PdfNumber(3))
        dict.put(PdfName.COLORSPACE, PdfName.DEVICERGB)

        let coords = PdfArray()
        coords.add(cx0); coords.add(cy0); coords.add(r0)
        coords.add(cx1); coords.add(cy1); coords.add(r1)
        dict.put(PdfName.COORDS, coords)

        dict.put(PdfName.FUNCTION, makeShadingColorFunction(color0, color1))

        let ext = PdfArray()
        ext.add(PdfBoolean(extendBoth))
        ext.add(PdfBoolean(extendBoth))
        dict.put(PdfName.EXTEND, ext)

        dict
    }
}
