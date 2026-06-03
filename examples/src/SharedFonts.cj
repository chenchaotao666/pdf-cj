package pdf_cj_examples

import pdf_cj.text.BaseFont
import std.env.getVariable
import std.fs.exists

// CJK 字体解析（健壮写法）：按以下优先级查找可用的中文字体文件
//   1. 环境变量 PDFCJ_CJK_FONT（部署时显式指定，最高优先级）
//   2. 随应用打包的字体 examples/fonts/NotoSansCJK-Regular.ttc（保证可移植）
//   3. 常见系统安装路径（Linux / macOS / Windows）
// 全部找不到时抛出明确错误，提示如何配置。
let _BUNDLED_CJK_FONT = "fonts/NotoSansCJK-Regular.ttc"

let _CJK_FONT_CANDIDATES: Array<String> = [
    // Linux（Noto / 文泉驿）
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc",
    "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc",
    // macOS
    "/System/Library/Fonts/PingFang.ttc",
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
    // Windows
    "C:/Windows/Fonts/msyh.ttc",
    "C:/Windows/Fonts/simsun.ttc"
]

// 解析出一个实际存在的 CJK 字体路径（结果缓存，避免重复探测）
var _resolvedCjkFont: ?String = None

func resolveCjkFont(): String {
    match (_resolvedCjkFont) {
        case Some(p) => return p
        case None => ()
    }

    // 1. 环境变量优先
    match (getVariable("PDFCJ_CJK_FONT")) {
        case Some(p) where p != "" =>
            if (exists(p)) {
                _resolvedCjkFont = Some(p)
                return p
            }
            println("警告：环境变量 PDFCJ_CJK_FONT 指向的字体不存在：${p}，改用其它候选")
        case _ => ()
    }

    // 2. 随应用打包的字体（相对运行目录 examples/）
    if (exists(_BUNDLED_CJK_FONT)) {
        _resolvedCjkFont = Some(_BUNDLED_CJK_FONT)
        return _BUNDLED_CJK_FONT
    }

    // 3. 常见系统路径
    for (cand in _CJK_FONT_CANDIDATES) {
        if (exists(cand)) {
            _resolvedCjkFont = Some(cand)
            return cand
        }
    }

    throw Exception(
        "未找到可用的 CJK 字体。请通过环境变量指定，例如：\n" +
        "  PDFCJ_CJK_FONT=/path/to/NotoSansCJK-Regular.ttc cjpm run\n" +
        "或将字体放到 examples/fonts/NotoSansCJK-Regular.ttc")
}

// 进程级缓存 BaseFont：保证 19MB 的 CJK 字体程序只加载一次（跑全部 23 个时避免反复加载 OOM）。
// 库已按文档（per-writer）独立做字体子集，故跨多个 Document 复用同一 BaseFont 是安全的：
// 每个 PDF 仍只嵌入自己用到的最小子集，不会累积。
var _cachedHelvBf: ?BaseFont = None
var _cachedCjkBf: ?BaseFont = None

func newHelvBf(): BaseFont {
    match (_cachedHelvBf) {
        case Some(bf) => bf
        case None =>
            let bf = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
            _cachedHelvBf = Some(bf)
            bf
    }
}

func newCjkBf(): BaseFont {
    match (_cachedCjkBf) {
        case Some(bf) => bf
        case None =>
            let bf = BaseFont.createFont(resolveCjkFont(), BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
            _cachedCjkBf = Some(bf)
            bf
    }
}
