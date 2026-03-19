/**
 * GIF 图片解析器
 * 解析 GIF 文件格式，提取图像数据
 * 支持 GIF87a 和 GIF89a 格式
 */
package pdf_cj.image

import std.collection.ArrayList

/**
 * GIF 图片信息
 */
public class GifInfo {
    public var width: Int32 = 0
    public var height: Int32 = 0
    public var globalColorTable: Array<UInt8> = Array<UInt8>(0, repeat: UInt8(0))  // RGB调色板
    public var imageData: Array<UInt8> = Array<UInt8>(0, repeat: UInt8(0))  // 索引数据
    public var hasGlobalColorTable: Bool = false
    public var colorTableSize: Int32 = 0
    public var backgroundColorIndex: UInt8 = 0

    public init() {}
}

/**
 * GIF 解析器
 */
public class GifParser {
    /**
     * 解析 GIF 文件（只解析第一帧）
     */
    public static func parse(data: Array<UInt8>): ?GifInfo {
        if (data.size < 13) {  // 最小 GIF：6(header) + 7(logical screen descriptor)
            return None
        }

        // 验证 GIF 签名
        if (!isValidGifSignature(data)) {
            return None
        }

        let info = GifInfo()
        var offset: Int64 = 6  // 跳过头部 "GIF87a" 或 "GIF89a"

        // 读取逻辑屏幕描述符 (Logical Screen Descriptor)
        info.width = readInt16LE(data, offset)
        info.height = readInt16LE(data, offset + 2)
        let packed = data[offset + 4]
        info.backgroundColorIndex = data[offset + 5]
        // let aspectRatio = data[offset + 6]

        // 解析 packed 字段
        info.hasGlobalColorTable = (packed & UInt8(0x80)) != UInt8(0)
        let colorResolution = (packed & UInt8(0x70)) >> 3
        let sortFlag = (packed & UInt8(0x08)) != UInt8(0)
        let globalColorTableSize = UInt8(packed & UInt8(0x07))

        offset += 7

        // 读取全局颜色表
        if (info.hasGlobalColorTable) {
            info.colorTableSize = 1 << (Int32(globalColorTableSize) + 1)
            let tableBytes = info.colorTableSize * 3  // RGB，每个颜色 3 字节

            if (offset + Int64(tableBytes) <= data.size) {
                info.globalColorTable = Array<UInt8>(Int64(tableBytes), repeat: UInt8(0))
                var i: Int64 = 0
                while (i < Int64(tableBytes)) {
                    info.globalColorTable[i] = data[offset + i]
                    i += 1
                }
                offset += Int64(tableBytes)
            }
        }

        // 查找第一个图像描述符
        var foundImage = false
        while (offset < data.size && !foundImage) {
            let separator = data[offset]
            offset += 1

            match (separator) {
                case 0x21 =>  // Extension
                    // 跳过扩展块
                    offset = skipExtension(data, offset)
                case 0x2C =>  // Image Descriptor
                    // 解析图像数据
                    info.imageData = parseImageData(data, offset, info)
                    foundImage = true
                case 0x3B =>  // Trailer (文件结束)
                    break
                case _ =>
                    // 未知块，继续
                    ()
            }
        }

        if (foundImage) {
            Some(info)
        } else {
            None
        }
    }

    /**
     * 验证 GIF 签名
     */
    private static func isValidGifSignature(data: Array<UInt8>): Bool {
        if (data.size < 6) {
            return false
        }
        // GIF87a 或 GIF89a
        (data[0] == UInt8(0x47) && data[1] == UInt8(0x49) && data[2] == UInt8(0x46) &&
         data[3] == UInt8(0x38) && (data[4] == UInt8(0x37) || data[4] == UInt8(0x39)) &&
         data[5] == UInt8(0x61))
    }

    /**
     * 读取 16 位小端序整数
     */
    private static func readInt16LE(data: Array<UInt8>, offset: Int64): Int32 {
        Int32(data[offset]) | (Int32(data[offset + 1]) << 8)
    }

    /**
     * 跳过扩展块
     */
    private static func skipExtension(data: Array<UInt8>, offset: Int64): Int64 {
        var pos = offset
        if (pos >= data.size) {
            return pos
        }

        // 跳过扩展标签
        pos += 1

        // 跳过所有子块
        while (pos < data.size) {
            let blockSize = Int64(data[pos])
            pos += 1

            if (blockSize == 0) {
                break
            }

            pos += blockSize
        }

        pos
    }

    /**
     * 解析图像数据（简化版本，直接提取 LZW 压缩数据）
     */
    private static func parseImageData(data: Array<UInt8>, offset: Int64, info: GifInfo): Array<UInt8> {
        var pos = offset

        if (pos + 9 > data.size) {
            return Array<UInt8>(0, repeat: UInt8(0))
        }

        // 添加异常处理
        try {
            return parseImageDataInternal(data, offset, info)
        } catch (e: Exception) {
            // 解析失败，返回空数组
            return Array<UInt8>(0, repeat: UInt8(0))
        }
    }

    /**
     * 内部解析方法
     */
    private static func parseImageDataInternal(data: Array<UInt8>, offset: Int64, info: GifInfo): Array<UInt8> {
        var pos = offset

        if (pos + 9 > data.size) {
            return Array<UInt8>(0, repeat: UInt8(0))
        }

        // 图像描述符 (10 字节)
        // let leftPosition = readInt16LE(data, pos)
        // let topPosition = readInt16LE(data, pos + 2)
        let imageWidth = readInt16LE(data, pos + 4)
        let imageHeight = readInt16LE(data, pos + 6)
        let packed = data[pos + 8]

        pos += 9

        // 检查是否有局部颜色表
        let hasLocalColorTable = (packed & UInt8(0x80)) != UInt8(0)
        if (hasLocalColorTable) {
            let localColorTableSize = 1 << (Int32(packed & UInt8(0x07)) + 1)
            let tableBytes = localColorTableSize * 3
            pos += Int64(tableBytes)  // 跳过局部颜色表
        }

        // LZW 最小码长
        let lzwMinCodeSize = data[pos]
        pos += 1

        // 读取所有图像数据子块
        var compressedData = ArrayList<UInt8>()
        while (pos < data.size) {
            let blockSize = Int64(data[pos])
            pos += 1

            if (blockSize == 0) {
                break
            }

            var i: Int64 = 0
            while (i < blockSize && pos + i < data.size) {
                compressedData.add(data[pos + i])
                i += 1
            }

            pos += blockSize
        }

        // LZW 解压
        decompressLZW(compressedData.toArray(), lzwMinCodeSize, imageWidth, imageHeight)
    }

    /**
     * LZW 解压算法（完整实现）
     * 返回索引数据（指向颜色表的索引）
     */
    private static func decompressLZW(compressedData: Array<UInt8>, minCodeSize: UInt8, width: Int32, height: Int32): Array<UInt8> {
        let outputSize = Int64(width) * Int64(height)
        var output = ArrayList<UInt8>()

        if (compressedData.size == 0) {
            return Array<UInt8>(outputSize, repeat: UInt8(0))
        }

        // LZW 初始化
        let initialCodeSize = Int32(minCodeSize)
        let clearCode = 1 << initialCodeSize
        let eoiCode = clearCode + 1
        var codeSize = initialCodeSize + 1
        var nextCode = eoiCode + 1

        // 代码表：每个代码对应一个字节序列
        // 注意：代码表需要为所有可能的代码预留空间，包括 clearCode 和 eoiCode
        var codeTable = ArrayList<ArrayList<UInt8>>()

        // 初始化代码表（0 到 clearCode-1 是字面值）
        var i: Int32 = 0
        while (i < 4096) {  // GIF LZW 最多 12 位，4096 个代码
            let entry = ArrayList<UInt8>()
            if (i < Int32(clearCode)) {
                entry.add(UInt8(i))  // 字面值
            }
            codeTable.add(entry)
            i += 1
        }

        // 位读取器状态
        var bitPos: Int32 = 0
        var bytePos: Int64 = 0

        // 读取下一个代码
        func readCode(): Int32 {
            var code: Int32 = 0
            var bitsRead: Int32 = 0

            while (bitsRead < codeSize && bytePos < compressedData.size) {
                let currentByte = Int32(compressedData[bytePos])
                let bitsAvailable = 8 - bitPos
                let bitsToRead = if (codeSize - bitsRead < bitsAvailable) {
                    codeSize - bitsRead
                } else {
                    bitsAvailable
                }

                let mask = (1 << bitsToRead) - 1
                let bits = (currentByte >> bitPos) & Int32(mask)
                code |= bits << bitsRead

                bitsRead += bitsToRead
                bitPos += bitsToRead

                if (bitPos >= 8) {
                    bitPos = 0
                    bytePos += 1
                }
            }

            code
        }

        var prevCode: Int32 = -1
        var first = true

        while (bytePos < compressedData.size && output.size < outputSize) {
            let code = readCode()

            if (code == Int32(clearCode)) {
                // 重置代码表
                codeTable = ArrayList<ArrayList<UInt8>>()
                i = 0
                while (i < 4096) {
                    let entry = ArrayList<UInt8>()
                    if (i < Int32(clearCode)) {
                        entry.add(UInt8(i))
                    }
                    codeTable.add(entry)
                    i += 1
                }
                codeSize = initialCodeSize + 1
                nextCode = eoiCode + 1
                prevCode = -1
                first = true
                continue
            }

            if (code == Int32(eoiCode)) {
                break
            }

            if (first) {
                // 第一个代码直接输出
                if (Int64(code) < codeTable.size) {
                    let entry = codeTable[Int64(code)]
                    var j: Int64 = 0
                    while (j < entry.size) {
                        output.add(entry[j])
                        j += 1
                    }
                    prevCode = code
                    first = false
                }
                continue
            }

            var entry = ArrayList<UInt8>()
            if (Int64(code) < codeTable.size) {
                // 代码在表中
                let codeEntry = codeTable[Int64(code)]
                var j: Int64 = 0
                while (j < codeEntry.size) {
                    entry.add(codeEntry[j])
                    j += 1
                }
            } else if (code == Int32(nextCode)) {
                // 特殊情况：代码 = 下一个代码
                let prevEntry = codeTable[Int64(prevCode)]
                var j: Int64 = 0
                while (j < prevEntry.size) {
                    entry.add(prevEntry[j])
                    j += 1
                }
                entry.add(prevEntry[0])
            } else {
                // 无效代码，跳过
                continue
            }

            // 输出当前代码的序列
            var k: Int64 = 0
            while (k < entry.size && output.size < outputSize) {
                output.add(entry[k])
                k += 1
            }

            // 添加新代码到表中
            if (prevCode >= 0 && Int32(nextCode) < 4096) {
                // 更新代码表中 nextCode 位置的���目
                let newEntry = ArrayList<UInt8>()
                let prevEntry = codeTable[Int64(prevCode)]
                var j: Int64 = 0
                while (j < prevEntry.size) {
                    newEntry.add(prevEntry[j])
                    j += 1
                }
                newEntry.add(entry[0])

                // 更新代码表（不是 append，而是更新已存在的位置）
                codeTable[Int64(nextCode)] = newEntry
                nextCode += 1

                // 增加代码大小
                if (Int32(nextCode) == (1 << codeSize) && codeSize < 12) {
                    codeSize += 1
                }
            }

            prevCode = code
        }

        // 转换为数组
        let result = Array<UInt8>(outputSize, repeat: UInt8(0))
        var idx: Int64 = 0
        while (idx < outputSize && idx < output.size) {
            result[idx] = output[idx]
            idx += 1
        }

        result
    }

    /**
     * 将 GIF 索引数据转换为 RGB 格式
     * @param gifInfo GIF 信息
     * @return RGB 数据
     */
    public static func convertToRGB(gifInfo: GifInfo): Array<UInt8> {
        let pixelCount = Int64(gifInfo.width) * Int64(gifInfo.height)
        let rgbSize = pixelCount * 3
        let rgbData = Array<UInt8>(rgbSize, repeat: UInt8(0))

        if (!gifInfo.hasGlobalColorTable || gifInfo.globalColorTable.size == 0) {
            // 没有颜色表，返回空白图像
            var i: Int64 = 0
            while (i < rgbSize) {
                rgbData[i] = UInt8(255)
                i += 1
            }
            return rgbData
        }

        var i: Int64 = 0
        while (i < pixelCount) {
            let index = if (i < gifInfo.imageData.size) {
                Int64(gifInfo.imageData[i])
            } else {
                Int64(gifInfo.backgroundColorIndex)
            }

            let paletteOffset = index * 3

            if (paletteOffset + 2 < gifInfo.globalColorTable.size) {
                rgbData[i * 3] = gifInfo.globalColorTable[paletteOffset]      // R
                rgbData[i * 3 + 1] = gifInfo.globalColorTable[paletteOffset + 1]  // G
                rgbData[i * 3 + 2] = gifInfo.globalColorTable[paletteOffset + 2]  // B
            } else {
                // 索引超出范围，使用白色
                rgbData[i * 3] = UInt8(255)
                rgbData[i * 3 + 1] = UInt8(255)
                rgbData[i * 3 + 2] = UInt8(255)
            }

            i += 1
        }

        rgbData
    }
}
