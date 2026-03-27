# Key Derivation — PBKDF2 and Salting

## The Problem: Why Not Just Hash Passwords?

Passwords are short and predictable. An attacker who gets your database and sees `SHA256("password123")` can look it up in a pre-computed rainbow table in milliseconds.

A **Key Derivation Function (KDF)** is designed to be *deliberately slow* — making brute-force search computationally expensive — and takes a **salt** to make rainbow tables useless.

---

## What Is a Salt?

A salt is a random value mixed into the derivation. It doesn't need to be secret, but it must be:

- **Unique per password** — even two users with the same password get a different derived key
- **Long enough** — 16+ bytes; 32 bytes recommended
- **Stored alongside the derived key** — you need it to verify a password later

```
Without salt:                 With salt:
SHA256("password") = X       PBKDF2("password", salt=A) = X
SHA256("password") = X       PBKDF2("password", salt=B) = Y
 ↑ rainbow table hit          ↑ unique per user, no precomputation possible
```

---

## How PBKDF2 Works

PBKDF2 (Password-Based Key Derivation Function 2, [RFC 8018](https://www.rfc-editor.org/rfc/rfc8018)) works by iterating HMAC many thousands of times:

```
T₁ = PRF(password, salt || 0x00000001)
T₂ = PRF(password, T₁) XOR T₁  ... (iterated `iterations` times)
DerivedKey = T₁ || T₂ || ... (until desired key length)
```

Where `PRF` is HMAC-SHA256 or HMAC-SHA512.

Each iteration feeds the previous output back as input, so the attacker must perform all `iterations` steps for every password guess. At 100,000 iterations:
- Verification on an iPhone: ~10 ms (fine for login)
- Brute-forcing 1 billion passwords: ~277 hours per GPU

---

## Choosing an Iteration Count

| Context | Minimum iterations (SHA-256) | Note |
|---|---|---|
| Low-powered device | 100,000 | iOS 15 baseline |
| Server-side | 600,000+ | NIST SP 800-132 (2023 recommendation) |
| High security | 1,000,000+ | Acceptable on modern hardware |

Increase iterations over time as hardware gets faster. Store the iteration count alongside the salt and derived key so you can upgrade on next login.

---

## Storing Derived Keys

```
Stored in database:
┌────────────────────────────────────────────────┐
│ user_id │ salt (32 bytes) │ derived_key (32 B) │ iterations │ algorithm │
└────────────────────────────────────────────────┘
```

To verify a password:
1. Retrieve `salt`, `iterations`, and `algorithm` for the user.
2. Call `SAKeyDerivation.deriveKey(fromPassword: input, salt: salt, iterations: ...)`.
3. Compare the result with the stored `derived_key` in constant time.

---

## Usage

```swift
import SACrypto

// On registration
let salt       = SASaltGenerator.generate()               // 32 random bytes
let derivedKey = try SAKeyDerivation.deriveKey(
    fromPassword: "hunter2",
    salt: salt,
    iterations: 100_000
)
// Store: salt + derivedKey

// On login
let candidate = try SAKeyDerivation.deriveKey(
    fromPassword: userInput,
    salt: storedSalt,
    iterations: 100_000
)
let matches = (candidate == storedDerivedKey)             // constant-time via ==

// Use derived key directly for AES encryption
let encrypted = try SAAESEncryptor.encrypt(payload, key: derivedKey)
```
