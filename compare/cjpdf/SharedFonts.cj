package pdf_cj_examples

import pdf_cj.text.BaseFont

let _SHARED_FONT_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"

// Package-level font getter functions — called inside each section function
// to avoid global initialization (which would OOM-load 23 × 19MB CJK fonts at startup).

func newHelvBf(): BaseFont {
    BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
}

func newCjkBf(): BaseFont {
    BaseFont.createFont(_SHARED_FONT_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
}
