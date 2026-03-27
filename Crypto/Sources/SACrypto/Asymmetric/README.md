# Asymmetric Encryption — RSA and Elliptic Curve Keys

**Asymmetric** (public-key) cryptography uses a mathematically linked key pair:
- **Public key** — share freely. Used to encrypt messages *to* the holder.
- **Private key** — kept secret. Used to decrypt messages.

No shared secret is needed in advance, which solves the key distribution problem.

---

## RSA (Rivest–Shamir–Adleman)

### How RSA Works

RSA security rests on the **integer factorisation problem**: multiplying two large primes `p` and `q` is easy, but factoring their product `n = p × q` back into primes is computationally infeasible for large enough `n`.

Key generation:
1. Choose two large primes `p` and `q`.
2. Compute `n = p × q` (the modulus, e.g. 2048 bits) and `φ(n) = (p−1)(q−1)`.
3. Choose public exponent `e` (usually 65537).
4. Compute private exponent `d` such that `e × d ≡ 1 (mod φ(n))`.
5. Public key = `(n, e)`. Private key = `(n, d)`.

Encryption: `c = mᵉ mod n`
Decryption: `m = cᵈ mod n`

### OAEP Padding

Raw RSA (textbook RSA) is deterministic and malleable — never use it directly. **OAEP (Optimal Asymmetric Encryption Padding)** adds random padding and a hash step, making output non-deterministic and IND-CCA2 secure.

```
plaintext → OAEP_pad(plaintext, SHA-256, random seed) → raw RSA → ciphertext
```

### RSA Size Limits

RSA can only encrypt data smaller than its key:
```
Max plaintext bytes = (keyBits / 8) − 2 × hashBytes − 2
2048-bit key, SHA-256 → 256 − 66 = 190 bytes max
```

**Pattern:** Use RSA to encrypt a random AES key, then AES for the actual data.

```swift
let aesKey    = SAAESEncryptor.generateKey()         // 32 bytes
let encAESKey = try SARSACipher.encrypt(aesKey, publicKeyData: recipientPublicKey)
let payload   = try SAAESEncryptor.encrypt(bigData, key: aesKey)
// Send: encAESKey + payload
```

### Key Sizes

| Size | Security bits | Notes |
|---|---|---|
| 1024 | ~80 | ⚠️ Broken — do not use |
| 2048 | ~112 | Minimum acceptable |
| 3072 | ~128 | Equivalent to AES-128 |
| 4096 | ~140 | High security, slower |

---

## Elliptic Curve Keys

EC keys are used for **signing** (`SAECDSASigner`) and **key agreement** (`SAECDHAgreement`). Direct EC encryption is not standard — use ECDH to establish a shared secret, then encrypt with AES.

Elliptic curves provide the same security level as RSA with much smaller keys:

| Curve | Security bits | Comparable RSA |
|---|---|---|
| P-256 | 128 | RSA-3072 |
| P-384 | 192 | RSA-7680 |
| P-521 | 260 | RSA-15360 |

---

## Usage

```swift
import SACrypto

// RSA key generation (slow — do once, store securely)
let rsaPair = try SARSACipher.generateKeyPair(keySize: .bits2048)

// Encrypt a small payload (e.g. an AES key) for the recipient
let aesKey     = SAAESEncryptor.generateKey()
let encAESKey  = try SARSACipher.encrypt(aesKey, publicKeyData: rsaPair.publicKeyData)

// Decrypt with private key
let decAESKey  = try SARSACipher.decrypt(encAESKey, privateKeyData: rsaPair.privateKeyData)

// EC key pair for signing
let ecPair = SAECKeyGenerator.generateSigningKeyPair(curve: .p256)

// EC key pair for key agreement
let ecdhPair = SAECKeyGenerator.generateKeyAgreementPair(curve: .p256)
```
