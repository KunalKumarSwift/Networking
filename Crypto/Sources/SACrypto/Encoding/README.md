# Encoding

Helpers for converting raw `Data` to and from human-readable or transport-safe string formats.

---

## Why Encoding Matters in Cryptography

Cryptographic outputs — hashes, ciphertext, keys — are raw bytes. To store them in databases, transmit them in JSON, or display them to a user you need a text encoding. The two most common are:

| Format | Characters | Overhead | Typical use |
|---|---|---|---|
| **Hex** | `0–9`, `a–f` | 2× size | Debug output, checksums |
| **Base64** | `A–Z`, `a–z`, `0–9`, `+/=` | ~1.33× size | HTTP headers, JSON |
| **Base64-URL** | same but `-_` replaces `+/`, no `=` | ~1.33× size | JWTs, URL query params |

---

## Hex Encoding

### How it works

Each byte (0–255) is written as exactly two hexadecimal digits. The digit pair `ff` represents the byte value 255, `00` represents 0.

```
Byte:  0x4A  →  "4a"
Byte:  0xFF  →  "ff"
```

### When to use it

- Displaying digests/hashes to users ("sha256: `e3b0c4...`")
- Storing checksums in databases
- Debugging — hex is easy to read byte-by-byte

### Usage

```swift
import SACrypto

let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
print(data.hexString)               // "deadbeef"

let restored = Data(hexString: "deadbeef")
```

---

## Base64-URL Encoding

### How it works

Standard Base64 encodes 3 bytes as 4 ASCII characters, producing output 33% larger than the input. **Base64-URL** is identical except:
- `+` → `-`
- `/` → `_`
- Trailing `=` padding is removed

This makes the output safe to embed in URLs and JSON without percent-encoding.

### When to use it

- Encoding keys or nonces in JWT / JWK
- Passing binary data in URL query parameters
- Storing encrypted payloads in JSON APIs

### Usage

```swift
import SACrypto

let key = SAAESEncryptor.generateKey()
let encoded = key.base64URLEncoded     // safe for URLs

let decoded = Data(base64URLEncoded: encoded)
```
