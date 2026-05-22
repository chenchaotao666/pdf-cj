/**
 * PDF-CJ 加密实战示例
 *
 * 演示三种真实场景：
 *   1. 生成打开密码保护的 PDF（AES-128）
 *   2. 生成双密码 + 权限限制的机密 PDF（AES-256）
 *   3. 生成只允许打印的 PDF（RC4-128）
 */
package pdf_cj_examples

import pdf_cj.api.Document
import pdf_cj.core.{PdfWriter, PdfContentByte}
import pdf_cj.security.{PdfEncryption, PdfEncryptionConfig, PdfPermissions, EncryptionAlgorithm}
import pdf_cj.text.{BaseFont, Font}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let helvetica     = BaseFont.createFont()
let helveticaBold = BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.WINANSI)

func bodyFont(): Font  { Font(helvetica, 12.0) }
func titleFont(): Font { Font(helveticaBold, 18.0) }
func noteFont(): Font  { Font(helvetica, 10.0) }

// ── 写入示例页内容 ─────────────────────────────────────────────────────────────

func writePageContent(writer: PdfWriter, title: String, lines: Array<String>): Unit {
    let cb = writer.getDirectContent()

    cb.beginText()
    cb.setFontAndSize("Helvetica-Bold", 18.0f32)
    cb.setTextMatrix(72.0f32, 750.0f32)
    cb.showText(title)
    cb.endText()

    var y = 700.0f32
    for (line in lines) {
        let cb2 = writer.getDirectContent()
        cb2.beginText()
        cb2.setFontAndSize("Helvetica", 12.0f32)
        cb2.setTextMatrix(72.0f32, y)
        cb2.showText(line)
        cb2.endText()
        y -= 20.0f32
    }
}

// ── 示例1：需要打开密码的 PDF（AES-128） ─────────────────────────────────────

func example1_passwordProtected(): Unit {
    println("\n--- 示例1：AES-128 打开密码保护 ---")
    let outPath = "output/example_secure_password.pdf"

    // 配置加密：用户密码 = 打开密码，所有者密码用于管理
    let cfg = PdfEncryptionConfig()
    cfg.setUserPassword("open1234")         // 读者需输入此密码才能打开
    cfg.setOwnerPassword("admin9999")       // 管理员密码（可修改权限）
    cfg.setAlgorithm(EncryptionAlgorithm.AES_128)
    cfg.setPermissions(
        PdfPermissions.ALLOW_PRINTING |      // 允许打印
        PdfPermissions.ALLOW_SCREEN_READERS  // 允许屏幕阅读器
    )
    let enc = PdfEncryption(cfg)

    let document = Document(PageSize.A4)
    let file     = File(Path(outPath), OpenMode.Write)
    let writer   = PdfWriter.getInstance(document, file)
    writer.setPdfVersion(PdfWriter.PDF_VERSION_1_6)

    // 在 open() 之前设置加密（写入 /Encrypt 到 trailer）
    writer.setEncryption(enc)

    document.open()
    writePageContent(writer, "Confidential Report",
        ["This document is password protected.",
         "User password : open1234",
         "Permissions   : print + screen reader only",
         "Algorithm     : AES-128 (R=4)"])
    document.close()

    println("  已生成: ${outPath}")
    println("  打开密码: open1234  |  所有者密码: admin9999")
    println("  权限: 仅允许打印和屏幕阅读")
}

// ── 示例2：双密码 + 最严格权限的机密 PDF（AES-256） ──────────────────────────

func example2_topSecret(): Unit {
    println("\n--- 示例2：AES-256 机密文档（禁止复制 / 修改） ---")
    let outPath = "output/example_secure_topsecret.pdf"

    let cfg = PdfEncryptionConfig()
    cfg.setUserPassword("view2024")         // 只能查看，不能复制/修改
    cfg.setOwnerPassword("ceo-only-2024")   // 所有者可做任何操作
    cfg.setAlgorithm(EncryptionAlgorithm.AES_256)
    cfg.setPermissions(
        PdfPermissions.ALLOW_PRINTING |
        PdfPermissions.ALLOW_SCREEN_READERS
        // 不含 ALLOW_COPY、ALLOW_MODIFY_CONTENTS，禁止复制和修改
    )
    let enc = PdfEncryption(cfg)

    let document = Document(PageSize.A4)
    let file     = File(Path(outPath), OpenMode.Write)
    let writer   = PdfWriter.getInstance(document, file)
    writer.setPdfVersion(PdfWriter.PDF_VERSION_1_7)
    writer.setEncryption(enc)

    document.open()
    writePageContent(writer, "TOP SECRET - Q4 Strategy",
        ["Classification : STRICTLY CONFIDENTIAL",
         "User password  : view2024",
         "Owner password : ceo-only-2024",
         "Permissions    : no copy, no edit, print only",
         "Algorithm      : AES-256 (R=6, PDF 2.0 compatible)",
         "",
         "This document may not be reproduced without",
         "written permission from the document owner."])
    document.close()

    println("  已生成: ${outPath}")
    println("  查看密码: view2024  |  管理密码: ceo-only-2024")
    println("  权限: 禁止复制和修改，仅允许打印")
}

// ── 示例3：无打开密码但限制打印质量（RC4-128） ───────────────────────────────

func example3_printOnly(): Unit {
    println("\n--- 示例3：RC4-128 仅允许低质量打印 ---")
    let outPath = "output/example_secure_printonly.pdf"

    let cfg = PdfEncryptionConfig()
    // 不设用户密码 → 任何人都能打开，但操作受权限限制
    cfg.setOwnerPassword("print-owner")
    cfg.setAlgorithm(EncryptionAlgorithm.RC4_128)
    cfg.setPermissions(
        PdfPermissions.ALLOW_DEGRADED_PRINTING  // 仅允许低质量打印
    )
    let enc = PdfEncryption(cfg)

    let document = Document(PageSize.A4)
    let file     = File(Path(outPath), OpenMode.Write)
    let writer   = PdfWriter.getInstance(document, file)
    writer.setPdfVersion(PdfWriter.PDF_VERSION_1_4)
    writer.setEncryption(enc)

    document.open()
    writePageContent(writer, "Watermarked Draft",
        ["This draft may only be printed in low quality.",
         "No copy / no high-res print / no edit.",
         "Owner password : print-owner",
         "Algorithm      : RC4-128 (R=3, PDF 1.4)"])
    document.close()

    println("  已生成: ${outPath}")
    println("  无打开密码，任何人可查看，但操作受限")
    println("  权限: 仅允许低质量打印（不含高清打印/复制/修改）")
}

// ── 示例4：加密往返正确性验证 ─────────────────────────────────────────────────

func example4_roundTrip(): Unit {
    println("\n--- 示例4：加密往返正确性验证 ---")

    let plain = "Hello, PDF Encryption!"
    let plainBytes = Array<UInt8>(plain.size, repeat: 0)
    var idx: Int64 = 0
    for (c in plain) { plainBytes[idx] = UInt8(Int64(c) & 0xFF); idx += 1 }

    for ((name, algo) in [("RC4-128", EncryptionAlgorithm.RC4_128),
                           ("AES-128", EncryptionAlgorithm.AES_128),
                           ("AES-256", EncryptionAlgorithm.AES_256)]) {
        let cfg = PdfEncryptionConfig()
        cfg.setUserPassword("testpass")
        cfg.setAlgorithm(algo)
        let enc = PdfEncryption(cfg)

        let ct = enc.encryptBytes(plainBytes, 1i32, 0i32)
        let pt = enc.decryptBytes(ct, 1i32, 0i32)

        // 验证解密后内容与原文一致
        var matched = pt.size == plainBytes.size
        if (matched) {
            for (i in 0..pt.size) {
                if (pt[i] != plainBytes[i]) { matched = false }
            }
        }
        println("  ${name}: ciphertext=${ct.size}B  往返=${if (matched) { "✓" } else { "✗" }}")
    }
}

main(): Int64 {
    println("=== PDF 加密实战示例 ===")

    try {
        example1_passwordProtected()
        example2_topSecret()
        example3_printOnly()
        example4_roundTrip()
        println("\n全部示例完成！")
        println("生成文件位于 output/ 目录，可用 Adobe Acrobat / Evince 验证密码保护效果")
    } catch (e: Exception) {
        println("错误: ${e.message}")
    }
    0
}
