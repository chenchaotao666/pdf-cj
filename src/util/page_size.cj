/**
 * PDF-CJ: PageSize - 页面尺寸常量
 * 定义标准纸张尺寸
 */
package pdf_cj.util

/**
 * 页面尺寸常量类
 * 所有尺寸单位为点（point），1 point = 1/72 inch
 */
public class PageSize {
    // ISO A 系列
    public static let A0 = Rectangle(2384.0, 3370.0)
    public static let A1 = Rectangle(1684.0, 2384.0)
    public static let A2 = Rectangle(1190.0, 1684.0)
    public static let A3 = Rectangle(842.0, 1190.0)
    public static let A4 = Rectangle(595.0, 842.0)
    public static let A5 = Rectangle(420.0, 595.0)
    public static let A6 = Rectangle(297.0, 420.0)
    public static let A7 = Rectangle(210.0, 297.0)
    public static let A8 = Rectangle(148.0, 210.0)
    public static let A9 = Rectangle(105.0, 148.0)
    public static let A10 = Rectangle(74.0, 105.0)

    // ISO B 系列
    public static let B0 = Rectangle(2834.0, 4008.0)
    public static let B1 = Rectangle(2004.0, 2834.0)
    public static let B2 = Rectangle(1417.0, 2004.0)
    public static let B3 = Rectangle(1000.0, 1417.0)
    public static let B4 = Rectangle(708.0, 1000.0)
    public static let B5 = Rectangle(498.0, 708.0)

    // 北美标准尺寸
    public static let LETTER = Rectangle(612.0, 792.0)
    public static let LEGAL = Rectangle(612.0, 1008.0)
    public static let TABLOID = Rectangle(792.0, 1224.0)
    public static let LEDGER = Rectangle(1224.0, 792.0)
    public static let EXECUTIVE = Rectangle(522.0, 756.0)

    // 其他常用尺寸
    public static let POSTCARD = Rectangle(283.0, 416.0)
    public static let ID_1 = Rectangle(242.65, 153.0)  // 信用卡尺寸

    /**
     * 获取横向页面（旋转90度）
     */
    public static func landscape(rect: Rectangle): Rectangle {
        if (rect.width < rect.height) {
            rect.rotate()
        } else {
            rect
        }
    }

    /**
     * 获取纵向页面
     */
    public static func portrait(rect: Rectangle): Rectangle {
        if (rect.width > rect.height) {
            rect.rotate()
        } else {
            rect
        }
    }
}
