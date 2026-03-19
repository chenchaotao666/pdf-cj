# PDF-CJ

用仓颉语言编写的原生 PDF 库，对标 Java 的 OpenPDF 库。

[![Cangjie](https://img.shields.io/badge/Cangjie-0.55.3-blue)](https://developer.huawei.com/consumer/cn/cangjie/)
[![License](https://img.shields.io/badge/license-Apache%202.0-green)](LICENSE)

## ✨ 特性

- 📄 **完整的 PDF 创建**：从零创建 PDF 文档
- 📝 **丰富的文本处理**：支持多种字体、样式和对齐方式
- 🌏 **中文字体支持**：支持 Unicode 编码和 CIDFont，完美显示中文 **[NEW]**
- 📊 **强大的表格功能**：支持复杂表格、跨行列、样式定制
- 🖼️ **图片支持**：支持 JPEG、PNG、GIF、BMP、TIFF 等格式
- 🗜️ **压缩和编码**：Flate、ASCII Hex、ASCII85 编码
- 📑 **页面管理**：页眉页脚、页码、自定义页面大小
- 🎨 **样式控制**：颜色、边框、背景、间距等
- 🔧 **元数据支持**：标题、作者、关键词等文档属性

## 📦 安装

### 从源码构建

```bash
git clone https://github.com/yourusername/pdf-cj.git
cd pdf-cj
cjpm build
```

### 在项目中使用

在您的 `cjpm.toml` 中添加依赖：

```toml
[dependencies]
pdf_cj = { path = "../pdf-cj" }
```

## 🚀 快速开始

### 基础示例

```cangjie
import std.fs.*
import pdf_cj.*

main() {
    // 创建输出文件
    let output = File(Path("hello.pdf"), OpenMode.Write)

    // 创建文档
    let document = Document(PageSize.A4)
    let writer = PdfWriter.getInstance(document, output)

    // 设置元数据
    document.addTitle("我的第一个PDF")
    document.addAuthor("张三")

    // 打开文档
    document.open()

    // 添加英文标题
    let titleFont = Font(FontFamily.Helvetica, 20.0, FontStyle.Bold)
    let title = Paragraph("Hello, PDF-CJ!", titleFont)
    title.setAlignment(Alignment.Center)
    document.add(title)

    // 添加中文段落
    let chineseBaseFont = BaseFont.createFont("SimSun", BaseFont.IDENTITY_H, BaseFont.NOT_EMBEDDED)
    let chineseFont = Font(chineseBaseFont, 12.0, FontStyle.Normal)
    let para = Paragraph("这是我的第一个PDF文档。", chineseFont)
    document.add(para)

    // 关闭文档
    document.close()
    output.close()

    println("PDF创建成功！")
}
```

### 中文字体支持

PDF-CJ 现已完美支持中文！详细使用方法请查看 [中文字体支持指南](CHINESE_SUPPORT.md)。

```cangjie
// 使用系统字体
let font = BaseFont.createFont("SimSun", BaseFont.IDENTITY_H, BaseFont.NOT_EMBEDDED)

// 或使用字体文件（推荐）
let font = BaseFont.createFont(
    "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc",
    BaseFont.IDENTITY_H,
    BaseFont.EMBEDDED
)
```

## 📚 文档

### 核心功能

#### 1. 创建文档

```cangjie
// 默认 A4 页面
let document = Document()

// 自定义页面大小
let document = Document(PageSize.LETTER)

// 自定义边距（左、右、上、下）
let document = Document(PageSize.A4, 50.0, 50.0, 50.0, 50.0)
```

#### 2. 文本和段落

```cangjie
// 创建字体
let font = Font(FontFamily.Helvetica, 14.0, FontStyle.Bold)

// 创建段落
let para = Paragraph("段落内容", font)
para.setAlignment(Alignment.Center)
para.setSpacingAfter(20.0)
para.setFirstLineIndent(20.0)

// 添加到文档
document.add(para)
```

#### 3. 表格

```cangjie
// 创建 3 列表格
let table = PdfPTable(3)
table.setWidthPercentage(100.0)

// 添加表头
let headerCell = PdfPCell(Phrase("表头", headerFont))
headerCell.setHorizontalAlignment(Alignment.Center)
headerCell.setBackgroundColor(Color(200, 200, 200))
headerCell.setPadding(8.0)
table.addCell(headerCell)

// 添加数据单元格
table.addCell("数据1")
table.addCell("数据2")
table.addCell("数据3")

// 跨列单元格
let spanCell = PdfPCell(Phrase("合并单元格", font))
spanCell.setColspan(3)
table.addCell(spanCell)

document.add(table)
```

#### 4. 图片

```cangjie
// 加载图片
let image = Image.getInstance("photo.jpg")

// 缩放到 50%
image.scalePercent(50.0)

// 或缩放到指定大小
image.scaleAbsolute(200.0, 150.0)

// 或适应指定区域（保持宽高比）
image.scaleToFit(400.0, 300.0)

// 设置对齐方式
image.setAlignment(Alignment.Center)

document.add(image)
```

#### 5. 页眉和页脚

```cangjie
// 设置页眉
let headerFont = Font(FontFamily.Helvetica, 10.0, FontStyle.Italic)
let headerPhrase = Phrase("文档标题", headerFont)
let header = HeaderFooter(headerPhrase, false)
header.setAlignment(Alignment.Right)
document.setHeader(header)

// 设置页脚（带页码）
let footerPhrase = Phrase("第 ", headerFont)
let afterPhrase = Phrase(" 页", headerFont)
let footer = HeaderFooter(footerPhrase, true, afterPhrase)
footer.setAlignment(Alignment.Center)
document.setFooter(footer)
```

#### 6. 编码和压缩

```cangjie
// ASCII Hex 编码
let data: Array<UInt8> = [0x48, 0x65, 0x6C, 0x6C, 0x6F]
let hexEncoded = ASCIIHexEncoder.encode(data)
// 输出: "48656C6C6F>"

// ASCII85 编码
let ascii85Encoded = ASCII85Encoder.encode(data)
// 输出: "87cURD]j~>"

// Flate 压缩
let compressed = FlateEncoder.encode(data)
```

## 📖 示例

项目包含四个完整示例：

1. **hello_world.cj** - 最简单的入门示例（含中英文混排）
2. **example_chinese.cj** - 中文字体使用示例 **[NEW]**
3. **example_table.cj** - 表格功能深入演示
4. **example_comprehensive.cj** - 所有功能综合展示

运行示例：

```bash
# 构建项目
cjpm build

# 运行示例（使用便捷脚本）
./run_example.sh hello_world
./run_example.sh example_chinese
./run_example.sh example_table
./run_example.sh example_comprehensive
```

详细说明请查看 [examples/README.md](examples/README.md)

## 🏗️ 项目结构

```
pdf-cj/
├── src/
│   ├── lib.cj              # 主入口，导出所有公共 API
│   ├── api/                # 核心 API（Document、Element、Paragraph等）
│   ├── base/               # 基础对象（PdfObject、PdfDictionary等）
│   ├── codec/              # 编码器（Flate、ASCIIHex、ASCII85）
│   ├── core/               # 核心写入器（PdfWriter、PdfContentByte）
│   ├── image/              # 图片处理（Image、ImageType）
│   ├── table/              # 表格模块（PdfPTable、PdfPCell）
│   ├── text/               # 文本相关（Font、Color、Alignment）
│   └── util/               # 工具类（PageSize、Rectangle）
├── examples/               # 示例程序
│   ├── hello_world.cj
│   ├── example_table.cj
│   ├── example_comprehensive.cj
│   └── README.md
├── cjpm.toml              # 项目配置
├── DESIGN.md              # API 设计文档
└── README.md              # 本文件
```

## 🔧 开发状态

当前版本：**v0.1.0**

### ✅ 已完成功能

- [x] 文档创建和基本属性
- [x] 文本处理（Chunk、Phrase、Paragraph）
- [x] 字体支持（Helvetica、Times、Courier 等）
- [x] **中文字体支持（Unicode、CIDFont）** **[NEW]**
- [x] 表格功能（PdfPTable、跨行列、样式）
- [x] 图片支持（JPEG、PNG、GIF、BMP、TIFF）
- [x] 编码和压缩（Flate、ASCIIHex、ASCII85）
- [x] 页眉和页脚
- [x] 颜色和对齐方式
- [x] 页面大小和边距
- [x] 基础 PDF 对象模型
- [x] PdfWriter 核心写入逻辑

### 🚧 进行中

- [ ] 字体子集化（减小嵌入字体的文件大小）
- [ ] ToUnicode CMap（改进文本提取）
- [ ] 高级绘图 API（线条、形状）
- [ ] 书签和目录
- [ ] PDF 表单
- [ ] 加密和权限控制

### 📝 计划中

- [ ] PDF 读取和解析
- [ ] PDF 修改和合并
- [ ] 数字签名
- [ ] PDF/A 支持
- [ ] 性能优化

## 🤝 贡献

欢迎贡献代码、报告问题或提出建议！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 Apache 2.0 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- 灵感来源于 Java 的 [OpenPDF](https://github.com/LibrePDF/OpenPDF) 库
- 感谢华为仓颉团队提供优秀的编程语言

## 📧 联系方式

- 问题反馈：[GitHub Issues](https://github.com/yourusername/pdf-cj/issues)
- 讨论交流：[GitHub Discussions](https://github.com/yourusername/pdf-cj/discussions)

---

**用仓颉创造，用 PDF-CJ 分享！** 🎉
