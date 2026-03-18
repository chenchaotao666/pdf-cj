# PDF-CJ 示例程序

本目录包含 PDF-CJ 库的示例程序，展示各种功能的使用方法。

## 📁 示例列表

### 1. hello_world.cj
**入门示例** - 最简单的 PDF 创建流程

展示内容：
- 创建基本 PDF 文档
- 添加标题和段落
- 设置字体和对齐方式

```bash
cjpm run hello_world
```

### 2. comprehensive_example.cj
**综合示例** - 展示所有核心功能

展示内容：
- ✅ 文本和段落处理
- ✅ 多种字体和样式
- ✅ 表格创建（简单和复杂）
- ✅ 图片支持（多种缩放方式）
- ✅ 编码和压缩（Flate、ASCIIHex、ASCII85）
- ✅ 页眉和页脚
- ✅ 文档元数据
- ✅ 高级格式控制

```bash
cjpm run comprehensive_example
```

### 3. table_example.cj
**表格专题示例** - 深入展示表格功能

展示内容：
- 基础表格创建
- 表格样式（背景色、边框、内边距）
- 跨行跨列
- 嵌套内容（在单元格中添加段落）
- 交替行颜色
- 合计行

```bash
cjpm run table_example
```

## 🚀 运行示例

### 前置条件

确保已经构建了 pdf-cj 库：

```bash
# 在项目根目录下
cd pdf-cj
cjpm build
```

### 方法 1：使用运行脚本（推荐）

项目提供了便捷的运行脚本：

```bash
# 运行 hello_world 示例
./run_example.sh hello_world

# 运行表格示例
./run_example.sh table_example

# 运行综合示例
./run_example.sh comprehensive_example
```

### 方法 2：手动编译运行

```bash
# 编译并运行 hello_world
cjc --import-path target/release/pdf_cj examples/hello_world.cj \
    target/release/pdf_cj/libpdf_cj*.a -o hello_world
./hello_world

# 或者使用更简洁的方式（链接所有库）
cjc --import-path target/release/pdf_cj examples/hello_world.cj \
    target/release/pdf_cj/*.a -o hello_world && ./hello_world
```

## 📖 示例说明

### 基本使用流程

所有示例都遵循以下基本流程：

```cangjie
// 1. 导入库
import std.io.FileOutputStream
import pdf_cj.*

main() {
    // 2. 创建输出流
    let output = FileOutputStream("output.pdf")
    
    // 3. 创建文档
    let document = Document()
    
    // 4. 获取写入器
    let writer = PdfWriter.getInstance(document, output)
    
    // 5. 打开文档
    document.open()
    
    // 6. 添加内容
    document.add(Paragraph("Hello World"))
    
    // 7. 关闭文档
    document.close()
    output.close()
}
```

### 常用代码片段

#### 创建带样式的段落

```cangjie
let font = Font(FontFamily.Helvetica, 14.0, FontStyle.Bold)
let para = Paragraph("标题文本", font)
para.setAlignment(Alignment.Center)
para.setSpacingAfter(20.0)
document.add(para)
```

#### 创建简单表格

```cangjie
let table = PdfPTable(3)  // 3列
table.setWidthPercentage(100.0)

// 添加表头
for (header in ["列1", "列2", "列3"]) {
    table.addCell(header)
}

// 添加数据
for (data in ["值1", "值2", "值3"]) {
    table.addCell(data)
}

document.add(table)
```

#### 创建带样式的单元格

```cangjie
let cell = PdfPCell(Phrase("内容", font))
cell.setHorizontalAlignment(Alignment.Center)
cell.setBackgroundColor(Color(200, 200, 200))
cell.setPadding(10.0)
cell.setBorderWidth(2.0)
table.addCell(cell)
```

#### 设置页眉页脚

```cangjie
let headerPhrase = Phrase("文档标题", headerFont)
let header = HeaderFooter(headerPhrase, false)
document.setHeader(header)

let footerPhrase = Phrase("第 ", footerFont)
let footer = HeaderFooter(footerPhrase, true)  // true 显示页码
document.setFooter(footer)
```

## 🎯 学习路径

1. **初学者**：从 `hello_world.cj` 开始，了解基本流程
2. **进阶**：阅读 `table_example.cj`，学习表格创建
3. **全面掌握**：研究 `comprehensive_example.cj`，了解所有功能

## 📚 更多资源

- [API 文档](../DESIGN.md) - 查看完整的 API 设计
- [项目主页](../README.md) - 了解项目概况
- [贡献指南](../CONTRIBUTING.md) - 如何为项目做贡献

## ⚠️ 注意事项

1. **图片文件**：图片相关示例需要实际的图片文件（.jpg、.png 等）
2. **字体支持**：当前版本使用内置字体，未来将支持自定义字体
3. **输出目录**：生成的 PDF 文件位于项目根目录

## 🐛 问题反馈

如果运行示例时遇到问题，请：
1. 检查 cjpm 版本是否最新
2. 确保项目已正确编译（`cjpm build`）
3. 查看错误信息并参考文档
4. 在 GitHub 提交 Issue

---

**Happy Coding with PDF-CJ! 🎉**
