# Symmetric Encryption — AES-GCM and ChaCha20-Poly1305

**Symmetric** means both parties use the same key to encrypt and decrypt. This is fast — orders of magnitude faster than asymmetric (RSA/EC) cryptography. It's the workhorse of most encrypted communication.

---

## Authenticated Encryption (AEAD)

Both ciphers in this library use **Authenticated Encryption with Associated Data (AEAD)**. This means they provide:

| Property | Meaning |
|---|---|
| **Confidentiality** | Only the key holder can read the plaintext |
| **Integrity** | Any bit-flip in the ciphertext is detected |
| **Authenticity** | Decryption fails if the message wasn't produced with the same key |

The **authentication tag** (16 bytes) is computed over the ciphertext during encryption and verified before decryption. If the tag doesn't match, decryption throws — the tampered data is never returned.

---

## AES-256-GCM

**AES (Advanced Encryption Standard)** is a block cipher — it processes 128-bit chunks. **GCM (Galois/Counter Mode)** turns it into a stream cipher and adds authentication.

### How It Works

```
plaintext blocks P₁, P₂, ...
    ↓  XOR with
AES_K(nonce || counter++)     ← counter mode stream
    ↓
ciphertext C₁, C₂, ...

Authentication tag = GHASH(ciphertext, nonce, key)
```

1. A 96-bit nonce (unique per message) is combined with an incrementing counter.
2. Each counter block is encrypted with AES and XORed with a plaintext block.
3. GHASH (a polynomial hash over GF(2¹²⁸)) authenticates the ciphertext.

### Hardware Acceleration

Modern Apple silicon (A7+) has dedicated AES hardware instructions (`AES{ENC|DEC}`, `AESMC`). AES-GCM on iPhone is extremely fast — typically >3 GB/s.

---

## ChaCha20-Poly1305

A stream cipher designed by Daniel Bernstein. Specified in [RFC 7539](https://www.rfc-editor.org/rfc/rfc7539) and mandatory in TLS 1.3.

### How It Works

```
ChaCha20 state: 512-bit block mixing key + nonce + counter with 20 rounds of ARX
    ↓ XOR with plaintext
ciphertext

Poly1305 MAC: a one-time authenticator using the key stream's first 256 bits
```

**ARX** = Add, Rotate, XOR — simple operations that are fast without hardware AES instructions.

### When to Choose ChaCha20 Over AES

| Situation | Prefer |
|---|---|
| iOS / Apple hardware | Either (both have hardware acceleration) |
| Older/embedded devices without AES HW | ChaCha20-Poly1305 |
| TLS 1.3 compatibility requirement | ChaCha20-Poly1305 |
| Key size simplicity (always 256-bit) | ChaCha20-Poly1305 |

---

## The Nonce — The Most Important Rule

> **Never reuse a nonce with the same key.**

Both AES-GCM and ChaCha20-Poly1305 use a 96-bit nonce. If you encrypt two different messages with the same (key, nonce) pair:
- The keystreams cancel out, revealing `plaintext1 XOR plaintext2`
- The authentication key is revealed, breaking all future MACs

This library generates a fresh random nonce on every call to `encrypt`. Since 96 bits is 2⁹⁶ ≈ 7.9 × 10²⁸ possible values, random collision probability is negligible (you'd need to encrypt ~2⁴⁸ messages before it becomes a concern).

---

## Usage

```swift
import SACrypto

let key       = SAAESEncryptor.generateKey()              // 32 random bytes
let plaintext = Data("secret payload".utf8)

// Encrypt
let sealed = try SAAESEncryptor.encrypt(plaintext, key: key)

// Store or transmit sealed.combined (nonce + ciphertext + tag)

// Decrypt
let recovered = try SAAESEncryptor.decrypt(sealed, key: key)
// OR from combined bytes:
let recovered2 = try SAAESEncryptor.decrypt(combined: sealed.combined, key: key)

// ChaCha20-Poly1305 has identical API
let chachaKey    = SAChaChaEncryptor.generateKey()
let chaSealed    = try SAChaChaEncryptor.encrypt(plaintext, key: chachaKey)
let chaRecovered = try SAChaChaEncryptor.decrypt(chaSealed, key: chachaKey)
```
