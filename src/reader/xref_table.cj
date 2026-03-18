/**
 * PDF-CJ: XRefTable - 交叉引用表解析
 * 解析 PDF 的 xref 表，建立对象索引
 */
package pdf_cj.reader

import std.collection.{HashMap, ArrayList}

/**
 * 交叉引用表条目
 */
public class XRefEntry {
    public let offset: Int64      // 对象在文件中的字节偏移
    public let generation: Int32  // 代数
    public let inUse: Bool        // 是否在使用中

    public init(offset: Int64, generation: Int32, inUse: Bool) {
        this.offset = offset
        this.generation = generation
        this.inUse = inUse
    }

    public func getOffset(): Int64 {
        offset
    }

    public func getGeneration(): Int32 {
        generation
    }

    public func isInUse(): Bool {
        inUse
    }
}

/**
 * 交叉引用表
 * 管理对象号到文件偏移的映射
 */
public class XRefTable {
    private var entries: HashMap<Int32, XRefEntry> = HashMap<Int32, XRefEntry>()
    private var trailerDict: ?HashMap<String, String> = None

    /**
     * 添加条目
     * @param objNum 对象号
     * @param entry 条目
     */
    public func addEntry(objNum: Int32, entry: XRefEntry): Unit {
        entries[objNum] = entry
    }

    /**
     * 获取条目
     * @param objNum 对象号
     * @return 条目，如果不存在返回 None
     */
    public func getEntry(objNum: Int32): ?XRefEntry {
        entries.get(objNum)
    }

    /**
     * 获取对象的文件偏移
     * @param objNum 对象号
     * @return 文件偏移，如果不存在返回 -1
     */
    public func getOffset(objNum: Int32): Int64 {
        match (entries.get(objNum)) {
            case Some(entry) => entry.getOffset()
            case None => -1
        }
    }

    /**
     * 检查对象是否存在
     */
    public func hasObject(objNum: Int32): Bool {
        entries.contains(objNum)
    }

    /**
     * 获取所有对象号
     */
    public func getAllObjectNumbers(): Array<Int32> {
        let result = ArrayList<Int32>()
        for ((objNum, _) in entries) {
            result.add(objNum)
        }

        let arr = Array<Int32>(result.size, repeat: 0)
        for (i in 0..result.size) {
            arr[i] = result[i]
        }
        arr
    }

    /**
     * 获取对象数量
     */
    public func getObjectCount(): Int64 {
        entries.size
    }

    /**
     * 设置 trailer 字典
     */
    public func setTrailer(trailer: HashMap<String, String>): Unit {
        this.trailerDict = Some(trailer)
    }

    /**
     * 获取 trailer 字典
     */
    public func getTrailer(): ?HashMap<String, String> {
        trailerDict
    }
}

/**
 * 交叉引用表解析器
 */
public class XRefParser {
    private var data: Array<UInt8>
    private var position: Int64

    public init(data: Array<UInt8>, startPosition: Int64) {
        this.data = data
        this.position = startPosition
    }

    /**
     * 解析交叉引用表
     * @return 交叉引用表
     */
    public func parse(): XRefTable {
        let xrefTable = XRefTable()

        // 跳过 "xref" 关键字
        skipKeyword("xref")

        // 读取所有 xref 子节
        while (true) {
            skipWhitespace()

            // 检查是否到达 trailer
            if (matchKeyword("trailer")) {
                break
            }

            // 读取子节：起始对象号和数量
            let startObj = readNumber()
            skipWhitespace()
            let count = readNumber()
            skipWhitespace()

            // 读取条目
            for (i in 0..count) {
                let entry = readEntry()
                let objNum = startObj + Int32(i)
                xrefTable.addEntry(objNum, entry)
            }
        }

        // 解析 trailer
        skipKeyword("trailer")
        let trailer = parseTrailer()
        xrefTable.setTrailer(trailer)

        xrefTable
    }

    /**
     * 读取一个 xref 条目
     * 格式：nnnnnnnnnn ggggg n/f
     */
    private func readEntry(): XRefEntry {
        skipWhitespace()

        // 读取偏移（10位数字）
        let offset = readFixedNumber(10)
        skipWhitespace()

        // 读取代数（5位数字）
        let generation = Int32(readFixedNumber(5))
        skipWhitespace()

        // 读取状态标志（n 或 f）
        let flag = readChar()
        let inUse = (flag == 0x6E)  // 'n'

        skipWhitespace()

        XRefEntry(offset, generation, inUse)
    }

    /**
     * 读取固定长度的数字
     */
    private func readFixedNumber(length: Int64): Int64 {
        var result: Int64 = 0

        for (i in 0..length) {
            if (position >= data.size) {
                break
            }

            let ch = data[position]
            position += 1

            if (ch >= 0x30 && ch <= 0x39) {  // 0-9
                result = result * 10 + Int64(ch - 0x30)
            }
        }

        result
    }

    /**
     * 读取数字
     */
    private func readNumber(): Int32 {
        var result: Int32 = 0

        while (position < data.size) {
            let ch = data[position]

            if (ch >= 0x30 && ch <= 0x39) {  // 0-9
                result = result * 10 + Int32(ch - 0x30)
                position += 1
            } else {
                break
            }
        }

        result
    }

    /**
     * 读取一个字符
     */
    private func readChar(): UInt8 {
        if (position < data.size) {
            let ch = data[position]
            position += 1
            return ch
        }
        0
    }

    /**
     * 跳过关键字
     */
    private func skipKeyword(keyword: String): Unit {
        for (ch in keyword) {
            if (position < data.size) {
                position += 1
            }
        }
        skipWhitespace()
    }

    /**
     * 检查是否匹配关键字
     */
    private func matchKeyword(keyword: String): Bool {
        let savedPos = position
        var matched = true

        for (ch in keyword) {
            if (position >= data.size) {
                matched = false
                break
            }

            let fileCh = data[position]
            if (Int64(fileCh) != Int64(ch)) {
                matched = false
                break
            }
            position += 1
        }

        if (!matched) {
            position = savedPos
        }

        matched
    }

    /**
     * 跳过空白字符
     */
    private func skipWhitespace(): Unit {
        while (position < data.size) {
            let ch = data[position]
            if (isWhitespace(ch)) {
                position += 1
            } else {
                break
            }
        }
    }

    /**
     * 判断是否为空白字符
     */
    private func isWhitespace(ch: UInt8): Bool {
        ch == 0x20 || ch == 0x09 || ch == 0x0A || ch == 0x0D || ch == 0x0C || ch == 0x00
    }

    /**
     * 解析 trailer 字典（简化版本）
     */
    private func parseTrailer(): HashMap<String, String> {
        let trailer = HashMap<String, String>()

        // 简化实现：跳过 trailer 内容
        // 实际应该使用 PdfParser 解析 trailer 字典

        trailer
    }

    /**
     * 查找 startxref 位置
     * 从文件末尾向前搜索
     */
    public static func findStartXRef(data: Array<UInt8>): Int64 {
        // 从文件末尾向前搜索 "startxref"
        let keyword = "startxref"
        let keywordBytes = stringToBytes(keyword)

        var pos = data.size - 1

        while (pos >= 0) {
            // 查找 's' 字符
            if (data[pos] == 0x73) {  // 's'
                // 检查是否匹配完整关键字
                if (matchBytesAt(data, pos, keywordBytes)) {
                    // 找到了，读取后面的数字
                    pos += Int64(keyword.size)
                    return readNumberAt(data, pos)
                }
            }
            pos -= 1
        }

        -1  // 未找到
    }

    /**
     * 在指定位置匹配字节序列
     */
    private static func matchBytesAt(data: Array<UInt8>, pos: Int64, pattern: Array<UInt8>): Bool {
        if (pos + pattern.size > data.size) {
            return false
        }

        for (i in 0..pattern.size) {
            if (data[pos + i] != pattern[i]) {
                return false
            }
        }

        true
    }

    /**
     * 在指定位置读取数字
     */
    private static func readNumberAt(data: Array<UInt8>, startPos: Int64): Int64 {
        var pos = startPos
        var result: Int64 = 0

        // 跳过空白
        while (pos < data.size) {
            let ch = data[pos]
            if (ch == 0x20 || ch == 0x09 || ch == 0x0A || ch == 0x0D) {
                pos += 1
            } else {
                break
            }
        }

        // 读取数字
        while (pos < data.size) {
            let ch = data[pos]
            if (ch >= 0x30 && ch <= 0x39) {  // 0-9
                result = result * 10 + Int64(ch - 0x30)
                pos += 1
            } else {
                break
            }
        }

        result
    }

    /**
     * 字符串转字节数组
     */
    private static func stringToBytes(str: String): Array<UInt8> {
        let arr = Array<UInt8>(str.size, repeat: 0)
        var index: Int64 = 0

        for (ch in str) {
            if (index < arr.size) {
                arr[index] = UInt8(Int64(ch))
                index += 1
            }
        }

        arr
    }
}
