# Secure Random Generation

## Why "Secure" Random?

Normal random-number generators (like `arc4random` or `Int.random(in:)`) are designed for simulation and games — they produce statistically good distributions, but their internal state can often be predicted. That is catastrophic in cryptography: a predictable nonce breaks AES-GCM, a predictable salt makes password dictionaries viable, and a predictable key is no key at all.

`SASecureRandom` reads from the **OS entropy pool** — a mix of hardware timing noise, interrupt jitter, and other true randomness sources — via `SecRandomCopyBytes`. This produces output that is computationally indistinguishable from true randomness.

---

## How `SecRandomCopyBytes` Works

```
Hardware events (keystrokes, network packets, sensor data)
    ↓
Kernel entropy pool  (/dev/random on Unix, CryptGenRandom on Windows)
    ↓
SecRandomCopyBytes()
    ↓
Your [UInt8] buffer
```

The kernel continuously stirs new entropy into the pool, so the pool never becomes predictable even after reading large amounts of data.

---

## Modulo Bias and Rejection Sampling

A common mistake when generating a random number in range `[0, N)` is:

```swift
let bad = uint32() % N   // ⚠️ biased if N doesn't divide UInt32.max evenly
```

If `UInt32.max` is not divisible by `N`, the lower values appear more often. `uniformRandom(upperBound:)` fixes this with **rejection sampling**: any value in the "uneven" tail is discarded and a new one drawn until a fair value lands.

---

## Usage

```swift
import SACrypto

// Raw bytes (for nonces, salts, IVs)
let nonce = SASecureRandom.bytes(count: 12)     // 96-bit nonce
let salt  = SASecureRandom.bytes(count: 32)     // 256-bit salt

// Random integers
let roll  = SASecureRandom.uniformRandom(upperBound: 6) + 1   // fair d6
```

---

## Security Notes

- Never seed a PRNG with output from `SASecureRandom` and then use the PRNG for cryptographic purposes — use `SASecureRandom` directly for every secret value.
- The `precondition` in `bytes(count:)` will crash in the highly unlikely event that the entropy source is unavailable (hardware fault). This is intentional — returning weak random bytes silently would be worse.
