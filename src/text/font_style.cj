/**
 * PDF-CJ: FontStyle - 字体样式
 * 定义字体的样式属性
 */
package pdf_cj.text

/**
 * 字体样式枚举
 */
public enum FontStyle <: Equatable<FontStyle> {
    | Normal
    | Bold
    | Italic
    | BoldItalic
    | Underline
    | Strikethrough

    public operator func ==(other: FontStyle): Bool {
        match ((this, other)) {
            case (Normal, Normal) => true
            case (Bold, Bold) => true
            case (Italic, Italic) => true
            case (BoldItalic, BoldItalic) => true
            case (Underline, Underline) => true
            case (Strikethrough, Strikethrough) => true
            case _ => false
        }
    }

    public operator func !=(other: FontStyle): Bool {
        !(this == other)
    }

    /**
     * 转换为整数值（可用于位运算组合）
     */
    public func toInt(): Int32 {
        match (this) {
            case Normal => 0
            case Bold => 1
            case Italic => 2
            case BoldItalic => 3
            case Underline => 4
            case Strikethrough => 8
        }
    }

    /**
     * 从整数值创建
     */
    public static func fromInt(value: Int32): FontStyle {
        match (value) {
            case 0 => Normal
            case 1 => Bold
            case 2 => Italic
            case 3 => BoldItalic
            case 4 => Underline
            case 8 => Strikethrough
            case _ => Normal
        }
    }

    /**
     * 是否为粗体
     */
    public func isBold(): Bool {
        match (this) {
            case Bold | BoldItalic => true
            case _ => false
        }
    }

    /**
     * 是否为斜体
     */
    public func isItalic(): Bool {
        match (this) {
            case Italic | BoldItalic => true
            case _ => false
        }
    }
}

/**
 * 字体家族
 */
public enum FontFamily {
    | Undefined
    | Courier
    | Helvetica
    | TimesRoman
    | Symbol
    | ZapfDingbats

    /**
     * 转换为整数值
     */
    public func toInt(): Int32 {
        match (this) {
            case Undefined => -1
            case Courier => 0
            case Helvetica => 1
            case TimesRoman => 2
            case Symbol => 3
            case ZapfDingbats => 4
        }
    }

    /**
     * 从整数值创建
     */
    public static func fromInt(value: Int32): FontFamily {
        match (value) {
            case 0 => Courier
            case 1 => Helvetica
            case 2 => TimesRoman
            case 3 => Symbol
            case 4 => ZapfDingbats
            case _ => Undefined
        }
    }
}
