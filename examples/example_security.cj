/**
 * PDF-CJ 安全功能验证示例
 */
package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.security.*
import pdf_cj.util.PageSize
import std.io.{File, FileMode}
import std.fs.Path

/**
 * 示例1：PDF 加密
 */
public func exampleEncryption(): Unit {
    try {
        println("\n示例1：PDF 加密...")

        // 创建加密配置
        let encryptionConfig = PdfEncryptionConfig()
        encryptionConfig.setUserPassword("user123")
        encryptionConfig.setOwnerPassword("owner456")
        encryptionConfig.setPermissions(PdfPermissions.createReadOnlyPermissions())
        encryptionConfig.setAlgorithm(EncryptionAlgorithm.AES_128)

        println("  - 用户密码: user123")
        println("  - 所有者密码: owner456")
        println("  - 加密算法: AES-128")
        println("  - 权限: 只读")

        // 创建加密器
        let encryption = PdfEncryption(encryptionConfig)

        println("  - 加密器已创建")
        println("  - 是否加密: ${encryption.isEncrypted()}")

        // 生成加密字典
        let encryptDict = encryption.getEncryptionDictionary()
        println("  - 加密字典已生成")

        println("✓ 加密配置验证成功")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例2：测试不同权限
 */
public func examplePermissions(): Unit {
    try {
        println("\n示例2：权限控制...")

        // 完全权限
        let fullPerms = PdfPermissions.createFullPermissions()
        println("  - 完全权限值: ${fullPerms}")

        // 只读权限
        let readOnlyPerms = PdfPermissions.createReadOnlyPermissions()
        println("  - 只读权限值: ${readOnlyPerms}")

        // 自定义权限（允许打印和复制）
        let customPerms = PdfPermissions.ALLOW_PRINTING | PdfPermissions.ALLOW_COPY
        println("  - 自定义权限值: ${customPerms}")

        println("✓ 权限配置验证成功")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例3：数字签名
 */
public func exampleDigitalSignature(): Unit {
    try {
        println("\n示例3：数字签名...")

        // 创建证书信息
        let certInfo = CertificateInfo()
        certInfo.setSubject("CN=Test User")
        certInfo.setIssuer("CN=Test CA")
        certInfo.setSerialNumber("123456")

        println("  - 证书主题: ${certInfo.subject}")
        println("  - 证书颁发者: ${certInfo.issuer}")

        // 创建证书
        let certificate = X509Certificate(certInfo)
        println("  - 证书已创建")

        // 创建证书链
        let certChain = CertificateChain()
        certChain.addCertificate(certificate)
        println("  - 证书链长度: ${certChain.getCertificateCount()}")

        // 创建私钥（模拟）
        let keyData = Array<UInt8>(256, repeat: 0)
        let privateKey = PrivateKey(keyData, "RSA")
        println("  - 私钥算法: ${privateKey.getAlgorithm()}")

        // 创建 PKCS#7 签名
        let pkcs7 = PdfPKCS7Factory.createForSigning(privateKey, certChain)
        pkcs7.setReason("测试签名")
        pkcs7.setLocation("中国")
        pkcs7.setContactInfo("test@example.com")

        println("  - 签名原因: ${pkcs7.getReason()}")
        println("  - 签名位置: ${pkcs7.getLocation()}")
        println("  - 联系方式: ${pkcs7.getContactInfo()}")
        println("  - 哈希算法: ${pkcs7.getHashAlgorithmName()}")

        // 测试哈希计算
        let testData = Array<UInt8>(10, repeat: 0)
        let hash = pkcs7.computeHash(testData)
        println("  - 哈希结果长度: ${hash.size} 字节")

        println("✓ 数字签名验证成功")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 示例4：签名外观
 */
public func exampleSignatureAppearance(): Unit {
    try {
        println("\n示例4：签名外观...")

        // 使用构建器创建签名外观
        let builder = SignatureAppearanceBuilder()
        builder.setFieldName("Signature1")
        builder.setPageNumber(1)
        builder.setRenderMode(SignatureRenderMode.NameAndDescription)
        builder.setSignerText("张三")

        println("  - 字段名: Signature1")
        println("  - 页码: 1")
        println("  - 渲染模式: 名称和描述")

        let appearance = builder.build()
        println("  - 签名外观已创建")

        // 测试预定义样式
        let standardStyle = SignatureStyles.createStandardStyle()
        println("  - 标准样式已创建")

        let minimalStyle = SignatureStyles.createMinimalStyle()
        println("  - 简洁样式已创建")

        println("✓ 签名外观验证成功")
    } catch (e: Exception) {
        println("✗ 错误: ${e.message}")
    }
}

/**
 * 主函数
 */
main(): Int64 {
    println("=== PDF-CJ 安全功能验证 ===")

    exampleEncryption()
    examplePermissions()
    exampleDigitalSignature()
    exampleSignatureAppearance()

    println("\n=== 验证完成 ===")
    println("\n注意:")
    println("  - 加密功能使用简化实现（XOR），生产环境需要真正的 RC4/AES")
    println("  - 数字签名使用简化实现，生产环境需要真正的 RSA/SHA 算法")
    println("  - 这些示例主要验证 API 接口和数据结构")

    0
}
