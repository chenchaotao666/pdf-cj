/**
 * PDF 文本提取
 * ContentStreamParser 解析 BT/ET/Tf/Tm/Td/Tj/TJ 算子，
 * 按阅读顺序（从上到下、从左到右）输出文本片段。
 */
package pdf_cj.reader

import std.collection.{ArrayList}

// ─── TextFragment ─────────────────────────────────────────────────────────────

public class TextFragment {
    public var text: String
    public var x: Float32
    public var y: Float32
    public var fontSize: Float32
    public var fontName: String

    public init(text: String, x: Float32, y: Float32, fontSize: Float32, fontName: String) {
        this.text = text
        this.x = x
        this.y = y
        this.fontSize = fontSize
        this.fontName = fontName
    }
}

// ─── 内部 token ───────────────────────────────────────────────────────────────

enum CSKind {
    | TKNum
    | TKName
    | TKStr
    | TKOp
    | TKArrB
    | TKArrE
}

class CSToken {
    let kind: CSKind
    let str: String
    let num: Float32

    init(kind: CSKind, str: String, num: Float32) {
        this.kind = kind
        this.str = str
        this.num = num
    }
}

// ─── CSTokenizer ──────────────────────────────────────────────────────────────

class CSTokenizer {
    private var data: Array<UInt8>
    private var pos: Int64 = 0
    private var len: Int64

    init(bytes: Array<UInt8>) {
        data = bytes
        len = bytes.size
    }

    func tokenize(): ArrayList<CSToken> {
        let res = ArrayList<CSToken>()
        while (pos < len) {
            skipWS()
            if (pos >= len) { break }
            let b = Int64(data[pos])
            // 注释
            if (b == 37) { skipLine(); continue }
            // 字面量字符串 (...)
            if (b == 40) { pos += 1; res.add(CSToken(TKStr, readLiteral(), 0.0)); continue }
            // 十六进制字符串 <...> 或字典 <<
            if (b == 60) {
                if (pos + 1 < len && Int64(data[pos + 1]) == 60) {
                    res.add(CSToken(TKOp, "<<", 0.0)); pos += 2
                } else {
                    pos += 1; res.add(CSToken(TKStr, readHex(), 0.0))
                }
                continue
            }
            // 字典结束 >>
            if (b == 62 && pos + 1 < len && Int64(data[pos + 1]) == 62) {
                res.add(CSToken(TKOp, ">>", 0.0)); pos += 2; continue
            }
            // 数组 [ ]
            if (b == 91) { res.add(CSToken(TKArrB, "", 0.0)); pos += 1; continue }
            if (b == 93) { res.add(CSToken(TKArrE, "", 0.0)); pos += 1; continue }
            // 名字 /name
            if (b == 47) { pos += 1; res.add(CSToken(TKName, readWord(), 0.0)); continue }
            // 数字或操作符
            let w = readWord()
            if (w.size == 0) { pos += 1; continue }
            match (tryParseFloat(w)) {
                case Some(v) => res.add(CSToken(TKNum, "", v))
                case None => res.add(CSToken(TKOp, w, 0.0))
            }
        }
        res
    }

    private func skipWS(): Unit {
        while (pos < len) {
            let b = Int64(data[pos])
            if (b == 32 || b == 9 || b == 10 || b == 13) { pos += 1 } else { break }
        }
    }

    private func skipLine(): Unit {
        while (pos < len) {
            let b = Int64(data[pos])
            if (b != 10 && b != 13) { pos += 1 } else { break }
        }
    }

    private func isWordEnd(b: Int64): Bool {
        b == 32 || b == 9 || b == 10 || b == 13 ||
        b == 40 || b == 41 || b == 60 || b == 62 ||
        b == 91 || b == 93 || b == 123 || b == 125 ||
        b == 47 || b == 37
    }

    private func readWord(): String {
        var s = ""
        while (pos < len && !isWordEnd(Int64(data[pos]))) {
            s += String(Rune(Int64(data[pos])))
            pos += 1
        }
        s
    }

    private func readLiteral(): String {
        var s = ""
        var depth = 1
        while (pos < len && depth > 0) {
            let b = Int64(data[pos])
            pos += 1
            if (b == 92 && pos < len) {
                let c = Int64(data[pos])
                pos += 1
                if (c == 110) { s += "\n" }
                else if (c == 114) { s += "\r" }
                else if (c == 116) { s += "\t" }
                else if (c == 40) { s += "(" }
                else if (c == 41) { s += ")" }
                else if (c == 92) { s += "\\" }
                else if (c >= 48 && c <= 55) {
                    var oct = c - 48
                    var n = 1
                    while (n < 3 && pos < len) {
                        let nc = Int64(data[pos])
                        if (nc >= 48 && nc <= 55) { oct = oct * 8 + nc - 48; pos += 1; n += 1 }
                        else { break }
                    }
                    if (oct > 0) { s += String(Rune(oct)) }
                } else {
                    s += String(Rune(c))
                }
            } else if (b == 40) {
                depth += 1; s += "("
            } else if (b == 41) {
                depth -= 1
                if (depth > 0) { s += ")" }
            } else {
                s += String(Rune(b))
            }
        }
        s
    }

    private func readHex(): String {
        let nib = ArrayList<Int64>()
        while (pos < len && Int64(data[pos]) != 62) {
            let b = Int64(data[pos])
            pos += 1
            if (b >= 48 && b <= 57) { nib.add(b - 48) }
            else if (b >= 65 && b <= 70) { nib.add(b - 55) }
            else if (b >= 97 && b <= 102) { nib.add(b - 87) }
        }
        if (pos < len) { pos += 1 }  // consume '>'
        var s = ""
        var i: Int64 = 0
        while (i < nib.size) {
            let hi = nib[i]
            let lo = if (i + 1 < nib.size) { nib[i + 1] } else { 0 }
            let code = hi * 16 + lo
            if (code > 0) { s += String(Rune(code)) }
            i += 2
        }
        s
    }

    private func tryParseFloat(s: String): ?Float32 {
        if (s.size == 0) { return None }
        var intPart: Float64 = 0.0
        var fracPart: Float64 = 0.0
        var fracDiv: Float64 = 1.0
        var inFrac = false
        var neg = false
        var hasDigit = false
        var firstChar = true
        for (c in s) {
            let code = Int64(c)
            if (firstChar && code == 45) { neg = true; firstChar = false; continue }
            if (firstChar && code == 43) { firstChar = false; continue }
            firstChar = false
            if (code == 46 && !inFrac) { inFrac = true; continue }
            if (code >= 48 && code <= 57) {
                hasDigit = true
                if (inFrac) {
                    fracDiv *= 10.0
                    fracPart += Float64(code - 48) / fracDiv
                } else {
                    intPart = intPart * 10.0 + Float64(code - 48)
                }
            } else {
                return None
            }
        }
        if (!hasDigit) { return None }
        let sign: Float64 = if (neg) { -1.0 } else { 1.0 }
        Some(Float32((intPart + fracPart) * sign))
    }
}

// ─── ContentStreamParser ──────────────────────────────────────────────────────

public class ContentStreamParser {

    /**
     * 解析内容流字节，返回文本片段列表（已按阅读顺序排序）
     */
    public static func parse(bytes: Array<UInt8>): ArrayList<TextFragment> {
        let toks = CSTokenizer(bytes).tokenize()
        extract(toks)
    }

    /**
     * 将文本片段列表拼接为纯文本字符串。
     * 同行片段之间用空格分隔，不同行之间用换行符分隔。
     */
    public static func assembleText(frags: ArrayList<TextFragment>): String {
        if (frags.size == 0) { return "" }
        var result = ""
        var prevY = frags[0].y
        var prevFS = frags[0].fontSize
        for (i in 0..frags.size) {
            let f = frags[i]
            if (i > 0) {
                let dy = prevY - f.y  // 正值：f 在 prevY 下方
                if (dy > prevFS * 0.8) {
                    result += "\n"
                } else {
                    result += " "
                }
            }
            result += f.text
            prevY = f.y
            prevFS = f.fontSize
        }
        result
    }

    // ── 内部：解析 token 列表提取片段 ─────────────────────────────────────────

    private static func extract(toks: ArrayList<CSToken>): ArrayList<TextFragment> {
        let frags = ArrayList<TextFragment>()
        var stack = ArrayList<CSToken>()
        var inText = false
        var curX: Float32 = 0.0
        var curY: Float32 = 0.0
        var lmX: Float32 = 0.0  // 行矩阵 x
        var lmY: Float32 = 0.0  // 行矩阵 y
        var fontSize: Float32 = 12.0
        var fontName: String = ""
        var leading: Float32 = 0.0

        var i: Int64 = 0
        while (i < toks.size) {
            let tok = toks[i]
            i += 1
            match (tok.kind) {
                case TKArrB =>
                    // 收集数组内容直到 ]，用于 TJ 操作符
                    let strs = ArrayList<String>()
                    var arrDone = false
                    while (i < toks.size && !arrDone) {
                        let t = toks[i]; i += 1
                        match (t.kind) {
                            case TKArrE => arrDone = true
                            case TKStr => strs.add(t.str)
                            case _ => ()
                        }
                    }
                    // 若下一个 token 是 TJ，输出拼接后的文本
                    var nextIsTJ = false
                    if (i < toks.size) {
                        match (toks[i].kind) {
                            case TKOp => nextIsTJ = (toks[i].str == "TJ")
                            case _ => ()
                        }
                    }
                    if (nextIsTJ) {
                        i += 1
                        if (inText) {
                            var combined = ""
                            for (j in 0..strs.size) { combined += strs[j] }
                            if (combined.size > 0) {
                                frags.add(TextFragment(combined, curX, curY, fontSize, fontName))
                            }
                        }
                    }
                    stack = ArrayList<CSToken>()

                case TKOp =>
                    let op = tok.str
                    if (op == "BT") {
                        inText = true
                        curX = 0.0; curY = 0.0; lmX = 0.0; lmY = 0.0
                        stack = ArrayList<CSToken>()
                    } else if (op == "ET") {
                        inText = false
                        stack = ArrayList<CSToken>()
                    } else if (op == "Tf") {
                        // /FontName size Tf
                        if (stack.size >= 2) {
                            fontName = stack[stack.size - 2].str
                            fontSize = stack[stack.size - 1].num
                        }
                        stack = ArrayList<CSToken>()
                    } else if (op == "Tm") {
                        // a b c d e f Tm  → 取 e(x) f(y)
                        if (stack.size >= 6) {
                            curX = stack[stack.size - 2].num
                            curY = stack[stack.size - 1].num
                            lmX = curX; lmY = curY
                        }
                        stack = ArrayList<CSToken>()
                    } else if (op == "Td" || op == "TD") {
                        // tx ty Td/TD
                        if (stack.size >= 2) {
                            let tx = stack[stack.size - 2].num
                            let ty = stack[stack.size - 1].num
                            lmX += tx; lmY += ty
                            curX = lmX; curY = lmY
                            if (op == "TD") { leading = -ty }
                        }
                        stack = ArrayList<CSToken>()
                    } else if (op == "T*") {
                        lmY -= leading; curX = lmX; curY = lmY
                        stack = ArrayList<CSToken>()
                    } else if (op == "TL") {
                        if (stack.size >= 1) { leading = stack[stack.size - 1].num }
                        stack = ArrayList<CSToken>()
                    } else if (op == "Tj") {
                        if (inText && stack.size >= 1) {
                            let s = stack[stack.size - 1].str
                            if (s.size > 0) {
                                frags.add(TextFragment(s, curX, curY, fontSize, fontName))
                            }
                        }
                        stack = ArrayList<CSToken>()
                    } else if (op == "'") {
                        // 换行后显示文本
                        lmY -= leading; curX = lmX; curY = lmY
                        if (inText && stack.size >= 1) {
                            let s = stack[stack.size - 1].str
                            if (s.size > 0) {
                                frags.add(TextFragment(s, curX, curY, fontSize, fontName))
                            }
                        }
                        stack = ArrayList<CSToken>()
                    } else {
                        stack = ArrayList<CSToken>()
                    }

                case _ =>
                    stack.add(tok)
            }
        }

        sortByReadingOrder(frags)
        frags
    }

    // 冒泡排序：y 降序（顶部优先），同行按 x 升序（左优先）
    private static func sortByReadingOrder(frags: ArrayList<TextFragment>): Unit {
        let n = frags.size
        var i: Int64 = 0
        while (i < n - 1) {
            var j: Int64 = 0
            while (j < n - i - 1) {
                let a = frags[j]
                let b_ = frags[j + 1]
                let dy = b_.y - a.y
                var doSwap = false
                if (dy > 2.0) {
                    doSwap = true  // b_ 位置更高，应排在前面
                } else if (dy > -2.0 && b_.x < a.x) {
                    doSwap = true  // 同行，b_ 在左侧
                }
                if (doSwap) { frags[j] = b_; frags[j + 1] = a }
                j += 1
            }
            i += 1
        }
    }
}

// ─── TextExtractor ────────────────────────────────────────────────────────────

public class TextExtractor {

    /**
     * 提取指定页（从 1 开始）的文本
     */
    public static func extractPage(reader: PdfReader, pageNum: Int32): String {
        let bytes = reader.getPageContent(pageNum)
        let frags = ContentStreamParser.parse(bytes)
        ContentStreamParser.assembleText(frags)
    }

    /**
     * 提取整个文档的文本，页间以换行符分隔
     */
    public static func extractAll(reader: PdfReader): String {
        let n = reader.getNumberOfPages()
        var result = ""
        for (p in 1..(n + 1)) {
            if (p > 1) { result += "\n" }
            result += extractPage(reader, Int32(p))
        }
        result
    }
}
