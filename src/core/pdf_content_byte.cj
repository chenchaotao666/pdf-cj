/**
 * PDF-CJ: PdfContentByte - PDF 内容流生成器
 * 用于生成页面内容流（文本、图形等）
 */
package pdf_cj.core

import std.collection.ArrayList
import pdf_cj.base.{PdfStream, PdfName, ByteWrapper}
import pdf_cj.text.{Color, BaseFont}

/**
 * PDF 内容流生成器
 * 提供绘制文本和图形的方法
 */
public class PdfContentByte {
    private var content: ArrayList<ByteWrapper> = ArrayList<ByteWrapper>()
    private var _writer: PdfWriter
    private var inText: Bool = false

    // 图形状态栈深度
    private var stateDepth: Int32 = 0

    public init(writer: PdfWriter) {
        this._writer = writer
    }

    /**
     * 获取 PdfWriter
     */
    public func getWriter(): PdfWriter {
        _writer
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
     * 设置虚线模式
     */
    public func setLineDash(phase: Float32): Unit {
        appendString("[] ")
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
     * 重置内容
     */
    public func reset(): Unit {
        content = ArrayList<ByteWrapper>()
        inText = false
        stateDepth = 0
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
