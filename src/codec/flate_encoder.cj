/**
 * PDF-CJ: FlateEncoder - Flate/Deflate 压缩编码器
 * 使用 DEFLATE 算法压缩数据
 */
package pdf_cj.codec

import std.collection.ArrayList
import zlib4cj.{Zlib, ZlibType}

/**
 * FlateEncoder 类 - Flate 压缩编码器
 * PDF 中最常用的压缩算法
 */
public class FlateEncoder {
    /**
     * 压缩数据
     * @param data 原始数据
     * @return 压缩后的数据
     */
    public static func encode(data: Array<UInt8>): Array<UInt8> {
        try {
            // 使用 zlib4cj 进行 ZLIB 压缩（PDF /FlateDecode 需要 ZLIB 格式）
            Zlib.compress(data, wrap: ZlibType.ZLIB, level: 6)
        } catch (e: Exception) {
            // 如果压缩失败，返回原始数据
            data
        }
    }

    /**
     * 压缩数据（使用指定压缩级别）
     * @param data 原始数据
     * @param level 压缩级别 (0-9, 0=不压缩, 9=最高压缩)
     * @return 压缩后的数据
     */
    public static func encode(data: Array<UInt8>, level: Int32): Array<UInt8> {
        try {
            // 使用 zlib4cj 进行 ZLIB 压缩，使用指定的压缩级别（PDF /FlateDecode 需要 ZLIB 格式）
            Zlib.compress(data, wrap: ZlibType.ZLIB, level: Int64(level))
        } catch (e: Exception) {
            // 如果压缩失败，返回原始数据
            data
        }
    }

    /**
     * 解压数据
     * @param data 压缩的数据
     * @return 解压后的数据
     */
    public static func decode(data: Array<UInt8>): Array<UInt8> {
        try {
            // 使用 zlib4cj 进行解压，自动检测格式
            Zlib.uncompress(data, wrap: ZlibType.AUTO_DETECT)
        } catch (e: Exception) {
            // 如果解压失败，返回原始数据
            data
        }
    }

    /**
     * 检查数据是否为有效的 Flate 压缩数据
     */
    public static func isValidFlateData(data: Array<UInt8>): Bool {
        if (data.size < 2) {
            return false
        }

        // Flate 数据以 0x78 开头（zlib 头）
        let firstByte = data[0]
        firstByte == UInt8(0x78) || firstByte == UInt8(0x08)
    }
}
