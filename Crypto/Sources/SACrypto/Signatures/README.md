# Digital Signatures

A **digital signature** is a cryptographic proof that:
1. A specific private key was used to sign the data — proving **identity**.
2. The data has not changed since it was signed — proving **integrity**.

Anyone with the matching public key can verify the signature, but only the holder of the private key can produce one.

---

## How Digital Signatures Work

```
Signing:
  data  →  hash(data)  →  sign(hash, privateKey)  →  signature

Verification:
  data  →  hash(data)
  signature + publicKey  →  verify(signature, hash, publicKey)  →  ✓ / ✗
```

The actual signature is computed over the *hash* of the data, not the data directly — this keeps signature size constant regardless of message size.

---

## Ed25519 (Recommended)

Ed25519 is a **Edwards-curve DSA** scheme built on Curve25519. It was designed by Daniel Bernstein and is specified in [RFC 8032](https://www.rfc-editor.org/rfc/rfc8032).

### Why Ed25519 is Preferred

| Property | Ed25519 | ECDSA-P256 |
|---|---|---|
| Key size | 32 bytes | 32 bytes |
| Signature size | 64 bytes | ~71 bytes (DER) |
| Deterministic? | ✅ Yes | ❌ No (needs good RNG) |
| Speed | Very fast | Fast |
| Side-channel resistance | High (constant-time) | Medium |
| Randomness dependency | None | Critical |

**ECDSA is dangerous if the random nonce `k` is ever reused or weak.** The Sony PlayStation 3 private key was extracted this way. Ed25519 eliminates this risk by deriving `k` deterministically from the message and private key.

### How Ed25519 Works

1. Private key: a random 32-byte scalar `s`.
2. Public key: `A = s × B` where `B` is the base point of Curve25519-Edwards.
3. Signing: `(R, S)` where `R = r×B`, `S = r + SHA512(R||A||message) × s`, and `r` is derived deterministically.
4. Verification: check `S×B == R + SHA512(R||A||message) × A`.

The curve equation is `−x² + y² = 1 − (121665/121666)x²y²`.

---

## ECDSA (P-256 / P-384 / P-521)

**Elliptic Curve Digital Signature Algorithm** over NIST curves.

### How ECDSA Works

1. Private key: random scalar `d`. Public key: `Q = d×G`.
2. Pick a random nonce `k` (or deterministic per RFC 6979).
3. Compute `r = (k×G).x mod n`, `s = k⁻¹(hash + r×d) mod n`.
4. Signature = `(r, s)`.
5. Verify: compute `u₁ = hash×s⁻¹`, `u₂ = r×s⁻¹`, check `(u₁G + u₂Q).x == r`.

### When to Use ECDSA Instead of Ed25519

- Your system is FIPS 140-2/3 certified (NIST curves are approved; Curve25519 is not yet)
- You need P-384 or P-521 for higher security levels
- Interoperability with TLS/X.509 certificates or JWT ES256/ES384

---

## Usage

```swift
import SACrypto

// Ed25519 (recommended for new code)
let pair      = SAEd25519Signer.generateKeyPair()
let message   = Data("sign this".utf8)
let signature = try SAEd25519Signer.sign(message, privateKeyData: pair.privateKeyData)
let valid     = try SAEd25519Signer.verify(signature, for: message, publicKeyData: pair.publicKeyData)

// Tampered message
let tampered  = Data("sign that".utf8)
try SAEd25519Signer.verify(signature, for: tampered, publicKeyData: pair.publicKeyData) // false

// ECDSA P-256
let ecPair  = SAECKeyGenerator.generateSigningKeyPair(curve: .p256)
let ecSig   = try SAECDSASigner.sign(message, privateKeyDER: ecPair.privateKeyDER, curve: .p256)
let ecValid = try SAECDSASigner.verify(ecSig, for: message, publicKeyDER: ecPair.publicKeyDER, curve: .p256)
```
