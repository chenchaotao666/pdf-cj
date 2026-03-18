/**
 * PDF-CJ: DefaultFontMapper - 默认字体映射器
 * 系统字体名称到字体文件的映射
 */
package pdf_cj.text

import std.collection.{HashMap, ArrayList}
import std.fs.{File, Path}

/**
 * 默认字体映射器
 * 将字体名称映射到系统字体文件路径
 */
public class DefaultFontMapper {
    private var fontMap: HashMap<String, String> = HashMap<String, String>()
    private var aliases: HashMap<String, String> = HashMap<String, String>()
    private var fontDirs: ArrayList<String> = ArrayList<String>()

    /**
     * 构造函数
     */
    public init() {
        initializeDefaultDirs()
        initializeAliases()
    }

    /**
     * 初始化默认字体目录
     */
    private func initializeDefaultDirs(): Unit {
        // Linux 字体目录
        fontDirs.add("/usr/share/fonts/")
        fontDirs.add("/usr/local/share/fonts/")
        fontDirs.add("${getHomeDir()}/.fonts/")
        fontDirs.add("/usr/share/fonts/truetype/")
        fontDirs.add("/usr/share/fonts/opentype/")

        // Windows 字体目录
        fontDirs.add("C:\\Windows\\Fonts\\")

        // macOS 字体目录
        fontDirs.add("/Library/Fonts/")
        fontDirs.add("/System/Library/Fonts/")
        fontDirs.add("${getHomeDir()}/Library/Fonts/")
    }

    /**
     * 获取用户主目录
     * 简化实现
     */
    private func getHomeDir(): String {
        "/home/user"  // 简化实现
    }

    /**
     * 初始化字体别名
     */
    private func initializeAliases(): Unit {
        // Sans-serif 字体
        aliases["sans-serif"] = "Helvetica"
        aliases["Arial"] = "Helvetica"
        aliases["Verdana"] = "Helvetica"

        // Serif 字体
        aliases["serif"] = "Times-Roman"
        aliases["Times"] = "Times-Roman"
        aliases["Georgia"] = "Times-Roman"

        // Monospace 字体
        aliases["monospace"] = "Courier"
        aliases["Courier New"] = "Courier"
        aliases["Monaco"] = "Courier"

        // CJK 字体别名
        aliases["宋体"] = "SimSun"
        aliases["黑体"] = "SimHei"
        aliases["微软雅黑"] = "Microsoft YaHei"
    }

    /**
     * 添加字体目录
     * @param dir 目录路径
     */
    public func addFontDirectory(dir: String): Unit {
        fontDirs.add(dir)
    }

    /**
     * 添加字体映射
     * @param fontName 字体名称
     * @param fontPath 字体文件路径
     */
    public func putFont(fontName: String, fontPath: String): Unit {
        fontMap[fontName] = fontPath
    }

    /**
     * 添加字体别名
     * @param alias 别名
     * @param fontName 实际字体名称
     */
    public func putAlias(alias: String, fontName: String): Unit {
        aliases[alias] = fontName
    }

    /**
     * 映射字体名称到文件路径
     * @param fontName 字体名称
     * @return 字体文件路径，如果未找到返回 None
     */
    public func mapFont(fontName: String): ?String {
        // 1. 检查是否已经映射
        match (fontMap.get(fontName)) {
            case Some(path) => return Some(path)
            case None => ()
        }

        // 2. 检查别名
        let actualName = match (aliases.get(fontName)) {
            case Some(name) => name
            case None => fontName
        }

        // 3. 在字体目录中搜索
        let foundPath = searchFontInDirs(actualName)
        match (foundPath) {
            case Some(path) =>
                // 缓存结果
                fontMap[fontName] = path
                return Some(path)
            case None => ()
        }

        // 4. 尝试样式变体
        let variants = generateStyleVariants(actualName)
        for (i in 0..variants.size) {
            let variant = variants[i]
            let variantPath = searchFontInDirs(variant)
            match (variantPath) {
                case Some(path) =>
                    fontMap[fontName] = path
                    return Some(path)
                case None => ()
            }
        }

        // 未找到
        None
    }

    /**
     * 在字体目录中搜索字体
     * @param fontName 字体名称
     * @return 字体文件路径
     */
    private func searchFontInDirs(fontName: String): ?String {
        // 生成可能的文件名
        let possibleNames = generatePossibleFileNames(fontName)

        for (i in 0..fontDirs.size) {
            let dir = fontDirs[i]
            for (j in 0..possibleNames.size) {
                let fileName = possibleNames[j]
                let fullPath = "${dir}${fileName}"

                // 检查文件是否存在（简化：不实际检查）
                // 实际应该使用 File.exists()
                if (fileExists(fullPath)) {
                    return Some(fullPath)
                }
            }
        }

        None
    }

    /**
     * 检查文件是否存在
     * 简化实现
     */
    private func fileExists(path: String): Bool {
        // 简化实现：总是返回 false
        // 实际应该检查文件系统
        false
    }

    /**
     * 生成可能的文件名
     * @param fontName 字体名称
     * @return 可能的文件名列表
     */
    private func generatePossibleFileNames(fontName: String): Array<String> {
        let names = ArrayList<String>()

        // 原始名称
        names.add("${fontName}.ttf")
        names.add("${fontName}.ttc")
        names.add("${fontName}.otf")

        // 小写（简化：不实现）
        // let lowerName = fontName.toLowerCase()
        // names.add("${lowerName}.ttf")

        // 去除空格
        let noSpace = fontName.replace(" ", "")
        names.add("${noSpace}.ttf")
        names.add("${noSpace}.ttc")
        names.add("${noSpace}.otf")

        // 转换为数组
        let arr = Array<String>(names.size, repeat: "")
        for (i in 0..names.size) {
            arr[i] = names[i]
        }
        arr
    }

    /**
     * 生成样式变体
     * @param fontName 字体名称
     * @return 样式变体列表
     */
    private func generateStyleVariants(fontName: String): Array<String> {
        let variants = ArrayList<String>()

        // 添加 Regular 变体
        variants.add("${fontName}-Regular")
        variants.add("${fontName}Regular")

        // 添加 Bold 变体
        variants.add("${fontName}-Bold")
        variants.add("${fontName}Bold")

        // 添加 Italic 变体
        variants.add("${fontName}-Italic")
        variants.add("${fontName}Italic")

        // 添加 BoldItalic 变体
        variants.add("${fontName}-BoldItalic")
        variants.add("${fontName}BoldItalic")

        // 转换为数组
        let arr = Array<String>(variants.size, repeat: "")
        for (i in 0..variants.size) {
            arr[i] = variants[i]
        }
        arr
    }

    /**
     * 映射字体族和样式
     * @param family 字体族名称
     * @param bold 是否粗体
     * @param italic 是否斜体
     * @return 字体文件路径
     */
    public func mapFontWithStyle(family: String, bold: Bool, italic: Bool): ?String {
        var fontName = family

        if (bold && italic) {
            fontName = "${family}-BoldItalic"
        } else if (bold) {
            fontName = "${family}-Bold"
        } else if (italic) {
            fontName = "${family}-Italic"
        }

        mapFont(fontName)
    }

    /**
     * 获取所有映射的字体
     */
    public func getAllMappings(): Array<String> {
        let result = ArrayList<String>()
        for ((name, path) in fontMap) {
            result.add("${name} -> ${path}")
        }

        let arr = Array<String>(result.size, repeat: "")
        for (i in 0..result.size) {
            arr[i] = result[i]
        }
        arr
    }

    /**
     * 清空所有映射
     */
    public func clear(): Unit {
        fontMap.clear()
    }

    /**
     * 获取映射的字体数量
     */
    public func getMappingCount(): Int64 {
        fontMap.size
    }
}

/**
 * 字体映射器工具类
 */
public class FontMapperUtil {
    /**
     * 从字体名称解析样式（简化实现）
     * @param fontName 字体名称
     * @return 样式描述字符串
     */
    public static func parseStyle(fontName: String): String {
        if (fontName.contains("BoldItalic") || fontName.contains("Bold Italic")) {
            return "BoldItalic"
        } else if (fontName.contains("Bold")) {
            return "Bold"
        } else if (fontName.contains("Italic") || fontName.contains("Oblique")) {
            return "Italic"
        } else {
            return "Regular"
        }
    }

    /**
     * 从字体名称提取字体族
     * @param fontName 字体名称
     * @return 字体族名称
     */
    public static func extractFamily(fontName: String): String {
        var family = fontName

        // 移除样式后缀
        family = family.replace("-Bold", "")
        family = family.replace("-Italic", "")
        family = family.replace("-BoldItalic", "")
        family = family.replace("Bold", "")
        family = family.replace("Italic", "")
        family = family.replace("-Regular", "")
        family = family.replace("Regular", "")

        family
    }

    /**
     * 创建标准字体映射器
     * 包含常见字体的映射
     */
    public static func createStandard(): DefaultFontMapper {
        let mapper = DefaultFontMapper()

        // 添加常见 CJK 字体映射（Linux）
        mapper.putFont("SimSun", "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc")
        mapper.putFont("SimHei", "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc")
        mapper.putFont("NotoSansCJK", "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc")

        mapper
    }
}
