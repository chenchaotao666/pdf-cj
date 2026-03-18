/**
 * PDF-CJ: ASCII85Encoder - ASCII85 编码器
 * 也称为 Base85，比 ASCII Hex 更紧凑的编码方式
 */
package pdf_cj.codec

import std.collection.ArrayList

/**
 * ASCII85Encoder 类 - ASCII85 编码器
 * 将 4 个字节编码为 5 个 ASCII 字符（编码效率 ~80%）
 */
public class ASCII85Encoder {
    /**
     * 编码数据为 ASCII85
     * @param data 原始数据
     * @return 编码后的字符串
     */
    public static func encode(data: Array<UInt8>): String {
        var result = ""
        var tuple: Int64 = 0
        var count: Int32 = 0

        for (b in data) {
            tuple = (tuple << 8) | Int64(b)
            count = count + 1

            if (count == 4) {
                result = result + encodeTuple(tuple)
                tuple = 0
                count = 0
            }
        }

        // 处理剩余的字节
        if (count > 0) {
            // 填充到 4 字节
            let remaining = 4 - count
            for (_ in 0..Int64(remaining)) {
                tuple = tuple << 8
            }
            result = result + encodePartialTuple(tuple, count)
        }

        // 添加结束标记
        result + "~>"
    }

    /**
     * 编码一个完整的 4 字节元组
     */
    private static func encodeTuple(value: Int64): String {
        // 特殊情况：全零编码为 'z'
        if (value == 0) {
            return "z"
        }

        var result = ""
        var v = value

        // 转换为 5 个 base-85 字符
        let chars = ArrayList<Rune>()
        for (_ in 0..5) {
            let digit = v % 85
            chars.add(Rune(Int32(33 + digit)))
            v = v / 85
        }

        // 反转顺序（从后往前）
        let size = Int64(chars.size)
        for (i in 0..size) {
            let index = size - 1 - i
            result = result + String([chars[index]])
        }

        result
    }

    /**
     * 编码不完整的元组
     */
    private static func encodePartialTuple(value: Int64, byteCount: Int32): String {
        var result = ""
        var v = value

        // 生成 byteCount + 1 个字符
        let numChars = byteCount + 1
        let chars = ArrayList<Rune>()

        for (_ in 0..5) {
            let digit = v % 85
            chars.add(Rune(Int32(33 + digit)))
            v = v / 85
        }

        // 只取需要的字符数（从后往前）
        let size = Int64(chars.size)
        let start = size - Int64(numChars)
        for (i in 0..Int64(numChars)) {
            let index = size - 1 - i
            if (index >= 0) {
                result = result + String([chars[index]])
            }
        }

        result
    }

    /**
     * 解码 ASCII85 字符串
     * @param encoded 编码的字符串
     * @return 解码后的数据
     */
    public static func decode(encoded: String): Array<UInt8> {
        let result = ArrayList<UInt8>()
        var tuple: Int64 = 0
        var count: Int32 = 0

        for (c in encoded) {
            // 跳过空白字符
            if (c == UInt8(32) || c == UInt8(9) || c == UInt8(10) || c == UInt8(13)) {
                continue
            }

            // 遇到结束标记
            if (c == UInt8(126)) { // '~'
                break
            }

            // 处理特殊的 'z'（表示 4 个零字节）
            if (c == UInt8(122)) { // 'z'
                if (count != 0) {
                    // 错误：'z' 只能在元组开始时出现
                    continue
                }
                addBytes(result, 0, 4)
                continue
            }

            // 普通字符（33-117，即 '!'-'u'）
            if (c >= UInt8(33) && c <= UInt8(117)) {
                tuple = tuple * 85 + Int64(c - UInt8(33))
                count = count + 1

                if (count == 5) {
                    addBytes(result, tuple, 4)
                    tuple = 0
                    count = 0
                }
            }
        }

        // 处理剩余的字符
        if (count > 0) {
            // 填充到 5 个字符
            let remaining = 5 - count
            for (_ in 0..Int64(remaining)) {
                tuple = tuple * 85 + 84 // 使用最大值填充
            }
            addBytes(result, tuple, count - 1)
        }

        arrayListToArray(result)
    }

    /**
     * 将整数值的字节添加到结果中
     */
    private static func addBytes(result: ArrayList<UInt8>, value: Int64, count: Int32): Unit {
        let bytes = [
            UInt8((value >> 24) & Int64(0xFF)),
            UInt8((value >> 16) & Int64(0xFF)),
            UInt8((value >> 8) & Int64(0xFF)),
            UInt8(value & Int64(0xFF))
        ]

        for (i in 0..Int64(count)) {
            result.add(bytes[i])
        }
    }

    /**
     * 将 ArrayList 转换为 Array
     */
    private static func arrayListToArray(list: ArrayList<UInt8>): Array<UInt8> {
        let size = list.size
        Array<UInt8>(size, { i: Int64 => list[i] })
    }
}
