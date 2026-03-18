/**
 * PDF-CJ: Alignment - 对齐方式
 * 定义文本和元素的对齐方式
 */
package pdf_cj.text

/**
 * 水平对齐方式
 */
public enum Alignment {
    | Left
    | Center
    | Right
    | Justified

    /**
     * 转换为整数值（兼容 OpenPDF 风格）
     */
    public func toInt(): Int32 {
        match (this) {
            case Left => 0
            case Center => 1
            case Right => 2
            case Justified => 3
        }
    }

    /**
     * 从整数值创建
     */
    public static func fromInt(value: Int32): Alignment {
        match (value) {
            case 0 => Left
            case 1 => Center
            case 2 => Right
            case 3 => Justified
            case _ => Left
        }
    }
}

/**
 * 垂直对齐方式
 */
public enum VerticalAlignment {
    | Top
    | Middle
    | Bottom
    | Baseline

    /**
     * 转换为整数值
     */
    public func toInt(): Int32 {
        match (this) {
            case Top => 4
            case Middle => 5
            case Bottom => 6
            case Baseline => 7
        }
    }

    /**
     * 从整数值创建
     */
    public static func fromInt(value: Int32): VerticalAlignment {
        match (value) {
            case 4 => Top
            case 5 => Middle
            case 6 => Bottom
            case 7 => Baseline
            case _ => Top
        }
    }
}

/**
 * 边框常量
 */
public class Border {
    public static let NO_BORDER: Int32 = 0
    public static let TOP: Int32 = 1
    public static let BOTTOM: Int32 = 2
    public static let LEFT: Int32 = 4
    public static let RIGHT: Int32 = 8
    public static let BOX: Int32 = TOP + BOTTOM + LEFT + RIGHT

    /**
     * 检查是否包含指定边框
     */
    public static func hasBorder(borders: Int32, border: Int32): Bool {
        (borders & border) != 0
    }
}
