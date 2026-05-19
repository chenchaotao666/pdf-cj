/**
 * PDF-CJ: PdfPTable - PDF 表格
 * 高级表格类，支持自动布局、跨列、跨行等功能
 */
package pdf_cj.table

import std.collection.ArrayList
import pdf_cj.api.{Element, ElementType, ElementListener, Chunk, Phrase, Paragraph}
import pdf_cj.text.Alignment
import pdf_cj.util.PdfException

/**
 * PdfPTable 类 - PDF 表格
 * 支持多列、自动布局、colspan、rowspan、表头重复等功能
 */
public class PdfPTable <: Element {
    private let _numColumns: Int32
    private var _rows: ArrayList<PdfPRow> = ArrayList<PdfPRow>()
    private var _currentRow: ArrayList<PdfPCell> = ArrayList<PdfPCell>()
    private var _currentRowStartCols: ArrayList<Int32> = ArrayList<Int32>()
    private var _currentRowSpan: Int32 = 0

    // 跨行追踪器：每列剩余被占用的行数（由 rowspan 产生）
    private var _rowspanTracker: Array<Int32> = Array<Int32>(0, {_ => 0})

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

    // 默认单元格
    private var _defaultCell: PdfPCell = PdfPCell()

    /**
     * 创建指定列数的表格
     */
    public init(numColumns: Int32) {
        if (numColumns <= 0) {
            throw PdfException("Table must have at least one column")
        }
        this._numColumns = numColumns
        this._rowspanTracker = Array<Int32>(Int64(numColumns), {_ => 0})
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
        this._rowspanTracker = Array<Int32>(relativeWidths.size, {_ => 0})
    }

    // ===== 单元格添加 =====

    /**
     * 添加单元格（支持 colspan 和 rowspan）
     */
    public func addCell(cell: PdfPCell): Unit {
        // 从当前位置向后探测第一个空闲列（未被 rowspan 占用）
        var startCol: Int32 = _currentRowSpan
        while (startCol < _numColumns && _rowspanTracker[Int64(startCol)] > 0) {
            startCol += 1
        }

        _currentRowStartCols.add(startCol)
        _currentRow.add(cell)

        // 为 rowspan > 1 的单元格标记后续行的占用状态
        if (cell.rowspan > 1) {
            var c: Int32 = 0
            while (c < cell.colspan && (startCol + c) < _numColumns) {
                _rowspanTracker[Int64(startCol + c)] = cell.rowspan
                c += 1
            }
        }

        _currentRowSpan = startCol + cell.colspan

        if (isCurrentRowComplete()) {
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
     * 完成当前行（填充剩余空闲列）
     */
    public func completeRow(): Unit {
        if (_currentRow.isEmpty()) {
            return
        }

        // 填充当前行中未被 rowspan 占用的剩余空列
        var col: Int32 = _currentRowSpan
        while (col < _numColumns) {
            if (_rowspanTracker[Int64(col)] == 0) {
                _currentRowStartCols.add(col)
                _currentRow.add(PdfPCell())
            }
            col += 1
        }

        _rows.add(PdfPRow(_currentRow, _currentRowStartCols))
        _currentRow = ArrayList<PdfPCell>()
        _currentRowStartCols = ArrayList<Int32>()

        // 递减跨行计数（本行消耗一层 rowspan）
        var c: Int32 = 0
        while (c < _numColumns) {
            if (_rowspanTracker[Int64(c)] > 0) {
                _rowspanTracker[Int64(c)] -= 1
            }
            c += 1
        }

        // 定位下一行的起始空闲列
        _currentRowSpan = 0
        while (_currentRowSpan < _numColumns && _rowspanTracker[Int64(_currentRowSpan)] > 0) {
            _currentRowSpan += 1
        }
    }

    /**
     * 判断当前行是否已填满（含 rowspan 占用列）
     */
    private func isCurrentRowComplete(): Bool {
        var col: Int32 = _currentRowSpan
        while (col < _numColumns) {
            if (_rowspanTracker[Int64(col)] == 0) {
                return false
            }
            col += 1
        }
        true
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

    // ===== 列宽计算 =====

    /**
     * 计算绝对列宽数组
     * 优先级：绝对列宽 > 相对列宽 > 等分
     */
    public func getAbsoluteColumnWidths(totalWidth: Float32): Array<Float32> {
        match (_columnWidths) {
            case Some(widths) => return widths
            case None => ()
        }
        match (_relativeWidths) {
            case Some(relWidths) =>
                var sum: Float32 = 0.0
                for (w in relWidths) {
                    sum += w
                }
                if (sum <= 0.0) {
                    sum = 1.0
                }
                let scale = totalWidth / sum
                return Array<Float32>(relWidths.size, {i => relWidths[i] * scale})
            case None => ()
        }
        Array<Float32>(Int64(_numColumns), {_ => totalWidth / Float32(_numColumns)})
    }

    // ===== 宽度设置 =====

    public func setWidthPercentage(percentage: Float32): Unit {
        this._widthPercentage = percentage
    }

    public prop widthPercentage: Float32 {
        get() { _widthPercentage }
    }

    public func setTotalWidth(width: Float32): Unit {
        this._totalWidth = width
        this._lockedWidth = true
    }

    public func setTotalWidth(widths: Array<Float32>): Unit {
        if (Int32(widths.size) != _numColumns) {
            throw PdfException("Wrong number of column widths")
        }
        this._columnWidths = Some(widths)
        var total: Float32 = 0.0
        for (w in widths) {
            total += w
        }
        this._totalWidth = total
        this._lockedWidth = true
    }

    public prop totalWidth: Float32 {
        get() { _totalWidth }
    }

    public func setLockedWidth(locked: Bool): Unit {
        this._lockedWidth = locked
    }

    public prop lockedWidth: Bool {
        get() { _lockedWidth }
    }

    public func setWidths(relativeWidths: Array<Float32>): Unit {
        if (Int32(relativeWidths.size) != _numColumns) {
            throw PdfException("Wrong number of column widths")
        }
        this._relativeWidths = Some(relativeWidths)
    }

    // ===== 对齐方式 =====

    public func setHorizontalAlignment(alignment: Alignment): Unit {
        this._horizontalAlignment = alignment
    }

    public func setHorizontalAlignment(alignment: Int32): Unit {
        this._horizontalAlignment = Alignment.fromInt(alignment)
    }

    public prop horizontalAlignment: Alignment {
        get() { _horizontalAlignment }
    }

    // ===== 表头设置 =====

    public func setHeaderRows(rows: Int32): Unit {
        this._headerRows = rows
    }

    public prop headerRows: Int32 {
        get() { _headerRows }
    }

    public func setFooterRows(rows: Int32): Unit {
        this._footerRows = rows
    }

    public prop footerRows: Int32 {
        get() { _footerRows }
    }

    public func setSkipFirstHeader(skip: Bool): Unit {
        this._skipFirstHeader = skip
    }

    public prop skipFirstHeader: Bool {
        get() { _skipFirstHeader }
    }

    public func setSkipLastFooter(skip: Bool): Unit {
        this._skipLastFooter = skip
    }

    public prop skipLastFooter: Bool {
        get() { _skipLastFooter }
    }

    // ===== 分页设置 =====

    public func setKeepTogether(keep: Bool): Unit {
        this._keepTogether = keep
    }

    public prop keepTogether: Bool {
        get() { _keepTogether }
    }

    public func setSplitLate(splitLate: Bool): Unit {
        this._splitLate = splitLate
    }

    public prop splitLate: Bool {
        get() { _splitLate }
    }

    public func setSplitRows(splitRows: Bool): Unit {
        this._splitRows = splitRows
    }

    public prop splitRows: Bool {
        get() { _splitRows }
    }

    // ===== 间距设置 =====

    public func setSpacingBefore(spacing: Float32): Unit {
        this._spacingBefore = spacing
    }

    public prop spacingBefore: Float32 {
        get() { _spacingBefore }
    }

    public func setSpacingAfter(spacing: Float32): Unit {
        this._spacingAfter = spacing
    }

    public prop spacingAfter: Float32 {
        get() { _spacingAfter }
    }

    // ===== 默认单元格 =====

    public func getDefaultCell(): PdfPCell {
        _defaultCell
    }

    // ===== Element 接口实现 =====

    public func getType(): ElementType {
        ElementType.Table
    }

    public func getChunks(): ArrayList<Chunk> {
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

    public prop columns: Int32 {
        get() { _numColumns }
    }

    public prop rowCount: Int32 {
        get() { Int32(_rows.size) }
    }

    public func getRow(index: Int32): ?PdfPRow {
        if (index >= 0 && index < Int32(_rows.size)) {
            Some(_rows[Int64(index)])
        } else {
            None
        }
    }

    public func getRows(): ArrayList<PdfPRow> {
        _rows
    }
}

/**
 * PdfPRow 类 - 表格行
 * 内部使用，记录单元格及每个单元格的起始列位置
 */
public class PdfPRow {
    private let _cells: ArrayList<PdfPCell>
    private let _columnPositions: ArrayList<Int32>
    private var _maxHeight: Float32 = 0.0
    private var _calculated: Bool = false

    /**
     * 带列位置信息创建行（推荐）
     */
    public init(cells: ArrayList<PdfPCell>, positions: ArrayList<Int32>) {
        this._cells = cells
        this._columnPositions = positions
    }

    /**
     * 仅提供单元格时，按 colspan 顺序推导列位置（兼容旧接口）
     */
    public init(cells: ArrayList<PdfPCell>) {
        this._cells = cells
        let positions = ArrayList<Int32>()
        var col: Int32 = 0
        for (cell in cells) {
            positions.add(col)
            col += cell.colspan
        }
        this._columnPositions = positions
    }

    public func getCell(index: Int32): ?PdfPCell {
        if (index >= 0 && index < Int32(_cells.size)) {
            Some(_cells[Int64(index)])
        } else {
            None
        }
    }

    /**
     * 获取指定单元格（按数组下标）的起始列号
     */
    public func getColumnPosition(cellIndex: Int32): Int32 {
        if (cellIndex >= 0 && Int64(cellIndex) < _columnPositions.size) {
            _columnPositions[Int64(cellIndex)]
        } else {
            0
        }
    }

    public prop cellCount: Int32 {
        get() { Int32(_cells.size) }
    }

    public func setMaxHeight(height: Float32): Unit {
        this._maxHeight = height
        this._calculated = true
    }

    public prop maxHeight: Float32 {
        get() { _maxHeight }
    }

    public prop isCalculated: Bool {
        get() { _calculated }
    }

    public func getCells(): ArrayList<PdfPCell> {
        _cells
    }
}
