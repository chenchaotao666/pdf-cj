/**
 * PDF-CJ: PdfName - PDF 名称对象
 */
package pdf_cj.base


/**
 * PDF 名称对象
 * 以 / 开头的标识符
 */
public class PdfName <: PdfObjectBase {
    private let _name: String

    /**
     * 从字符串创建（不含 / 前缀）
     */
    public init(name: String) {
        this._name = name
    }

    /**
     * 获取名称字符串
     */
    public prop name: String {
        get() { _name }
    }

    public override func getType(): PdfObjectType {
        PdfObjectType.Name
    }

    public override func writeTo(os: PdfOutputStream): Unit {
        os.write(UInt8(0x2F))  // /
        for (c in _name) {
            let code = UInt32(c)
            // 需要转义的字符: 空格、特殊字符、非ASCII
            if (code < 33 || code > 126 || isDelimiter(UInt8(c)) || code == 0x23) {
                os.write(UInt8(0x23))  // #
                writeHexByte(os, UInt8(code))
            } else {
                os.write(UInt8(c))
            }
        }
    }

    /**
     * 检查是否为分隔符
     */
    private func isDelimiter(c: UInt8): Bool {
        match (c) {
            case '(' | ')' | '<' | '>' | '[' | ']' | '{' | '}' | '/' | '%' => true
            case _ => false
        }
    }

    /**
     * 写入十六进制字节
     */
    private func writeHexByte(os: PdfOutputStream, b: Byte): Unit {
        let hexChars = "0123456789ABCDEF"
        let high = (UInt32(b) >> 4) & 0x0F
        let low = UInt32(b) & 0x0F
        os.write(UInt8(hexChars[Int64(high)]))
        os.write(UInt8(hexChars[Int64(low)]))
    }

    // ===== 预定义常用名称 =====

    // 类型名称
    public static let TYPE = PdfName("Type")
    public static let SUBTYPE = PdfName("Subtype")

    // 页面相关
    public static let PAGE = PdfName("Page")
    public static let PAGES = PdfName("Pages")
    public static let CATALOG = PdfName("Catalog")
    public static let KIDS = PdfName("Kids")
    public static let COUNT = PdfName("Count")
    public static let PARENT = PdfName("Parent")
    public static let MEDIABOX = PdfName("MediaBox")
    public static let CROPBOX = PdfName("CropBox")
    public static let RESOURCES = PdfName("Resources")
    public static let CONTENTS = PdfName("Contents")
    public static let ROTATE = PdfName("Rotate")

    // 字体相关
    public static let FONT = PdfName("Font")
    public static let BASEFONT = PdfName("BaseFont")
    public static let ENCODING = PdfName("Encoding")
    public static let TYPE1 = PdfName("Type1")
    public static let TRUETYPE = PdfName("TrueType")
    public static let WINANSIENCODING = PdfName("WinAnsiEncoding")
    public static let FONTDESCRIPTOR = PdfName("FontDescriptor")
    public static let FONTNAME = PdfName("FontName")
    public static let FLAGS = PdfName("Flags")
    public static let FONTBBOX = PdfName("FontBBox")
    public static let ITALICANGLE = PdfName("ItalicAngle")
    public static let ASCENT = PdfName("Ascent")
    public static let DESCENT = PdfName("Descent")
    public static let CAPHEIGHT = PdfName("CapHeight")
    public static let STEMV = PdfName("StemV")
    public static let FIRSTCHAR = PdfName("FirstChar")
    public static let LASTCHAR = PdfName("LastChar")
    public static let WIDTHS = PdfName("Widths")

    // 图形状态
    public static let EXTGSTATE = PdfName("ExtGState")
    public static let CA = PdfName("CA")
    public static let ca = PdfName("ca")
    public static let BM = PdfName("BM")

    // 渐变与图案
    public static let PATTERN = PdfName("Pattern")
    public static let SHADING = PdfName("Shading")
    public static let PATTERNTYPE = PdfName("PatternType")
    public static let SHADINGTYPE = PdfName("ShadingType")
    public static let COORDS = PdfName("Coords")
    public static let DOMAIN = PdfName("Domain")
    public static let FUNCTION = PdfName("Function")
    public static let FUNCTIONTYPE = PdfName("FunctionType")
    public static let EXTEND = PdfName("Extend")
    public static let MATRIX = PdfName("Matrix")
    public static let C0 = PdfName("C0")
    public static let C1 = PdfName("C1")

    // 颜色空间
    public static let COLORSPACE = PdfName("ColorSpace")
    public static let DEVICERGB = PdfName("DeviceRGB")
    public static let DEVICEGRAY = PdfName("DeviceGray")
    public static let DEVICECMYK = PdfName("DeviceCMYK")

    // 流相关
    public static let LENGTH = PdfName("Length")
    public static let FILTER = PdfName("Filter")
    public static let FLATEDECODE = PdfName("FlateDecode")
    public static let ASCIIHEXDECODE = PdfName("ASCIIHexDecode")
    public static let ASCII85DECODE = PdfName("ASCII85Decode")
    public static let LZWDECODE = PdfName("LZWDecode")
    public static let DCTDECODE = PdfName("DCTDecode")
    public static let JPXDECODE = PdfName("JPXDecode")

    // 图片相关
    public static let XOBJECT = PdfName("XObject")
    public static let IMAGE = PdfName("Image")
    public static let WIDTH = PdfName("Width")
    public static let HEIGHT = PdfName("Height")
    public static let BITSPERCOMPONENT = PdfName("BitsPerComponent")
    public static let INTERPOLATE = PdfName("Interpolate")
    public static let MASK = PdfName("Mask")
    public static let SMASK = PdfName("SMask")

    // 文档信息
    public static let INFO = PdfName("Info")
    public static let ROOT = PdfName("Root")
    public static let SIZE = PdfName("Size")
    public static let TITLE = PdfName("Title")
    public static let AUTHOR = PdfName("Author")
    public static let SUBJECT = PdfName("Subject")
    public static let KEYWORDS = PdfName("Keywords")
    public static let CREATOR = PdfName("Creator")
    public static let PRODUCER = PdfName("Producer")
    public static let CREATIONDATE = PdfName("CreationDate")
    public static let MODDATE = PdfName("ModDate")

    // 文档结构
    public static let OUTLINES = PdfName("Outlines")
    public static let DESTS = PdfName("Dests")
    public static let NAMES = PdfName("Names")
    public static let PAGELABELS = PdfName("PageLabels")
    public static let STRUCTTREEROOT = PdfName("StructTreeRoot")
    public static let MARKINFO = PdfName("MarkInfo")
    public static let LANG = PdfName("Lang")

    // 注释
    public static let ANNOTS = PdfName("Annots")
    public static let ANNOT = PdfName("Annot")
    public static let LINK = PdfName("Link")
    public static let RECT = PdfName("Rect")
    public static let BORDER = PdfName("Border")
    public static let A = PdfName("A")
    public static let DEST = PdfName("Dest")
    public static let URI = PdfName("URI")
    public static let S = PdfName("S")

    // 动作
    public static let ACTION = PdfName("Action")
    public static let GOTO = PdfName("GoTo")
    public static let GOTOR = PdfName("GoToR")
    public static let NAMED = PdfName("Named")
    public static let LAUNCH = PdfName("Launch")
    public static let JAVASCRIPT = PdfName("JavaScript")
    public static let JS = PdfName("JS")
    public static let N = PdfName("N")
    public static let D = PdfName("D")
    public static let F = PdfName("F")

    // 表单
    public static let ACROFORM = PdfName("AcroForm")
    public static let FIELDS = PdfName("Fields")
    public static let FT = PdfName("FT")
    public static let TX = PdfName("Tx")
    public static let BTN = PdfName("Btn")
    public static let CH = PdfName("Ch")
    public static let SIG = PdfName("Sig")
    public static let V = PdfName("V")
    public static let T = PdfName("T")

    // 透明度
    public static let TRANSPARENCY = PdfName("Transparency")
    public static let GROUP = PdfName("Group")
    public static let CS = PdfName("CS")

    // 其他
    public static let PROCSET = PdfName("ProcSet")
    public static let PDF = PdfName("PDF")
    public static let TEXT = PdfName("Text")
    public static let IMAGEB = PdfName("ImageB")
    public static let IMAGEC = PdfName("ImageC")
    public static let IMAGEI = PdfName("ImageI")
}
