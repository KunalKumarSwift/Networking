# HMAC — Hash-Based Message Authentication Code

## The Problem: Hashes Alone Don't Prove Authorship

A plain hash tells you a message hasn't been corrupted, but nothing about *who* sent it. If an attacker intercepts a message and its hash, they can replace both with their own message and hash — and the receiver can't tell the difference.

HMAC solves this by mixing a **secret key** into the hash computation. Only someone who knows the key can produce a valid tag, and only they can verify one.

---

## How HMAC Works

HMAC is defined in [RFC 2104](https://www.rfc-editor.org/rfc/rfc2104) as:

```
HMAC(K, m) = H((K' ⊕ opad) || H((K' ⊕ ipad) || m))
```

Where:
- `H` = the underlying hash function (SHA-256, SHA-384, SHA-512)
- `K` = the secret key (padded/hashed to block size → K')
- `opad` = outer padding (`0x5c5c5c...`)
- `ipad` = inner padding (`0x363636...`)
- `||` = concatenation, `⊕` = XOR

In plain English:
1. Pad the key to the hash's block size.
2. XOR the padded key with `ipad`, concatenate the message, hash it → inner hash.
3. XOR the padded key with `opad`, concatenate the inner hash, hash it → the MAC.

The double-hashing ensures the outer and inner computations are independent, protecting against length-extension attacks.

---

## Constant-Time Verification

Comparing two MACs with `==` leaks information through timing — a byte-by-byte comparison exits early on the first mismatch, so an attacker can time how many bytes matched. CryptoKit's `isValidAuthenticationCode` always takes the same time regardless of how many bytes match, closing this side channel.

---

## HMAC vs. Encryption

| | HMAC | Encryption |
|---|---|---|
| **Goal** | Prove authenticity + integrity | Provide confidentiality |
| **Reversible?** | No (one-way) | Yes (decrypt) |
| **Provides secrecy?** | No | Yes |

If you need both confidentiality *and* authenticity, use **AES-GCM** or **ChaCha20-Poly1305** — they bundle authentication in automatically.

---

## When to Use HMAC

- Signing API requests (e.g. AWS Signature V4 uses HMAC-SHA256)
- Generating secure tokens (e.g. JWT `HS256` is HMAC-SHA256)
- Verifying webhook payloads
- Generating a key from a shared secret + context (step in some protocols)

---

## Usage

```swift
import SACrypto

let key  = SASecureRandom.bytes(count: 32)
let data = Data("important payload".utf8)

// Produce a MAC
let mac = SAHMAC.authenticate(data, key: key)

// Verify (constant-time)
let isValid = SAHMAC.verify(data, mac: mac, key: key)     // true

// Tampered message → invalid
let tampered = Data("tampered payload".utf8)
SAHMAC.verify(tampered, mac: mac, key: key)               // false

// Choose a stronger algorithm
let mac512 = SAHMAC.authenticate(data, key: key, using: .sha512)
```
