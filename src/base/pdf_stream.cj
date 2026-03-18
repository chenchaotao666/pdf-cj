/**
 * PDF-CJ: PdfStream - PDF 流对象
 */
package pdf_cj.base

import std.collection.ArrayList

/**
 * PDF 流对象
 * 包含字典和字节流数据
 */
public class PdfStream <: PdfObjectBase {
    private var _dictionary: PdfDictionary = PdfDictionary()
    private var _content: ArrayList<ByteWrapper> = ArrayList<ByteWrapper>()
    // 用于大型二进制数据的高效存储
    private var _binaryContent: ?Array<Byte> = None
    private var _useBinaryContent: Bool = false

    /**
     * 创建空流
     */
    public init() {}

    /**
     * 从字节数组创建
     */
    public init(content: Array<Byte>) {
        for (b in content) {
            _content.add(ByteWrapper(b))
        }
    }

    /**
     * 从字符串创建
     */
    public init(content: String) {
        for (c in content) {
            _content.add(ByteWrapper(UInt8(c)))
        }
    }

    /**
     * 获取流字典
     */
    public prop dictionary: PdfDictionary {
        get() { _dictionary }
    }

    /**
     * 设置字典值
     */
    public func put(key: PdfName, value: PdfObject): Unit {
        _dictionary.put(key, value)
    }

    /**
     * 获取字典值
     */
    public func get(key: PdfName): ?PdfObject {
        _dictionary.get(key)
    }

    /**
     * 写入字节
     */
    public func write(byte: Byte): Unit {
        _content.add(ByteWrapper(byte))
    }

    /**
     * 写入字节数组
     */
    public func writeBytes(bytes: Array<Byte>): Unit {
        for (b in bytes) {
            _content.add(ByteWrapper(b))
        }
    }

    /**
     * 写入字符串
     */
    public func writeString(s: String): Unit {
        for (c in s) {
            _content.add(ByteWrapper(UInt8(c)))
        }
    }

    /**
     * 获取流内容
     */
    public func getContent(): Array<Byte> {
        if (_useBinaryContent) {
            match (_binaryContent) {
                case Some(data) => data
                case None => Array<Byte>(0, repeat: UInt8(0))
            }
        } else {
            let arr = Array<Byte>(_content.size, repeat: UInt8(0))
            var i = 0
            for (wrapper in _content) {
                arr[i] = wrapper.value
                i += 1
            }
            arr
        }
    }

    /**
     * 获取流长度
     */
    public prop length: Int64 {
        get() {
            if (_useBinaryContent) {
                match (_binaryContent) {
                    case Some(data) => data.size
                    case None => 0
                }
            } else {
                _content.size
            }
        }
    }

    /**
     * 清空流内容
     */
    public func clear(): Unit {
        _content = ArrayList<ByteWrapper>()
        _binaryContent = None
        _useBinaryContent = false
    }

    public override func getType(): PdfObjectType {
        PdfObjectType.Stream
    }

    public override func writeTo(os: PdfOutputStream): Unit {
        // 设置长度
        let contentLength = if (_useBinaryContent) {
            match (_binaryContent) {
                case Some(data) => data.size
                case None => 0
            }
        } else {
            _content.size
        }
        _dictionary.put(PdfName.LENGTH, contentLength)

        // 写入字典
        _dictionary.writeTo(os)
        os.writeNewLine()

        // 写入流内容
        os.writeString("stream")
        os.writeNewLine()

        if (_useBinaryContent) {
            // 使用高效的批量写入
            match (_binaryContent) {
                case Some(data) =>
                    os.writeBytes(data)
                case None => ()
            }
        } else {
            // 使用 ByteWrapper 列表输出
            for (wrapper in _content) {
                os.write(wrapper.value)
            }
        }

        os.writeNewLine()
        os.writeString("endstream")
    }

    /**
     * 设置流内容
     * 对于大型数据（>10KB）使用高效的二进制存储
     */
    public func setContent(content: Array<Byte>): Unit {
        // 对于大型数据，直接存储，避免创建大量 ByteWrapper 对象
        if (content.size > 10240) {  // 10KB
            _binaryContent = Some(content)
            _useBinaryContent = true
            _content = ArrayList<ByteWrapper>()  // 清空旧数据
        } else {
            _useBinaryContent = false
            _binaryContent = None
            _content = ArrayList<ByteWrapper>()
            for (b in content) {
                _content.add(ByteWrapper(b))
            }
        }
    }

    /**
     * 设置流内容（字符串）
     */
    public func setContent(content: String): Unit {
        _content = ArrayList<ByteWrapper>()
        for (c in content) {
            _content.add(ByteWrapper(UInt8(c)))
        }
    }
}
