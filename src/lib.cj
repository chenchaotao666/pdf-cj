/**
 * PDF-CJ: 仓颉 PDF 库
 * 用于创建、编辑和读取 PDF 文档的原生仓颉库
 *
 * 对标 Java 的 OpenPDF 库
 */
package pdf_cj

// 导出核心 API
public import pdf_cj.api.{
    Document, Element, ElementType, ElementListener,
    Chunk, Phrase, Paragraph, Chapter, HeaderFooter, DocListener
}

// 导出核心写入器
public import pdf_cj.core.{
    PdfWriter, PdfContentByte, PdfPageEvent, PdfPageEventAdapter,
    ColumnText
}

// 导出文本相关
public import pdf_cj.text.{
    Font, BaseFont, FontFactory, FontStyle, FontFamily,
    Color, Alignment
}

// 导出工具类
public import pdf_cj.util.{
    Rectangle, PageSize, PdfException
}

// 导出表格模块
public import pdf_cj.table.{
    PdfPTable, PdfPRow, PdfPCell, VerticalAlignment
}

// 导出图片模块
public import pdf_cj.image.{
    Image, ImageType
}

// 导出编解码模块
public import pdf_cj.codec.{
    FlateEncoder, ASCIIHexEncoder, ASCII85Encoder
}

// 导出基础对象（供高级用户使用）
public import pdf_cj.base.{
    PdfObject, PdfObjectType,
    PdfNull, PdfBoolean, PdfNumber, PdfString,
    PdfName, PdfArray, PdfDictionary, PdfStream,
    PdfIndirectReference
}
