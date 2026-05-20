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
     * 自动检测传统 xref 表和 PDF 1.5+ XRef 流对象
     * @return 交叉引用表
     */
    public func parse(): XRefTable {
        let xrefTable = XRefTable()
        skipWhitespace()

        // 检测：传统 "xref" 关键字（首字节为 'x' = 0x78），或 XRef 流对象（首字节为数字）
        if (position < data.size && data[position] == 0x78) {  // 'x' — start of "xref"
            parseTraditionalXRef(xrefTable)
        } else {
            parseXRefStream(xrefTable)
            return xrefTable  // 流解析自行处理 Prev 链
        }

        // 跟随 /Prev 更新链
        match (xrefTable.getTrailer()) {
            case Some(trailer) =>
                match (trailer.get("Prev")) {
                    case Some(prevOffsetStr) =>
                        let prevOffset = parseIntFromStr(prevOffsetStr)
                        if (prevOffset > 0) {
                            let prevParser = XRefParser(data, prevOffset)
                            let prevTable = prevParser.parse()
                            // 合并：仅添加当前表中不存在的条目（当前表优先）
                            for (objNum in prevTable.getAllObjectNumbers()) {
                                if (!xrefTable.hasObject(objNum)) {
                                    match (prevTable.getEntry(objNum)) {
                                        case Some(entry) => xrefTable.addEntry(objNum, entry)
                                        case None => ()
                                    }
                                }
                            }
                        }
                    case None => ()
                }
            case None => ()
        }

        xrefTable
    }

    /**
     * 解析传统 xref 表（从 "xref" 关键字开始）
     */
    private func parseTraditionalXRef(xrefTable: XRefTable): Unit {
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

        // 解析 trailer 字典
        skipKeyword("trailer")
        let trailer = parseTrailer()
        xrefTable.setTrailer(trailer)
    }

    /**
     * 解析 PDF 1.5+ XRef 流对象
     * 格式：objNum gen obj\n<< /Type /XRef ... >>\nstream\n...\nendstream
     */
    private func parseXRefStream(xrefTable: XRefTable): Unit {
        // 跳过 "objNum gen obj" 头部
        skipNumber(); skipWhitespace()
        skipNumber(); skipWhitespace()
        skipKeyword("obj")
        skipWhitespace()

        // 解析流字典以获取 W、Index、Size、Filter、Length、Prev
        var wWidths: Array<Int32> = [1, 2, 1]
        var indexPairs: Array<Int32> = [0, 0]
        var streamLength: Int32 = 0
        var prevOffset: Int64 = -1
        var isFlate = false

        // 期望 "<<"
        if (position + 1 >= data.size || data[position] != 0x3C || data[position + 1] != 0x3C) {
            return
        }
        position += 2

        while (position < data.size) {
            skipWhitespace()
            if (position + 1 < data.size && data[position] == 0x3E && data[position + 1] == 0x3E) {
                position += 2
                break
            }
            if (data[position] != 0x2F) {
                position += 1
                continue
            }
            position += 1  // skip '/'
            let key = readToken()
            skipWhitespace()

            if (key == "W") {
                wWidths = parseIntArrayInline()
            } else if (key == "Index") {
                indexPairs = parseIntArrayInline()
            } else if (key == "Size") {
                streamLength = Int32(parseIntFromStr(readToken()))
            } else if (key == "Length") {
                streamLength = Int32(parseIntFromStr(readToken()))
            } else if (key == "Filter") {
                let v = readTrailerValue()
                isFlate = v.contains("FlateDecode")
            } else if (key == "Prev") {
                prevOffset = parseIntFromStr(readToken())
            } else {
                // 跳过不关心的值
                readTrailerValue()
            }
        }

        // 跳过 "stream\n"
        skipKeyword("stream")
        if (position < data.size && data[position] == 0x0D) { position += 1 }
        if (position < data.size && data[position] == 0x0A) { position += 1 }

        // 读取原始流字节（streamLength 字节）
        let rawStart = position
        let rawEnd = if (rawStart + Int64(streamLength) < data.size) {
            rawStart + Int64(streamLength)
        } else {
            data.size
        }
        let rawBytes = Array<UInt8>(rawEnd - rawStart, repeat: 0)
        for (i in 0..(rawEnd - rawStart)) {
            rawBytes[i] = data[rawStart + i]
        }
        position = rawEnd

        // 解压缩（FlateDecode）需要 Zlib 支持 — 暂存 Prev 信息
        // TODO: 集成 Zlib 解压后完整解析二进制条目

        // 保存 Prev 用于链式跟随
        if (prevOffset > 0) {
            let prevTrailer = HashMap<String, String>()
            prevTrailer["Prev"] = "${prevOffset}"
            xrefTable.setTrailer(prevTrailer)
        }
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
     * 读取数字（Int32）
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
     * 跳过关键字（使用 matchBytesAt 精确检测后跳过）
     */
    private func skipKeyword(keyword: String): Unit {
        skipWhitespace()
        let kw = stringToBytes(keyword)
        if (matchBytesAt(data, position, kw)) {
            position += Int64(kw.size)
        }
        skipWhitespace()
    }

    /**
     * 跳过纯数字序列
     */
    private func skipNumber(): Unit {
        skipWhitespace()
        while (position < data.size) {
            let ch = data[position]
            if (ch >= 0x30 && ch <= 0x39) {
                position += 1
            } else {
                break
            }
        }
    }

    /**
     * 检查是否匹配关键字（不改变位置，匹配时前进）
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
     * 解析 trailer 字典 << /Key Value ... >>
     */
    private func parseTrailer(): HashMap<String, String> {
        let trailer = HashMap<String, String>()
        skipWhitespace()

        // 跳过 "<<"
        if (position + 1 < data.size && data[position] == 0x3C && data[position + 1] == 0x3C) {
            position += 2
        } else {
            return trailer
        }

        // 逐个解析键值对，直到 ">>"
        while (position < data.size) {
            skipWhitespace()
            // 检测 ">>"
            if (position + 1 < data.size && data[position] == 0x3E && data[position + 1] == 0x3E) {
                position += 2
                break
            }
            // 期望 "/" 开头的键名
            if (position >= data.size || data[position] != 0x2F) {
                break
            }
            position += 1  // 跳过 '/'
            let key = readToken()
            skipWhitespace()

            // 读取值（数字、名称、数组、间接引用 "n g R" 等）
            let value = readTrailerValue()
            trailer[key] = value
        }

        trailer
    }

    /**
     * 读取原始 token 字符串（遇到空白或分隔符停止）
     */
    private func readToken(): String {
        var result = ""
        while (position < data.size) {
            let ch = data[position]
            if (isWhitespace(ch) || ch == 0x2F || ch == 0x3E || ch == 0x5B || ch == 0x5D) {
                break
            }
            result += String(Rune(Int64(ch)))
            position += 1
        }
        result
    }

    /**
     * 读取 trailer 中的值（字符串表示）
     * 支持：数字、名称（/Name）、数组（[...]）、嵌套字典（<<...>>）、间接引用（n g R）
     */
    private func readTrailerValue(): String {
        skipWhitespace()
        if (position >= data.size) { return "" }

        let ch = data[position]

        // 名称值 /Name
        if (ch == 0x2F) {
            position += 1
            return "/" + readToken()
        }

        // 数组：读取到 ']' 并原样返回
        if (ch == 0x5B) {
            var result = "["
            position += 1
            var depth = 1
            while (position < data.size && depth > 0) {
                let c = data[position]
                result += String(Rune(Int64(c)))
                if (c == 0x5B) { depth += 1 }
                if (c == 0x5D) { depth -= 1 }
                position += 1
            }
            return result
        }

        // 嵌套字典：跳过（trailer 中通常不需要展开）
        if (ch == 0x3C && position + 1 < data.size && data[position + 1] == 0x3C) {
            position += 2
            var depth = 1
            while (position < data.size && depth > 0) {
                if (position + 1 < data.size && data[position] == 0x3C && data[position + 1] == 0x3C) {
                    depth += 1
                    position += 2
                } else if (position + 1 < data.size && data[position] == 0x3E && data[position + 1] == 0x3E) {
                    depth -= 1
                    position += 2
                } else {
                    position += 1
                }
            }
            return "<<dict>>"
        }

        // 数字或间接引用 "n g R" — 读取第一个 token，向前窥视
        let num1 = readToken()
        skipWhitespace()
        // 保存位置，尝试读取第二个 token
        let savedPos = position
        let num2 = readToken()
        skipWhitespace()
        if (position < data.size && data[position] == 0x52) {  // 'R'
            position += 1
            return num1 + " " + num2 + " R"
        }
        // 非间接引用，回退
        position = savedPos
        return num1
    }

    /**
     * 解析内联整数数组 [n1 n2 ...]，返回 Array<Int32>
     */
    private func parseIntArrayInline(): Array<Int32> {
        let result = ArrayList<Int32>()
        skipWhitespace()
        // 跳过 '['
        if (position < data.size && data[position] == 0x5B) { position += 1 }
        while (position < data.size) {
            skipWhitespace()
            if (data[position] == 0x5D) {
                position += 1
                break
            }
            let num = readToken()
            if (!num.isEmpty()) {
                result.add(Int32(parseIntFromStr(num)))
            }
        }
        let arr = Array<Int32>(result.size, repeat: 0)
        for (i in 0..result.size) {
            arr[i] = result[i]
        }
        arr
    }

    /**
     * 从字符串解析 Int64（只读前缀数字部分）
     */
    private func parseIntFromStr(s: String): Int64 {
        var result: Int64 = 0
        for (r in s.runes()) {
            let code = UInt32(r)
            if (code >= 0x30 && code <= 0x39) {
                result = result * 10 + Int64(code - 0x30)
            } else {
                break
            }
        }
        result
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
