# SACrypto

A reusable Swift 6 cryptography library for iOS. Built entirely on Apple's first-party frameworks — **CryptoKit**, **CommonCrypto**, and **Security** — with no third-party dependencies.

## Requirements

- iOS 15+
- Swift 6 / Xcode 16+

## Adding to a Project

```swift
// Package.swift
.package(url: "https://github.com/KunalKumarSwift/Crypto", from: "1.0.0")
```

Then add `"SACrypto"` to your target's dependencies.

---

## Modules

| Module | File | Description |
|---|---|---|
| [Hashing](Sources/SACrypto/Hashing/README.md) | `SAHasher`, `SAInsecureHasher` | SHA-256/384/512, MD5, SHA-1 |
| [Authentication](Sources/SACrypto/Authentication/README.md) | `SAHMAC` | HMAC-SHA256/384/512 + verification |
| [Key Derivation](Sources/SACrypto/KeyDerivation/README.md) | `SAKeyDerivation`, `SASaltGenerator` | PBKDF2, secure salt generation |
| [Symmetric Encryption](Sources/SACrypto/Symmetric/README.md) | `SAAESEncryptor`, `SAChaChaEncryptor` | AES-256-GCM, ChaCha20-Poly1305 |
| [Asymmetric Encryption](Sources/SACrypto/Asymmetric/README.md) | `SARSACipher`, `SAECKeyPair` | RSA-OAEP, EC key pair generation |
| [Digital Signatures](Sources/SACrypto/Signatures/README.md) | `SAEd25519Signer`, `SAECDSASigner` | Ed25519, ECDSA P-256/384/521 |
| [Key Agreement](Sources/SACrypto/KeyAgreement/README.md) | `SAX25519Agreement`, `SAECDHAgreement` | X25519, ECDH P-256/384/521 |
| [Keychain](Sources/SACrypto/Keychain/README.md) | `SAKeychain` | Secure storage of keys & secrets |
| [Secure Random](Sources/SACrypto/Random/README.md) | `SASecureRandom` | Cryptographically secure random bytes |
| [Encoding](Sources/SACrypto/Encoding/README.md) | `SACryptoEncoding` | Hex and Base64 URL encoding helpers |

---

## Quick Examples

```swift
import SACrypto

// Hash a string
let hash = SAHasher.hexString("hello world")           // SHA-256 hex

// HMAC
let mac = SAHMAC.authenticate(data, key: keyData)

// Symmetric encryption
let key = SAAESEncryptor.generateKey()
let sealed = try SAAESEncryptor.encrypt(plaintext, key: key)
let plain  = try SAAESEncryptor.decrypt(sealed, key: key)

// Password hashing
let salt    = SASaltGenerator.generate()
let derived = try SAKeyDerivation.deriveKey(fromPassword: "hunter2", salt: salt)

// Ed25519 signing
let pair = SAEd25519Signer.generateKeyPair()
let sig  = try SAEd25519Signer.sign(data, privateKeyData: pair.privateKeyData)
let ok   = try SAEd25519Signer.verify(sig, for: data, publicKeyData: pair.publicKeyData)

// Keychain
try SAKeychain.store(key, forKey: "mySymmetricKey")
let stored = try SAKeychain.retrieve(forKey: "mySymmetricKey")
```

---

## Design Principles

- **All public types are `Sendable`** — safe to pass across actor/task boundaries
- **Value types throughout** — `struct` over `class` wherever possible
- **Throws, never crashes** — errors surface as typed `enum` values
- **No external dependencies** — only Apple system frameworks
- **Swift 6 strict concurrency** enabled from day one
