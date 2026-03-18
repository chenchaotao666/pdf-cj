/**
 * PDF-CJ: Image - 图片元素
 * 支持 JPEG、PNG 等格式的图片
 */
package pdf_cj.image

import std.collection.ArrayList
import std.fs.{File, Path, OpenMode}
import pdf_cj.api.{Element, ElementType, ElementListener, Chunk}
import pdf_cj.text.Alignment

/**
 * 图片类型枚举
 */
public enum ImageType {
    | Unknown
    | Jpeg
    | Png
    | Gif
    | Bmp
    | Tiff

    /**
     * 转换为整数
     */
    public func toInt(): Int32 {
        match (this) {
            case Unknown => 0
            case Jpeg => 1
            case Png => 2
            case Gif => 3
            case Bmp => 4
            case Tiff => 5
        }
    }
}

/**
 * Image 类 - 图片元素
 * 支持图片的加载、缩放、旋转等操作
 */
public class Image <: Element {
    // 图片数据
    private var _rawData: ?Array<UInt8> = None
    private var _filePath: ?String = None
    private var _imageType: ImageType = ImageType.Unknown

    // 原始尺寸
    private var _width: Float32 = 0.0
    private var _height: Float32 = 0.0

    // 缩放后尺寸
    private var _scaledWidth: Float32 = 0.0
    private var _scaledHeight: Float32 = 0.0

    // 位置和样式
    private var _alignment: Alignment = Alignment.Left
    private var _rotation: Float32 = 0.0
    private var _rotationRadians: Float32 = 0.0

    // 绝对位置
    private var _absoluteX: Float32 = 0.0
    private var _absoluteY: Float32 = 0.0

    // 透明度
    private var _transparency: ?Array<Int32> = None

    // DPI
    private var _dpiX: Float32 = 0.0
    private var _dpiY: Float32 = 0.0

    // 私有构造函数
    private init() {}

    // ===== 静态工厂方法 =====

    /**
     * 从文件路径加载图片
     */
    public static func getInstance(filename: String): Image {
        let img = Image()
        img._filePath = Some(filename)
        img.loadFromFile(filename)
        img
    }

    /**
     * 从字节数组创建图片
     */
    public static func getInstance(data: Array<UInt8>): Image {
        let img = Image()
        img._rawData = Some(data)
        img.detectType(data)
        img.parseImageData(data)
        img
    }

    // ===== 文件加载 =====

    /**
     * 从文件加载图片数据
     */
    private func loadFromFile(filename: String): Unit {
        // 读取文件内容
        let file = File(Path(filename), OpenMode.Read)

        // 读取所有数据（使用较大的缓冲区）
        var buffer = ArrayList<UInt8>()
        var chunk = Array<UInt8>(4096, {_ => UInt8(0)})

        var bytesRead = file.read(chunk)
        while (bytesRead > 0) {
            for (i in 0..bytesRead) {
                buffer.add(chunk[i])
            }
            bytesRead = file.read(chunk)
        }
        file.close()

        // 转换为数组
        let bufferSize = buffer.size
        let data = Array<UInt8>(bufferSize, repeat: UInt8(0))
        var idx: Int64 = 0
        while (idx < bufferSize) {
            data[idx] = buffer[idx]
            idx += 1
        }

        // 保存原始数据
        this._rawData = Some(data)

        // 检测图片类型
        detectType(data)

        // 根据类型解析图片
        parseImageData(data)
    }

    /**
     * 检测图片类型
     */
    private func detectType(data: Array<UInt8>): Unit {
        if (data.size < 8) {
            _imageType = ImageType.Unknown
            return
        }

        // JPEG 魔数: FF D8 FF
        if (data[0] == UInt8(0xFF) && data[1] == UInt8(0xD8) && data[2] == UInt8(0xFF)) {
            _imageType = ImageType.Jpeg
            return
        }

        // PNG 魔数: 89 50 4E 47 0D 0A 1A 0A
        if (data[0] == UInt8(0x89) && data[1] == UInt8(0x50) &&
           data[2] == UInt8(0x4E) && data[3] == UInt8(0x47)) {
            _imageType = ImageType.Png
            return
        }

        // GIF 魔数: 47 49 46
        if (data[0] == UInt8(0x47) && data[1] == UInt8(0x49) && data[2] == UInt8(0x46)) {
            _imageType = ImageType.Gif
            return
        }

        // BMP 魔数: 42 4D
        if (data[0] == UInt8(0x42) && data[1] == UInt8(0x4D)) {
            _imageType = ImageType.Bmp
            return
        }

        _imageType = ImageType.Unknown
    }

    /**
     * 解析图片数据获取尺寸等信息
     */
    private func parseImageData(data: Array<UInt8>): Unit {
        match (_imageType) {
            case ImageType.Png =>
                parsePngData(data)
            case ImageType.Jpeg =>
                parseJpegData(data)
            case _ =>
                // 默认尺寸
                this._width = 100.0
                this._height = 100.0
        }
    }

    /**
     * 解析PNG图片数据
     */
    private func parsePngData(data: Array<UInt8>): Unit {
        match (PngParser.parse(data)) {
            case Some(info) =>
                this._width = Float32(info.width)
                this._height = Float32(info.height)
                println("[Image] PNG dimensions: ${this._width} x ${this._height}")
            case None =>
                this._width = 100.0
                this._height = 100.0
                println("[Image] PNG parse failed, using default: 100 x 100")
        }
    }

    /**
     * 解析JPEG图片数据
     */
    private func parseJpegData(data: Array<UInt8>): Unit {
        // JPEG标记：FF D8 = SOI (Start of Image)
        // 寻找SOF标记 (Start of Frame): FF C0 或 FF C2
        var i: Int64 = 2  // 跳过SOI标记

        while (i < data.size - 10) {
            if (data[i] == UInt8(0xFF)) {
                let marker = data[i + 1]
                // SOF0 (Baseline) = 0xC0, SOF2 (Progressive) = 0xC2
                if (marker == UInt8(0xC0) || marker == UInt8(0xC2)) {
                    // SOF块格式：FF Cn (2) + 长度(2) + 精度(1) + 高(2) + 宽(2) + ...
                    let height = (Int32(data[i + 5]) << 8) | Int32(data[i + 6])
                    let width = (Int32(data[i + 7]) << 8) | Int32(data[i + 8])
                    this._width = Float32(width)
                    this._height = Float32(height)
                    return
                }
                // 跳过当前段
                if (i + 2 < data.size) {
                    let segmentLength = (Int32(data[i + 2]) << 8) | Int32(data[i + 3])
                    i += Int64(segmentLength) + 2
                } else {
                    i += 1
                }
            } else {
                i += 1
            }
        }

        // 如果没找到，使用默认值
        this._width = 100.0
        this._height = 100.0
    }

    // ===== 缩放方法 =====

    /**
     * 缩放到绝对大小
     */
    public func scaleAbsolute(newWidth: Float32, newHeight: Float32): Unit {
        this._scaledWidth = newWidth
        this._scaledHeight = newHeight
    }

    /**
     * 按百分比缩放
     */
    public func scalePercent(percent: Float32): Unit {
        scalePercent(percent, percent)
    }

    /**
     * 按 X 和 Y 方向不同百分比缩放
     */
    public func scalePercent(percentX: Float32, percentY: Float32): Unit {
        this._scaledWidth = _width * percentX / 100.0
        this._scaledHeight = _height * percentY / 100.0
    }

    /**
     * 缩放以适应指定大小（保持宽高比）
     */
    public func scaleToFit(maxWidth: Float32, maxHeight: Float32): Unit {
        let ratioWidth = maxWidth / _width
        let ratioHeight = maxHeight / _height
        let ratio = if (ratioWidth < ratioHeight) { ratioWidth } else { ratioHeight }
        this._scaledWidth = _width * ratio
        this._scaledHeight = _height * ratio
    }

    // ===== 位置和旋转 =====

    /**
     * 设置对齐方式
     */
    public func setAlignment(alignment: Alignment): Unit {
        this._alignment = alignment
    }

    /**
     * 设置对齐方式（整数）
     */
    public func setAlignment(alignment: Int32): Unit {
        this._alignment = Alignment.fromInt(alignment)
    }

    /**
     * 获取对齐方式
     */
    public prop alignment: Alignment {
        get() { _alignment }
    }

    /**
     * 设置旋转角度（度数）
     */
    public func setRotation(degrees: Float32): Unit {
        this._rotation = degrees
        // 转换为弧度
        this._rotationRadians = degrees * 3.14159 / 180.0
    }

    /**
     * 设置旋转角度（弧度）
     */
    public func setRotationRadians(radians: Float32): Unit {
        this._rotationRadians = radians
        // 转换为度数
        this._rotation = radians * 180.0 / 3.14159
    }

    /**
     * 获取旋转角度（度数）
     */
    public prop rotation: Float32 {
        get() { _rotation }
    }

    /**
     * 获取旋转角度（弧度）
     */
    public prop rotationRadians: Float32 {
        get() { _rotationRadians }
    }

    /**
     * 设置绝对位置
     */
    public func setAbsolutePosition(x: Float32, y: Float32): Unit {
        this._absoluteX = x
        this._absoluteY = y
    }

    /**
     * 获取绝对 X 坐标
     */
    public prop absoluteX: Float32 {
        get() { _absoluteX }
    }

    /**
     * 获取绝对 Y 坐标
     */
    public prop absoluteY: Float32 {
        get() { _absoluteY }
    }

    // ===== 尺寸属性 =====

    /**
     * 获取原始宽度
     */
    public prop plainWidth: Float32 {
        get() { _width }
    }

    /**
     * 获取原始高度
     */
    public prop plainHeight: Float32 {
        get() { _height }
    }

    /**
     * 获取缩放后的宽度
     */
    public prop scaledWidth: Float32 {
        get() {
            if (_scaledWidth > 0.0) {
                _scaledWidth
            } else {
                _width
            }
        }
    }

    /**
     * 获取缩放后的高度
     */
    public prop scaledHeight: Float32 {
        get() {
            if (_scaledHeight > 0.0) {
                _scaledHeight
            } else {
                _height
            }
        }
    }

    // ===== 其他属性 =====

    /**
     * 获取图片类型
     */
    public prop imageType: ImageType {
        get() { _imageType }
    }

    /**
     * 获取原始数据
     */
    public prop rawData: ?Array<UInt8> {
        get() { _rawData }
    }

    /**
     * 设置 DPI
     */
    public func setDpi(dpiX: Float32, dpiY: Float32): Unit {
        this._dpiX = dpiX
        this._dpiY = dpiY
    }

    /**
     * 获取 DPI X
     */
    public prop dpiX: Float32 {
        get() { _dpiX }
    }

    /**
     * 获取 DPI Y
     */
    public prop dpiY: Float32 {
        get() { _dpiY }
    }

    // ===== Element 接口实现 =====

    public func getType(): ElementType {
        ElementType.Image
    }

    public func getChunks(): ArrayList<Chunk> {
        // 图片没有 Chunk
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
}
