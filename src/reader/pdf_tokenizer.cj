/**
 * PDF-CJ: PdfTokenizer - PDF 词法分析器
 * 解析 PDF 文件的底层 token 流
 */
package pdf_cj.reader

import std.collection.ArrayList

/**
 * Token 类型枚举
 */
public enum TokenType {
    | Number        // 数字
    | String        // 字符串
    | Name          // 名称（以 / 开头）
    | Keyword       // 关键字
    | StartArray    // [
    | EndArray      // ]
    | StartDict     // <<
    | EndDict       // >>
    | Ref           // 间接引用标记 R
    | EndOfFile     // 文件结束
    | Unknown       // 未知
}

/**
 * Token 类
 */
public class Token {
    public let tokenType: TokenType
    public let value: String

    public init(tokenType: TokenType, value: String) {
        this.tokenType = tokenType
        this.value = value
    }

    public func getType(): TokenType {
        tokenType
    }

    public func getValue(): String {
        value
    }

    public func isNumber(): Bool {
        match (tokenType) {
            case TokenType.Number => true
            case _ => false
        }
    }

    public func isString(): Bool {
        match (tokenType) {
            case TokenType.String => true
            case _ => false
        }
    }

    public func isName(): Bool {
        match (tokenType) {
            case TokenType.Name => true
            case _ => false
        }
    }

    public func isKeyword(): Bool {
        match (tokenType) {
            case TokenType.Keyword => true
            case _ => false
        }
    }
}

/**
 * PDF 词法分析器
 * 将 PDF 字节流解析为 token 流
 */
public class PdfTokenizer {
    private var data: Array<UInt8>
    private var position: Int64 = 0
    private var length: Int64

    /**
     * 构造函数
     * @param data PDF 文件数据
     */
    public init(data: Array<UInt8>) {
        this.data = data
        this.length = data.size
    }

    /**
     * 获取当前位置
     */
    public func getPosition(): Int64 {
        position
    }

    /**
     * 设置当前位置
     */
    public func setPosition(pos: Int64): Unit {
        if (pos >= 0 && pos < length) {
            this.position = pos
        }
    }

    /**
     * 读取下一个 token
     */
    public func nextToken(): ?Token {
        skipWhitespace()

        if (position >= length) {
            return None
        }

        let ch = data[position]

        // 注释
        if (ch == 0x25) {  // '%'
            skipComment()
            return nextToken()
        }

        // 字符串
        if (ch == 0x28) {  // '('
            return Some(readString())
        }

        // 十六进制字符串
        if (ch == 0x3C) {  // '<'
            if (position + 1 < length && data[position + 1] == 0x3C) {
                // <<
                position += 2
                return Some(Token(TokenType.StartDict, "<<"))
            } else {
                return Some(readHexString())
            }
        }

        // 结束字典
        if (ch == 0x3E) {  // '>'
            if (position + 1 < length && data[position + 1] == 0x3E) {
                position += 2
                return Some(Token(TokenType.EndDict, ">>"))
            }
        }

        // 数组
        if (ch == 0x5B) {  // '['
            position += 1
            return Some(Token(TokenType.StartArray, "["))
        }

        if (ch == 0x5D) {  // ']'
            position += 1
            return Some(Token(TokenType.EndArray, "]"))
        }

        // 名称
        if (ch == 0x2F) {  // '/'
            return Some(readName())
        }

        // 数字或关键字
        if (isDigit(ch) || ch == 0x2B || ch == 0x2D || ch == 0x2E) {  // + - .
            return Some(readNumberOrKeyword())
        }

        // 关键字
        if (isAlpha(ch)) {
            return Some(readKeyword())
        }

        // 未知字符，跳过
        position += 1
        return nextToken()
    }

    /**
     * 跳过空白字符
     */
    private func skipWhitespace(): Unit {
        while (position < length) {
            let ch = data[position]
            if (isWhitespace(ch)) {
                position += 1
            } else {
                break
            }
        }
    }

    /**
     * 跳过注释（从 % 到行尾）
     */
    private func skipComment(): Unit {
        while (position < length) {
            let ch = data[position]
            position += 1
            if (ch == 0x0A || ch == 0x0D) {  // LF or CR
                break
            }
        }
    }

    /**
     * 读取字符串（括号包围）
     */
    private func readString(): Token {
        var result = ArrayList<UInt8>()
        position += 1  // 跳过开始的 '('

        var depth = 1
        var escaped = false

        while (position < length && depth > 0) {
            let ch = data[position]
            position += 1

            if (escaped) {
                // 转义字符
                if (ch == 0x6E) {  // 'n'
                    result.add(0x0A)  // \n
                } else if (ch == 0x72) {  // 'r'
                    result.add(0x0D)  // \r
                } else if (ch == 0x74) {  // 't'
                    result.add(0x09)  // \t
                } else {
                    result.add(ch)
                }
                escaped = false
            } else {
                if (ch == 0x5C) {  // '\\'
                    escaped = true
                } else if (ch == 0x28) {  // '('
                    depth += 1
                    result.add(ch)
                } else if (ch == 0x29) {  // ')'
                    depth -= 1
                    if (depth > 0) {
                        result.add(ch)
                    }
                } else {
                    result.add(ch)
                }
            }
        }

        // 转换为字符串
        let str = bytesToString(result)
        Token(TokenType.String, str)
    }

    /**
     * 读取十六进制字符串
     */
    private func readHexString(): Token {
        var result = ArrayList<UInt8>()
        position += 1  // 跳过 '<'

        while (position < length) {
            let ch = data[position]
            if (ch == 0x3E) {  // '>'
                position += 1
                break
            }

            if (!isWhitespace(ch)) {
                result.add(ch)
            }
            position += 1
        }

        let str = bytesToString(result)
        Token(TokenType.String, str)
    }

    /**
     * 读取名称（以 / 开头）
     */
    private func readName(): Token {
        var result = ArrayList<UInt8>()
        position += 1  // 跳过 '/'

        while (position < length) {
            let ch = data[position]
            if (isWhitespace(ch) || isDelimiter(ch)) {
                break
            }
            result.add(ch)
            position += 1
        }

        let str = bytesToString(result)
        Token(TokenType.Name, str)
    }

    /**
     * 读取数字或关键字
     */
    private func readNumberOrKeyword(): Token {
        var result = ArrayList<UInt8>()

        while (position < length) {
            let ch = data[position]
            if (isWhitespace(ch) || isDelimiter(ch)) {
                break
            }
            result.add(ch)
            position += 1
        }

        let str = bytesToString(result)

        // 判断是否为数字
        if (isNumeric(str)) {
            return Token(TokenType.Number, str)
        }

        Token(TokenType.Keyword, str)
    }

    /**
     * 读取关键字
     */
    private func readKeyword(): Token {
        var result = ArrayList<UInt8>()

        while (position < length) {
            let ch = data[position]
            if (isWhitespace(ch) || isDelimiter(ch)) {
                break
            }
            result.add(ch)
            position += 1
        }

        let str = bytesToString(result)
        Token(TokenType.Keyword, str)
    }

    /**
     * 判断是否为空白字符
     */
    private func isWhitespace(ch: UInt8): Bool {
        ch == 0x20 || ch == 0x09 || ch == 0x0A || ch == 0x0D || ch == 0x0C || ch == 0x00
    }

    /**
     * 判断是否为分隔符
     */
    private func isDelimiter(ch: UInt8): Bool {
        ch == 0x28 || ch == 0x29 ||  // ( )
        ch == 0x3C || ch == 0x3E ||  // < >
        ch == 0x5B || ch == 0x5D ||  // [ ]
        ch == 0x7B || ch == 0x7D ||  // { }
        ch == 0x2F || ch == 0x25     // / %
    }

    /**
     * 判断是否为数字字符
     */
    private func isDigit(ch: UInt8): Bool {
        ch >= 0x30 && ch <= 0x39  // 0-9
    }

    /**
     * 判断是否为字母字符
     */
    private func isAlpha(ch: UInt8): Bool {
        (ch >= 0x41 && ch <= 0x5A) ||  // A-Z
        (ch >= 0x61 && ch <= 0x7A)     // a-z
    }

    /**
     * 判断字符串是否为数字
     */
    private func isNumeric(str: String): Bool {
        if (str.size == 0) {
            return false
        }

        var hasDigit = false
        var hasDot = false

        for (ch in str) {
            let code = Int64(ch)
            if (code >= 0x30 && code <= 0x39) {  // 0-9
                hasDigit = true
            } else if (code == 0x2E) {  // '.'
                if (hasDot) {
                    return false
                }
                hasDot = true
            } else if (code == 0x2B || code == 0x2D) {  // '+' or '-'
                // 只能在开头
                continue
            } else {
                return false
            }
        }

        hasDigit
    }

    /**
     * 字节数组转字符串
     */
    private func bytesToString(bytes: ArrayList<UInt8>): String {
        var result = ""
        for (i in 0..bytes.size) {
            let ch = bytes[i]
            result = "${result}${Rune(Int64(ch))}"
        }
        result
    }

    /**
     * 查看下一个 token（不移动位置）
     */
    public func peekToken(): ?Token {
        let savedPos = position
        let token = nextToken()
        position = savedPos
        token
    }

    /**
     * 是否到达文件末尾
     */
    public func isEOF(): Bool {
        position >= length
    }
}
