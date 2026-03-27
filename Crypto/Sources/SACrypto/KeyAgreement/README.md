# Key Agreement — ECDH and X25519

**Key agreement** lets two parties derive the same shared secret over an insecure channel — without transmitting any secret. This is the foundation of **forward secrecy** in TLS and messaging protocols like Signal.

---

## The Diffie-Hellman Problem

Imagine Alice and Bob want to communicate secretly, but Eve can read everything they send. DH lets them agree on a shared secret:

```
Alice generates:  private a, public A = a × G
Bob generates:    private b, public B = b × G

Alice sends A to Bob  (Eve sees A)
Bob sends B to Alice  (Eve sees B)

Alice computes:  S = a × B = a × (b × G)
Bob computes:    S = b × A = b × (a × G)

Both get the same S.
Eve sees A and B but cannot compute a×b×G (discrete log problem).
```

`G` is a public base point on the elliptic curve. The discrete logarithm problem — finding `a` given `G` and `A = a×G` — is computationally infeasible on properly chosen curves.

---

## X25519 (Recommended)

X25519 is DH over **Curve25519**, a Montgomery curve designed by Daniel Bernstein. It was designed with implementation safety in mind:

- Every 32-byte string is a valid public key (no invalid-point attacks)
- Scalar multiplication is defined so accidental blunders don't create vulnerabilities
- Extremely fast (~200 µs on A-series iPhone)
- Mandatory in TLS 1.3

### How X25519 Scalar Multiplication Works

The curve equation is `y² = x³ + 486662x² + x` over GF(2²⁵⁵ − 19).

X25519 computes the x-coordinate of `s × P` using the **Montgomery ladder**, which runs in constant time (no secret-dependent branches), resisting timing attacks.

---

## ECDH over NIST Curves (P-256 / P-384 / P-521)

Same DH idea, different curves. The NIST curves use Weierstrass form (`y² = x³ + ax + b`). They are FIPS-approved and broadly supported in enterprise environments.

NIST curves have more implementation pitfalls than Curve25519 (e.g. point-at-infinity handling), but CryptoKit handles all of these correctly.

---

## HKDF — Turning a Shared Secret into a Key

The raw DH output is not uniformly distributed — it has structure that makes it unsuitable to use directly as a cipher key. **HKDF (HMAC-based Key Derivation Function, [RFC 5869](https://www.rfc-editor.org/rfc/rfc5869))** fixes this:

```
HKDF-Extract(salt, sharedSecret)  →  pseudorandom key (PRK)
HKDF-Expand(PRK, info, length)    →  final key material
```

Both `SAX25519Agreement` and `SAECDHAgreement` apply HKDF internally — you get a ready-to-use symmetric key out.

---

## Forward Secrecy

**Perfect Forward Secrecy (PFS)** means that compromising today's long-term private key doesn't expose past sessions. To achieve PFS:
- Generate a **fresh ephemeral key pair** for every session.
- Delete the private key after the session ends.
- An attacker who steals the long-term key cannot derive past session keys.

TLS 1.3 mandates ephemeral key agreement — static RSA key exchange (which has no PFS) was removed.

---

## Usage

```swift
import SACrypto

// X25519 — Alice's side
let aliceKP = SAX25519Agreement.generateKeyPair()

// X25519 — Bob's side
let bobKP   = SAX25519Agreement.generateKeyPair()

// Exchange public keys (over any channel, even insecure)
// Alice derives shared key using Bob's public key
let aliceShared = try SAX25519Agreement.sharedSymmetricKey(
    myPrivateKeyData: aliceKP.privateKeyData,
    peerPublicKeyData: bobKP.publicKeyData
)

// Bob derives shared key using Alice's public key
let bobShared = try SAX25519Agreement.sharedSymmetricKey(
    myPrivateKeyData: bobKP.privateKeyData,
    peerPublicKeyData: aliceKP.publicKeyData
)

assert(aliceShared == bobShared)   // ✅ same 32-byte key

// Use to encrypt
let sealed = try SAAESEncryptor.encrypt(payload, key: aliceShared)
```
