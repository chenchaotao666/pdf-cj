/**
 * OpenHiTLS crypto FFI 绑定
 * 链接 libhitls_crypto.so / libhitls_bsl.so
 */
package pdf_cj.security

// ── 不透明指针类型 ─────────────────────────────────────────────────────────────
public type CryptEalCipherCtx = CPointer<Unit>
public type CryptEalMdCtx     = CPointer<Unit>

// ── 算法 ID 常量（来自 bsl_obj.h） ────────────────────────────────────────────
public let CRYPT_MD_MD5:    Int32 = 40
public let CRYPT_MD_SHA256: Int32 = 43

public let CRYPT_CIPHER_AES128_CBC: Int32 = 19
public let CRYPT_CIPHER_AES256_CBC: Int32 = 27

// CRYPT_PaddingType: NONE=0 ZEROS=1 ISO7816=2 X923=3 PKCS5=4 PKCS7=5
public let CRYPT_PADDING_PKCS7: Int32 = 5

public let CRYPT_SUCCESS: Int32 = 0

// ── 摘要函数 ──────────────────────────────────────────────────────────────────
@C
foreign func CRYPT_EAL_Md(id: Int32, inData: CPointer<UInt8>, inLen: UInt32,
                           out: CPointer<UInt8>, outLen: CPointer<UInt32>): Int32

// ── 对称加密函数 ───────────────────────────────────────────────────────────────
@C
foreign func CRYPT_EAL_CipherNewCtx(id: Int32): CryptEalCipherCtx

@C
foreign func CRYPT_EAL_CipherFreeCtx(ctx: CryptEalCipherCtx): Unit

@C
foreign func CRYPT_EAL_CipherInit(ctx: CryptEalCipherCtx,
                                   key: CPointer<UInt8>, keyLen: UInt32,
                                   iv: CPointer<UInt8>, ivLen: UInt32,
                                   enc: Bool): Int32

@C
foreign func CRYPT_EAL_CipherSetPadding(ctx: CryptEalCipherCtx, padType: Int32): Int32

@C
foreign func CRYPT_EAL_CipherUpdate(ctx: CryptEalCipherCtx,
                                     inData: CPointer<UInt8>, inLen: UInt32,
                                     out: CPointer<UInt8>, outLen: CPointer<UInt32>): Int32

@C
foreign func CRYPT_EAL_CipherFinal(ctx: CryptEalCipherCtx,
                                    out: CPointer<UInt8>, outLen: CPointer<UInt32>): Int32

// ── LibC ──────────────────────────────────────────────────────────────────────
@C
foreign func malloc(size: UInt64): CPointer<Unit>

@C
foreign func free(ptr: CPointer<Unit>): Unit

// /dev/urandom 用于随机数（无需初始化 DRBG）
@C
foreign func open(pathname: CPointer<UInt8>, flags: Int32): Int32

@C
foreign func read(fd: Int32, buf: CPointer<Unit>, count: UInt64): Int64

@C
foreign func close(fd: Int32): Int32

// ── 内部缓冲区辅助 ────────────────────────────────────────────────────────────

func allocBuf(data: Array<UInt8>): CPointer<UInt8> {
    unsafe {
        let ptr = CPointer<UInt8>(malloc(UInt64(data.size + 1)))
        for (i in 0..data.size) { (ptr + i).write(data[i]) }
        (ptr + data.size).write(0u8)
        ptr
    }
}

func freeBuf(ptr: CPointer<UInt8>): Unit {
    unsafe { free(CPointer<Unit>(ptr)) }
}

func allocZero(n: Int64): CPointer<UInt8> {
    unsafe {
        let ptr = CPointer<UInt8>(malloc(UInt64(n + 1)))
        for (i in 0..(n + 1)) { (ptr + i).write(0u8) }
        ptr
    }
}

// ── 公开的 Cangjie 友好 API ───────────────────────────────────────────────────

/**
 * MD5 摘要，返回 16 字节
 */
public func hitlsMd5(data: Array<UInt8>): Array<UInt8> {
    let out = Array<UInt8>(16, repeat: 0)
    unsafe {
        let inPtr  = allocBuf(data)
        let outPtr = allocZero(16)
        let lenPtr = CPointer<UInt32>(malloc(4u64))
        lenPtr.write(16u32)
        CRYPT_EAL_Md(CRYPT_MD_MD5, inPtr, UInt32(data.size), outPtr, lenPtr)
        for (i in 0..16) { out[i] = (outPtr + i).read() }
        freeBuf(inPtr)
        free(CPointer<Unit>(outPtr))
        free(CPointer<Unit>(lenPtr))
    }
    out
}

/**
 * SHA-256 摘要，返回 32 字节
 */
public func hitlsSha256(data: Array<UInt8>): Array<UInt8> {
    let out = Array<UInt8>(32, repeat: 0)
    unsafe {
        let inPtr  = allocBuf(data)
        let outPtr = allocZero(32)
        let lenPtr = CPointer<UInt32>(malloc(4u64))
        lenPtr.write(32u32)
        CRYPT_EAL_Md(CRYPT_MD_SHA256, inPtr, UInt32(data.size), outPtr, lenPtr)
        for (i in 0..32) { out[i] = (outPtr + i).read() }
        freeBuf(inPtr)
        free(CPointer<Unit>(outPtr))
        free(CPointer<Unit>(lenPtr))
    }
    out
}

/**
 * AES-CBC 加密（PKCS7 padding）
 */
public func hitlsAesCbcEncrypt(key: Array<UInt8>, iv: Array<UInt8>, data: Array<UInt8>): Array<UInt8> {
    let algId  = if (key.size == 32) { CRYPT_CIPHER_AES256_CBC } else { CRYPT_CIPHER_AES128_CBC }
    let maxOut = data.size + 32
    let outArr = Array<UInt8>(maxOut, repeat: 0)
    unsafe {
        let ctx    = CRYPT_EAL_CipherNewCtx(algId)
        let keyPtr = allocBuf(key)
        let ivPtr  = allocBuf(iv)
        let inPtr  = allocBuf(data)
        let outPtr = allocZero(maxOut)
        let lenPtr = CPointer<UInt32>(malloc(4u64))

        CRYPT_EAL_CipherInit(ctx, keyPtr, UInt32(key.size), ivPtr, 16u32, true)
        CRYPT_EAL_CipherSetPadding(ctx, CRYPT_PADDING_PKCS7)

        lenPtr.write(UInt32(maxOut))
        CRYPT_EAL_CipherUpdate(ctx, inPtr, UInt32(data.size), outPtr, lenPtr)
        var written = Int64(lenPtr.read())

        lenPtr.write(32u32)
        CRYPT_EAL_CipherFinal(ctx, outPtr + written, lenPtr)
        written += Int64(lenPtr.read())

        for (i in 0..written) { outArr[i] = (outPtr + i).read() }

        CRYPT_EAL_CipherFreeCtx(ctx)
        freeBuf(keyPtr); freeBuf(ivPtr); freeBuf(inPtr)
        free(CPointer<Unit>(outPtr)); free(CPointer<Unit>(lenPtr))

        return outArr[0..written]
    }
}

/**
 * AES-CBC 解密（PKCS7 padding 自动去除）
 */
public func hitlsAesCbcDecrypt(key: Array<UInt8>, iv: Array<UInt8>, data: Array<UInt8>): Array<UInt8> {
    let algId  = if (key.size == 32) { CRYPT_CIPHER_AES256_CBC } else { CRYPT_CIPHER_AES128_CBC }
    let outArr = Array<UInt8>(data.size, repeat: 0)
    unsafe {
        let ctx    = CRYPT_EAL_CipherNewCtx(algId)
        let keyPtr = allocBuf(key)
        let ivPtr  = allocBuf(iv)
        let inPtr  = allocBuf(data)
        let outPtr = allocZero(data.size)
        let lenPtr = CPointer<UInt32>(malloc(4u64))

        CRYPT_EAL_CipherInit(ctx, keyPtr, UInt32(key.size), ivPtr, 16u32, false)
        CRYPT_EAL_CipherSetPadding(ctx, CRYPT_PADDING_PKCS7)

        lenPtr.write(UInt32(data.size))
        CRYPT_EAL_CipherUpdate(ctx, inPtr, UInt32(data.size), outPtr, lenPtr)
        var written = Int64(lenPtr.read())

        lenPtr.write(32u32)
        CRYPT_EAL_CipherFinal(ctx, outPtr + written, lenPtr)
        written += Int64(lenPtr.read())

        for (i in 0..written) { outArr[i] = (outPtr + i).read() }

        CRYPT_EAL_CipherFreeCtx(ctx)
        freeBuf(keyPtr); freeBuf(ivPtr); freeBuf(inPtr)
        free(CPointer<Unit>(outPtr)); free(CPointer<Unit>(lenPtr))

        return outArr[0..written]
    }
}

/**
 * 从 /dev/urandom 生成随机字节
 */
public func hitlsRandBytes(n: Int32): Array<UInt8> {
    let out = Array<UInt8>(Int64(n), repeat: 0)
    unsafe {
        // "/dev/urandom" as UInt8 array + null terminator
        let path: Array<UInt8> = [
            0x2Fu8, 0x64u8, 0x65u8, 0x76u8, 0x2Fu8,  // /dev/
            0x75u8, 0x72u8, 0x61u8, 0x6Eu8, 0x64u8,   // urand
            0x6Fu8, 0x6Du8                              // om
        ]
        let pathPtr = allocBuf(path)
        let fd = open(pathPtr, 0)   // O_RDONLY = 0
        freeBuf(pathPtr)
        if (fd < 0) { return out }
        let buf = allocZero(Int64(n))
        read(fd, CPointer<Unit>(buf), UInt64(n))
        for (i in 0..Int64(n)) { out[i] = (buf + i).read() }
        free(CPointer<Unit>(buf))
        close(fd)
    }
    out
}
