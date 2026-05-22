/**
 * PdfEncryption 单元测试
 *
 * 覆盖：
 *   - hitlsMd5 已知向量
 *   - hitlsSha256 已知向量
 *   - RC4 加解密对称性
 *   - AES-128 / AES-256 CBC 往返
 *   - padPassword 长度与填充字节
 *   - PdfPermissions 标志位
 *   - PdfEncryptionConfig 默认值与 setter
 *   - PdfEncryption 字典结构（V / R / O / U）
 *   - encryptBytes 三种算法往返
 */
package pdf_cj.test.security

import std.unittest.*
import std.unittest.testmacro.*
import pdf_cj.security.*
import pdf_cj.base.{PdfName, PdfDictionary}

// ── 工具函数 ──────────────────────────────────────────────────────────────────

func toHex(bytes: Array<UInt8>): String {
    let hex: Array<UInt8> = [0x30u8, 0x31u8, 0x32u8, 0x33u8, 0x34u8, 0x35u8, 0x36u8, 0x37u8,
                              0x38u8, 0x39u8, 0x61u8, 0x62u8, 0x63u8, 0x64u8, 0x65u8, 0x66u8]
    var s = ""
    for (b in bytes) {
        s = s + String([Rune(Int32(hex[Int64(b) >> 4]))]) +
                String([Rune(Int32(hex[Int64(b) & 0xF]))])
    }
    s
}

func strBytes(s: String): Array<UInt8> {
    let r = Array<UInt8>(s.size, repeat: 0)
    var i: Int64 = 0
    for (c in s) { r[i] = UInt8(Int64(c) & 0xFF); i += 1 }
    r
}

func bytesEqual(a: Array<UInt8>, b: Array<UInt8>): Bool {
    if (a.size != b.size) { return false }
    for (i in 0..a.size) { if (a[i] != b[i]) { return false } }
    true
}

// ── MD5 已知向量 ──────────────────────────────────────────────────────────────

@Test
public class Md5Tests {

    @TestCase
    func testEmptyString(): Unit {
        // MD5("") = d41d8cd98f00b204e9800998ecf8427e
        let r = hitlsMd5(Array<UInt8>(0, repeat: 0))
        @Expect(toHex(r), "d41d8cd98f00b204e9800998ecf8427e")
    }

    @TestCase
    func testAbc(): Unit {
        // MD5("abc") = 900150983cd24fb0d6963f7d28e17f72
        let r = hitlsMd5(strBytes("abc"))
        @Expect(toHex(r), "900150983cd24fb0d6963f7d28e17f72")
    }

    @TestCase
    func testOutputIs16Bytes(): Unit {
        @Expect(hitlsMd5(strBytes("hello")).size, 16)
    }

    @TestCase
    func testDeterministic(): Unit {
        let a = hitlsMd5(strBytes("pdf-cj"))
        let b = hitlsMd5(strBytes("pdf-cj"))
        @Expect(bytesEqual(a, b), true)
    }
}

// ── SHA-256 已知向量 ──────────────────────────────────────────────────────────

@Test
public class Sha256Tests {

    @TestCase
    func testEmptyString(): Unit {
        // SHA-256("") = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
        let r = hitlsSha256(Array<UInt8>(0, repeat: 0))
        @Expect(toHex(r), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }

    @TestCase
    func testOutputIs32Bytes(): Unit {
        @Expect(hitlsSha256(strBytes("test")).size, 32)
    }

    @TestCase
    func testDeterministic(): Unit {
        let a = hitlsSha256(strBytes("deterministic"))
        let b = hitlsSha256(strBytes("deterministic"))
        @Expect(bytesEqual(a, b), true)
    }

    @TestCase
    func testDiffersFromMd5(): Unit {
        let input = strBytes("hello")
        let md5   = hitlsMd5(input)
        let sha   = hitlsSha256(input)
        @Expect(md5.size != sha.size, true)
    }
}

// ── RC4 ───────────────────────────────────────────────────────────────────────

@Test
public class Rc4Tests {

    @TestCase
    func testRoundTrip(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setAlgorithm(EncryptionAlgorithm.RC4_128)
        cfg.setUserPassword("testkey")
        let enc   = PdfEncryption(cfg)
        let plain = strBytes("Hello RC4!")
        let ct    = enc.encryptBytes(plain, 1i32, 0i32)
        let pt    = enc.decryptBytes(ct, 1i32, 0i32)
        @Expect(bytesEqual(plain, pt), true)
    }

    @TestCase
    func testDifferentObjNumGivesDifferentCt(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setAlgorithm(EncryptionAlgorithm.RC4_128)
        cfg.setUserPassword("samekey")
        let enc   = PdfEncryption(cfg)
        let plain = strBytes("SameData")
        let ct1   = enc.encryptBytes(plain, 1i32, 0i32)
        let ct2   = enc.encryptBytes(plain, 2i32, 0i32)
        @Expect(bytesEqual(ct1, ct2), false)
    }

    @TestCase
    func testCiphertextDiffersFromPlain(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setAlgorithm(EncryptionAlgorithm.RC4_128)
        cfg.setUserPassword("key123")
        let enc   = PdfEncryption(cfg)
        let plain = strBytes("SecretData")
        let ct    = enc.encryptBytes(plain, 5i32, 0i32)
        @Expect(bytesEqual(plain, ct), false)
    }
}

// ── AES-128 CBC ───────────────────────────────────────────────────────────────

@Test
public class Aes128Tests {

    @TestCase
    func testRoundTrip(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setAlgorithm(EncryptionAlgorithm.AES_128)
        cfg.setUserPassword("aes128pass")
        let enc   = PdfEncryption(cfg)
        let plain = strBytes("AES-128 round trip test")
        let ct    = enc.encryptBytes(plain, 10i32, 0i32)
        let pt    = enc.decryptBytes(ct, 10i32, 0i32)
        @Expect(bytesEqual(plain, pt), true)
    }

    @TestCase
    func testCiphertextIncludesIv(): Unit {
        // 输出 = 16字节IV + PKCS7填充后密文，最小 32 字节
        var cfg = PdfEncryptionConfig()
        cfg.setAlgorithm(EncryptionAlgorithm.AES_128)
        cfg.setUserPassword("pass")
        let enc = PdfEncryption(cfg)
        let ct  = enc.encryptBytes(strBytes("data"), 1i32, 0i32)
        @Expect(ct.size >= 32, true)
    }

    @TestCase
    func testRandomIvEachTime(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setAlgorithm(EncryptionAlgorithm.AES_128)
        cfg.setUserPassword("pass")
        let enc  = PdfEncryption(cfg)
        let data = strBytes("same input")
        let ct1  = enc.encryptBytes(data, 1i32, 0i32)
        let ct2  = enc.encryptBytes(data, 1i32, 0i32)
        @Expect(bytesEqual(ct1, ct2), false)
    }

    @TestCase
    func testEmptyInputRoundTrip(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setAlgorithm(EncryptionAlgorithm.AES_128)
        cfg.setUserPassword("p")
        let enc = PdfEncryption(cfg)
        let ct  = enc.encryptBytes(Array<UInt8>(0, repeat: 0), 1i32, 0i32)
        let pt  = enc.decryptBytes(ct, 1i32, 0i32)
        @Expect(pt.size, 0)
    }
}

// ── AES-256 CBC ───────────────────────────────────────────────────────────────

@Test
public class Aes256Tests {

    @TestCase
    func testRoundTrip(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setAlgorithm(EncryptionAlgorithm.AES_256)
        cfg.setUserPassword("aes256longpassword!")
        let enc   = PdfEncryption(cfg)
        let plain = strBytes("AES-256 round trip OK")
        let ct    = enc.encryptBytes(plain, 3i32, 0i32)
        let pt    = enc.decryptBytes(ct, 3i32, 0i32)
        @Expect(bytesEqual(plain, pt), true)
    }

    @TestCase
    func testLargeBlock(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setAlgorithm(EncryptionAlgorithm.AES_256)
        cfg.setUserPassword("key")
        let enc   = PdfEncryption(cfg)
        let plain = Array<UInt8>(1024, repeat: 0xABu8)
        let ct    = enc.encryptBytes(plain, 7i32, 0i32)
        let pt    = enc.decryptBytes(ct, 7i32, 0i32)
        @Expect(bytesEqual(plain, pt), true)
    }
}

// ── padPassword ───────────────────────────────────────────────────────────────

@Test
public class PadPasswordTests {

    @TestCase
    func testAlwaysReturns32Bytes(): Unit {
        @Expect(EncryptionUtils.padPassword("").size, 32)
        @Expect(EncryptionUtils.padPassword("hello").size, 32)
        @Expect(EncryptionUtils.padPassword("aaaaaaaaaabbbbbbbbbbccccccccccdd").size, 32)
    }

    @TestCase
    func testShortPasswordFirstByteIsChar(): Unit {
        // 'A' = 0x41
        let pad = EncryptionUtils.padPassword("A")
        @Expect(pad[0], 0x41u8)
    }

    @TestCase
    func testRemainingBytesArePdfPadding(): Unit {
        let pad = EncryptionUtils.padPassword("A")
        // 第1字节起为 PDF 标准填充首字节 0x28
        @Expect(pad[1], 0x28u8)
    }
}

// ── PdfPermissions ────────────────────────────────────────────────────────────

@Test
public class PermissionTests {

    @TestCase
    func testFlagValues(): Unit {
        @Expect(PdfPermissions.ALLOW_PRINTING, 2052i32)
        @Expect(PdfPermissions.ALLOW_MODIFY_CONTENTS, 8i32)
        @Expect(PdfPermissions.ALLOW_COPY, 16i32)
        @Expect(PdfPermissions.ALLOW_FILL_IN, 256i32)
        @Expect(PdfPermissions.ALLOW_SCREEN_READERS, 512i32)
    }

    @TestCase
    func testFullPermissionsHasPrint(): Unit {
        let full = PdfPermissions.createFullPermissions()
        @Expect((full & PdfPermissions.ALLOW_PRINTING) != 0i32, true)
    }

    @TestCase
    func testFullPermissionsHasCopy(): Unit {
        let full = PdfPermissions.createFullPermissions()
        @Expect((full & PdfPermissions.ALLOW_COPY) != 0i32, true)
    }

    @TestCase
    func testReadOnlyLacksCopy(): Unit {
        let ro = PdfPermissions.createReadOnlyPermissions()
        @Expect((ro & PdfPermissions.ALLOW_COPY), 0i32)
    }

    @TestCase
    func testReadOnlyHasScreenReader(): Unit {
        let ro = PdfPermissions.createReadOnlyPermissions()
        @Expect((ro & PdfPermissions.ALLOW_SCREEN_READERS) != 0i32, true)
    }

    @TestCase
    func testCustomCombination(): Unit {
        let perms = PdfPermissions.ALLOW_PRINTING | PdfPermissions.ALLOW_SCREEN_READERS
        @Expect((perms & PdfPermissions.ALLOW_PRINTING) != 0i32, true)
        @Expect((perms & PdfPermissions.ALLOW_COPY), 0i32)
    }
}

// ── PdfEncryptionConfig ───────────────────────────────────────────────────────

@Test
public class EncryptionConfigTests {

    @TestCase
    func testDefaultPasswords(): Unit {
        let cfg = PdfEncryptionConfig()
        @Expect(cfg.userPassword, "")
        @Expect(cfg.ownerPassword, "")
    }

    @TestCase
    func testDefaultEncryptMetadata(): Unit {
        @Expect(PdfEncryptionConfig().encryptMetadata, true)
    }

    @TestCase
    func testSetUserPassword(): Unit {
        let cfg = PdfEncryptionConfig()
        cfg.setUserPassword("user123")
        @Expect(cfg.userPassword, "user123")
    }

    @TestCase
    func testSetOwnerPassword(): Unit {
        let cfg = PdfEncryptionConfig()
        cfg.setOwnerPassword("ownerABC")
        @Expect(cfg.ownerPassword, "ownerABC")
    }

    @TestCase
    func testSetPermissions(): Unit {
        let cfg = PdfEncryptionConfig()
        cfg.setPermissions(PdfPermissions.ALLOW_PRINTING)
        @Expect(cfg.permissions, PdfPermissions.ALLOW_PRINTING)
    }
}

// ── PdfEncryption 字典结构 ────────────────────────────────────────────────────

@Test
public class EncryptionDictTests {

    func dictNum(dict: PdfDictionary, key: String): Int64 {
        match (dict.getAsNumber(PdfName(key))) {
            case Some(n) => n.intVal()
            case None    => -1
        }
    }

    @TestCase
    func testRc4DictV2R3(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setAlgorithm(EncryptionAlgorithm.RC4_128)
        cfg.setUserPassword("u")
        let d = PdfEncryption(cfg).getEncryptionDictionary()
        @Expect(dictNum(d, "V"), 2)
        @Expect(dictNum(d, "R"), 3)
    }

    @TestCase
    func testAes128DictV4R4(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setAlgorithm(EncryptionAlgorithm.AES_128)
        cfg.setUserPassword("u")
        let d = PdfEncryption(cfg).getEncryptionDictionary()
        @Expect(dictNum(d, "V"), 4)
        @Expect(dictNum(d, "R"), 4)
    }

    @TestCase
    func testAes256DictV5R5(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setAlgorithm(EncryptionAlgorithm.AES_256)
        cfg.setUserPassword("u")
        let d = PdfEncryption(cfg).getEncryptionDictionary()
        @Expect(dictNum(d, "V"), 5)
        @Expect(dictNum(d, "R"), 5)
    }

    @TestCase
    func testDictHasOAndU(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setUserPassword("pass")
        let d = PdfEncryption(cfg).getEncryptionDictionary()
        @Expect(d.contains(PdfName("O")), true)
        @Expect(d.contains(PdfName("U")), true)
    }

    @TestCase
    func testFileIdIs16Bytes(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setUserPassword("x")
        @Expect(PdfEncryption(cfg).getFileID().size, 16)
    }

    @TestCase
    func testFileIdIsRandom(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setUserPassword("x")
        let id1 = PdfEncryption(cfg).getFileID()
        let id2 = PdfEncryption(cfg).getFileID()
        @Expect(bytesEqual(id1, id2), false)
    }

    @TestCase
    func testIsEncryptedUserPwd(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setUserPassword("pass")
        @Expect(PdfEncryption(cfg).isEncrypted(), true)
    }

    @TestCase
    func testIsEncryptedOwnerPwd(): Unit {
        var cfg = PdfEncryptionConfig()
        cfg.setOwnerPassword("owner")
        @Expect(PdfEncryption(cfg).isEncrypted(), true)
    }
}

// ── 随机数生成 ────────────────────────────────────────────────────────────────

@Test
public class RandTests {

    @TestCase
    func testCorrectLength(): Unit {
        @Expect(EncryptionUtils.generateRandomBytes(32).size, 32)
    }

    @TestCase
    func testTwoCallsDiffer(): Unit {
        let a = EncryptionUtils.generateRandomBytes(16)
        let b = EncryptionUtils.generateRandomBytes(16)
        @Expect(bytesEqual(a, b), false)
    }

    @TestCase
    func testNotAllZero(): Unit {
        let bytes = EncryptionUtils.generateRandomBytes(16)
        var allZero = true
        for (b in bytes) { if (b != 0u8) { allZero = false } }
        @Expect(allZero, false)
    }
}
