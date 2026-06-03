package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph}
import pdf_cj.core.PdfWriter
import pdf_cj.security.{PdfEncryptionFactory, PdfEncryptionConfig, PdfEncryption, PdfPermissions, EncryptionAlgorithm}
import pdf_cj.text.{Font, FontStyle, Alignment}
import pdf_cj.util.PageSize
import std.fs.{File, OpenMode, Path}

let _s20_FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
let _s20_OUT  = "output/"



func s20AddContent(doc: Document, title: String, encType: String): Unit {
    let helvBf = newHelvBf()
    let cjkBf = newCjkBf()
    var titlePara = Paragraph(title, Font(helvBf, 18.0, FontStyle.Bold))
    titlePara.setAlignment(Alignment.Center)
    titlePara.setSpacingAfter(20.0)
    doc.add(titlePara)

    doc.add(Paragraph("Encryption type: ${encType}", Font(helvBf, 12.0)))
    doc.add(Paragraph("This PDF is encrypted. Open with appropriate password.", Font(helvBf, 11.0)))
    doc.add(Paragraph("User password: 'user123'", Font(helvBf, 11.0)))
    doc.add(Paragraph("Owner password: 'owner456'", Font(helvBf, 11.0)))
    doc.add(Paragraph("Permissions reflect the allowed operations.", Font(helvBf, 11.0)))
    doc.add(Paragraph("CJK: 这是加密的PDF文档，需要密码才能访问。", Font(cjkBf, 12.0)))
}

func s20CreateFallback(filename: String, title: String, note: String): Unit {
    let helvBf = newHelvBf()
    let cjkBf = newCjkBf()
    let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
    let file = File(Path(_s20_OUT + filename), OpenMode.Write)
    PdfWriter.getInstance(doc, file)
    doc.open()
    doc.add(Paragraph(title, Font(helvBf, 18.0, FontStyle.Bold)))
    doc.add(Paragraph(note, Font(helvBf, 11.0)))
    doc.add(Paragraph("Note: Encryption requires HiTLS crypto library.", Font(helvBf, 11.0)))
    doc.add(Paragraph("Ensure libhitls_crypto.so is available at runtime.", Font(helvBf, 11.0)))
    doc.add(Paragraph("示意：加密功能需要HiTLS加密库支持。", Font(cjkBf, 11.0)))
    doc.close()
}

func s20_security(): Unit {
    println("S20: Security & Encryption Demo")
    let helvBf = newHelvBf()
    try {
        // ---- 1. AES-128, print-only permissions ----
        try {
            let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
            let file = File(Path(_s20_OUT + "cj_s20_encrypted_aes128.pdf"), OpenMode.Write)
            let writer = PdfWriter.getInstance(doc, file)

            let aes128Config = PdfEncryptionConfig()
            aes128Config.setUserPassword("user123")
            aes128Config.setOwnerPassword("owner456")
            aes128Config.setPermissions(PdfPermissions.ALLOW_PRINTING)
            aes128Config.setAlgorithm(EncryptionAlgorithm.AES_128)
            let enc = PdfEncryption(aes128Config)
            writer.setEncryption(enc)

            doc.open()
            s20AddContent(doc, "S20: AES-128 Encrypted PDF (Print Only)", "ENCRYPTION_AES_128")
            doc.add(Paragraph("Permissions: ALLOW_PRINTING only", Font(helvBf, 11.0)))
            doc.add(Paragraph("Cannot copy, modify, or annotate.", Font(helvBf, 11.0)))
            doc.close()
            println("  AES-128 encrypted: ${_s20_OUT}cj_s20_encrypted_aes128.pdf")
        } catch (e: Exception) {
            println("  AES-128 encryption failed (HiTLS missing?): ${e.message}")
            s20CreateFallback("cj_s20_encrypted_aes128.pdf",
                "S20: AES-128 Security Demo (no-encrypt fallback)", "ENCRYPTION_AES_128 requires HiTLS.")
        }

        // ---- 2. AES-256, all permissions ----
        try {
            let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
            let file = File(Path(_s20_OUT + "cj_s20_encrypted_aes256.pdf"), OpenMode.Write)
            let writer = PdfWriter.getInstance(doc, file)

            let config = PdfEncryptionConfig()
            config.setUserPassword("user123")
            config.setOwnerPassword("owner456")
            config.setPermissions(
                PdfPermissions.ALLOW_PRINTING | PdfPermissions.ALLOW_COPY |
                PdfPermissions.ALLOW_MODIFY_CONTENTS | PdfPermissions.ALLOW_MODIFY_ANNOTATIONS)
            config.setAlgorithm(EncryptionAlgorithm.AES_256)
            let enc = PdfEncryption(config)
            writer.setEncryption(enc)

            doc.open()
            s20AddContent(doc, "S20: AES-256 Encrypted PDF (All Permissions)", "ENCRYPTION_AES_256")
            doc.add(Paragraph("Permissions: ALLOW_PRINTING | ALLOW_COPY | ALLOW_MODIFY_CONTENTS | ALLOW_MODIFY_ANNOTATIONS", Font(helvBf, 11.0)))
            doc.close()
            println("  AES-256 encrypted: ${_s20_OUT}cj_s20_encrypted_aes256.pdf")
        } catch (e: Exception) {
            println("  AES-256 encryption failed: ${e.message}")
            s20CreateFallback("cj_s20_encrypted_aes256.pdf",
                "S20: AES-256 Security Demo (no-encrypt fallback)", "ENCRYPTION_AES_256 requires HiTLS.")
        }

        // ---- 3. Standard-128, printing + copy permissions ----
        try {
            let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
            let file = File(Path(_s20_OUT + "cj_s20_encrypted_std128.pdf"), OpenMode.Write)
            let writer = PdfWriter.getInstance(doc, file)

            let enc = PdfEncryptionFactory.createStandardEncryption("user123", "owner456",
                PdfPermissions.ALLOW_PRINTING | PdfPermissions.ALLOW_COPY)
            writer.setEncryption(enc)

            doc.open()
            s20AddContent(doc, "S20: Standard-128 Encrypted PDF", "STANDARD_ENCRYPTION_128")
            doc.add(Paragraph("Permissions: ALLOW_PRINTING | ALLOW_COPY", Font(helvBf, 11.0)))
            doc.close()
            println("  Standard-128 encrypted: ${_s20_OUT}cj_s20_encrypted_std128.pdf")
        } catch (e: Exception) {
            println("  Standard-128 encryption failed: ${e.message}")
            s20CreateFallback("cj_s20_encrypted_std128.pdf",
                "S20: Standard-128 Security Demo (no-encrypt fallback)", "STANDARD_ENCRYPTION_128 requires HiTLS.")
        }

        println("  S20 done")
    } catch (e: Exception) {
        println("  ✗ S20: ${e.message}")
    }
}
