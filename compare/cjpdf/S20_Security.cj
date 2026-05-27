package pdf_cj_examples

import pdf_cj.api.{Document, Paragraph, Phrase, Chunk}
import pdf_cj.core.PdfWriter
import pdf_cj.security.{PdfEncryptionFactory, PdfEncryptionConfig, PdfEncryption, PdfPermissions, EncryptionAlgorithm}
import pdf_cj.text.{BaseFont, Font, FontStyle, Color, Alignment}
import pdf_cj.util.{PageSize, Rectangle}
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
    doc.add(Paragraph("Note: Encryption requires appropriate crypto library.", Font(helvBf, 11.0)))
    doc.add(Paragraph("示意：加密功能需要加密库支持。", Font(cjkBf, 11.0)))
    doc.close()
}

func s20_security(): Unit {
    println("S20: Security & Encryption Demo")
    let helvBf = newHelvBf()
    try {
        // ---- 1. AES-128 encryption ----
        try {
            let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
            let file = File(Path(_s20_OUT + "cj_s20_encrypted_aes128.pdf"), OpenMode.Write)
            let writer = PdfWriter.getInstance(doc, file)

            // Set encryption BEFORE doc.open()
            let enc = PdfEncryptionFactory.createAES128Encryption("user123", "owner456")
            writer.setEncryption(enc)

            doc.open()
            s20AddContent(doc, "S20: AES-128 Encrypted PDF", "AES-128")
            doc.add(Paragraph("Permissions: ALLOW_PRINTING only", Font(helvBf, 11.0)))
            doc.add(Paragraph("Cannot copy, modify, or annotate.", Font(helvBf, 11.0)))
            doc.close()
            println("  AES-128 encrypted: ${_s20_OUT}cj_s20_encrypted_aes128.pdf")
        } catch (e: Exception) {
            println("  AES-128 encryption failed: ${e.message}")
            s20CreateFallback("cj_s20_encrypted_aes128.pdf",
                "S20: AES-128 Security Demo (fallback)", "AES-128 encryption failed: " + e.message)
        }

        // ---- 2. AES-256 encryption ----
        try {
            let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
            let file = File(Path(_s20_OUT + "cj_s20_encrypted_aes256.pdf"), OpenMode.Write)
            let writer = PdfWriter.getInstance(doc, file)

            let enc = PdfEncryptionFactory.createAES256Encryption("user123", "owner456")
            writer.setEncryption(enc)

            doc.open()
            s20AddContent(doc, "S20: AES-256 Encrypted PDF", "AES-256")
            doc.add(Paragraph("Permissions: ALLOW_PRINTING | ALLOW_COPY | ALLOW_MODIFY", Font(helvBf, 11.0)))
            doc.close()
            println("  AES-256 encrypted: ${_s20_OUT}cj_s20_encrypted_aes256.pdf")
        } catch (e: Exception) {
            println("  AES-256 encryption failed: ${e.message}")
            s20CreateFallback("cj_s20_encrypted_aes256.pdf",
                "S20: AES-256 Security Demo (fallback)", "AES-256 encryption failed: " + e.message)
        }

        // ---- 3. PdfEncryptionConfig approach ----
        try {
            let doc = Document(PageSize.A4, 72.0, 72.0, 72.0, 72.0)
            let file = File(Path(_s20_OUT + "cj_s20_encrypted_config.pdf"), OpenMode.Write)
            let writer = PdfWriter.getInstance(doc, file)

            let config = PdfEncryptionConfig()
            config.setUserPassword("user123")
            config.setOwnerPassword("owner456")
            config.setPermissions(PdfPermissions.ALLOW_PRINTING)
            config.setAlgorithm(EncryptionAlgorithm.AES_128)
            let enc = PdfEncryption(config)
            writer.setEncryption(enc)

            doc.open()
            s20AddContent(doc, "S20: PdfEncryptionConfig AES-128", "AES_128 via config")
            doc.add(Paragraph("Using PdfEncryptionConfig API.", Font(helvBf, 11.0)))
            doc.close()
            println("  Config-based encryption: ${_s20_OUT}cj_s20_encrypted_config.pdf")
        } catch (e: Exception) {
            println("  Config encryption failed: ${e.message}")
            s20CreateFallback("cj_s20_encrypted_config.pdf",
                "S20: Config Encryption Demo (fallback)", "Config encryption failed: " + e.message)
        }

        println("  S20 done")
    } catch (e: Exception) {
        println("  ✗ S20: ${e.message}")
    }
}
