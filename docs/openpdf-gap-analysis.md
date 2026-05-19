# pdf-cj vs OpenPDF 差距分析与实施提案

> 基准版本：pdf-cj v0.1.0 / OpenPDF v2.x  
> 目标：以仓颉语言完整替代 Java 版 OpenPDF

---

## 一、现状评估（pdf-cj v0.1.0）

| 模块 | 文件数 | 完成度 | 备注 |
|------|--------|--------|------|
| api/ (Document/Chunk/Paragraph等) | 7 | ✅ 95% | 核心文档模型完整 |
| base/ (PDF原始对象) | 11 | ✅ 90% | 基础类型完整 |
| util/ (PageSize/Rectangle等) | 4 | ✅ 95% | 完整 |
| codec/ (Flate/Hex/ASCII85) | 3 | ✅ 100% | 完整 |
| text/font.cj, color.cj, alignment.cj | 3 | ✅ 95% | 完整 |
| text/base_font.cj, font_factory.cj | 2 | 🟡 60% | 标准14字体可用，TrueType嵌入部分 |
| text/truetype_font.cj, font_subsetting.cj | 2 | 🟡 70% | CIDToGIDMap已实现，待验证 |
| text/cff_subsetter.cj | 1 | 🟡 40% | 算法框架有，细节待完善 |
| core/pdf_writer.cj | 1 | 🟡 50% | 页面管理/字体/图片写入，表格/注释集成中 |
| core/pdf_content_byte.cj | 1 | 🟡 30% | 文本BT/ET基础有，图形算子全缺 |
| table/ (PdfPTable/PdfPCell) | 2 | 🟡 40% | 数据结构有，布局算法缺 |
| image/ | 4 | 🟡 35% | 格式检测有，各格式解析器为框架 |
| form/ (annotation/formfield/outline) | 4 | 🔴 25% | 数据结构有，外观生成缺 |
| reader/ (Reader/Stamper/Tokenizer等) | 9 | 🔴 15% | 框架有，解析逻辑全缺 |
| security/ (Encryption/Signature) | 4 | 🔴 10% | 配置项有，算法实现缺 |
| text/cjk_font.cj, font_selector.cj等 | 5 | 🔴 10% | 骨架 |

---

## 二、功能差距对比表

### 2.1 已有且基本对齐

| 功能 | OpenPDF 类 | pdf-cj 状态 |
|------|-----------|------------|
| 文档生命周期 | `Document`, `DocListener` | ✅ 完整 |
| 文本元素 | `Chunk`, `Phrase`, `Paragraph` | ✅ 完整 |
| 章节结构 | `Chapter`, `Section` | ✅ 完整 |
| 页眉页脚 | `HeaderFooter` | ✅ 完整 |
| 标准14字体 | `BaseFont.HELVETICA` 等 | ✅ 完整 |
| RGB颜色 | `java.awt.Color` | ✅ 完整 |
| 页面尺寸 | `PageSize.A4` 等40+种 | ✅ 完整 |
| 文档元数据 | `addTitle/Author/Subject` | ✅ 完整 |
| Flate压缩 | `FlateDecoder` | ✅ 完整 |
| TrueType字体+CJK | `IDENTITY_H` + TTC | 🟡 70%（嵌入待稳定） |
| 表格结构 | `PdfPTable`, `PdfPCell` | 🟡 40%（布局算法缺） |
| 图片加载 | `Image.getInstance()` | 🟡 35%（解析器是骨架） |

### 2.2 缺失的核心功能

| 功能 | OpenPDF 类/方法 | 差距描述 | 优先级 |
|------|----------------|---------|--------|
| **图形绘制API** | `PdfContentByte.moveTo/lineTo/curveTo/rectangle/stroke/fill` | 完全缺失——无法画线、矩形、曲线 | P0 |
| **文本绝对定位** | `showTextAligned(align, text, x, y, rotation)` | 缺失——水印、页码等都依赖此接口 | P0 |
| **图形状态管理** | `saveState/restoreState/setLineWidth/setLineDash` | 缺失 | P0 |
| **PNG解析** | 内置PNG decoder | 框架有，IDAT/滤波器/Alpha通道未实现 | P0 |
| **表格布局算法** | `PdfPTable` 列宽计算、单元格换行、跨行 | 结构有，计算逻辑全缺 | P0 |
| **CMYK颜色** | `CMYKColor`, `setColorFill(CMYKColor)` | 仅支持RGB | P1 |
| **灰度颜色** | `GrayColor`, `setGrayFill` | 仅支持RGB | P1 |
| **注释渲染** | `PdfAnnotation.createText/createLink/createMarkup` | 数据结构有，外观生成/写入缺 | P1 |
| **书签写入** | `PdfOutline` 嵌套、样式 | PdfOutlineTree已启动，写入集成缺 | P1 |
| **页面事件** | `PdfPageEvent.onEndPage` 等8个hook | 接口有，PdfWriter未调用 | P1 |
| **多列文本** | `ColumnText` | 完全骨架 | P1 |
| **PDF阅读** | `PdfReader`（xref解析、对象流） | 框架有，tokenizer/parser全缺 | P2 |
| **PDF叠印** | `PdfStamper.getOverContent` | 框架有，实现全缺 | P2 |
| **PDF合并** | `PdfCopy`, `PdfSmartCopy` | 框架有，实现全缺 | P2 |
| **文本提取** | `SimpleTextExtractionStrategy` | 完全缺失 | P2 |
| **RC4加密** | `STANDARD_ENCRYPTION_128` | 配置有，算法缺 | P3 |
| **AES加密** | `ENCRYPTION_AES128/256` | 配置有，算法缺 | P3 |
| **表单外观生成** | `TextField.getTextField()` | 字段结构有，AP字典生成缺 | P3 |
| **表单填写** | `AcroFields.setField()` | 框架有，实现全缺 | P3 |
| **数字签名** | `PdfSignatureAppearance`, PKCS#7 | 完全骨架 | P4 |
| **条形码** | `Barcode128`, `BarcodeQRCode` 等 | 完全缺失 | P4 |
| **JPEG2000/TIFF/WMF** | 对应Image子类 | 完全缺失 | P4 |
| **透明度/渐变** | `PdfGState`, `PdfShading` | 完全缺失 | P4 |
| **Spot颜色** | `SpotColor`, `PdfSpotColor` | 完全缺失 | P4 |
| **图层(OCG)** | `PdfLayer`, `PdfOCProperties` | 完全缺失 | P5 |
| **PDF/A合规** | `setPDFXConformance(PDFA1B)` | 完全缺失 | P5 |
| **Tagged PDF** | `setTagged()`, `PdfStructureElement` | 完全缺失 | P5 |
| **HTML输入** | `HtmlWorker`, `XMLWorker` | 完全缺失 | P5 |

---

## 三、实施提案

### Phase 1 — 核心绘制引擎（P0，约4周）

**目标**：让当前已有的文档/表格/图片功能真正落纸。

#### 1.1 PdfContentByte 图形算子 (`src/core/pdf_content_byte.cj`)

```
// 路径构建
moveTo(x: Float32, y: Float32)
lineTo(x: Float32, y: Float32)
curveTo(x1, y1, x2, y2, x3, y3: Float32)   // 三阶贝塞尔
rectangle(x, y, w, h: Float32)
roundRectangle(x, y, w, h, r: Float32)
closePath()

// 绘制
stroke()
fill()
fillStroke()
newPath()
clip()

// 图形状态
saveState()
restoreState()
setLineWidth(w: Float32)
setLineCap(cap: Int32)
setLineJoin(join: Int32)
setLineDash(phase: Float32, on: Float32, off: Float32)
setFlatness(f: Float32)

// 颜色（扩展RGB到CMYK/Gray）
setColorFill(c: Color)
setColorStroke(c: Color)
setCMYKColorFill(c, m, y, k: Float32)
setGrayFill(g: Float32)

// 文本绝对定位（高频使用）
showTextAligned(align: Int32, text: String, x: Float32, y: Float32, rotation: Float32)
setCharacterSpacing(cs: Float32)
setWordSpacing(ws: Float32)
setTextRenderingMode(mode: Int32)
```

#### 1.2 表格布局算法 (`src/table/`)

```
- 列宽分配：百分比模式 + 绝对模式 + 相对权重模式
- 单元格内容高度计算（文本换行、图片缩放到格宽）
- Colspan 合并列（水平跨格）
- Rowspan 合并行（垂直跨格）
- writeSelectedRows() —— 在绝对坐标写入表格（供页面事件使用）
- 跨页分割（splitRows）
```

#### 1.3 图片解析器 (`src/image/`)

| 文件 | 要实现的内容 |
|------|------------|
| `png_parser.cj` | IDAT chunk 解析、5种行滤波器、RGB/RGBA/灰度/调色板 |
| `gif_parser.cj` | LZW解压、帧提取（取第一帧） |
| `bmp_parser.cj` | DIB header、24/32-bit RGB、RLE压缩 |

**验收标准**：`example_table.cj`、`example_basic.cj` 生成的PDF可在 Adobe Reader / Chrome 中正确渲染。

---

### Phase 2 — 交互元素（P1，约3周）

**目标**：书签、注释、页面事件、多列文本。

#### 2.1 页面事件集成 (`src/core/page_event.cj` → `src/core/pdf_writer.cj`)

```
PdfPageEventHelper 实现8个默认空hook：
  onOpenDocument / onCloseDocument
  onStartPage / onEndPage        ← 水印/页眉/页脚的核心hook
  onParagraph / onParagraphEnd
  onChapter / onChapterEnd
  onSection / onSectionEnd
  onGenericTag                   ← 配合 Chunk.setGenericTag()

PdfWriter 中：
  setPageEvent(event: PdfPageEvent)
  在 newPage() / completePage() 处调用对应hook
```

#### 2.2 书签写入 (`src/form/pdf_outline.cj` → `src/core/pdf_writer.cj`)

```
PdfOutline 字段：
  title: String
  destination: PdfDestination    // XYZ / FIT / FITH / FITV
  style: Int32                   // BOLD=1, ITALIC=2
  color: ?Color
  children: ArrayList<PdfOutline>

PdfWriter.close() 中：
  序列化 outlineTree 为 PDF 间接对象链
  Catalog 写入 /Outlines 引用
  Catalog 写入 /PageMode /UseOutlines
```

#### 2.3 注释渲染 (`src/form/pdf_annotation.cj`)

```
工厂方法：
  createText(rect, title, content, open, icon)
  createLink(rect, action)
  createHighlight(rect, quadPoints)
  createFreeText(rect, content, defaultAppearance)

PdfWriter.completePage() 将 _currentPageAnnots 序列化到页面 /Annots 数组
```

#### 2.4 颜色扩展 (`src/text/color.cj`)

```
新增：
  CMYKColor(c, m, y, k: Float32)
  GrayColor(gray: Float32)

PdfContentByte 根据颜色类型输出正确算子：
  RGB  → "r g b rg/RG"
  CMYK → "c m y k k/K"
  Gray → "g G"
```

#### 2.5 ColumnText (`src/core/column_text.cj`)

```
addSimpleColumn(left, right, bottom, top: Float32)
addElement(Element)
go() → NO_MORE_TEXT | NO_MORE_COLUMN
```

---

### Phase 3 — PDF 读取与操作（P2，约5周）

**目标**：PdfReader + PdfStamper + 合并/分割，覆盖PDF后处理场景。

#### 3.1 PDF Tokenizer (`src/reader/pdf_tokenizer.cj`)

识别所有PDF token：数字、字符串（literal/hex）、名字、布尔、null、数组 `[]`、字典 `<<>>`、流 `stream...endstream`、间接引用 `n g R`、间接对象 `n g obj`。

#### 3.2 XRef 解析 (`src/reader/xref_table.cj`)

```
- 传统交叉引用表（xref...trailer）
- PDF 1.5+ 交叉引用流（XRef stream）
- 线性化PDF的主xref + 更新xref链
输出：objNum → offset 的映射表
```

#### 3.3 PdfReader (`src/reader/pdf_reader.cj`)

```
getNumberOfPages(): Int32
getPageSize(page: Int32): Rectangle
getPageContent(page: Int32): Array<Byte>
setPageContent(page: Int32, content: Array<Byte>)
getInfo(): HashMap<String, String>
getAcroFields(): AcroFields
close()
```

#### 3.4 PdfStamper (`src/reader/pdf_stamper.cj`)

```
getOverContent(page: Int32): PdfContentByte
getUnderContent(page: Int32): PdfContentByte
getAcroFields(): AcroFields
setEncryption(...)
setMoreInfo(info: HashMap<String, String>)
close()
```

#### 3.5 PdfCopy / PdfSmartCopy (`src/reader/pdf_copy.cj`)

```
addPage(importedPage)
addDocument(reader: PdfReader)
selectPages(ranges: String)    // 如 "1-3,5"
智能去重：相同资源（字体、图片）只嵌入一次
```

#### 3.6 文本提取

ContentStreamParser 解析 `BT/ET/Tf/Tm/Tj/TJ` 算子，按阅读顺序输出文本片段。

---

### Phase 4 — 安全与表单（P3，约4周）

**目标**：加密、表单填写，覆盖企业文档场景。

#### 4.1 RC4 / AES 加密 (`src/security/pdf_encryption.cj`)

```
RC4-128   （PDF 1.4，标准加密字典 R=3）
AES-128   （PDF 1.6，R=4）
AES-256   （PDF 2.0，R=6）

PdfWriter.setEncryption(userPwd, ownerPwd, permissions, algorithm)
PdfStamper.setEncryption(...)

权限flags（OR组合）：
  AllowPrinting / AllowCopy / AllowModifyContents
  AllowModifyAnnotations / AllowFillIn / AllowScreenReaders
```

#### 4.2 表单字段外观生成 (`src/form/pdf_form_field.cj`)

```
为每种字段类型生成 /AP（Appearance）字典：
  TextField   → 文本内容流（BT Tf Td Tj ET）
  CheckBox    → 勾选/未勾选外观（√ 或空）
  RadioButton → 选中/未选中外观
  ComboBox    → 当前选项文本流
  PushButton  → 背景色 + 文字标签
```

#### 4.3 AcroFields 填写 (`src/reader/acro_fields.cj`)

读取字段当前值 / 设置新值 / 重新生成外观流，支持通过 PdfStamper 增量写入。

---

### Phase 5 — 富媒体（P4，约3周）

**目标**：条形码、高级图片格式、透明度。

#### 5.1 条形码 (`src/barcode/` 新包)

| 类 | 类型 |
|---|---|
| `Barcode128` | Code 128 A/B/C，GS1-128 |
| `BarcodeEAN` | EAN-13/8，UPC-A/E |
| `Barcode39` | Code 39 / Code 39 Extended |
| `BarcodeQRCode` | 二维码 |
| `BarcodePDF417` | PDF417（物流常用） |

公共接口：`createImage(cb: PdfContentByte, barColor: Color, textColor: Color): Image`

#### 5.2 高级图片格式

```
TIFF     → CCITT Group 3/4（传真压缩）+ 非压缩
JPEG2000 → 直接嵌入 JPXDecode 流
WMF      → 矢量图转 PDF 路径（有限支持）
```

#### 5.3 透明度与渐变

```
PdfGState        → /ca（fill alpha）、/CA（stroke alpha）、/BM（blend mode）
PdfShading       → 轴向渐变（axial）、径向渐变（radial）
PdfShadingPattern → 渐变填充模式
```

---

### Phase 6 — 合规与无障碍（P5，约4周）

**目标**：PDF/A、Tagged PDF，覆盖政府/金融/医疗合规场景。

#### 6.1 PDF/A-1b 合规

```
强制项：
  所有字体嵌入（BaseFont.EMBEDDED）
  禁止加密
  禁止透明度（PDF/A-1）
  ICC输出意图嵌入（OutputIntent）
  XMP元数据（pdfaid:part=1, pdfaid:conformance=B）
  PDF版本 1.4

新增 API：
  PdfWriter.setPdfAConformance(level: PdfAConformance)
  自动检查违规并抛出异常
```

#### 6.2 Tagged PDF（结构树）

```
PdfWriter.setTagged()
PdfStructureElement(parent, role: String)   // P/H1/Table/TR/TD/Figure 等
PdfContentByte.beginMarkedContentSequence(elem)
PdfContentByte.endMarkedContentSequence()
```

#### 6.3 Optional Content Layers（OCG）

```
PdfLayer(name: String, writer: PdfWriter)
cb.beginLayer(layer: PdfLayer)
cb.endLayer()
```

#### 6.4 HTML 输入（低优先级）

解析 `<p>/<b>/<i>/<br>/<ul>/<table>/<img>` 标签，映射为 `Paragraph/Chunk/PdfPTable/Image`，不支持复杂CSS。

---

## 四、工作量估算

| 阶段 | 主要交付 | 估算工时 | 里程碑验收 |
|------|---------|---------|-----------|
| Phase 1 | 图形算子 + 表格布局 + PNG/GIF/BMP解析 | 约4周 | 所有示例PDF可正确渲染 |
| Phase 2 | 页面事件 + 书签 + 注释 + ColumnText | 约3周 | 水印/目录/超链接可用 |
| Phase 3 | PdfReader + PdfStamper + Merge/Split | 约5周 | PDF后处理场景覆盖 |
| Phase 4 | 加密 + 表单填写 | 约4周 | 企业文档安全场景 |
| Phase 5 | 条形码 + 高级图片 + 透明度 | 约3周 | 物流/营销场景覆盖 |
| Phase 6 | PDF/A + Tagged + OCG + HTML | 约4周 | 合规场景覆盖 |
| **合计** | | **约23周** | |

---

## 五、关键技术风险

| 风险 | 说明 | 缓解策略 |
|------|------|---------|
| TrueType 字体嵌入稳定性 | CIDToGIDMap + subset 正确性需多阅读器验证 | Phase 1 前先做多阅读器兼容测试 |
| 表格跨页/跨行 | rowspan 跨页场景逻辑复杂 | 先交付无 rowspan 版本，跨行作为 Phase 1.5 |
| PDF Reader 的流对象嵌套 | 对象流（ObjStm，PDF 1.5+）解析难度较高 | 先实现传统 xref，ObjStm 放 Phase 3 后期 |
| AES-256 (R=6) 规范复杂 | PDF 2.0 加密规范变化较大 | 先实现 RC4-128 和 AES-128，AES-256 作为独立子任务 |
| 仓颉生态缺第三方库 | 无 BouncyCastle 等现成加密库 | 加密算法自行实现或 FFI 调用 OpenSSL |

---

## 六、推荐推进顺序

```
立即启动 → Phase 1（图形绘制 + 表格布局 + PNG解析）
              ↓ 完成后
          Phase 2（页面事件 + 书签）← 用户可见价值最高
              ↓ 完成后
          Phase 3（PDF读取）← 企业使用必须
              ↓ 完成后
          Phase 4（加密 + 表单）← 安全合规
              ↓ 按需
          Phase 5 / Phase 6 按业务优先级选择
```

**当前最紧迫的单项工作**：`PdfContentByte` 图形算子——表格边框、图片定位、文本绝对坐标等全部依赖它，没有它其他模块无法真正出图。
