/**
 * PDF-CJ: PdfString - PDF 字符串对象
 */
package pdf_cj.base

/**
 * PDF 字符串编码类型
 */
public enum PdfStringEncoding <: Equatable<PdfStringEncoding> {
    | Text       // 普通文本 (括号分隔)
    | Hex        // 十六进制 (尖括号分隔)
    | Unicode    // Unicode (带 BOM)

    public operator func ==(other: PdfStringEncoding): Bool {
        match ((this, other)) {
            case (Text, Text) => true
            case (Hex, Hex) => true
            case (Unicode, Unicode) => true
            case _ => false
        }
    }

    public operator func !=(other: PdfStringEncoding): Bool {
        !(this == other)
    }
}

/**
 * PDF 字符串对象
 */
public class PdfString <: PdfObjectBase {
    private var _value: String
    private var _encoding: PdfStringEncoding
    private var _bytes: ?Array<Byte> = None

    /**
     * 从字符串创建（自动检测编码：含非 ASCII 字符时使用 UTF-16BE Unicode 编码）
     */
    public init(value: String) {
        this._value = value
        var needsUnicode = false
        for (c in value.runes()) {
            if (UInt32(c) > 0x7Eu32) {
                needsUnicode = true
                break
            }
        }
        this._encoding = if (needsUnicode) { PdfStringEncoding.Unicode } else { PdfStringEncoding.Text }
    }

    /**
     * 从字符串创建（指定编码）
     */
    public init(value: String, encoding: PdfStringEncoding) {
        this._value = value
        this._encoding = encoding
    }

    /**
     * 从字节数组创建
     */
    public init(bytes: Array<Byte>) {
        this._bytes = Some(bytes)
        this._value = ""
        this._encoding = PdfStringEncoding.Hex
    }

    /**
     * 获取字符串值
     */
    public prop value: String {
        get() { _value }
    }

    /**
     * 获取编码类型
     */
    public prop encoding: PdfStringEncoding {
        get() { _encoding }
    }

    public override func getType(): PdfObjectType {
        PdfObjectType.String
    }

    public override func writeTo(os: PdfOutputStream): Unit {
        match (_encoding) {
            case Text => writeTextString(os)
            case Hex => writeHexString(os)
            case Unicode => writeUnicodeString(os)
        }
    }

    /**
     * 写入文本字符串 (用括号包围)
     */
    private func writeTextString(os: PdfOutputStream): Unit {
        os.write(UInt8(0x28))  // (
        for (c in _value) {
            let code = UInt32(c)
            // 转义特殊字符
            if (code == 0x5C) {  // backslash
                os.write(UInt8(0x5C))
                os.write(UInt8(0x5C))
            } else if (code == 0x28) {  // (
                os.write(UInt8(0x5C))
                os.write(UInt8(0x28))
            } else if (code == 0x29) {  // )
                os.write(UInt8(0x5C))
                os.write(UInt8(0x29))
            } else if (code == 0x0D) {  // \r
                os.write(UInt8(0x5C))
                os.write(UInt8(0x72))
            } else if (code == 0x0A) {  // \n
                os.write(UInt8(0x5C))
                os.write(UInt8(0x6E))
            } else if (code == 0x09) {  // \t
                os.write(UInt8(0x5C))
                os.write(UInt8(0x74))
            } else {
                os.write(UInt8(code))
            }
        }
        os.write(UInt8(0x29))  // )
    }

    /**
     * 写入十六进制字符串
     */
    private func writeHexString(os: PdfOutputStream): Unit {
        os.write(UInt8(0x3C))  // <
        if (_bytes.isSome()) {
            let bytes = _bytes.getOrThrow()
            for (b in bytes) {
                writeHexByte(os, b)
            }
        } else {
            for (c in _value) {
                writeHexByte(os, UInt8(c))
            }
        }
        os.write(UInt8(0x3E))  // >
    }

    /**
     * 写入 Unicode 字符串
     */
    private func writeUnicodeString(os: PdfOutputStream): Unit {
        os.write(UInt8(0x3C))  // <
        // BOM
        os.writeString("FEFF")
        // UTF-16BE 编码（必须用 .runes() 以获取 Unicode 码位，而非 UTF-8 字节）
        for (c in _value.runes()) {
            let codePoint = UInt32(c)
            if (codePoint < 0x10000) {
                writeHexByte(os, UInt8((codePoint >> 8) & 0xFF))
                writeHexByte(os, UInt8(codePoint & 0xFF))
            } else {
                // 代理对
                let adjusted = codePoint - 0x10000
                let high = UInt16(0xD800 + ((adjusted >> 10) & 0x3FF))
                let low = UInt16(0xDC00 + (adjusted & 0x3FF))
                writeHexByte(os, UInt8((high >> 8) & 0xFF))
                writeHexByte(os, UInt8(high & 0xFF))
                writeHexByte(os, UInt8((low >> 8) & 0xFF))
                writeHexByte(os, UInt8(low & 0xFF))
            }
        }
        os.write(UInt8(0x3E))  // >
    }

    /**
     * 写入十六进制字节
     */
    private func writeHexByte(os: PdfOutputStream, b: Byte): Unit {
        let hexChars = "0123456789ABCDEF"
        let high = (UInt32(b) >> 4) & 0x0F
        let low = UInt32(b) & 0x0F
        os.write(UInt8(hexChars[Int64(high)]))
        os.write(UInt8(hexChars[Int64(low)]))
    }

    // 空字符串
    public static let EMPTY = PdfString("")
}
