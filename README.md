# PDF-CJ

用仓颉（Cangjie）语言编写的原生 PDF 库。
支持从零创建、读取、修改、合并 PDF，内置中文字体嵌入与子集化、表格、图片、
矢量绘图、书签、注释、表单、条形码、渐变/透明度、加密与数字签名等能力。

![Cangjie](https://img.shields.io/badge/Cangjie-1.0.4-blue)
![License](https://img.shields.io/badge/license-Apache%202.0-green)

## ✨ 特性

- 📄 **PDF 创建**：从零创建文档，自定义页面大小与边距、元数据
- 📝 **文本排版**：Chunk / Phrase / Paragraph，字体样式、对齐、缩进、行距、间距
- 🌏 **中文字体**：Unicode（Identity-H）+ CIDFont，TrueType/OpenType 嵌入并**自动子集化**
- 📊 **表格**：PdfPTable / PdfPCell，跨行列、表头重复、边框/背景/对齐/内边距
- 🖼️ **图片**：JPEG、PNG、GIF、BMP、JPEG2000；缩放、旋转、定位
- ✏️ **底层绘图**：PdfContentByte 路径/填充/描边/贝塞尔/线型/文本/变换/裁剪
- 📰 **多列排版**：ColumnText
- 📑 **页面管理**：页眉页脚、页码、PageEvent 页面事件钩子
- 🔖 **书签与章节**：Chapter / Section 自动书签，PdfOutline 树形大纲
- 💬 **注释**：文本、链接、高亮、下划线、删除线、方框、圆形、自由文本、图章
- 📋 **表单**：AcroForm 文本框/复选框/单选/下拉/列表/按钮，读取与填写
- 🔢 **条形码**：Code 128、EAN-13/8、Code 39、QR、PDF417、DataMatrix
- 🎨 **渐变与透明**：轴向/径向渐变、Alpha 透明度与混合模式
- 🔐 **加密与签名**：RC4-128 / AES-128 / AES-256 + 权限控制，PKCS#7 数字签名
- 📖 **读取与修改**：PdfReader 读取、PdfStamper 盖章/填表、PdfCopy/PdfSmartCopy 合并、文本提取
- 🗜️ **编码压缩**：Flate、ASCII Hex、ASCII85

## 📦 安装

### 从源码构建

```bash
git clone https://github.com/chenchaotao666/pdf-cj.git
cd pdf-cj
./build.sh        # 自动检测 HiTLS 路径、生成 cjpm.toml 并构建
```

> pdf-cj 依赖 [OpenHiTLS](https://gitcode.com/openHiTLS/openhitls)（加密 FFI）与 `zlib4cj`（压缩）。

## 🚀 快速开始

```cangjie
import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.text.{Font, BaseFont, FontStyle, Alignment}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

main(): Int64 {
    // 1. 创建文档（A4，四边留白 72pt）
    let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
    let file = File(Path("hello.pdf"), OpenMode.Write)
    let writer = PdfWriter.getInstance(doc, file)

    doc.addTitle("我的第一个 PDF")
    doc.open()

    // 2. 英文标题（标准 14 字体，无需嵌入）
    let helv = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED)
    let title = Paragraph("Hello, PDF-CJ!", Font(helv, 20.0, FontStyle.Bold))
    title.setAlignment(Alignment.Center)
    doc.add(title)

    // 3. 中文段落（嵌入 CJK 字体，自动子集化）
    let cjk = BaseFont.createFont(
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
    doc.add(Paragraph("这是我的第一个 PDF 文档。", Font(cjk, 12.0)))

    // 4. 关闭文档（写出 xref / trailer）
    doc.close()
    0
}
```

## 📚 文档

- **[完整 API 指南 docs/feature_api.md](docs/feature_api.md)** —— 23 节、覆盖全部公开 API，
  含文档/字体/颜色/文本/表格/图片/绘图/书签/注释/表单/条形码/加密/读取/合并/文本提取等用法与代码片段。
- **[示例 examples/](examples/README.md)** —— 23 个可运行的端到端示例（S01–S23）。
- **[gap 分析 docs/openpdf-gap-analysis.md](docs/openpdf-gap-analysis.md)** —— 与 OpenPDF 的对照差距。

## 📖 示例

`examples/` 是一个独立的 cjpm 可执行项目，通过 `pdf_cj = { path = ".." }` 依赖本库，
包含 23 个功能模块（S01–S23），与 `openpdf-examples/` 下的 OpenPDF Java 示例一一对应。

```bash
cd examples
./build.sh                       # 检测 HiTLS、生成 cjpm.toml 并构建

cjpm run                         # 运行全部 23 个模块（默认）
cjpm run --run-args "7"          # 运行单个模块（示例：S07 表格）
```

详细说明见 [examples/README.md](examples/README.md)。

## 🏗️ 项目结构

```
pdf-cj/
├── src/
│   ├── lib.cj              # 主入口，导出所有公共 API
│   ├── api/                # 高层元素（Document、Paragraph、Chunk、Chapter…）
│   ├── base/               # 基础对象（PdfObject、PdfDictionary、输出流…）
│   ├── codec/              # 编码器（Flate、ASCIIHex、ASCII85）
│   ├── core/               # 写入器与画布（PdfWriter、PdfContentByte、渐变、ColumnText…）
│   ├── text/               # 字体与文本（BaseFont、Font、Color、字体子集化…）
│   ├── table/              # 表格（PdfPTable、PdfPCell）
│   ├── image/              # 图片（Image、各格式解析器）
│   ├── form/               # 注释、表单、书签、动作
│   ├── barcode/            # 条形码（128/EAN/39/QR/PDF417/DataMatrix）
│   ├── security/           # 加密、PKCS#7 签名、证书
│   ├── reader/             # 读取/盖章/合并/文本提取
│   └── util/               # 工具类（PageSize、Rectangle）
├── examples/               # 仓颉示例（独立 cjpm 可执行项目）
│   ├── src/               # S01–S23 + main.cj + SharedFonts.cj
│   ├── images/            # 示例图片资源
│   ├── cjpm.toml.example  # 配置模板（build.sh 据此生成 cjpm.toml）
│   ├── build.sh           # 检测 HiTLS、生成 cjpm.toml 并构建
│   └── README.md
├── openpdf-examples/       # OpenPDF Java 对照示例（与 examples 一一对应）
│   ├── src/main/java/
│   ├── images/
│   ├── pom.xml
│   └── README.md
├── docs/                   # feature_api.md（API 指南）、gap 分析
├── build.sh               # 检测 HiTLS、生成 cjpm.toml 并构建
├── cjpm.toml.example      # 配置模板（build.sh 据此生成 cjpm.toml）
└── README.md              # 本文件
```

## 📄 许可证

本项目采用 **MIT License** 许可证。

## 🙏 致谢

- 灵感来源于 Java 的 [OpenPDF](https://github.com/LibrePDF/OpenPDF) 库
- 加密能力基于 [OpenHiTLS](https://gitcode.com/openHiTLS/openhitls)

---

**用仓颉创造，用 PDF-CJ 分享！** 🎉
