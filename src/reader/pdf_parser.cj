/**
 * PDF-CJ: PdfParser - PDF 对象解析器
 * 从 token 流构建 PDF 对象，支持间接引用、布尔、空值
 */
package pdf_cj.reader

import pdf_cj.base.*

/**
 * PDF 对象解析器
 * 将 token 流解析为 PDF 对象
 */
public class PdfParser {
    private var tokenizer: PdfTokenizer

    public init(tokenizer: PdfTokenizer) {
        this.tokenizer = tokenizer
    }

    /**
     * 解析下一个对象
     */
    public func parseObject(): ?PdfObject {
        let token = tokenizer.nextToken()
        match (token) {
            case None => None
            case Some(t) =>
                match (t.getType()) {
                    case TokenType.Number =>
                        parseNumberOrRef(t.getValue())
                    case TokenType.String =>
                        Some(PdfString(t.getValue()))
                    case TokenType.Name =>
                        Some(PdfName(t.getValue()))
                    case TokenType.Boolean =>
                        Some(PdfBoolean(t.getValue() == "true"))
                    case TokenType.Null =>
                        Some(PdfNull.INSTANCE)
                    case TokenType.StartArray =>
                        Some(parseArray())
                    case TokenType.StartDict =>
                        Some(parseDictionary())
                    case TokenType.Keyword =>
                        parseKeyword(t.getValue())
                    case _ =>
                        None
                }
        }
    }

    /**
     * 解析数字或间接引用 "n1 n2 R"
     * 消费 n1 后向前窥视：若后跟 n2 R 则返回 PdfIndirectReference，否则回退
     */
    private func parseNumberOrRef(numStr: String): ?PdfObject {
        let n1 = stringToInt(numStr)
        let savedPos = tokenizer.getPosition()
        match (tokenizer.nextToken()) {
            case Some(t2) =>
                if (!t2.isNumber()) {
                    tokenizer.setPosition(savedPos)
                    return Some(PdfNumber(Float32(n1)))
                }
                let n2 = stringToInt(t2.getValue())
                match (tokenizer.peekToken()) {
                    case Some(t3) =>
                        match (t3.getType()) {
                            case TokenType.Ref =>
                                tokenizer.nextToken()  // consume R
                                Some(PdfIndirectReference(n1, n2))
                            case _ =>
                                tokenizer.setPosition(savedPos)
                                Some(PdfNumber(Float32(n1)))
                        }
                    case None =>
                        tokenizer.setPosition(savedPos)
                        Some(PdfNumber(Float32(n1)))
                }
            case None =>
                tokenizer.setPosition(savedPos)
                Some(PdfNumber(Float32(n1)))
        }
    }

    /**
     * 解析关键字（处理旧格式 PDF 中以 keyword 方式出现的 true/false）
     */
    private func parseKeyword(keyword: String): ?PdfObject {
        if (keyword == "true") {
            return Some(PdfBoolean(true))
        } else if (keyword == "false") {
            return Some(PdfBoolean(false))
        }
        Some(PdfName(keyword))
    }

    /**
     * 解析数组
     */
    private func parseArray(): PdfArray {
        let array = PdfArray()
        while (true) {
            let token = tokenizer.peekToken()
            match (token) {
                case None => break
                case Some(t) =>
                    match (t.getType()) {
                        case TokenType.EndArray =>
                            tokenizer.nextToken()
                            break
                        case _ =>
                            let obj = parseObject()
                            match (obj) {
                                case Some(o) => array.add(o)
                                case None => break
                            }
                    }
            }
        }
        array
    }

    /**
     * 解析字典
     */
    private func parseDictionary(): PdfDictionary {
        let dict = PdfDictionary()
        while (true) {
            let token = tokenizer.peekToken()
            match (token) {
                case None => break
                case Some(t) =>
                    match (t.getType()) {
                        case TokenType.EndDict =>
                            tokenizer.nextToken()
                            break
                        case TokenType.Name =>
                            tokenizer.nextToken()
                            let key = PdfName(t.getValue())
                            let value = parseObject()
                            match (value) {
                                case Some(v) => dict.put(key, v)
                                case None => ()
                            }
                        case _ => break
                    }
            }
        }
        dict
    }

    /**
     * 字符串转 Int32（处理可选负号）
     */
    private func stringToInt(str: String): Int32 {
        var result: Int32 = 0
        var negative = false
        var started = false

        for (ch in str) {
            let code = Int64(ch)
            if (code == 0x2D && !started) {  // '-'
                negative = true
                started = true
            } else if (code >= 0x30 && code <= 0x39) {  // 0-9
                result = result * 10 + Int32(code - 0x30)
                started = true
            }
        }

        if (negative) {
            return -result
        }
        result
    }
}
