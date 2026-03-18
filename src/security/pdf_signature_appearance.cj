/**
 * PDF-CJ: PdfSignatureAppearance - PDF 签名外观
 * 定义数字签名在 PDF 中的可视化显示
 */
package pdf_cj.security

import pdf_cj.base.*
import pdf_cj.form.{PdfSignatureFormField, PdfAnnotation, AnnotationType}
import pdf_cj.util.Rectangle
import std.collection.ArrayList

/**
 * 签名渲染模式
 */
public enum SignatureRenderMode {
    | Description        // 仅显示描述文本
    | NameAndDescription // 显示名称和描述
    | GraphicAndDescription // 显示图形和描述
    | Graphic           // 仅显示图形
}

/**
 * 签名外观配置
 */
public class SignatureAppearanceConfig {
    public var renderMode: SignatureRenderMode = SignatureRenderMode.NameAndDescription
    public var layer2Text: String = ""
    public var layer4Text: String = ""
    public var signatureGraphic: ?Array<UInt8> = None  // 图片数据
    public var backgroundColor: ?Array<Float32> = None
    public var borderWidth: Float32 = 1.0

    public init() {}

    /**
     * 设置渲染模式
     */
    public func setRenderMode(mode: SignatureRenderMode): Unit {
        this.renderMode = mode
    }

    /**
     * 设置第2层文本（签名者信息）
     */
    public func setLayer2Text(text: String): Unit {
        this.layer2Text = text
    }

    /**
     * 设置第4层文本（附加信息）
     */
    public func setLayer4Text(text: String): Unit {
        this.layer4Text = text
    }

    /**
     * 设置签名图形
     */
    public func setSignatureGraphic(imageData: Array<UInt8>): Unit {
        this.signatureGraphic = Some(imageData)
    }

    /**
     * 设置背景颜色
     */
    public func setBackgroundColor(r: Float32, g: Float32, b: Float32): Unit {
        let color = Array<Float32>(3, repeat: 0.0)
        color[0] = r
        color[1] = g
        color[2] = b
        this.backgroundColor = Some(color)
    }

    /**
     * 设置边框宽度
     */
    public func setBorderWidth(width: Float32): Unit {
        this.borderWidth = width
    }
}

/**
 * PDF 签名外观
 */
public class PdfSignatureAppearance {
    private var fieldName: String
    private var rectangle: Rectangle
    private var pageNumber: Int32
    private var config: SignatureAppearanceConfig
    private var signatureField: ?PdfSignatureFormField = None
    private var pkcs7: ?PdfPKCS7 = None

    /**
     * 构造函数
     */
    public init(fieldName: String, rect: Rectangle, pageNum: Int32) {
        this.fieldName = fieldName
        this.rectangle = rect
        this.pageNumber = pageNum
        this.config = SignatureAppearanceConfig()
    }

    /**
     * 设置配置
     */
    public func setConfig(cfg: SignatureAppearanceConfig): Unit {
        this.config = cfg
    }

    /**
     * 设置 PKCS#7 签名
     */
    public func setPKCS7(signature: PdfPKCS7): Unit {
        this.pkcs7 = Some(signature)
    }

    /**
     * 创建签名字段
     */
    public func createSignatureField(): PdfSignatureFormField {
        let field = PdfSignatureFormField(fieldName, rectangle)
        this.signatureField = Some(field)

        // 设置字段属性
        setupFieldProperties(field)

        field
    }

    /**
     * 设置字段属性
     */
    private func setupFieldProperties(field: PdfSignatureFormField): Unit {
        // 设置字段的外观
        match (pkcs7) {
            case Some(signature) =>
                // 可以设置签名相关信息
                let reason = signature.getReason()
                let location = signature.getLocation()
            case None => ()
        }
    }

    /**
     * 生成外观流
     */
    public func generateAppearanceStream(): PdfStream {
        // 构建外观内容
        let content = buildAppearanceContent()

        // 创建流对象
        PdfStream(content)
    }

    /**
     * 构建外观内容
     */
    private func buildAppearanceContent(): Array<UInt8> {
        // 简化实现：生成基本的外观指令
        // 实际应该根据配置生成完整的 PDF 内容流

        let width = rectangle.right - rectangle.left
        let height = rectangle.top - rectangle.bottom

        var contentStr = ""

        // 绘制边框
        if (config.borderWidth > 0.0) {
            contentStr = "${contentStr}${config.borderWidth} w\n"
            contentStr = "${contentStr}0 0 ${width} ${height} re S\n"
        }

        // 绘制背景
        match (config.backgroundColor) {
            case Some(color) =>
                contentStr = "${contentStr}${color[0]} ${color[1]} ${color[2]} rg\n"
                contentStr = "${contentStr}0 0 ${width} ${height} re f\n"
            case None => ()
        }

        // 绘制文本
        match (config.renderMode) {
            case Description | NameAndDescription =>
                contentStr = "${contentStr}BT\n"
                contentStr = "${contentStr}/Helv 12 Tf\n"
                contentStr = "${contentStr}10 ${height - 20.0} Td\n"
                contentStr = "${contentStr}(${config.layer2Text}) Tj\n"
                contentStr = "${contentStr}ET\n"
            case _ => ()
        }

        stringToBytes(contentStr)
    }

    /**
     * 获取签名字典
     */
    public func getSignatureDictionary(): PdfDictionary {
        let dict = PdfDictionary()

        // 签名类型
        dict.put(PdfName("Type"), PdfName("Sig"))

        // 过滤器
        dict.put(PdfName("Filter"), PdfName("Adobe.PPKLite"))

        // 子过滤器
        dict.put(PdfName("SubFilter"), PdfName("adbe.pkcs7.detached"))

        // 签名者姓名
        match (pkcs7) {
            case Some(signature) =>
                let signer = signature.getSignerInfo()
                if (signer.size > 0) {
                    dict.put(PdfName("Name"), PdfString(signer))
                }

                // 签名原因
                let reason = signature.getReason()
                if (reason.size > 0) {
                    dict.put(PdfName("Reason"), PdfString(reason))
                }

                // 签名位置
                let location = signature.getLocation()
                if (location.size > 0) {
                    dict.put(PdfName("Location"), PdfString(location))
                }

                // 联系信息
                let contact = signature.getContactInfo()
                if (contact.size > 0) {
                    dict.put(PdfName("ContactInfo"), PdfString(contact))
                }
            case None => ()
        }

        // 签名时间（简化）
        dict.put(PdfName("M"), PdfString("D:20240101000000Z"))

        dict
    }

    /**
     * 获取字段名
     */
    public func getFieldName(): String {
        fieldName
    }

    /**
     * 获取矩形
     */
    public func getRectangle(): Rectangle {
        rectangle
    }

    /**
     * 获取页码
     */
    public func getPageNumber(): Int32 {
        pageNumber
    }

    /**
     * 设置可见性
     */
    public func setVisible(visible: Bool): Unit {
        if (!visible) {
            // 设置为不可见签名（矩形大小为0）
            this.rectangle = Rectangle(0.0, 0.0, 0.0, 0.0)
        }
    }

    /**
     * 字符串转字节数组
     */
    private func stringToBytes(str: String): Array<UInt8> {
        let bytes = Array<UInt8>(str.size, repeat: 0)
        var index: Int64 = 0

        for (ch in str) {
            if (index < bytes.size) {
                bytes[index] = UInt8(Int64(ch))
                index += 1
            }
        }

        bytes
    }
}

/**
 * 签名外观构建器
 */
public class SignatureAppearanceBuilder {
    private var fieldName: String = "Signature1"
    private var rectangle: Rectangle = Rectangle(0.0, 0.0, 200.0, 50.0)
    private var pageNumber: Int32 = 1
    private var config: SignatureAppearanceConfig = SignatureAppearanceConfig()
    private var pkcs7: ?PdfPKCS7 = None

    /**
     * 构造函数
     */
    public init() {}

    /**
     * 设置字段名
     */
    public func setFieldName(name: String): SignatureAppearanceBuilder {
        this.fieldName = name
        this
    }

    /**
     * 设置位置
     */
    public func setRectangle(rect: Rectangle): SignatureAppearanceBuilder {
        this.rectangle = rect
        this
    }

    /**
     * 设置页码
     */
    public func setPageNumber(pageNum: Int32): SignatureAppearanceBuilder {
        this.pageNumber = pageNum
        this
    }

    /**
     * 设置渲染模式
     */
    public func setRenderMode(mode: SignatureRenderMode): SignatureAppearanceBuilder {
        config.setRenderMode(mode)
        this
    }

    /**
     * 设置签名者文本
     */
    public func setSignerText(text: String): SignatureAppearanceBuilder {
        config.setLayer2Text(text)
        this
    }

    /**
     * 设置 PKCS#7
     */
    public func setPKCS7(signature: PdfPKCS7): SignatureAppearanceBuilder {
        this.pkcs7 = Some(signature)
        this
    }

    /**
     * 构建签名外观
     */
    public func build(): PdfSignatureAppearance {
        let appearance = PdfSignatureAppearance(fieldName, rectangle, pageNumber)
        appearance.setConfig(config)
        match (pkcs7) {
            case Some(sig) =>
                appearance.setPKCS7(sig)
            case None => ()
        }
        appearance
    }
}

/**
 * 预定义签名样式
 */
public class SignatureStyles {
    /**
     * 创建标准样式
     */
    public static func createStandardStyle(): SignatureAppearanceConfig {
        let config = SignatureAppearanceConfig()
        config.setRenderMode(SignatureRenderMode.NameAndDescription)
        config.setBorderWidth(1.0)
        config
    }

    /**
     * 创建简洁样式
     */
    public static func createMinimalStyle(): SignatureAppearanceConfig {
        let config = SignatureAppearanceConfig()
        config.setRenderMode(SignatureRenderMode.Description)
        config.setBorderWidth(0.0)
        config
    }

    /**
     * 创建图形样式
     */
    public static func createGraphicStyle(): SignatureAppearanceConfig {
        let config = SignatureAppearanceConfig()
        config.setRenderMode(SignatureRenderMode.Graphic)
        config.setBorderWidth(0.0)
        config
    }
}

/**
 * 签名助手
 * 提供便捷的签名操作方法
 */
public class SignatureHelper {
    /**
     * 创建简单签名外观
     */
    public static func createSimpleAppearance(
        fieldName: String,
        x: Float32,
        y: Float32,
        width: Float32,
        height: Float32,
        pageNum: Int32
    ): PdfSignatureAppearance {
        let rect = Rectangle(x, y, x + width, y + height)
        PdfSignatureAppearance(fieldName, rect, pageNum)
    }

    /**
     * 创建不可见签名外观
     */
    public static func createInvisibleAppearance(fieldName: String): PdfSignatureAppearance {
        let rect = Rectangle(0.0, 0.0, 0.0, 0.0)
        let appearance = PdfSignatureAppearance(fieldName, rect, 1)
        appearance.setVisible(false)
        appearance
    }

    /**
     * 创建带文本的签名外观
     */
    public static func createTextAppearance(
        fieldName: String,
        signerName: String,
        reason: String,
        x: Float32,
        y: Float32,
        pageNum: Int32
    ): PdfSignatureAppearance {
        let rect = Rectangle(x, y, x + 200.0, y + 50.0)
        let appearance = PdfSignatureAppearance(fieldName, rect, pageNum)

        let config = SignatureAppearanceConfig()
        config.setLayer2Text("Signed by: ${signerName}")
        config.setLayer4Text("Reason: ${reason}")
        appearance.setConfig(config)

        appearance
    }
}
