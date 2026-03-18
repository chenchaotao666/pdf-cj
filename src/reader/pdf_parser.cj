/**
 * PDF-CJ: PdfParser - PDF 对象解析器（简化版本）
 * 从 token 流构建 PDF 对象
 */
package pdf_cj.reader

import pdf_cj.base.*

/**
 * PDF 对象解析器
 * 将 token 流解析为 PDF 对象
 */
public class PdfParser {
    private var tokenizer: PdfTokenizer

    /**
     * 构造函数
     * @param tokenizer 词法分析器
     */
    public init(tokenizer: PdfTokenizer) {
        this.tokenizer = tokenizer
    }

    /**
     * 解析下一个对象
     * @return PDF 对象，如果没有返回 None
     */
    public func parseObject(): ?PdfObject {
        let token = tokenizer.nextToken()
        match (token) {
            case None => None
            case Some(t) =>
                // 根据 token 类型解析对象
                match (t.getType()) {
                    case TokenType.Number =>
                        Some(PdfNumber(Float32(stringToInt(t.getValue()))))
                    case TokenType.String =>
                        Some(PdfString(t.getValue()))
                    case TokenType.Name =>
                        Some(PdfName(t.getValue()))
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
     * 解析关键字
     */
    private func parseKeyword(keyword: String): ?PdfObject {
        if (keyword == "true") {
            return Some(PdfBoolean(true))
        } else if (keyword == "false") {
            return Some(PdfBoolean(false))
        }

        // 其他关键字作为名称处理
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
                    // 检查是否结束
                    match (t.getType()) {
                        case TokenType.EndArray =>
                            tokenizer.nextToken()  // 消费 ]
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
                    // 检查是否结束
                    match (t.getType()) {
                        case TokenType.EndDict =>
                            tokenizer.nextToken()  // 消费 >>
                            break
                        case TokenType.Name =>
                            // 读取键
                            tokenizer.nextToken()
                            let key = PdfName(t.getValue())

                            // 读取值
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
     * 字符串转整数
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
