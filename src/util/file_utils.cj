/**
 * PDF-CJ: FileUtils - 文件工具类
 * 提供高效的文件读取功能
 */
package pdf_cj.util

import std.fs.*
import std.collection.ArrayList

/**
 * 高效读取整个文件到字节数组
 */
public func readFileToBytes(path: String): Array<UInt8> {
    let file = File(Path(path), OpenMode.Read)

    // 使用较大的缓冲区进行批量读取
    let bufferSize: Int64 = 65536  // 64KB 缓冲区
    let buffer = Array<UInt8>(bufferSize, repeat: UInt8(0))

    // 使用 ArrayList 收集数据块
    var chunks = ArrayList<Array<UInt8>>()
    var totalSize: Int64 = 0

    while (true) {
        let bytesRead = file.read(buffer)
        if (bytesRead <= 0) {
            break
        }

        // 复制读取的部分
        let chunk = Array<UInt8>(bytesRead, repeat: UInt8(0))
        for (i in 0..bytesRead) {
            chunk[i] = buffer[i]
        }
        chunks.add(chunk)
        totalSize += bytesRead
    }

    file.close()

    // 合并所有块到一个数组
    let result = Array<UInt8>(totalSize, repeat: UInt8(0))
    var offset: Int64 = 0
    for (chunkIndex in 0..chunks.size) {
        let chunk = chunks[chunkIndex]
        for (i in 0..chunk.size) {
            result[offset + i] = chunk[i]
        }
        offset += chunk.size
    }

    result
}
