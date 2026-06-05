/**
 * PDF-CJ: FontNameReader - 轻量字体名读取器
 *
 * 解析字体文件的 `name` 表，提取 family / full / postscript 名，供 FontFactory
 * 「按名注册/查找」。先读文件头解析表目录，再 seek 到 `name` 表只读所需字节，
 * 不整体加载字体（CJK 字体可达 19MB，且其 name 表可能位于文件末尾）。
 * 支持 TTF / OTF / TTC（TTC 取第一个字体）。
 */
package pdf_cj.text

import std.fs.{File, OpenMode, Path}
import std.io.SeekPosition
import std.collection.ArrayList

class FontNameReader {
    // 返回 (字体名, 子字体序号)；TTC 的每个子字体各自带其序号。
    static func readNames(path: String): ArrayList<(String, Int64)> {
        let result = ArrayList<(String, Int64)>()
        try {
            let file = File(Path(path), OpenMode.Read)

            // 1) 读文件头（足以覆盖 sfnt 偏移表 + 表目录）
            let head = readN(file, 65536)
            if (head.size < 12) { file.close(); return result }

            // 收集所有子字体的 sfnt 偏移（TTC 含多个，如 NotoSansCJK 的 SC/TC/JP/KR）
            var bases = ArrayList<Int64>()
            if (readU32(head, 0) == 0x74746366) {  // 'ttcf'
                if (head.size < 12) { file.close(); return result }
                var numFonts = Int64(readU32(head, 8))
                if (numFonts > 256) { numFonts = 256 }  // 防御异常文件
                var fi: Int64 = 0
                while (fi < numFonts) {
                    let offPos = 12 + fi * 4
                    if (offPos + 4 > head.size) { break }
                    bases.add(Int64(readU32(head, offPos)))
                    fi += 1
                }
            } else {
                bases.add(0)
            }

            // 2) 对每个子字体解析其 name 表
            for (bi in 0..bases.size) {
                let base = bases[bi]
                if (base < 0 || base + 12 > head.size) { continue }
                var numTables = Int64(readU16(head, base + 4))
                if (numTables > 256) { numTables = 256 }  // 防御异常文件
                var rec = base + 12
                var nameOff: Int64 = -1
                var nameLen: Int64 = 0
                var i: Int64 = 0
                while (i < numTables) {
                    if (rec + 16 > head.size) { break }
                    if (readU32(head, rec) == 0x6e616d65) {  // 'name'
                        nameOff = Int64(readU32(head, rec + 8))
                        nameLen = Int64(readU32(head, rec + 12))
                        break
                    }
                    rec += 16
                    i += 1
                }
                // name 表正常远小于 1MB；超出视为误判，跳过以防读入整个大字体导致 OOM
                if (nameOff < 0 || nameLen <= 6 || nameLen > 1048576) { continue }
                file.seek(SeekPosition.Begin(nameOff))
                let nameData = readN(file, nameLen)
                parseNameTable(nameData, bi, result)
            }
            file.close()
        } catch (_: Exception) {}
        result
    }

    // 解析 name 表（nameData 从 name 表起始）；fontIndex 为该字体在 TTC 中的序号
    private static func parseNameTable(d: Array<UInt8>, fontIndex: Int64, out: ArrayList<(String, Int64)>): Unit {
        if (d.size < 6) { return }
        let count = Int64(readU16(d, 2))
        let storage = Int64(readU16(d, 4))
        var r: Int64 = 6
        var k: Int64 = 0
        while (k < count) {
            if (r + 12 > d.size) { break }
            let platformId = readU16(d, r)
            let nameId = readU16(d, r + 6)
            let len = Int64(readU16(d, r + 8))
            let off = Int64(readU16(d, r + 10))
            r += 12
            // nameID 1=Family, 4=Full, 6=PostScript
            if (nameId == 1 || nameId == 4 || nameId == 6) {
                let strStart = storage + off
                if (len > 0 && strStart >= 0 && strStart + len <= d.size) {
                    let s = decodeName(d, strStart, len, platformId)
                    if (s.size > 0) { out.add((s, fontIndex)) }
                }
            }
            k += 1
        }
    }

    // 从当前位置顺序读取最多 n 字节
    private static func readN(file: File, n: Int64): Array<UInt8> {
        if (n <= 0) { return Array<UInt8>(0, repeat: UInt8(0)) }
        let bufSize: Int64 = 65536
        let buffer = Array<UInt8>(bufSize, repeat: UInt8(0))
        var chunks = ArrayList<Array<UInt8>>()
        var total: Int64 = 0
        while (total < n) {
            let want = if (n - total < bufSize) { n - total } else { bufSize }
            let view = if (want == bufSize) { buffer } else { Array<UInt8>(want, repeat: UInt8(0)) }
            let got = file.read(view)
            if (got <= 0) { break }
            let chunk = Array<UInt8>(got, repeat: UInt8(0))
            for (j in 0..got) { chunk[j] = view[j] }
            chunks.add(chunk)
            total += got
        }
        let outArr = Array<UInt8>(total, repeat: UInt8(0))
        var o: Int64 = 0
        for (ci in 0..chunks.size) {
            let c = chunks[ci]
            for (j in 0..c.size) { outArr[o + j] = c[j] }
            o += c.size
        }
        outArr
    }

    // platform 1 (Mac) → 单字节 ASCII；platform 0/3 (Unicode/Windows) → UTF-16BE
    private static func decodeName(data: Array<UInt8>, start: Int64, len: Int64, platformId: UInt16): String {
        // 字体名极少超过 256 字符；超长视为误判，截断。
        // 用 Rune 数组一次构造 String，避免逐字符不可变拼接的 O(n²) 爆内存。
        let cap = if (len > 512) { 512 } else { len }
        let runes = ArrayList<Rune>()
        if (platformId == 1) {
            var j: Int64 = 0
            while (j < cap) {
                let b = data[start + j]
                if (b >= 0x20 && b < 0x7F) { runes.add(Rune(UInt32(b))) }
                j += 1
            }
        } else {
            // UTF-16BE，仅处理 BMP（字体名极少用代理对）
            var j: Int64 = 0
            while (j + 1 < cap) {
                let cu = (UInt32(data[start + j]) << 8) | UInt32(data[start + j + 1])
                if (cu != 0) { runes.add(Rune(cu)) }
                j += 2
            }
        }
        String(runes.toArray())
    }

    private static func readU16(data: Array<UInt8>, pos: Int64): UInt16 {
        (UInt16(data[pos]) << 8) | UInt16(data[pos + 1])
    }

    private static func readU32(data: Array<UInt8>, pos: Int64): UInt32 {
        (UInt32(data[pos]) << 24) | (UInt32(data[pos + 1]) << 16) |
        (UInt32(data[pos + 2]) << 8) | UInt32(data[pos + 3])
    }
}
