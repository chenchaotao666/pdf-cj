/**
 * PDF-CJ: ASCIIHexEncoder - ASCII Hex 编码器
 * 将二进制数据编码为 ASCII 十六进制字符串
 */
package pdf_cj.codec

import std.collection.ArrayList

/**
 * ASCIIHexEncoder 类 - ASCII Hex 编码器
 * 将每个字节编码为两个十六进制字符
 */
public class ASCIIHexEncoder {
    // 十六进制字符
    private static let HEX_STRING: String = "0123456789ABCDEF"

    /**
     * 编码数据为 ASCII Hex
     * @param data 原始数据
     * @return 编码后的字符串
     */
    public static func encode(data: Array<UInt8>): String {
        var result = ""

        for (b in data) {
            // 将字节分解为高4位和低4位
            let high = (b >> 4) & UInt8(0x0F)
            let low = b & UInt8(0x0F)

            // 转换为十六进制字符
            result = result + getHexChar(Int32(high))
            result = result + getHexChar(Int32(low))
        }

        // 添加结束标记
        result + ">"
    }

    /**
     * 获取十六进制字符
     */
    private static func getHexChar(value: Int32): String {
        if (value >= 0 && value < 16) {
            let char = HEX_STRING[Int64(value)]
            String([Rune(Int32(char))])
        } else {
            "0"
        }
    }

    /**
     * 解码 ASCII Hex 字符串
     * @param hex 十六进制字符串
     * @return 解码后的数据
     */
    public static func decode(hex: String): Array<UInt8> {
        let result = ArrayList<UInt8>()
        var currentByte: UInt8 = UInt8(0)
        var nibbleCount = 0

        for (c in hex) {
            // 跳过空白字符
            if (c == UInt8(32) || c == UInt8(9) || c == UInt8(10) || c == UInt8(13)) {
                continue
            }

            // 遇到结束标记 '>'
            if (c == UInt8(62)) {
                break
            }

            // 转换字符为数值
            let value = hexCharToValue(c)
            if (value >= 0) {
                if (nibbleCount == 0) {
                    currentByte = UInt8(value) << 4
                    nibbleCount = 1
                } else {
                    currentByte = currentByte | UInt8(value)
                    result.add(currentByte)
                    nibbleCount = 0
                    currentByte = UInt8(0)
                }
            }
        }

        // 如果有未完成的字节（奇数个十六进制字符）
        if (nibbleCount == 1) {
            result.add(currentByte)
        }

        arrayListToArray(result)
    }

    /**
     * 将十六进制字符转换为数值
     */
    private static func hexCharToValue(c: UInt8): Int32 {
        // '0'-'9'
        if (c >= UInt8(48) && c <= UInt8(57)) {
            return Int32(c - UInt8(48))
        }
        // 'A'-'F'
        if (c >= UInt8(65) && c <= UInt8(70)) {
            return Int32(c - UInt8(65) + UInt8(10))
        }
        // 'a'-'f'
        if (c >= UInt8(97) && c <= UInt8(102)) {
            return Int32(c - UInt8(97) + UInt8(10))
        }
        -1
    }

    /**
     * 将 ArrayList 转换为 Array
     */
    private static func arrayListToArray(list: ArrayList<UInt8>): Array<UInt8> {
        let size = list.size
        Array<UInt8>(size, { i: Int64 => list[i] })
    }
}
