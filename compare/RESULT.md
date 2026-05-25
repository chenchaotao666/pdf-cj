# pdf-cj vs OpenPDF 对比结果

> 自动生成 by `compare/run_compare.sh`

DATE: 2026-05-25 15:08:29

## 文件大小对比

| Section | pdf-cj | OpenPDF 2.x | 比值 (cj/java) |
|---------|--------|-------------|----------------|
| S1 文本与字体 | 1528.3 KB | 213.8 KB | 7.1x |
| S2 表格 | 1553.3 KB | 218.9 KB | 7.0x |
| S3 图片 | 2538.0 KB | 1195.5 KB | 2.1x |
| S4 底层绘图 | 1546.2 KB | 193.9 KB | 7.9x |
| S5 页面事件 | 1555.2 KB | 200.9 KB | 7.7x |
| S6 书签与注释 | 1555.8 KB | 212.6 KB | 7.3x |

## 各 Section 详细对比

### S1 文本与字体

**元数据**

| 项目 | pdf-cj | OpenPDF |
|------|--------|---------|
| PDF 版本 | 1.4 | 1.5 |
| 页数 | 2 | 2 |
| Producer | PDF-CJ | OpenPDF 2.0.3 |

**字体嵌入**

```
[pdf-cj]
name                                 type              encoding         emb sub uni object ID
------------------------------------ ----------------- ---------------- --- --- --- ---------
NotoSansCJKsc-Regular                CID Type 0C       Identity-H       yes no  no       7  0
Helvetica                            Type 1            WinAnsi          no  no  no      10  0
Times-Roman                          Type 1            WinAnsi          no  no  no      11  0
Courier                              Type 1            WinAnsi          no  no  no      12  0

[OpenPDF]
name                                 type              encoding         emb sub uni object ID
------------------------------------ ----------------- ---------------- --- --- --- ---------
BJOGVD+NotoSansCJKjp-Regular-Identity-H CID Type 0C       Identity-H       yes yes yes      1  0
Helvetica                            Type 1            WinAnsi          no  no  no       2  0
Times-Roman                          Type 1            WinAnsi          no  no  no       6  0
Courier                              Type 1            WinAnsi          no  no  no       7  0
```

**字体统计**：pdf-cj 嵌入=1 子集=0，OpenPDF 嵌入=1 子集=1

**PDF 结构差异（qpdf --qdf）**

总差异行数：25973

典型差异（可打印部分）：
```diff
< %PDF-1.4
> %PDF-1.5
<   /Author <feff0050006400660043006f006d0070006100720065>
<   /Creator <feff007000640066002d0063006a>
<   /Producer <feff005000440046002d0043004a>
<   /Subject <feff005400650078007400200061006e006400200066006f006e007400200063006f006d00700061007200690073006f006e>
<   /Title <feff00500044004600200043006f006d00700061007200650020005300310020002d00200054006500780074>
>   /Author (PdfCompare)
>   /CreationDate (D:20260525145116+08'00')
>   /Creator (OpenPDF OpenPDF 2.0.3)
>   /Producer (OpenPDF 2.0.3)
>   /Subject (Text and font comparison)
>   /Title (PDF Compare S1 - Text)
>       /F2 9 0 R
<     /ProcSet [
<       /PDF
<       /Text
<       /ImageB
<       /ImageC
<       /ImageI
<     ]
<   /Contents 9 0 R
>   /Contents 10 0 R
<       /F2 11 0 R
>       /F2 9 0 R
<     /ProcSet [
<       /PDF
<       /Text
<       /ImageB
<       /ImageC
```

---

### S2 表格

**元数据**

| 项目 | pdf-cj | OpenPDF |
|------|--------|---------|
| PDF 版本 | 1.4 | 1.5 |
| 页数 | 1 | 1 |
| Producer | PDF-CJ | OpenPDF 2.0.3 |

**字体嵌入**

```
[pdf-cj]
name                                 type              encoding         emb sub uni object ID
------------------------------------ ----------------- ---------------- --- --- --- ---------
NotoSansCJKsc-Regular                CID Type 0C       Identity-H       yes no  no       7  0

[OpenPDF]
name                                 type              encoding         emb sub uni object ID
------------------------------------ ----------------- ---------------- --- --- --- ---------
BKDWRF+NotoSansCJKjp-Regular-Identity-H CID Type 0C       Identity-H       yes yes yes      1  0
Helvetica                            Type 1            WinAnsi          no  no  no       2  0
```

**字体统计**：pdf-cj 嵌入=1 子集=0，OpenPDF 嵌入=1 子集=1

**PDF 结构差异（qpdf --qdf）**

总差异行数：28211

典型差异（可打印部分）：
```diff
< %PDF-1.4
> %PDF-1.5
<   /Producer <feff005000440046002d0043004a>
<   /Title <feff00500044004600200043006f006d00700061007200650020005300320020002d0020005400610062006c0065>
>   /CreationDate (D:20260525145116+08'00')
>   /Producer (OpenPDF 2.0.3)
>   /Title (PDF Compare S2 - Table)
>       /F2 8 0 R
<     /ProcSet [
<       /PDF
<       /Text
<       /ImageB
<       /ImageC
<       /ImageI
<     ]
> q
< <00340013001b00018f9052b22c7580063d5259425b7e9652> Tj
< <00340013001b00018f9052b22c7580063d5259425b7e9652> Tj
< ET
< BT
> <00340013001b00018f9052b22c7580063d5259425b7e9652>Tj
> /F2 12 Tf
> ( )Tj
< <0013000e0022001b000134f96efc25142b9b8f9052b2e6ae0054004600550038004a00450055004900310046005300440046004f00550042004800460001000c00010054004600550038004a0045005500490054e6af> Tj
< <0013000e0022001b000134f96efc25142b9b8f9052b2e6ae0054004600550038004a00450055004900310046005300440046004f00550042004800460001000c00010054004600550038004a0045005500490054e6af> Tj
> <0013000e0022001b000134f96efc25142b9b8f9052b2e6ae0054004600550038004a00450055004900310046005300440046004f00550042004800460001000c00010054004600550038004a0045005500490054e6af>Tj
> /F1 12 Tf
> <0013000e0023001b000100240050004d005400510042004fe6ae99552b9be6af>Tj
> /F1 12 Tf
> <0013000e0024001b0001003300500058005400510042004f0001000c00012d9d2a5552b22ac23fca58ff86fd>Tj
```

---

### S3 图片

**元数据**

| 项目 | pdf-cj | OpenPDF |
|------|--------|---------|
| PDF 版本 | 1.4 | 1.5 |
| 页数 | 3 | 3 |
| Producer | PDF-CJ | OpenPDF 2.0.3 |

**字体嵌入**

```
[pdf-cj]
name                                 type              encoding         emb sub uni object ID
------------------------------------ ----------------- ---------------- --- --- --- ---------
NotoSansCJKsc-Regular                CID Type 0C       Identity-H       yes no  no       7  0

[OpenPDF]
name                                 type              encoding         emb sub uni object ID
------------------------------------ ----------------- ---------------- --- --- --- ---------
EWSPSC+NotoSansCJKjp-Regular-Identity-H CID Type 0C       Identity-H       yes yes yes      3  0
Helvetica                            Type 1            WinAnsi          no  no  no       4  0
```

**字体统计**：pdf-cj 嵌入=1 子集=0，OpenPDF 嵌入=1 子集=1

**PDF 结构差异（qpdf --qdf）**

总差异行数：1


---

### S4 底层绘图

**元数据**

| 项目 | pdf-cj | OpenPDF |
|------|--------|---------|
| PDF 版本 | 1.4 | 1.5 |
| 页数 | 1 | 1 |
| Producer | PDF-CJ | OpenPDF 2.0.3 |

**字体嵌入**

```
[pdf-cj]
name                                 type              encoding         emb sub uni object ID
------------------------------------ ----------------- ---------------- --- --- --- ---------
NotoSansCJKsc-Regular                CID Type 0C       Identity-H       yes no  no       7  0
Helvetica                            Type 1            WinAnsi          no  no  no       8  0

[OpenPDF]
name                                 type              encoding         emb sub uni object ID
------------------------------------ ----------------- ---------------- --- --- --- ---------
Helvetica                            Type 1            WinAnsi          no  no  no       1  0
LCYJPO+NotoSansCJKjp-Regular-Identity-H CID Type 0C       Identity-H       yes yes yes      2  0
```

**字体统计**：pdf-cj 嵌入=1 子集=0，OpenPDF 嵌入=1 子集=1

**PDF 结构差异（qpdf --qdf）**

总差异行数：26486

典型差异（可打印部分）：
```diff
< %PDF-1.4
> %PDF-1.5
<   /Producer <feff005000440046002d0043004a>
<   /Title <feff00500044004600200043006f006d00700061007200650020005300340020002d002000440072006100770069006e0067>
>   /CreationDate (D:20260525145117+08'00')
>   /Producer (OpenPDF 2.0.3)
>   /Title (PDF Compare S4 - Drawing)
<     /ProcSet [
<       /PDF
<       /Text
<       /ImageB
<       /ImageC
<       /ImageI
<     ]
> q
< /F1 18 Tf
< <00340015001b000142133dc47c033382e6ae00310045004700240050004f00550046004f00550023005a00550046e6af> Tj
< <00340015001b000142133dc47c033382e6ae00310045004700240050004f00550046004f00550023005a00550046e6af> Tj
> /F2 18 Tf
> <00340015001b000142133dc47c033382e6ae00310045004700240050004f00550046004f00550023005a00550046e6af>Tj
> Q
< h
< /F2 12 Tf
> /F1 12 Tf
< (Left  @\(280\)) Tj
< (Center@\(380\)) Tj
< (Right @\(480\)) Tj
< (Rotated 45) Tj
> (Left  @ \(280, 442.0\))Tj
> (Center@ \(380, 422.0\))Tj
```

---

### S5 页面事件

**元数据**

| 项目 | pdf-cj | OpenPDF |
|------|--------|---------|
| PDF 版本 | 1.4 | 1.5 |
| 页数 | 3 | 3 |
| Producer | PDF-CJ | OpenPDF 2.0.3 |

**字体嵌入**

```
[pdf-cj]
name                                 type              encoding         emb sub uni object ID
------------------------------------ ----------------- ---------------- --- --- --- ---------
Helvetica                            Type 1            WinAnsi          no  no  no       3  0
NotoSansCJKsc-Regular                CID Type 0C       Identity-H       yes no  no       8  0

[OpenPDF]
name                                 type              encoding         emb sub uni object ID
------------------------------------ ----------------- ---------------- --- --- --- ---------
Helvetica                            Type 1            WinAnsi          no  no  no       1  0
CMDEOO+NotoSansCJKjp-Regular-Identity-H CID Type 0C       Identity-H       yes yes yes      2  0
```

**字体统计**：pdf-cj 嵌入=1 子集=0，OpenPDF 嵌入=1 子集=1

**PDF 结构差异（qpdf --qdf）**

总差异行数：26779

典型差异（可打印部分）：
```diff
< %PDF-1.4
> %PDF-1.5
<   /Producer <feff005000440046002d0043004a>
<   /Title <feff00500044004600200043006f006d00700061007200650020005300350020002d00200050006100670065004500760065006e0074>
>   /CreationDate (D:20260525145117+08'00')
>   /Producer (OpenPDF 2.0.3)
>   /Title (PDF Compare S5 - PageEvent)
<     /ProcSet [
<       /PDF
<       /Text
<       /ImageB
<       /ImageC
<       /ImageI
<     ]
<     /ProcSet [
<       /PDF
<       /Text
<       /ImageB
<       /ImageC
<       /ImageI
<     ]
<     /ProcSet [
<       /PDF
<       /Text
<       /ImageB
<       /ImageC
<       /ImageI
<     ]
> BT
> /F2 16 Tf
```

---

### S6 书签与注释

**元数据**

| 项目 | pdf-cj | OpenPDF |
|------|--------|---------|
| PDF 版本 | 1.4 | 1.5 |
| 页数 | 2 | 2 |
| Producer | PDF-CJ | OpenPDF 2.0.3 |

**字体嵌入**

```
[pdf-cj]
name                                 type              encoding         emb sub uni object ID
------------------------------------ ----------------- ---------------- --- --- --- ---------
NotoSansCJKsc-Regular                CID Type 0C       Identity-H       yes no  no       7  0

[OpenPDF]
name                                 type              encoding         emb sub uni object ID
------------------------------------ ----------------- ---------------- --- --- --- ---------
YSRNWK+NotoSansCJKjp-Regular-Identity-H CID Type 0C       Identity-H       yes yes yes      2  0
Helvetica                            Type 1            WinAnsi          no  no  no       3  0
```

**字体统计**：pdf-cj 嵌入=1 子集=0，OpenPDF 嵌入=1 子集=1

**PDF 结构差异（qpdf --qdf）**

总差异行数：26904

典型差异（可打印部分）：
```diff
< %PDF-1.4
> %PDF-1.5
<   /Outlines 3 0 R
<   /PageMode /UseOutlines
<   /Pages 4 0 R
>   /Names 3 0 R
>   /Outlines 4 0 R
>   /Pages 5 0 R
<   /Producer <feff005000440046002d0043004a>
<   /Title <feff00500044004600200043006f006d00700061007200650020005300360020002d00200042006f006f006b006d00610072006b0020002600200041006e006e006f0074006100740069006f006e>
>   /CreationDate (D:20260525145117+08'00')
>   /Producer (OpenPDF 2.0.3)
>   /Title (PDF Compare S6 - Bookmark & Annotation)
<   /Count 2
<   /First 5 0 R
<   /Last 6 0 R
<   /Title (Outlines)
>   /Dests 6 0 R
>   /Count 5
>   /First 7 0 R
>   /Last 8 0 R
>   /Type /Outlines
> >>
> endobj
> <<
<     7 0 R
<     8 0 R
>     9 0 R
>     10 0 R
> <<
```

---

## 关键发现

| # | 维度 | pdf-cj | OpenPDF 2.x | 说明 |
|---|------|--------|-------------|------|
| 1 | **PDF 版本** | 1.4 | 1.5 | OpenPDF 2.x 默认输出 1.5，pdf-cj 输出 1.4 |
| 2 | **字体子集化** | 未子集（sub=no） | 完整子集（sub=yes，有 6 字符前缀） | pdf-cj 嵌入完整 CJK 字体，导致文件偏大 |
| 3 | **文件大小** | ~1.5 MB | ~200 KB | 差异主要来自第 2 点，非子集的完整 CJK 字体约 1.5 MB |
| 4 | **TTC 加载** | 直接传路径 `"font.ttc"` | 需加索引 `"font.ttc,0"` | OpenPDF 2.x 破坏性变更 |
| 5 | **字符串元数据** | UTF-16BE 编码（BOM `feff`） | Latin-1 字符串 | 两种编码都符合 PDF 规范 |
| 6 | **Producer 字段** | `PDF-CJ` | `OpenPDF 2.0.3` | 标识库来源 |
| 7 | **ProcSet** | 包含 `/ProcSet` 数组 | 无（PDF 1.4+ 已废弃） | pdf-cj 保留了旧兼容性字段 |
| 8 | **Chunk 装饰** | 仅 `setColor` | `setUnderline`、背景高亮等 | OpenPDF Chunk 功能更丰富 |
| 9 | **PageEvent** | 必须命名类 | 可匿名内部类 | 语言特性差异，非 API 差异 |
| 10 | **CMYK 参数** | `Float32` 0.0~1.0 | `int` 0~255（2.x 变更） | 1.x 也是 float，2.x 为破坏性变更 |

