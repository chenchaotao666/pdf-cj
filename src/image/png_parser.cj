/**
 * PNG 图片解析器
 * 解析PNG文件格式，提取图像数据
 */
package pdf_cj.image

import std.collection.ArrayList

/**
 * PNG图片信息
 */
public class PngInfo {
    public var width: Int32 = 0
    public var height: Int32 = 0
    public var bitDepth: UInt8 = 0
    public var colorType: UInt8 = 0
    public var compressionMethod: UInt8 = 0
    public var filterMethod: UInt8 = 0
    public var interlaceMethod: UInt8 = 0
    public var idatData: Array<UInt8> = Array<UInt8>(0, repeat: UInt8(0))
    public var palette: Array<UInt8> = Array<UInt8>(0, repeat: UInt8(0))  // RGB调色板数据

    public init() {}
}

/**
 * PNG解析器
 */
public class PngParser {
    /**
     * 解析PNG文件
     */
    public static func parse(data: Array<UInt8>): ?PngInfo {
        if (data.size < 33) {
            return None
        }

        // 验证PNG签名
        if (!isValidPngSignature(data)) {
            return None
        }

        let info = PngInfo()
        var offset: Int64 = 8  // 跳过PNG签名

        // 收集所有IDAT数据和调色板
        var idatList = ArrayList<UInt8>()
        var paletteList = ArrayList<UInt8>()

        while (offset < data.size - 12) {
            // 读取块长度（大端序）
            let length = readInt32BE(data, offset)
            offset += 4

            // 读取块类型
            let chunkType = readChunkType(data, offset)
            offset += 4

            if (chunkType == "IHDR") {
                // 解析IHDR
                if (!parseIHDR(data, offset, info)) {
                    return None
                }
            } else if (chunkType == "PLTE") {
                // 解析调色板（索引色必需）
                var i: Int64 = 0
                while (i < Int64(length)) {
                    if (offset + i < data.size) {
                        paletteList.add(data[offset + i])
                    }
                    i += 1
                }
            } else if (chunkType == "IDAT") {
                // 收集IDAT数据
                var i: Int64 = 0
                while (i < Int64(length)) {
                    if (offset + i < data.size) {
                        idatList.add(data[offset + i])
                    }
                    i += 1
                }
            } else if (chunkType == "IEND") {
                // PNG结束
                break
            }

            // 跳过数据和CRC
            offset += Int64(length) + 4
        }

        // 转换IDAT列表和调色板为数组
        info.idatData = idatList.toArray()
        info.palette = paletteList.toArray()

        Some(info)
    }

    /**
     * 验证PNG签名
     */
    private static func isValidPngSignature(data: Array<UInt8>): Bool {
        if (data.size < 8) {
            return false
        }
        data[0] == UInt8(0x89) && data[1] == UInt8(0x50) &&
        data[2] == UInt8(0x4E) && data[3] == UInt8(0x47) &&
        data[4] == UInt8(0x0D) && data[5] == UInt8(0x0A) &&
        data[6] == UInt8(0x1A) && data[7] == UInt8(0x0A)
    }

    /**
     * 读取32位大端序整数
     */
    private static func readInt32BE(data: Array<UInt8>, offset: Int64): Int32 {
        (Int32(data[offset]) << 24) |
        (Int32(data[offset + 1]) << 16) |
        (Int32(data[offset + 2]) << 8) |
        Int32(data[offset + 3])
    }

    /**
     * 读取块类型（4个ASCII字符）
     */
    private static func readChunkType(data: Array<UInt8>, offset: Int64): String {
        let c1 = Rune(Int64(data[offset]))
        let c2 = Rune(Int64(data[offset + 1]))
        let c3 = Rune(Int64(data[offset + 2]))
        let c4 = Rune(Int64(data[offset + 3]))
        "${c1}${c2}${c3}${c4}"
    }

    /**
     * 解析IHDR块
     */
    private static func parseIHDR(data: Array<UInt8>, offset: Int64, info: PngInfo): Bool {
        if (offset + 13 > data.size) {
            return false
        }

        info.width = readInt32BE(data, offset)
        info.height = readInt32BE(data, offset + 4)
        info.bitDepth = data[offset + 8]
        info.colorType = data[offset + 9]
        info.compressionMethod = data[offset + 10]
        info.filterMethod = data[offset + 11]
        info.interlaceMethod = data[offset + 12]

        true
    }

    /**
     * 获取颜色空间组件数
     */
    public static func getColorComponents(colorType: UInt8): Int32 {
        match (colorType) {
            case 0 => 1  // 灰度
            case 2 => 3  // RGB
            case 3 => 1  // 索引色
            case 4 => 2  // 灰度+Alpha
            case 6 => 4  // RGBA
            case _ => 3
        }
    }
}
