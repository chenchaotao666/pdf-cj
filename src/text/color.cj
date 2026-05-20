/**
 * PDF-CJ: Color - 颜色类
 * 支持 RGB 和灰度颜色
 */
package pdf_cj.text

/**
 * 颜色结构体
 * 使用 RGBA 模型
 */
public struct Color {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let alpha: UInt8

    // 预定义颜色常量
    public static let BLACK = Color(0, 0, 0, 255)
    public static let WHITE = Color(255, 255, 255, 255)
    public static let RED = Color(255, 0, 0, 255)
    public static let GREEN = Color(0, 255, 0, 255)
    public static let BLUE = Color(0, 0, 255, 255)
    public static let CYAN = Color(0, 255, 255, 255)
    public static let MAGENTA = Color(255, 0, 255, 255)
    public static let YELLOW = Color(255, 255, 0, 255)
    public static let ORANGE = Color(255, 165, 0, 255)
    public static let PINK = Color(255, 175, 175, 255)
    public static let GRAY = Color(128, 128, 128, 255)
    public static let LIGHT_GRAY = Color(192, 192, 192, 255)
    public static let DARK_GRAY = Color(64, 64, 64, 255)

    /**
     * 使用 RGB 值创建颜色（不透明）
     */
    public init(red: UInt8, green: UInt8, blue: UInt8) {
        this.red = red
        this.green = green
        this.blue = blue
        this.alpha = 255
    }

    /**
     * 使用 RGBA 值创建颜色
     */
    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        this.red = red
        this.green = green
        this.blue = blue
        this.alpha = alpha
    }

    /**
     * 从十六进制值创建颜色 (0xRRGGBB)
     */
    public static func fromHex(hex: Int32): Color {
        let r = UInt8((hex >> 16) & 0xFF)
        let g = UInt8((hex >> 8) & 0xFF)
        let b = UInt8(hex & 0xFF)
        Color(r, g, b)
    }

    /**
     * 从十六进制值创建颜色 (0xRRGGBBAA)
     */
    public static func fromHexWithAlpha(hex: Int32): Color {
        let r = UInt8((hex >> 24) & 0xFF)
        let g = UInt8((hex >> 16) & 0xFF)
        let b = UInt8((hex >> 8) & 0xFF)
        let a = UInt8(hex & 0xFF)
        Color(r, g, b, a)
    }

    /**
     * 转换为 PDF RGB 浮点值 (0.0 - 1.0)
     */
    public func toRgbFloat(): (Float32, Float32, Float32) {
        (
            Float32(red) / 255.0,
            Float32(green) / 255.0,
            Float32(blue) / 255.0
        )
    }

    /**
     * 转换为灰度值
     */
    public func toGray(): Float32 {
        // 使用标准灰度转换公式
        (0.299 * Float32(red) + 0.587 * Float32(green) + 0.114 * Float32(blue)) / 255.0
    }

    /**
     * 是否为灰度色
     */
    public func isGray(): Bool {
        red == green && green == blue
    }

    /**
     * 调整亮度
     * factor > 1.0 变亮，factor < 1.0 变暗
     */
    public func adjustBrightness(factor: Float32): Color {
        let newR = UInt8(min(255.0, Float32(red) * factor))
        let newG = UInt8(min(255.0, Float32(green) * factor))
        let newB = UInt8(min(255.0, Float32(blue) * factor))
        Color(newR, newG, newB, alpha)
    }

    /**
     * 获取互补色
     */
    public func complementary(): Color {
        Color(255 - red, 255 - green, 255 - blue, alpha)
    }
}

/**
 * CMYK 颜色，各分量范围 0.0–1.0
 */
public struct CMYKColor {
    public let cyan: Float32
    public let magenta: Float32
    public let yellow: Float32
    public let black: Float32

    public static let BLACK   = CMYKColor(0.0, 0.0, 0.0, 1.0)
    public static let WHITE   = CMYKColor(0.0, 0.0, 0.0, 0.0)
    public static let RED     = CMYKColor(0.0, 1.0, 1.0, 0.0)
    public static let GREEN   = CMYKColor(1.0, 0.0, 1.0, 0.0)
    public static let BLUE    = CMYKColor(1.0, 1.0, 0.0, 0.0)
    public static let CYAN    = CMYKColor(1.0, 0.0, 0.0, 0.0)
    public static let MAGENTA = CMYKColor(0.0, 1.0, 0.0, 0.0)
    public static let YELLOW  = CMYKColor(0.0, 0.0, 1.0, 0.0)

    public init(c: Float32, m: Float32, y: Float32, k: Float32) {
        this.cyan = c
        this.magenta = m
        this.yellow = y
        this.black = k
    }
}

/**
 * 灰度颜色，gray 范围 0.0（黑）–1.0（白）
 */
public struct GrayColor {
    public let gray: Float32

    public static let BLACK      = GrayColor(0.0)
    public static let DARK_GRAY  = GrayColor(0.25)
    public static let GRAY       = GrayColor(0.5)
    public static let LIGHT_GRAY = GrayColor(0.75)
    public static let WHITE      = GrayColor(1.0)

    public init(gray: Float32) {
        this.gray = gray
    }
}

/**
 * 取最小值辅助函数
 */
func min(a: Float32, b: Float32): Float32 {
    if (a < b) { a } else { b }
}
