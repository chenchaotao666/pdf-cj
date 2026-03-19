/**
 * BMP 图片解析器
 * 解析 BMP 文件格式，提取图像数据
 */
package pdf_cj.image

import std.collection.ArrayList

/**
 * BMP 图片信息
 */
public class BmpInfo {
    public var width: Int32 = 0
    public var height: Int32 = 0
    public var bitDepth: UInt16 = 0
    public var compression: Int32 = 0
    public var imageDataOffset: Int32 = 0
    public var palette: Array<UInt8> = Array<UInt8>(0, repeat: UInt8(0))  // RGB调色板数据
    public var imageData: Array<UInt8> = Array<UInt8>(0, repeat: UInt8(0))  // 像素数据

    public init() {}
}

/**
 * BMP 解析器
 */
public class BmpParser {
    /**
     * 解析 BMP 文件
     */
    public static func parse(data: Array<UInt8>): ?BmpInfo {
        if (data.size < 54) {  // BMP 最小头部：14 + 40 字节
            return None
        }

        // 验证 BMP 签名
        if (!isValidBmpSignature(data)) {
            return None
        }

        let info = BmpInfo()

        // 读取文件头 (14 字节)
        info.imageDataOffset = readInt32LE(data, 10)

        // 读取 DIB 头
        let dibHeaderSize = readInt32LE(data, 14)

        if (dibHeaderSize == 40) {
            // BITMAPINFOHEADER (最常见)
            info.width = readInt32LE(data, 18)
            info.height = readInt32LE(data, 22)
            info.bitDepth = readUInt16LE(data, 28)
            info.compression = readInt32LE(data, 30)
        } else if (dibHeaderSize == 12) {
            // BITMAPCOREHEADER (旧格式)
            info.width = Int32(readUInt16LE(data, 18))
            info.height = Int32(readUInt16LE(data, 20))
            info.bitDepth = readUInt16LE(data, 24)
            info.compression = 0  // 不支持压缩
        } else {
            // 不支持的头部格式
            return None
        }

        // 只支持无压缩的 BMP
        if (info.compression != 0) {
            return None
        }

        // 读取调色板（如果是索引色）
        if (info.bitDepth <= 8) {
            let paletteSize = (1 << Int32(info.bitDepth)) * 4  // 每个颜色 4 字节 (B, G, R, reserved)
            let paletteStart = Int64(14 + dibHeaderSize)

            if (paletteStart + Int64(paletteSize) <= data.size) {
                var paletteList = ArrayList<UInt8>()
                var i: Int64 = 0
                while (i < Int64(paletteSize)) {
                    let idx = Int64(paletteStart) + i
                    if (idx < data.size) {
                        // BMP 调色板格式：B, G, R, reserved
                        // 转换为 RGB 格式
                        if (i % 4 == 0 && idx + 2 < data.size) {
                            paletteList.add(data[idx + 2])  // R
                            paletteList.add(data[idx + 1])  // G
                            paletteList.add(data[idx])      // B
                        }
                    }
                    i += 4  // 跳过 4 字节
                }
                info.palette = paletteList.toArray()
            }
        }

        // 读取像素数据
        if (Int64(info.imageDataOffset) < data.size) {
            let imageDataSize = data.size - Int64(info.imageDataOffset)
            info.imageData = Array<UInt8>(imageDataSize, repeat: UInt8(0))
            var i: Int64 = 0
            while (i < imageDataSize) {
                info.imageData[i] = data[Int64(info.imageDataOffset) + i]
                i += 1
            }
        }

        Some(info)
    }

    /**
     * 验证 BMP 签名
     */
    private static func isValidBmpSignature(data: Array<UInt8>): Bool {
        if (data.size < 2) {
            return false
        }
        // BMP 签名：'B' 'M' (0x42 0x4D)
        data[0] == UInt8(0x42) && data[1] == UInt8(0x4D)
    }

    /**
     * 读取 32 位小端序整数
     */
    private static func readInt32LE(data: Array<UInt8>, offset: Int64): Int32 {
        Int32(data[offset]) |
        (Int32(data[offset + 1]) << 8) |
        (Int32(data[offset + 2]) << 16) |
        (Int32(data[offset + 3]) << 24)
    }

    /**
     * 读取 16 位小端序整数
     */
    private static func readUInt16LE(data: Array<UInt8>, offset: Int64): UInt16 {
        UInt16(data[offset]) |
        (UInt16(data[offset + 1]) << 8)
    }

    /**
     * 将 BMP 像素数据转换为 RGB 格式（处理上下翻转和行对齐）
     * @param bmpInfo BMP 信息
     * @return RGB 数据（从上到下）
     */
    public static func convertToRGB(bmpInfo: BmpInfo): Array<UInt8> {
        let width = Int64(bmpInfo.width)
        let height = Int64(bmpInfo.height)
        let bitDepth = Int64(bmpInfo.bitDepth)

        // 计算每行字节数（需要 4 字节对齐）
        let bytesPerPixel = bitDepth / 8
        let rowSize = ((width * bitDepth + 31) / 32) * 4

        // 输出 RGB 数据
        let rgbSize = width * height * 3
        let rgbData = Array<UInt8>(rgbSize, repeat: UInt8(0))

        if (bitDepth == 24) {
            // 24 位真彩色（BGR 格式）
            var y: Int64 = 0
            while (y < height) {
                // BMP 从底部开始存储，需要翻转
                let srcRow = (height - 1 - y) * rowSize
                let dstRow = y * width * 3

                var x: Int64 = 0
                while (x < width) {
                    let srcIdx = srcRow + x * 3
                    let dstIdx = dstRow + x * 3

                    if (srcIdx + 2 < bmpInfo.imageData.size && dstIdx + 2 < rgbSize) {
                        // BMP 是 BGR，转换为 RGB
                        rgbData[dstIdx] = bmpInfo.imageData[srcIdx + 2]      // R
                        rgbData[dstIdx + 1] = bmpInfo.imageData[srcIdx + 1]  // G
                        rgbData[dstIdx + 2] = bmpInfo.imageData[srcIdx]      // B
                    }

                    x += 1
                }

                y += 1
            }
        } else if (bitDepth == 16) {
            // 16 位真彩色（RGB565 或 RGB555 格式）
            var y: Int64 = 0
            while (y < height) {
                let srcRow = (height - 1 - y) * rowSize
                let dstRow = y * width * 3

                var x: Int64 = 0
                while (x < width) {
                    let srcIdx = srcRow + x * 2
                    let dstIdx = dstRow + x * 3

                    if (srcIdx + 1 < bmpInfo.imageData.size && dstIdx + 2 < rgbSize) {
                        // 读取 16 位像素值（小端序）
                        let pixel = Int32(bmpInfo.imageData[srcIdx]) |
                                   (Int32(bmpInfo.imageData[srcIdx + 1]) << 8)

                        // 假��� RGB565 格式（最常见）
                        // RGB555: 0RRRRR GGGGG BBBBB (最高位未使用)
                        let r = ((pixel >> 10) & 0x1F) * 255 / 31
                        let g = ((pixel >> 5) & 0x1F) * 255 / 31
                        let b = (pixel & 0x1F) * 255 / 31

                        rgbData[dstIdx] = UInt8(r)
                        rgbData[dstIdx + 1] = UInt8(g)
                        rgbData[dstIdx + 2] = UInt8(b)
                    }

                    x += 1
                }

                y += 1
            }
        } else if (bitDepth == 8) {
            // 8 位索引色
            var y: Int64 = 0
            while (y < height) {
                let srcRow = (height - 1 - y) * rowSize
                let dstRow = y * width * 3

                var x: Int64 = 0
                while (x < width) {
                    let srcIdx = srcRow + x
                    let dstIdx = dstRow + x * 3

                    if (srcIdx < bmpInfo.imageData.size && dstIdx + 2 < rgbSize) {
                        let index = Int64(bmpInfo.imageData[srcIdx])
                        let paletteOffset = index * 3

                        if (paletteOffset + 2 < bmpInfo.palette.size) {
                            rgbData[dstIdx] = bmpInfo.palette[paletteOffset]      // R
                            rgbData[dstIdx + 1] = bmpInfo.palette[paletteOffset + 1]  // G
                            rgbData[dstIdx + 2] = bmpInfo.palette[paletteOffset + 2]  // B
                        }
                    }

                    x += 1
                }

                y += 1
            }
        } else {
            // 其他位深度暂不支持，返回空白图像
            var i: Int64 = 0
            while (i < rgbSize) {
                rgbData[i] = UInt8(255)
                i += 1
            }
        }

        rgbData
    }
}
