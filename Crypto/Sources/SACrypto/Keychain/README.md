# Keychain

The **iOS Keychain** is a secure, encrypted database managed by the operating system. It survives app reinstalls (by default), is protected by the device passcode and Secure Enclave, and is separate from the app sandbox.

---

## Why the Keychain?

| Storage | Encrypted at rest | Survives reinstall | Accessible when locked |
|---|---|---|---|
| `UserDefaults` | ❌ | ✅ | ✅ |
| App's `Documents/` folder | ❌ | ❌ | ✅ |
| **Keychain** | ✅ | ✅ (configurable) | Configurable |
| Secure Enclave | ✅ Hardware | ✅ | Configurable |

Never store cryptographic keys, API tokens, or passwords outside the Keychain.

---

## Accessibility Classes

`SAKeychain` stores items with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`:

| Accessibility | When readable | iCloud backup |
|---|---|---|
| `WhenUnlocked` | Device unlocked | ✅ Yes |
| `WhenUnlockedThisDeviceOnly` | Device unlocked | ❌ No |
| `AfterFirstUnlock` | After first unlock post-reboot | ✅ Yes |
| `AfterFirstUnlockThisDeviceOnly` | After first unlock | ❌ No |
| `WhenPasscodeSetThisDeviceOnly` | Unlocked + passcode set | ❌ No |

**`ThisDeviceOnly`** means keys are bound to the device via the hardware UID and cannot be restored from a backup on a different device. This is the most secure option for cryptographic keys.

---

## How Keychain Storage Works

```
SecItemAdd("myKey", data: keyBytes)
    ↓
OS encrypts data with hardware-derived key
    ↓
Encrypted blob stored in SQLite database at /private/var/Keychains/keychain-2.db
    ↓
Access mediated by securityd daemon
```

Your app can only access its own items (by default) — the `kSecAttrService` attribute scopes access per app.

---

## Keychain Groups (Shared Keychain)

If you want to share keys between your app and an extension or another app in the same team, configure a **Keychain Access Group** in Entitlements and pass `kSecAttrAccessGroup` in the query. `SAKeychain` doesn't set this, so keys are app-private.

---

## Usage

```swift
import SACrypto

let key = SAAESEncryptor.generateKey()        // 32 random bytes

// Store
try SAKeychain.store(key, forKey: "com.myapp.aes-key")

// Retrieve
let stored = try SAKeychain.retrieve(forKey: "com.myapp.aes-key")

// Check existence
if SAKeychain.exists(forKey: "com.myapp.aes-key") { ... }

// Delete
try SAKeychain.delete(forKey: "com.myapp.aes-key")
```

---

## Security Notes

- Use **reverse-domain-style keys** (`"com.myapp.feature.keyname"`) to avoid collisions.
- Keys stored with `ThisDeviceOnly` are wiped if the device is restored from backup on new hardware — generate and store new keys on first launch.
- For keys that should be tied to biometric authentication, use `kSecAttrAccessControl` with a `LAContext` — this is beyond this library's scope but builds on the same APIs.
