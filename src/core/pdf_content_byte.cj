/**
 * PDF-CJ: PdfContentByte - PDF 内容流生成器
 * 用于生成页面内容流（文本、图形等）
 */
package pdf_cj.core

import std.collection.ArrayList
import pdf_cj.base.{PdfStream, PdfName, ByteWrapper}
import pdf_cj.text.{Color, BaseFont}
import std.math.{sin, cos, tan}

/**
 * PDF 内容流生成器
 * 提供绘制文本和图形的方法
 */
public class PdfContentByte {
    private var content: ArrayList<ByteWrapper> = ArrayList<ByteWrapper>()
    private var _writer: ?PdfWriter = None
    private var inText: Bool = false

    // 图形状态栈深度
    private var stateDepth: Int32 = 0

    // 当前字体（用于 showTextAligned 宽度计算）
    private var _currentBaseFont: ?BaseFont = None
    private var _currentFontSize: Float32 = 12.0

    // 文本对齐常量（与 OpenPDF Element 对齐值保持一致）
    public static let ALIGN_LEFT: Int32 = 0
    public static let ALIGN_CENTER: Int32 = 1
    public static let ALIGN_RIGHT: Int32 = 2

    public init(writer: PdfWriter) {
        this._writer = Some(writer)
    }

    // 测试专用：不依赖真实 PdfWriter
    public init() {
        this._writer = None
    }

    /**
     * 获取 PdfWriter
     */
    public func getWriter(): PdfWriter {
        match (_writer) {
            case Some(w) => w
            case None => throw Exception("PdfContentByte: writer not initialized")
        }
    }

    // ===== 文本操作 =====

    /**
     * 开始文本块
     */
    public func beginText(): Unit {
        if (inText) {
            return
        }
        inText = true
        appendString("BT")
        appendNewLine()
    }

    /**
     * 结束文本块
     */
    public func endText(): Unit {
        if (!inText) {
            return
        }
        inText = false
        appendString("ET")
        appendNewLine()
    }

    /**
     * 设置字体和大小
     */
    public func setFontAndSize(fontName: String, size: Float32): Unit {
        appendString("/")
        appendString(fontName)
        appendSpace()
        appendFloat(size)
        appendString(" Tf")
        appendNewLine()
    }

    /**
     * 设置字体和大小（同时追踪 BaseFont，供 showTextAligned 计算宽度使用）
     */
    public func setFontAndSize(baseFont: BaseFont, name: String, size: Float32): Unit {
        _currentBaseFont = Some(baseFont)
        _currentFontSize = size
        setFontAndSize(name, size)
    }

    /**
     * 在绝对坐标处显示对齐文本（需在 BT/ET 块内调用）
     * @param align   对齐方式：ALIGN_LEFT / ALIGN_CENTER / ALIGN_RIGHT
     * @param text    文本内容
     * @param x       锚点 x 坐标（LEFT=左边缘，CENTER=中心，RIGHT=右边缘）
     * @param y       锚点 y 坐标
     * @param rotation 旋转角度（度，逆时针）
     */
    public func showTextAligned(align: Int32, text: String, x: Float32, y: Float32, rotation: Float32): Unit {
        var textWidth: Float32 = 0.0
        var useUnicode = false
        match (_currentBaseFont) {
            case Some(bf) =>
                textWidth = bf.getWidthPoint(text, _currentFontSize)
                useUnicode = bf.isUnicodeEncoding()
            case None => ()
        }

        let PI = 3.14159265358979
        var adjX = x
        var adjY = y

        if (rotation == 0.0) {
            if (align == ALIGN_CENTER) {
                adjX = x - textWidth / 2.0
            } else if (align == ALIGN_RIGHT) {
                adjX = x - textWidth
            }
            setTextMatrix(adjX, adjY)
        } else {
            let rad = Float64(rotation) * PI / 180.0
            let cosR = cos(rad)
            let sinR = sin(rad)
            var offset: Float32 = 0.0
            if (align == ALIGN_CENTER) {
                offset = textWidth / 2.0
            } else if (align == ALIGN_RIGHT) {
                offset = textWidth
            }
            // 沿旋转方向回退 offset，使锚点对应到文字末尾/中点
            adjX = x - Float32(Float64(offset) * cosR)
            adjY = y - Float32(Float64(offset) * sinR)
            setTextMatrix(Float32(cosR), Float32(sinR), Float32(-sinR), Float32(cosR), adjX, adjY)
        }

        showText(text, useUnicode, _currentBaseFont)
    }

    /**
     * 设置文本矩阵（定位文本）
     */
    public func setTextMatrix(x: Float32, y: Float32): Unit {
        appendFloat(1.0)
        appendSpace()
        appendFloat(0.0)
        appendSpace()
        appendFloat(0.0)
        appendSpace()
        appendFloat(1.0)
        appendSpace()
        appendFloat(x)
        appendSpace()
        appendFloat(y)
        appendString(" Tm")
        appendNewLine()
    }

    /**
     * 设置文本矩阵（完整版）
     */
    public func setTextMatrix(a: Float32, b: Float32, c: Float32, d: Float32, x: Float32, y: Float32): Unit {
        appendFloat(a)
        appendSpace()
        appendFloat(b)
        appendSpace()
        appendFloat(c)
        appendSpace()
        appendFloat(d)
        appendSpace()
        appendFloat(x)
        appendSpace()
        appendFloat(y)
        appendString(" Tm")
        appendNewLine()
    }

    /**
     * 显示文本（自动检测编码）
     */
    public func showText(text: String): Unit {
        showText(text, false, None)
    }

    /**
     * 显示文本
     * @param text 文本内容
     * @param useUnicode 是否使用 Unicode 编码（十六进制字符串）
     */
    public func showText(text: String, useUnicode: Bool): Unit {
        showText(text, useUnicode, None)
    }

    /**
     * 显示文本（带字体参数）
     * @param text 文本内容
     * @param useUnicode 是否使用 Unicode 编码
     * @param baseFont 用于 Unicode 到 Glyph ID 转换的字体（可选）
     */
    public func showText(text: String, useUnicode: Bool, baseFont: ?BaseFont): Unit {
        if (useUnicode) {
            showTextUnicode(text, baseFont)
        } else {
            showTextLatin(text)
        }
    }

    /**
     * 显示文本（拉丁编码，括号字符串）
     */
    private func showTextLatin(text: String): Unit {
        appendString("(")
        appendEscapedString(text)
        appendString(") Tj")
        appendNewLine()
    }

    /**
     * 显示文本（Unicode 编码，十六进制字符串）
     * @param text 文本内容
     * @param baseFont 用于 Unicode 到 Glyph ID 转换的字体
     */
    private func showTextUnicode(text: String, baseFont: ?BaseFont): Unit {
        appendString("<")
        appendHexStringWithFont(text, baseFont)
        appendString("> Tj")
        appendNewLine()
    }

    /**
     * 移动文本位置
     */
    public func moveText(x: Float32, y: Float32): Unit {
        appendFloat(x)
        appendSpace()
        appendFloat(y)
        appendString(" Td")
        appendNewLine()
    }

    /**
     * 设置行距并移动
     */
    public func setLeading(leading: Float32): Unit {
        appendFloat(leading)
        appendString(" TL")
        appendNewLine()
    }

    /**
     * 换行
     */
    public func newlineText(): Unit {
        appendString("T*")
        appendNewLine()
    }

    /**
     * 显示文本并换行
     */
    public func showTextLine(text: String): Unit {
        appendString("(")
        appendEscapedString(text)
        appendString(") '")
        appendNewLine()
    }

    /**
     * 设置字符间距
     */
    public func setCharacterSpacing(spacing: Float32): Unit {
        appendFloat(spacing)
        appendString(" Tc")
        appendNewLine()
    }

    /**
     * 设置字间距
     */
    public func setWordSpacing(spacing: Float32): Unit {
        appendFloat(spacing)
        appendString(" Tw")
        appendNewLine()
    }

    /**
     * 设置水平缩放
     */
    public func setHorizontalScaling(scale: Float32): Unit {
        appendFloat(scale)
        appendString(" Tz")
        appendNewLine()
    }

    /**
     * 设置文本渲染模式
     */
    public func setTextRenderingMode(mode: Int32): Unit {
        appendInt(mode)
        appendString(" Tr")
        appendNewLine()
    }

    /**
     * 设置文本上升
     */
    public func setTextRise(rise: Float32): Unit {
        appendFloat(rise)
        appendString(" Ts")
        appendNewLine()
    }

    // ===== 颜色操作 =====

    /**
     * 设置填充颜色（RGB）
     */
    public func setColorFill(color: Color): Unit {
        appendFloat(Float32(color.red) / 255.0)
        appendSpace()
        appendFloat(Float32(color.green) / 255.0)
        appendSpace()
        appendFloat(Float32(color.blue) / 255.0)
        appendString(" rg")
        appendNewLine()
    }

    /**
     * 设置描边颜色（RGB）
     */
    public func setColorStroke(color: Color): Unit {
        appendFloat(Float32(color.red) / 255.0)
        appendSpace()
        appendFloat(Float32(color.green) / 255.0)
        appendSpace()
        appendFloat(Float32(color.blue) / 255.0)
        appendString(" RG")
        appendNewLine()
    }

    /**
     * 设置填充颜色（灰度）
     */
    public func setGrayFill(gray: Float32): Unit {
        appendFloat(gray)
        appendString(" g")
        appendNewLine()
    }

    /**
     * 设置描边颜色（灰度）
     */
    public func setGrayStroke(gray: Float32): Unit {
        appendFloat(gray)
        appendString(" G")
        appendNewLine()
    }

    /**
     * 设置填充颜色（CMYK，各分量 0.0-1.0）
     */
    public func setCMYKColorFill(c: Float32, m: Float32, y: Float32, k: Float32): Unit {
        appendFloat(c)
        appendSpace()
        appendFloat(m)
        appendSpace()
        appendFloat(y)
        appendSpace()
        appendFloat(k)
        appendString(" k")
        appendNewLine()
    }

    /**
     * 设置描边颜色（CMYK，各分量 0.0-1.0）
     */
    public func setCMYKColorStroke(c: Float32, m: Float32, y: Float32, k: Float32): Unit {
        appendFloat(c)
        appendSpace()
        appendFloat(m)
        appendSpace()
        appendFloat(y)
        appendSpace()
        appendFloat(k)
        appendString(" K")
        appendNewLine()
    }

    // ===== 图形状态 =====

    /**
     * 保存图形状态
     */
    public func saveState(): Unit {
        stateDepth += 1
        appendString("q")
        appendNewLine()
    }

    /**
     * 恢复图形状态
     */
    public func restoreState(): Unit {
        if (stateDepth > 0) {
            stateDepth -= 1
            appendString("Q")
            appendNewLine()
        }
    }

    /**
     * 设置线宽
     */
    public func setLineWidth(width: Float32): Unit {
        appendFloat(width)
        appendString(" w")
        appendNewLine()
    }

    /**
     * 设置线帽样式
     */
    public func setLineCap(style: Int32): Unit {
        appendInt(style)
        appendString(" J")
        appendNewLine()
    }

    /**
     * 设置线连接样式
     */
    public func setLineJoin(style: Int32): Unit {
        appendInt(style)
        appendString(" j")
        appendNewLine()
    }

    /**
     * 设置斜接限制
     */
    public func setMiterLimit(limit: Float32): Unit {
        appendFloat(limit)
        appendString(" M")
        appendNewLine()
    }

    /**
     * 取消虚线（恢复实线）
     */
    public func setLineDash(phase: Float32): Unit {
        appendString("[] ")
        appendFloat(phase)
        appendString(" d")
        appendNewLine()
    }

    /**
     * 设置等长虚线
     * @param on    实线长度（点）
     * @param off   间隔长度（点）
     * @param phase 相位偏移（点）
     */
    public func setLineDash(on: Float32, off: Float32, phase: Float32): Unit {
        appendString("[")
        appendFloat(on)
        appendSpace()
        appendFloat(off)
        appendString("] ")
        appendFloat(phase)
        appendString(" d")
        appendNewLine()
    }

    /**
     * 设置自定义虚线模式（任意段数）
     * @param pattern 交替实线/间隔长度数组（点）
     * @param phase   相位偏移（点）
     */
    public func setLineDash(pattern: Array<Float32>, phase: Float32): Unit {
        appendString("[")
        var i = 0
        while (i < pattern.size) {
            if (i > 0) { appendSpace() }
            appendFloat(pattern[i])
            i += 1
        }
        appendString("] ")
        appendFloat(phase)
        appendString(" d")
        appendNewLine()
    }

    // ===== 路径操作 =====

    /**
     * 移动到点
     */
    public func moveTo(x: Float32, y: Float32): Unit {
        appendFloat(x)
        appendSpace()
        appendFloat(y)
        appendString(" m")
        appendNewLine()
    }

    /**
     * 画直线到点
     */
    public func lineTo(x: Float32, y: Float32): Unit {
        appendFloat(x)
        appendSpace()
        appendFloat(y)
        appendString(" l")
        appendNewLine()
    }

    /**
     * 画贝塞尔曲线
     */
    public func curveTo(x1: Float32, y1: Float32, x2: Float32, y2: Float32, x3: Float32, y3: Float32): Unit {
        appendFloat(x1)
        appendSpace()
        appendFloat(y1)
        appendSpace()
        appendFloat(x2)
        appendSpace()
        appendFloat(y2)
        appendSpace()
        appendFloat(x3)
        appendSpace()
        appendFloat(y3)
        appendString(" c")
        appendNewLine()
    }

    /**
     * 关闭路径
     */
    public func closePath(): Unit {
        appendString("h")
        appendNewLine()
    }

    /**
     * 描边路径
     */
    public func stroke(): Unit {
        appendString("S")
        appendNewLine()
    }

    /**
     * 关闭并描边路径
     */
    public func closePathStroke(): Unit {
        appendString("s")
        appendNewLine()
    }

    /**
     * 填充路径
     */
    public func fill(): Unit {
        appendString("f")
        appendNewLine()
    }

    /**
     * 使用奇偶规则填充
     */
    public func eoFill(): Unit {
        appendString("f*")
        appendNewLine()
    }

    /**
     * 填充并描边
     */
    public func fillStroke(): Unit {
        appendString("B")
        appendNewLine()
    }

    /**
     * 关闭、填充并描边
     */
    public func closePathFillStroke(): Unit {
        appendString("b")
        appendNewLine()
    }

    /**
     * 使用奇偶规则填充并描边
     */
    public func eoFillStroke(): Unit {
        appendString("B*")
        appendNewLine()
    }

    /**
     * 结束路径（不绘制）
     */
    public func newPath(): Unit {
        appendString("n")
        appendNewLine()
    }

    /**
     * 用当前路径设置裁剪区域（非零绕数规则）
     * 注意：clip() 必须在 stroke()/fill()/newPath() 之前调用
     */
    public func clip(): Unit {
        appendString("W")
        appendNewLine()
    }

    /**
     * 用当前路径设置裁剪区域（奇偶规则）
     */
    public func eoClip(): Unit {
        appendString("W*")
        appendNewLine()
    }

    // ===== 矩形 =====

    /**
     * 画矩形
     */
    public func rectangle(x: Float32, y: Float32, width: Float32, height: Float32): Unit {
        appendFloat(x)
        appendSpace()
        appendFloat(y)
        appendSpace()
        appendFloat(width)
        appendSpace()
        appendFloat(height)
        appendString(" re")
        appendNewLine()
    }

    /**
     * 画圆角矩形
     * @param x      左下角 x
     * @param y      左下角 y
     * @param width  宽度
     * @param height 高度
     * @param radius 圆角半径
     */
    public func roundRectangle(x: Float32, y: Float32, width: Float32, height: Float32, radius: Float32): Unit {
        // k = 0.5523 是用贝塞尔曲线近似四分之一圆弧的最优控制点系数
        let k = radius * 0.5523
        moveTo(x + radius, y)
        lineTo(x + width - radius, y)
        curveTo(x + width - radius + k, y, x + width, y + radius - k, x + width, y + radius)
        lineTo(x + width, y + height - radius)
        curveTo(x + width, y + height - radius + k, x + width - radius + k, y + height, x + width - radius, y + height)
        lineTo(x + radius, y + height)
        curveTo(x + radius - k, y + height, x, y + height - radius + k, x, y + height - radius)
        lineTo(x, y + radius)
        curveTo(x, y + radius - k, x + radius - k, y, x + radius, y)
        closePath()
    }

    /**
     * 画椭圆（以外接矩形定义）
     * @param x1 外接矩形左下角 x
     * @param y1 外接矩形左下角 y
     * @param x2 外接矩形右上角 x
     * @param y2 外接矩形右上角 y
     */
    public func ellipse(x1: Float32, y1: Float32, x2: Float32, y2: Float32): Unit {
        arc(x1, y1, x2, y2, 0.0, 360.0)
    }

    /**
     * 画弧线（贝塞尔近似，精度 ≤ 0.03%）
     * @param x1        外接矩形左下角 x
     * @param y1        外接矩形左下角 y
     * @param x2        外接矩形右上角 x
     * @param y2        外接矩形右上角 y
     * @param startAngle 起始角度（度，0=右，逆时针为正）
     * @param extent    扫过角度（度，正=逆时针，负=顺时针）
     */
    public func arc(x1: Float32, y1: Float32, x2: Float32, y2: Float32, startAngle: Float32, extent: Float32): Unit {
        let PI = 3.14159265358979
        let cx = Float64((x1 + x2) / 2.0)
        let cy = Float64((y1 + y2) / 2.0)
        let rx = Float64((x2 - x1) / 2.0)
        let ry = Float64((y2 - y1) / 2.0)

        // 每次最多处理 90°，sign 决定扫描方向
        let sign = if (extent >= 0.0) { 1.0 } else { -1.0 }
        var rem = Float64(extent)
        var startA = Float64(startAngle)
        var first = true

        while (rem * sign > 0.001) {
            let step = if (rem * sign > 90.0) { 90.0 * sign } else { rem }
            let angRad = startA * PI / 180.0
            let stepRad = step * PI / 180.0

            // (4/3)*tan(α/4) 是贝塞尔近似圆弧的最优系数
            let k = (4.0 / 3.0) * tan(stepRad / 4.0)

            let cosA = cos(angRad)
            let sinA = sin(angRad)
            let cosE = cos(angRad + stepRad)
            let sinE = sin(angRad + stepRad)

            let sx = Float32(cx + rx * cosA)
            let sy = Float32(cy + ry * sinA)
            let ex = Float32(cx + rx * cosE)
            let ey = Float32(cy + ry * sinE)
            let c1x = Float32(cx + rx * (cosA - k * sinA))
            let c1y = Float32(cy + ry * (sinA + k * cosA))
            let c2x = Float32(cx + rx * (cosE + k * sinE))
            let c2y = Float32(cy + ry * (sinE - k * cosE))

            if (first) {
                moveTo(sx, sy)
                first = false
            }
            curveTo(c1x, c1y, c2x, c2y, ex, ey)

            startA += step
            rem -= step
        }
    }

    // ===== 变换 =====

    /**
     * 拼接变换矩阵
     */
    public func concatCTM(a: Float32, b: Float32, c: Float32, d: Float32, e: Float32, f: Float32): Unit {
        appendFloat(a)
        appendSpace()
        appendFloat(b)
        appendSpace()
        appendFloat(c)
        appendSpace()
        appendFloat(d)
        appendSpace()
        appendFloat(e)
        appendSpace()
        appendFloat(f)
        appendString(" cm")
        appendNewLine()
    }

    // ===== XObject =====

    /**
     * 绘制 XObject
     */
    public func addXObject(name: String): Unit {
        appendString("/")
        appendString(name)
        appendString(" Do")
        appendNewLine()
    }

    // ===== 输出 =====

    /**
     * 转换为流对象
     */
    public func toStream(): PdfStream {
        let stream = PdfStream()
        let bytes = toByteArray()
        stream.setContent(bytes)
        stream
    }

    /**
     * 获取字节数组
     */
    public func toByteArray(): Array<Byte> {
        let arr = Array<Byte>(content.size, repeat: UInt8(0))
        var i = 0
        for (wrapper in content) {
            arr[i] = wrapper.value
            i += 1
        }
        arr
    }

    /**
     * 获取内容大小
     */
    public prop size: Int64 {
        get() { content.size }
    }

    /**
     * 重置内容（清除所有已生成的操作符和追踪状态）
     */
    public func reset(): Unit {
        content = ArrayList<ByteWrapper>()
        inText = false
        stateDepth = 0
        _currentBaseFont = None
        _currentFontSize = 12.0
    }

    // ===== 内部辅助方法 =====

    private func appendByte(b: Byte): Unit {
        content.add(ByteWrapper(b))
    }

    private func appendString(s: String): Unit {
        for (c in s) {
            content.add(ByteWrapper(UInt8(c)))
        }
    }

    private func appendEscapedString(s: String): Unit {
        for (c in s) {
            let code = UInt32(c)
            if (code == 0x28) {  // (
                content.add(ByteWrapper(UInt8(0x5C)))
                content.add(ByteWrapper(UInt8(0x28)))
            } else if (code == 0x29) {  // )
                content.add(ByteWrapper(UInt8(0x5C)))
                content.add(ByteWrapper(UInt8(0x29)))
            } else if (code == 0x5C) {  // backslash
                content.add(ByteWrapper(UInt8(0x5C)))
                content.add(ByteWrapper(UInt8(0x5C)))
            } else {
                content.add(ByteWrapper(UInt8(code)))
            }
        }
    }

    /**
     * 将字符串编码为十六进制格式（使用 Glyph ID）
     * 对于 TrueType 字体，将 Unicode 转换为 Glyph ID
     * @param s 文本内容
     * @param baseFont 用于转换的字体，如果为 None 则使用 Unicode 码点
     */
    private func appendHexStringWithFont(s: String, baseFont: ?BaseFont): Unit {
        // 遍历每个 Unicode 字符
        for (rune in s.runes()) {
            let code = UInt32(rune)

            // 获取 Glyph ID
            let glyphId: UInt16 = match (baseFont) {
                case Some(font) =>
                    // 使用字体的 cmap 表转换 Unicode 到 Glyph ID
                    let gid = font.getGlyphId(code)
                    if (gid == 0 && code != 0) {
                        // 如果字体中没有找到字形，尝试使用 Unicode 码点作为后备
                        // 这对于某些简单字体可能有效
                        if (code <= 0xFFFF) {
                            UInt16(code)
                        } else {
                            UInt16(0)  // 超出 BMP 的字符，使用 .notdef
                        }
                    } else {
                        gid
                    }
                case None =>
                    // 没有字体信息，直接使用 Unicode 码点（旧行为）
                    if (code <= 0xFFFF) {
                        UInt16(code)
                    } else {
                        UInt16(0)
                    }
            }

            // 输出 2 字节的 Glyph ID（Big Endian）
            let high = UInt8((glyphId >> 8) & 0xFF)
            let low = UInt8(glyphId & 0xFF)
            appendByteAsHex(high)
            appendByteAsHex(low)
        }
    }

    /**
     * 将字符串编码为 UTF-16BE 十六进制格式（旧方法，保留兼容性）
     * 格式：FEFF + UTF-16BE 编码的字符
     */
    private func appendHexString(s: String): Unit {
        // BOM (Byte Order Mark) for UTF-16BE
        appendString("FEFF")

        // 将每个字符转换为 UTF-16BE 编码的十六进制
        // 重要：使用 runes() 来遍历 Unicode 字符，而不是 UTF-8 字节
        for (rune in s.runes()) {
            let code = UInt32(rune)

            if (code <= 0xFFFF) {
                // BMP (Basic Multilingual Plane) - 使用 2 字节
                let high = UInt8((code >> 8) & 0xFF)
                let low = UInt8(code & 0xFF)
                appendByteAsHex(high)
                appendByteAsHex(low)
            } else {
                // 补充平面 - 使用代理对（surrogate pair）
                let adjusted = code - 0x10000
                let highSurrogate = 0xD800 + ((adjusted >> 10) & 0x3FF)
                let lowSurrogate = 0xDC00 + (adjusted & 0x3FF)

                // 输出高代理
                appendByteAsHex(UInt8((highSurrogate >> 8) & 0xFF))
                appendByteAsHex(UInt8(highSurrogate & 0xFF))

                // 输出低代理
                appendByteAsHex(UInt8((lowSurrogate >> 8) & 0xFF))
                appendByteAsHex(UInt8(lowSurrogate & 0xFF))
            }
        }
    }

    /**
     * 将字节输出为两位十六进制
     */
    private func appendByteAsHex(b: UInt8): Unit {
        let hexChars = "0123456789ABCDEF"
        let high = Int64((b >> 4) & 0x0F)
        let low = Int64(b & 0x0F)
        content.add(ByteWrapper(UInt8(hexChars[high])))
        content.add(ByteWrapper(UInt8(hexChars[low])))
    }

    private func appendSpace(): Unit {
        content.add(ByteWrapper(UInt8(0x20)))
    }

    private func appendNewLine(): Unit {
        content.add(ByteWrapper(UInt8(0x0A)))
    }

    private func appendInt(value: Int32): Unit {
        appendString(value.toString())
    }

    private func appendFloat(value: Float32): Unit {
        let intPart = Int32(value)
        if (Float32(intPart) == value) {
            appendString(intPart.toString())
        } else {
            appendString(formatFloat(value))
        }
    }

    private func formatFloat(value: Float32): String {
        var s = value.toString()
        if (s.contains(".")) {
            while (s.endsWith("0") && !s.endsWith(".0")) {
                s = s[0..s.size-1]
            }
            if (s.endsWith(".0")) {
                s = s[0..s.size-2]
            }
        }
        s
    }
}
