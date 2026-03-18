/**
 * PDF-CJ: PdfPTable - PDF 表格
 * 高级表格类，支持自动布局、跨页等功能
 */
package pdf_cj.table

import std.collection.ArrayList
import pdf_cj.api.{Element, ElementType, ElementListener, Chunk, Phrase, Paragraph}
import pdf_cj.text.Alignment
import pdf_cj.util.PdfException

/**
 * PdfPTable 类 - PDF 表格
 * 支持多列、自动布局、表头重复等高级功能
 */
public class PdfPTable <: Element {
    private let _numColumns: Int32
    private var _rows: ArrayList<PdfPRow> = ArrayList<PdfPRow>()
    private var _currentRow: ArrayList<PdfPCell> = ArrayList<PdfPCell>()
    private var _currentRowSpan: Int32 = 0  // 当前行已占用的列数（考虑 colspan）

    // 宽度设置
    private var _widthPercentage: Float32 = 80.0
    private var _totalWidth: Float32 = 0.0
    private var _lockedWidth: Bool = false
    private var _columnWidths: ?Array<Float32> = None
    private var _relativeWidths: ?Array<Float32> = None

    // 对齐方式
    private var _horizontalAlignment: Alignment = Alignment.Center

    // 表头设置
    private var _headerRows: Int32 = 0
    private var _footerRows: Int32 = 0
    private var _skipFirstHeader: Bool = false
    private var _skipLastFooter: Bool = false

    // 分页设置
    private var _keepTogether: Bool = false
    private var _splitLate: Bool = true
    private var _splitRows: Bool = true

    // 间距设置
    private var _spacingBefore: Float32 = 0.0
    private var _spacingAfter: Float32 = 0.0

    // 默认单元格（用于设置默认样式）
    private var _defaultCell: PdfPCell = PdfPCell()

    /**
     * 创建指定列数的表格
     */
    public init(numColumns: Int32) {
        if (numColumns <= 0) {
            throw PdfException("Table must have at least one column")
        }
        this._numColumns = numColumns
    }

    /**
     * 使用相对宽度创建表格
     */
    public init(relativeWidths: Array<Float32>) {
        if (relativeWidths.size == 0) {
            throw PdfException("Table must have at least one column")
        }
        this._numColumns = Int32(relativeWidths.size)
        this._relativeWidths = Some(relativeWidths)
    }

    // ===== 单元格添加 =====

    /**
     * 添加单元格
     */
    public func addCell(cell: PdfPCell): Unit {
        _currentRow.add(cell)
        _currentRowSpan += cell.colspan

        // 如果当前行已满（考虑 colspan），创建新行
        if (_currentRowSpan >= _numColumns) {
            completeRow()
        }
    }

    /**
     * 添加 Phrase 作为单元格
     */
    public func addCell(phrase: Phrase): Unit {
        addCell(PdfPCell(phrase))
    }

    /**
     * 添加 Paragraph 作为单元格
     */
    public func addCell(paragraph: Paragraph): Unit {
        addCell(PdfPCell(paragraph))
    }

    /**
     * 添加文本作为单元格
     */
    public func addCell(text: String): Unit {
        addCell(Phrase(text))
    }

    /**
     * 完成当前行
     */
    public func completeRow(): Unit {
        if (_currentRow.isEmpty()) {
            return
        }

        // 如果当前行不足列数，用空单元格填充
        while (_currentRowSpan < _numColumns) {
            _currentRow.add(PdfPCell())
            _currentRowSpan += 1
        }

        _rows.add(PdfPRow(_currentRow))
        _currentRow = ArrayList<PdfPCell>()
        _currentRowSpan = 0  // 重置列跨度计数
    }

    /**
     * 删除最后一行
     */
    public func deleteLastRow(): Bool {
        if (_rows.isEmpty()) {
            return false
        }
        _rows.remove((_rows.size - 1)..(_rows.size))
        true
    }

    /**
     * 删除所有非表头行
     */
    public func deleteBodyRows(): Unit {
        while (Int32(_rows.size) > _headerRows) {
            _rows.remove((_rows.size - 1)..(_rows.size))
        }
    }

    // ===== 宽度设置 =====

    /**
     * 设置宽度百分比
     */
    public func setWidthPercentage(percentage: Float32): Unit {
        this._widthPercentage = percentage
    }

    /**
     * 获取宽度百分比
     */
    public prop widthPercentage: Float32 {
        get() { _widthPercentage }
    }

    /**
     * 设置总宽度
     */
    public func setTotalWidth(width: Float32): Unit {
        this._totalWidth = width
        this._lockedWidth = true
    }

    /**
     * 设置列宽（绝对宽度）
     */
    public func setTotalWidth(widths: Array<Float32>): Unit {
        if (Int32(widths.size) != _numColumns) {
            throw PdfException("Wrong number of column widths")
        }
        this._columnWidths = Some(widths)

        var total: Float32 = 0.0
        for (w in widths) {
            total = total + w
        }
        this._totalWidth = total
        this._lockedWidth = true
    }

    /**
     * 获取总宽度
     */
    public prop totalWidth: Float32 {
        get() { _totalWidth }
    }

    /**
     * 设置是否锁定宽度
     */
    public func setLockedWidth(locked: Bool): Unit {
        this._lockedWidth = locked
    }

    /**
     * 获取是否锁定宽度
     */
    public prop lockedWidth: Bool {
        get() { _lockedWidth }
    }

    /**
     * 设置相对列宽
     */
    public func setWidths(relativeWidths: Array<Float32>): Unit {
        if (Int32(relativeWidths.size) != _numColumns) {
            throw PdfException("Wrong number of column widths")
        }
        this._relativeWidths = Some(relativeWidths)
    }

    // ===== 对齐方式 =====

    /**
     * 设置水平对齐
     */
    public func setHorizontalAlignment(alignment: Alignment): Unit {
        this._horizontalAlignment = alignment
    }

    /**
     * 设置水平对齐（整数）
     */
    public func setHorizontalAlignment(alignment: Int32): Unit {
        this._horizontalAlignment = Alignment.fromInt(alignment)
    }

    /**
     * 获取水平对齐
     */
    public prop horizontalAlignment: Alignment {
        get() { _horizontalAlignment }
    }

    // ===== 表头设置 =====

    /**
     * 设置表头行数
     */
    public func setHeaderRows(rows: Int32): Unit {
        this._headerRows = rows
    }

    /**
     * 获取表头行数
     */
    public prop headerRows: Int32 {
        get() { _headerRows }
    }

    /**
     * 设置页脚行数
     */
    public func setFooterRows(rows: Int32): Unit {
        this._footerRows = rows
    }

    /**
     * 获取页脚行数
     */
    public prop footerRows: Int32 {
        get() { _footerRows }
    }

    /**
     * 设置跳过第一个表头
     */
    public func setSkipFirstHeader(skip: Bool): Unit {
        this._skipFirstHeader = skip
    }

    /**
     * 获取是否跳过第一个表头
     */
    public prop skipFirstHeader: Bool {
        get() { _skipFirstHeader }
    }

    /**
     * 设置跳过最后一个页脚
     */
    public func setSkipLastFooter(skip: Bool): Unit {
        this._skipLastFooter = skip
    }

    /**
     * 获取是否跳过最后一个页脚
     */
    public prop skipLastFooter: Bool {
        get() { _skipLastFooter }
    }

    // ===== 分页设置 =====

    /**
     * 设置是否保持在一页
     */
    public func setKeepTogether(keep: Bool): Unit {
        this._keepTogether = keep
    }

    /**
     * 获取是否保持在一页
     */
    public prop keepTogether: Bool {
        get() { _keepTogether }
    }

    /**
     * 设置是否延迟拆分
     */
    public func setSplitLate(splitLate: Bool): Unit {
        this._splitLate = splitLate
    }

    /**
     * 获取是否延迟拆分
     */
    public prop splitLate: Bool {
        get() { _splitLate }
    }

    /**
     * 设置是否允许拆分行
     */
    public func setSplitRows(splitRows: Bool): Unit {
        this._splitRows = splitRows
    }

    /**
     * 获取是否允许拆分行
     */
    public prop splitRows: Bool {
        get() { _splitRows }
    }

    // ===== 间距设置 =====

    /**
     * 设置前间距
     */
    public func setSpacingBefore(spacing: Float32): Unit {
        this._spacingBefore = spacing
    }

    /**
     * 获取前间距
     */
    public prop spacingBefore: Float32 {
        get() { _spacingBefore }
    }

    /**
     * 设置后间距
     */
    public func setSpacingAfter(spacing: Float32): Unit {
        this._spacingAfter = spacing
    }

    /**
     * 获取后间距
     */
    public prop spacingAfter: Float32 {
        get() { _spacingAfter }
    }

    // ===== 默认单元格 =====

    /**
     * 获取默认单元格（用于设置默认样式）
     */
    public func getDefaultCell(): PdfPCell {
        _defaultCell
    }

    // ===== Element 接口实现 =====

    public func getType(): ElementType {
        ElementType.Table
    }

    public func getChunks(): ArrayList<Chunk> {
        // 表格没有直接的 Chunk
        ArrayList<Chunk>()
    }

    public func isContent(): Bool {
        true
    }

    public func isNestable(): Bool {
        false
    }

    public func process(listener: ElementListener): Bool {
        listener.add(this)
    }

    // ===== 属性访问 =====

    /**
     * 获取列数
     */
    public prop columns: Int32 {
        get() { _numColumns }
    }

    /**
     * 获取行数
     */
    public prop rowCount: Int32 {
        get() { Int32(_rows.size) }
    }

    /**
     * 获取指定行
     */
    public func getRow(index: Int32): ?PdfPRow {
        if (index >= 0 && index < Int32(_rows.size)) {
            Some(_rows[Int64(index)])
        } else {
            None
        }
    }

    /**
     * 获取所有行
     */
    public func getRows(): ArrayList<PdfPRow> {
        _rows
    }
}

/**
 * PdfPRow 类 - 表格行
 * 内部使用，表示表格的一行
 */
public class PdfPRow {
    private let _cells: ArrayList<PdfPCell>
    private var _maxHeight: Float32 = 0.0
    private var _calculated: Bool = false

    /**
     * 使用单元格列表创建行
     */
    public init(cells: ArrayList<PdfPCell>) {
        this._cells = cells
    }

    /**
     * 获取指定列的单元格
     */
    public func getCell(index: Int32): ?PdfPCell {
        if (index >= 0 && index < Int32(_cells.size)) {
            Some(_cells[Int64(index)])
        } else {
            None
        }
    }

    /**
     * 获取单元格数量
     */
    public prop cellCount: Int32 {
        get() { Int32(_cells.size) }
    }

    /**
     * 设置最大高度
     */
    public func setMaxHeight(height: Float32): Unit {
        this._maxHeight = height
        this._calculated = true
    }

    /**
     * 获取最大高度
     */
    public prop maxHeight: Float32 {
        get() { _maxHeight }
    }

    /**
     * 是否已计算高度
     */
    public prop isCalculated: Bool {
        get() { _calculated }
    }

    /**
     * 获取所有单元格
     */
    public func getCells(): ArrayList<PdfPCell> {
        _cells
    }
}
