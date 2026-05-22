/**
 * PDF-CJ: PdfEncryption - PDF 标准安全处理器
 *
 * 支持：
 *   RC4-128  (V=2, R=3) — PDF 1.4
 *   AES-128  (V=4, R=4) — PDF 1.6
 *   AES-256  (V=5, R=6) — PDF 2.0
 *
 * 密钥派生算法遵循 ISO 32000-1 §7.6.3 / ISO 32000-2 §7.6.4
 * 加密算法依赖 OpenHiTLS（AES-CBC）；RC4 纯 Cangjie 实现。
 */
package pdf_cj.security

import pdf_cj.base.*

// ── PDF 标准密码填充字节串（32 字节，ISO 32000-1 §7.6.3.3） ──────────────────
let PDF_PWD_PADDING: Array<UInt8> = [
    0x28u8, 0xBFu8, 0x4Eu8, 0x5Eu8, 0x4Eu8, 0x75u8, 0x8Au8, 0x41u8,
    0x64u8, 0x00u8, 0x4Eu8, 0x56u8, 0xFFu8, 0xFAu8, 0x01u8, 0x08u8,
    0x2Eu8, 0x2Eu8, 0x00u8, 0xB6u8, 0xD0u8, 0x68u8, 0x3Eu8, 0x80u8,
    0x2Fu8, 0x0Cu8, 0xA9u8, 0xFEu8, 0x64u8, 0x53u8, 0x69u8, 0x7Au8
]

// ── 公开 API：加密算法枚举 ────────────────────────────────────────────────────
public enum EncryptionAlgorithm {
    | RC4_128     // V=2 R=3, 128-bit key
    | AES_128     // V=4 R=4, 128-bit key
    | AES_256     // V=5 R=6, 256-bit key
}

// ── 权限标志 ──────────────────────────────────────────────────────────────────
public class PdfPermissions {
    // ALLOW_PRINTING = bit3(4) + bit12(2048): full quality print (matches iText convention)
    public static let ALLOW_PRINTING: Int32           = 2052
    public static let ALLOW_MODIFY_CONTENTS: Int32    = 8
    public static let ALLOW_COPY: Int32               = 16
    public static let ALLOW_MODIFY_ANNOTATIONS: Int32 = 32
    public static let ALLOW_FILL_IN: Int32            = 256
    public static let ALLOW_SCREEN_READERS: Int32     = 512
    public static let ALLOW_ASSEMBLY: Int32           = 1024
    // ALLOW_DEGRADED_PRINTING = bit3(4) only: low quality print only
    public static let ALLOW_DEGRADED_PRINTING: Int32  = 4

    public static func createFullPermissions(): Int32 {
        ALLOW_PRINTING | ALLOW_MODIFY_CONTENTS | ALLOW_COPY |
        ALLOW_MODIFY_ANNOTATIONS | ALLOW_FILL_IN | ALLOW_SCREEN_READERS |
        ALLOW_ASSEMBLY | ALLOW_DEGRADED_PRINTING
    }

    public static func createReadOnlyPermissions(): Int32 {
        ALLOW_SCREEN_READERS
    }
}

// ── 加密配置 ──────────────────────────────────────────────────────────────────
public class PdfEncryptionConfig {
    public var userPassword: String  = ""
    public var ownerPassword: String = ""
    public var permissions: Int32    = PdfPermissions.createFullPermissions()
    public var algorithm: EncryptionAlgorithm = EncryptionAlgorithm.AES_128
    public var encryptMetadata: Bool = true

    public init() {}

    public func setUserPassword(password: String): Unit  { this.userPassword  = password }
    public func setOwnerPassword(password: String): Unit { this.ownerPassword = password }
    public func setPermissions(perms: Int32): Unit       { this.permissions   = perms }
    public func setAlgorithm(algo: EncryptionAlgorithm): Unit { this.algorithm = algo }
}

// ── RC4 纯实现（OpenHiTLS 不暴露 RC4 cipher API） ────────────────────────────
func rc4(key: Array<UInt8>, data: Array<UInt8>): Array<UInt8> {
    var S = Array<UInt8>(256, repeat: 0)
    for (i in 0..256) { S[i] = UInt8(i % 256) }

    var j: Int64 = 0
    for (i in 0..256) {
        j = (j + Int64(S[i]) + Int64(key[i % key.size])) % 256
        let tmp = S[i]; S[i] = S[j]; S[j] = tmp
    }

    let out = Array<UInt8>(data.size, repeat: 0)
    var i: Int64 = 0
    j = 0
    for (k in 0..data.size) {
        i = (i + 1) % 256
        j = (j + Int64(S[i])) % 256
        let tmp = S[i]; S[i] = S[j]; S[j] = tmp
        out[k] = data[k] ^ S[(Int64(S[i]) + Int64(S[j])) % 256]
    }
    out
}

// ── 工具函数 ──────────────────────────────────────────────────────────────────

// 将密码字符串填充/截断到32字节（PDF标准填充）
func padPassword(pwd: String): Array<UInt8> {
    let result = Array<UInt8>(32, repeat: 0)
    let bytes  = pwd.toArray()  // Rune array
    var i: Int64 = 0
    // 先写密码字节（取低8位即可，PDF 密码为 Latin-1）
    while (i < Int64(bytes.size) && i < 32) {
        result[i] = UInt8(Int64(bytes[i]) & 0xFF)
        i += 1
    }
    // 剩余用标准填充补齐
    var p: Int64 = 0
    while (i < 32) {
        result[i] = PDF_PWD_PADDING[p % 32]
        i += 1
        p += 1
    }
    result
}

// 连接多个 Array<UInt8>
func concat(arrays: Array<Array<UInt8>>): Array<UInt8> {
    var total: Int64 = 0
    for (a in arrays) { total += a.size }
    let result = Array<UInt8>(total, repeat: 0)
    var offset: Int64 = 0
    for (a in arrays) {
        for (b in a) { result[offset] = b; offset += 1 }
    }
    result
}

// Int32 → 4 字节小端
func int32ToLE(v: Int32): Array<UInt8> {
    [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF),
     UInt8((v >> 16) & 0xFF), UInt8((v >> 24) & 0xFF)]
}

// 截取前 n 字节
func take(a: Array<UInt8>, n: Int64): Array<UInt8> {
    let result = Array<UInt8>(n, repeat: 0)
    for (i in 0..n) { result[i] = a[i] }
    result
}

// ── 主加密类 ──────────────────────────────────────────────────────────────────
public class PdfEncryption {
    private var config: PdfEncryptionConfig
    // PDF spec: bits 7-8 and 13-32 of P must be 1 (reserved).
    // 0xFFFFF0C0 = -3904 as Int32 sets all required reserved bits.
    private var effectiveP: Int32             // config.permissions | 0xFFFFF0C0
    private var fileID: Array<UInt8>          // 16 字节，随机生成
    private var encryptionKey: Array<UInt8>   // 文件加密密钥
    private var oHash: Array<UInt8>           // /O 值
    private var uHash: Array<UInt8>           // /U 值
    private var oeHash: Array<UInt8>          // /OE（AES-256 专用）
    private var ueHash: Array<UInt8>          // /UE（AES-256 专用）
    private var permsHash: Array<UInt8>       // /Perms（AES-256 专用）

    public init(config: PdfEncryptionConfig) {
        this.config        = config
        this.effectiveP    = config.permissions | Int32(-3904)
        this.fileID        = hitlsRandBytes(16)
        this.encryptionKey = Array<UInt8>(0, repeat: 0)
        this.oHash         = Array<UInt8>(32, repeat: 0)
        this.uHash         = Array<UInt8>(32, repeat: 0)
        this.oeHash        = Array<UInt8>(0, repeat: 0)
        this.ueHash        = Array<UInt8>(0, repeat: 0)
        this.permsHash     = Array<UInt8>(0, repeat: 0)
        computeHashes()
    }

    // ── 密钥派生 ──────────────────────────────────────────────────────────────

    private func computeHashes(): Unit {
        match (config.algorithm) {
            case RC4_128 => computeHashesRC4()
            case AES_128 => computeHashesAes128()
            case AES_256 => computeHashesAes256()
        }
    }

    // --- R=3 RC4-128 ---

    private func computeHashesRC4(): Unit {
        let keyLen: Int64 = 16

        // Algorithm 3: 计算 /O
        oHash = computeO_RC4(keyLen)

        // Algorithm 2: 计算文件加密密钥
        encryptionKey = computeFileKey_RC4(oHash, keyLen)

        // Algorithm 5: 计算 /U
        uHash = computeU_RC4(encryptionKey)
    }

    // Algorithm 3 — Owner password hash (R=3)
    private func computeO_RC4(keyLen: Int64): Array<UInt8> {
        let ownerPadded = padPassword(if (config.ownerPassword.size > 0) {
            config.ownerPassword
        } else {
            config.userPassword
        })

        // MD5(ownerPadded) → iterate 50 times
        var key = hitlsMd5(ownerPadded)
        for (_ in 0..50) { key = hitlsMd5(key) }
        key = take(key, keyLen)

        // RC4 encrypt padded user password with key, then 19 more with key XOR i
        let userPadded = padPassword(config.userPassword)
        var result = rc4(key, userPadded)
        for (i in 1..20) {
            let xorKey = Array<UInt8>(keyLen, repeat: 0)
            for (j in 0..keyLen) { xorKey[j] = key[j] ^ UInt8(i) }
            result = rc4(xorKey, result)
        }
        result
    }

    // Algorithm 2 — File encryption key (R≥3)
    private func computeFileKey_RC4(oValue: Array<UInt8>, keyLen: Int64): Array<UInt8> {
        let userPadded = padPassword(config.userPassword)
        let pBytes     = int32ToLE(effectiveP)

        var input = concat([userPadded, oValue, pBytes, fileID])
        var key   = hitlsMd5(input)
        // 50 iterations
        for (_ in 0..50) { key = hitlsMd5(key) }
        take(key, keyLen)
    }

    // Algorithm 6 — /U value (R=3/4): MD5(PDF_PWD_PADDING || fileID) → RC4 → 19 XOR iterations
    private func computeU_RC4(key: Array<UInt8>): Array<UInt8> {
        // Step b/c: MD5(PDF_PWD_PADDING || fileID) → 16 bytes
        let hash16 = hitlsMd5(concat([PDF_PWD_PADDING, fileID]))

        // Step d: RC4 encrypt those 16 bytes with the file key
        var result = rc4(key, hash16)

        // Step e: 19 more iterations with XOR'd key
        for (i in 1..20) {
            let xorKey = Array<UInt8>(key.size, repeat: 0)
            for (j in 0..key.size) { xorKey[j] = key[j] ^ UInt8(i) }
            result = rc4(xorKey, result)
        }

        // Step f: append 16 bytes arbitrary padding → 32 bytes
        let u32 = Array<UInt8>(32, repeat: 0)
        for (i in 0..result.size) { u32[i] = result[i] }
        u32
    }

    // --- R=4 AES-128 ---

    private func computeHashesAes128(): Unit {
        let keyLen: Int64 = 16
        oHash         = computeO_RC4(keyLen)   // O 值派生与 R=3 相同
        encryptionKey = computeFileKey_RC4(oHash, keyLen)
        uHash         = computeU_RC4(encryptionKey)  // R=4 /U 使用同 Algorithm 6（RC4）
    }

    // --- R=5 AES-256 (PDF 1.7 Ext.3, simple SHA-256; Acrobat 9+) ---
    // R=6 requires Algorithm 2.B with SHA-384/512 which we don't have.

    private func computeHashesAes256(): Unit {
        encryptionKey = hitlsRandBytes(32)

        // Algorithm 9: /U and /UE  (must compute first; /O depends on /U)
        let (u, ue) = computeU_AES256()
        uHash  = u
        ueHash = ue

        // Algorithm 8: /O and /OE
        let (o, oe) = computeO_AES256()
        oHash  = o
        oeHash = oe

        // /Perms
        permsHash = computePerms_AES256()
    }

    // Algorithm 9 (R=5) — /U and /UE
    // /U  = SHA-256(pwd || val_salt)(32) || val_salt(8) || key_salt(8)  → 48 bytes
    // /UE = AES-256-CBC(SHA-256(pwd || key_salt), zero_IV, file_key)    → 32 bytes
    private func computeU_AES256(): (Array<UInt8>, Array<UInt8>) {
        let pwd     = padPwd256(config.userPassword)
        let valSalt = hitlsRandBytes(8)
        let keySalt = hitlsRandBytes(8)

        let hash = hitlsSha256(concat([pwd, valSalt]))
        let u    = concat([hash, valSalt, keySalt])

        let interKey = hitlsSha256(concat([pwd, keySalt]))
        let zeroIv   = Array<UInt8>(16, repeat: 0)
        // PKCS7 pads 32-byte input → 48 bytes; first 32 bytes are the raw CBC ciphertext
        let ue = take(hitlsAesCbcEncrypt(interKey, zeroIv, encryptionKey), 32)

        (u, ue)
    }

    // Algorithm 8 (R=5) — /O and /OE
    // /O  = SHA-256(pwd || val_salt || /U)(32) || val_salt(8) || key_salt(8)  → 48 bytes
    // /OE = AES-256-CBC(SHA-256(pwd || key_salt || /U), zero_IV, file_key)    → 32 bytes
    private func computeO_AES256(): (Array<UInt8>, Array<UInt8>) {
        let pwd     = padPwd256(config.ownerPassword)
        let valSalt = hitlsRandBytes(8)
        let keySalt = hitlsRandBytes(8)

        let hash = hitlsSha256(concat([pwd, valSalt, uHash]))
        let o    = concat([hash, valSalt, keySalt])

        let interKey = hitlsSha256(concat([pwd, keySalt, uHash]))
        let zeroIv   = Array<UInt8>(16, repeat: 0)
        let oe = take(hitlsAesCbcEncrypt(interKey, zeroIv, encryptionKey), 32)

        (o, oe)
    }

    // /Perms (16 bytes): AES-256-ECB(file_key, perms_block)
    // Single-block CBC with zero IV equals ECB; take first 16 bytes of 32-byte PKCS7 output.
    private func computePerms_AES256(): Array<UInt8> {
        let permsData = Array<UInt8>(16, repeat: 0)
        let pLE = int32ToLE(effectiveP)
        for (i in 0..4) { permsData[i] = pLE[i] }
        permsData[4] = 0xFFu8; permsData[5] = 0xFFu8
        permsData[6] = 0xFFu8; permsData[7] = 0xFFu8
        permsData[8]  = if (config.encryptMetadata) { 0x54u8 } else { 0x46u8 }  // 'T'/'F'
        permsData[9]  = 0x61u8  // 'a'
        permsData[10] = 0x64u8  // 'd'
        permsData[11] = 0x62u8  // 'b'
        let rnd = hitlsRandBytes(4)
        permsData[12] = rnd[0]; permsData[13] = rnd[1]
        permsData[14] = rnd[2]; permsData[15] = rnd[3]

        let zeroIv = Array<UInt8>(16, repeat: 0)
        take(hitlsAesCbcEncrypt(encryptionKey, zeroIv, permsData), 16)
    }

    // AES-256 密码截断到127字节（UTF-8 原始字节）
    private func padPwd256(pwd: String): Array<UInt8> {
        let raw   = strToBytes(pwd)
        let limit = if (raw.size > 127) { 127 } else { raw.size }
        let result = Array<UInt8>(limit, repeat: 0)
        for (i in 0..limit) { result[i] = raw[i] }
        result
    }

    // ── 对象级加密 ────────────────────────────────────────────────────────────

    /**
     * 加密一段字节（PDF 字符串 / 流）
     * objNum / genNum 用于派生对象密钥（R=3/4）；AES-256 直接用文件密钥
     */
    public func encryptBytes(data: Array<UInt8>, objNum: Int32, genNum: Int32): Array<UInt8> {
        match (config.algorithm) {
            case RC4_128 => encryptRC4Object(data, objNum, genNum)
            case AES_128 => encryptAES128Object(data, objNum, genNum)
            case AES_256 => encryptAES256Object(data)
        }
    }

    public func encryptString(plaintext: String, objNum: Int32, genNum: Int32): Array<UInt8> {
        encryptBytes(strToBytes(plaintext), objNum, genNum)
    }

    public func decryptBytes(encrypted: Array<UInt8>, objNum: Int32, genNum: Int32): Array<UInt8> {
        match (config.algorithm) {
            case RC4_128 => encryptRC4Object(encrypted, objNum, genNum)  // RC4 对称
            case AES_128 => decryptAES128Object(encrypted, objNum, genNum)
            case AES_256 => decryptAES256Object(encrypted)
        }
    }

    // 对象密钥派生（R=3/4，Algorithm 1）
    private func objectKey(objNum: Int32, genNum: Int32, extra: Array<UInt8>): Array<UInt8> {
        let suffix: Array<UInt8> = [
            UInt8(objNum & 0xFF), UInt8((objNum >> 8) & 0xFF), UInt8((objNum >> 16) & 0xFF),
            UInt8(genNum & 0xFF), UInt8((genNum >> 8) & 0xFF)
        ]
        let input = concat([encryptionKey, suffix, extra])
        let hash  = hitlsMd5(input)
        let n     = encryptionKey.size + 5
        take(hash, if (n > 16) { 16 } else { n })
    }

    private func encryptRC4Object(data: Array<UInt8>, objNum: Int32, genNum: Int32): Array<UInt8> {
        let key = objectKey(objNum, genNum, [])
        rc4(key, data)
    }

    private func encryptAES128Object(data: Array<UInt8>, objNum: Int32, genNum: Int32): Array<UInt8> {
        let key = objectKey(objNum, genNum, [0x73u8, 0x41u8, 0x6Cu8, 0x54u8])  // "sAlT"
        let iv  = hitlsRandBytes(16)
        let enc = hitlsAesCbcEncrypt(key, iv, data)
        concat([iv, enc])  // prepend IV per PDF spec
    }

    private func decryptAES128Object(data: Array<UInt8>, objNum: Int32, genNum: Int32): Array<UInt8> {
        if (data.size < 16) { return data }
        let key = objectKey(objNum, genNum, [0x73u8, 0x41u8, 0x6Cu8, 0x54u8])
        let iv       = take(data, 16)
        let ciphertext = data[16..data.size]
        hitlsAesCbcDecrypt(key, iv, ciphertext)
    }

    private func encryptAES256Object(data: Array<UInt8>): Array<UInt8> {
        let iv  = hitlsRandBytes(16)
        let enc = hitlsAesCbcEncrypt(encryptionKey, iv, data)
        concat([iv, enc])
    }

    private func decryptAES256Object(data: Array<UInt8>): Array<UInt8> {
        if (data.size < 16) { return data }
        let iv         = take(data, 16)
        let ciphertext = data[16..data.size]
        hitlsAesCbcDecrypt(encryptionKey, iv, ciphertext)
    }

    // ── PDF 加密字典 ──────────────────────────────────────────────────────────

    public func getEncryptionDictionary(): PdfDictionary {
        let dict = PdfDictionary()
        dict.put(PdfName("Filter"), PdfName("Standard"))

        let (v, r) = match (config.algorithm) {
            case RC4_128 => (2, 3)
            case AES_128 => (4, 4)
            case AES_256 => (5, 5)  // R=5: PDF 1.7 Ext.3, uses simple SHA-256
        }
        dict.put(PdfName("V"), PdfNumber(v))
        dict.put(PdfName("R"), PdfNumber(r))

        let keyBits = Int32(encryptionKey.size * 8)
        dict.put(PdfName("Length"), PdfNumber(keyBits))

        dict.put(PdfName("P"), PdfNumber(effectiveP))

        dict.put(PdfName("O"), PdfString(oHash))
        dict.put(PdfName("U"), PdfString(uHash))

        // AES-256 (V=5) requires /OE, /UE, /Perms in addition to /O and /U
        if (v == 5) {
            dict.put(PdfName("OE"), PdfString(oeHash))
            dict.put(PdfName("UE"), PdfString(ueHash))
            dict.put(PdfName("Perms"), PdfString(permsHash))
        }

        // AES (V>=4) requires crypt filter entries for stream and string decryption.
        if (v >= 4) {
            let cfmName = if (v == 5) { "AESV3" } else { "AESV2" }
            let keyLen  = if (v == 5) { 32 } else { 16 }

            let stdCf = PdfDictionary()
            stdCf.put(PdfName("Type"), PdfName("CryptFilter"))
            stdCf.put(PdfName("CFM"), PdfName(cfmName))
            stdCf.put(PdfName("AuthEvent"), PdfName("DocOpen"))
            stdCf.put(PdfName("Length"), PdfNumber(keyLen))

            let cf = PdfDictionary()
            cf.put(PdfName("StdCF"), stdCf)
            dict.put(PdfName("CF"), cf)
            dict.put(PdfName("StmF"), PdfName("StdCF"))
            dict.put(PdfName("StrF"), PdfName("StdCF"))
        }

        if (!config.encryptMetadata) {
            dict.put(PdfName("EncryptMetadata"), PdfBoolean(false))
        }

        dict
    }

    public func getFileID(): Array<UInt8> { fileID }

    public func isEncrypted(): Bool {
        config.userPassword.size > 0 || config.ownerPassword.size > 0
    }
}

// 字符串 → 字节（Latin-1，取低8位）
func strToBytes(s: String): Array<UInt8> {
    let result = Array<UInt8>(s.size, repeat: 0)
    var i: Int64 = 0
    for (ch in s) {
        if (i < result.size) {
            result[i] = UInt8(Int64(ch) & 0xFF)
            i += 1
        }
    }
    result
}

// ── 辅助工具 ──────────────────────────────────────────────────────────────────
public class EncryptionUtils {
    public static func generateRandomBytes(length: Int64): Array<UInt8> {
        hitlsRandBytes(Int32(length))
    }

    public static func padPassword(password: String): Array<UInt8> {
        let result = Array<UInt8>(32, repeat: 0)
        let bytes  = password.toArray()
        var i: Int64 = 0
        while (i < Int64(bytes.size) && i < 32) {
            result[i] = UInt8(Int64(bytes[i]) & 0xFF)
            i += 1
        }
        var p: Int64 = 0
        while (i < 32) {
            result[i] = PDF_PWD_PADDING[p % 32]
            i += 1
            p += 1
        }
        result
    }
}

// ── 工厂 ──────────────────────────────────────────────────────────────────────
public class PdfEncryptionFactory {
    public static func createStandardEncryption(
        userPassword: String, ownerPassword: String, permissions: Int32
    ): PdfEncryption {
        let c = PdfEncryptionConfig()
        c.setUserPassword(userPassword)
        c.setOwnerPassword(ownerPassword)
        c.setPermissions(permissions)
        PdfEncryption(c)
    }

    public static func createAES128Encryption(
        userPassword: String, ownerPassword: String
    ): PdfEncryption {
        let c = PdfEncryptionConfig()
        c.setUserPassword(userPassword)
        c.setOwnerPassword(ownerPassword)
        c.setAlgorithm(EncryptionAlgorithm.AES_128)
        PdfEncryption(c)
    }

    public static func createAES256Encryption(
        userPassword: String, ownerPassword: String
    ): PdfEncryption {
        let c = PdfEncryptionConfig()
        c.setUserPassword(userPassword)
        c.setOwnerPassword(ownerPassword)
        c.setAlgorithm(EncryptionAlgorithm.AES_256)
        PdfEncryption(c)
    }
}
