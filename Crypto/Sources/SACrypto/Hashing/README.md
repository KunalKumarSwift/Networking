# Hashing

A **cryptographic hash function** maps an arbitrary-length input to a fixed-length output (the *digest*). Small changes in the input produce completely different digests — this is the **avalanche effect**.

---

## Properties of a Good Hash Function

| Property | Meaning |
|---|---|
| **Deterministic** | Same input always produces the same digest |
| **Fast** | Hashing a gigabyte of data should take milliseconds |
| **Pre-image resistant** | Cannot reconstruct the input from the digest |
| **Collision resistant** | Cannot find two different inputs with the same digest |
| **Avalanche effect** | Changing one bit flips ~50% of output bits |

---

## The SHA-2 Family

SHA-2 (Secure Hash Algorithm 2) was designed by the NSA and standardised by NIST in 2001. The variants differ only in the number of internal rounds and the size of their state:

| Algorithm | Digest size | Internal state | Rounds | Use case |
|---|---|---|---|---|
| SHA-256 | 32 bytes (256 bits) | 256 bits | 64 | General purpose |
| SHA-384 | 48 bytes (384 bits) | 512 bits | 80 | TLS certificates |
| SHA-512 | 64 bytes (512 bits) | 512 bits | 80 | Maximum strength |

All three are considered secure for the foreseeable future. SHA-256 is the default for this library.

### How SHA-256 Works (Simplified)

1. **Padding** — the message is padded to a multiple of 512 bits, with the original message length encoded at the end.
2. **Parsing** — the padded message is split into 512-bit blocks.
3. **Compression function** — each block is processed through 64 rounds that mix the block with the current hash state using bitwise operations (AND, OR, XOR, ROTR) and addition modulo 2³².
4. **Output** — the final 256-bit state is the digest.

---

## MD5 and SHA-1 (Legacy — Insecure)

**MD5** (1992) and **SHA-1** (1995) are both broken:

- **MD5**: Collision attacks are fast enough to run on a laptop (Wang & Yu, 2004). Do not use for signatures or integrity checks.
- **SHA-1**: Google's [SHAttered](https://shattered.io/) attack (2017) produced the first practical SHA-1 collision. All major CAs stopped issuing SHA-1 certificates in 2016.

They are provided in `SAInsecureHasher` only for reading legacy data or interoperating with old APIs. Never use them to protect new data.

---

## Common Use Cases

| Use case | Right tool | Why |
|---|---|---|
| Data integrity (checksums) | `SAHasher` (SHA-256) | Fast, collision-resistant |
| Password storage | `SAKeyDerivation` (PBKDF2) | Hashing alone is too fast — use a KDF |
| File deduplication | `SAHasher` (SHA-256) | Content-addressable storage |
| HMAC | `SAHMAC` | Hash + secret key for authentication |
| Digital signatures | `SAEd25519Signer` / `SAECDSASigner` | Signs the hash of a message |

---

## Usage

```swift
import SACrypto

// Hash raw bytes
let digest = SAHasher.hash(data, using: .sha256)          // → Data (32 bytes)

// Hash a string (UTF-8 encoded)
let hex = SAHasher.hexString("hello world")               // → "b94d27b9..."

// Choose a stronger algorithm
let strong = SAHasher.hash(data, using: .sha512)          // → Data (64 bytes)

// Legacy MD5 (interop only)
let md5 = SAInsecureHasher.md5HexString("legacy input")   // ⚠️ insecure
```
