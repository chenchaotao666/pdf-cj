/**
 * PDF-CJ: Rectangle - 矩形类
 * 用于表示页面尺寸、边界框等
 */
package pdf_cj.util

/**
 * 矩形结构体
 * 使用 PDF 坐标系（左下角为原点）
 */
public struct Rectangle {
    public let left: Float32
    public let bottom: Float32
    public let right: Float32
    public let top: Float32

    /**
     * 使用宽高创建矩形（原点在左下角）
     */
    public init(width: Float32, height: Float32) {
        this.left = 0.0
        this.bottom = 0.0
        this.right = width
        this.top = height
    }

    /**
     * 使用四个边界值创建矩形
     */
    public init(left: Float32, bottom: Float32, right: Float32, top: Float32) {
        this.left = left
        this.bottom = bottom
        this.right = right
        this.top = top
    }

    /**
     * 获取矩形宽度
     */
    public prop width: Float32 {
        get() { right - left }
    }

    /**
     * 获取矩形高度
     */
    public prop height: Float32 {
        get() { top - bottom }
    }

    /**
     * 旋转矩形（交换宽高）
     */
    public func rotate(): Rectangle {
        Rectangle(height, width)
    }

    /**
     * 检查点是否在矩形内
     */
    public func contains(x: Float32, y: Float32): Bool {
        x >= left && x <= right && y >= bottom && y <= top
    }

    /**
     * 转换为 PDF 数组格式 [left bottom right top]
     */
    public func toArray(): Array<Float32> {
        [left, bottom, right, top]
    }
}
