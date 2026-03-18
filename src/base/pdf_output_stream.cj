/**
 * PDF-CJ: PdfOutputStream - PDF 输出流
 * 包装标准输出流，提供 PDF 写入功能
 */
package pdf_cj.base

import std.io.OutputStream
import std.collection.ArrayList

/**
 * PDF 输出流接口
 * 提供写入 PDF 数据的基本方法
 */
public interface PdfOutputStream {
    /**
     * 写入单个字节
     */
    func write(byte: Byte): Unit

    /**
     * 写入字节数组
     */
    func writeBytes(bytes: Array<Byte>): Unit

    /**
     * 写入字符串（ASCII）
     */
    func writeString(s: String): Unit

    /**
     * 获取当前位置
     */
    prop position: Int64

    /**
     * 刷新缓冲区
     */
    func flush(): Unit

    /**
     * 写入换行符
     */
    func writeNewLine(): Unit

    /**
     * 写入空格
     */
    func writeSpace(): Unit

    /**
     * 写入整数
     */
    func writeInt(value: Int64): Unit

    /**
     * 写入浮点数（Float32）
     */
    func writeFloat32(value: Float32): Unit

    /**
     * 写入浮点数（Float64）
     */
    func writeFloat64(value: Float64): Unit
}

/**
 * 文件输出流包装器
 */
public class PdfFileOutputStream <: PdfOutputStream {
    private let outputStream: OutputStream
    private var _position: Int64 = 0

    public init(os: OutputStream) {
        this.outputStream = os
    }

    public func write(byte: Byte): Unit {
        outputStream.write(byte)
        _position += 1
    }

    public func writeBytes(bytes: Array<Byte>): Unit {
        outputStream.write(bytes)
        _position += Int64(bytes.size)
    }

    public func writeString(s: String): Unit {
        for (c in s) {
            write(UInt8(c))
        }
    }

    public prop position: Int64 {
        get() { _position }
    }

    public func flush(): Unit {
        outputStream.flush()
    }

    public func writeNewLine(): Unit {
        write(UInt8(0x0A))
    }

    public func writeSpace(): Unit {
        write(UInt8(0x20))
    }

    public func writeInt(value: Int64): Unit {
        writeString(value.toString())
    }

    public func writeFloat32(value: Float32): Unit {
        writeFloat64(Float64(value))
    }

    public func writeFloat64(value: Float64): Unit {
        let intPart = Int64(value)
        if (Float64(intPart) == value) {
            writeString(intPart.toString())
        } else {
            writeString(formatFloat(value))
        }
    }

    private func formatFloat(value: Float64): String {
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

/**
 * 字节包装类，用于 ArrayList
 */
public class ByteWrapper {
    public var value: Byte

    public init(b: Byte) {
        this.value = b
    }
}

/**
 * 字节数组输出流
 */
public class PdfByteArrayOutputStream <: PdfOutputStream {
    private var buffer: ArrayList<ByteWrapper> = ArrayList<ByteWrapper>()
    private var _position: Int64 = 0

    public init() {}

    public func write(byte: Byte): Unit {
        buffer.add(ByteWrapper(byte))
        _position += 1
    }

    public func writeBytes(bytes: Array<Byte>): Unit {
        for (b in bytes) {
            buffer.add(ByteWrapper(b))
        }
        _position += Int64(bytes.size)
    }

    public func writeString(s: String): Unit {
        for (c in s) {
            buffer.add(ByteWrapper(UInt8(c)))
        }
    }

    public prop position: Int64 {
        get() { _position }
    }

    /**
     * 获取字节数组
     */
    public func toByteArray(): Array<Byte> {
        let arr = Array<Byte>(buffer.size, {i => UInt8(0)})
        var i = 0
        for (wrapper in buffer) {
            arr[i] = wrapper.value
            i += 1
        }
        arr
    }

    /**
     * 获取大小
     */
    public prop size: Int64 {
        get() { _position }
    }

    /**
     * 重置缓冲区
     */
    public func reset(): Unit {
        buffer = ArrayList<ByteWrapper>()
        _position = 0
    }

    public func flush(): Unit {
        // 无需操作
    }

    public func writeNewLine(): Unit {
        write(UInt8(0x0A))
    }

    public func writeSpace(): Unit {
        write(UInt8(0x20))
    }

    public func writeInt(value: Int64): Unit {
        writeString(value.toString())
    }

    public func writeFloat32(value: Float32): Unit {
        writeFloat64(Float64(value))
    }

    public func writeFloat64(value: Float64): Unit {
        let intPart = Int64(value)
        if (Float64(intPart) == value) {
            writeString(intPart.toString())
        } else {
            writeString(formatFloat(value))
        }
    }

    private func formatFloat(value: Float64): String {
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
