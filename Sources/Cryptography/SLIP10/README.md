# SLIP10

This is an implementation of [`SLIP-10` Universal private key derivation from master private key](https://github.com/satoshilabs/slips/blob/master/slip-0010.md), by Satoshi Labs, in Swift.

Only ed25519 is supported. We will create [`CryptoKit Curve25519`](https://developer.apple.com/documentation/cryptokit/curve25519) types so we will call ed25519 Curve25519.

# Usage

```swift
let insecureSeed = "insecure seed of at least 128 bit".data(using: .utf8)!
let root = try HD.Root(seed: insecureSeed)
let path = try HD.Path.Full(string: "m/1022'/0'/0'/0'/0'")
let extendedKey = try root.derivePrivateKey(path: path, curve: Curve25519.self)
assert(extendedKey.derivationPath == .full(path))

let messageToHashAndSign = "Hello World!".data(using: .utf8)!
let signature = try extendedKey.privateKey!.signature(for: messageToHashAndSign)
assert(extendedKey.publicKey.isValidSignature(signature, for: messageToHashAndSign))


assert(try extendedKey.xpub() == "xpub6G29mZKKVXdqcEYLaAUxdGPMGAvXbwXXxUpJSDLFEJh6rRWnUb7HdDDLDzaD2zkCiu1P4GP4R6y7P7zos8HfQNy1iKopzApn5a7HFjKHzUb")
assert(try extendedKey.xprv() == "xprvA32oN3nRfA5YPkTsU8wxG8Sci963CUogbFthdpvdfyA7ydBdw3o35QtrNnaM6G5kBU2mwFbNPBPsB7Am3g3Zi6bm3YXvDnDXtihS3yUvAgo")
assert(extendedKey.chainCode.chainCode.hex() == "67645a3e13ea63de86742415470489e343a0267b5864f77f2db909efd4616e70")
assert(extendedKey.fingerprint.fingerprint.hex() == "525ce405")

let childPublicKey = try extendedKey.derivePublicKey(path: .harden(1))

assert(childPublicKey.derivationPath == try HD.Path(string: "m/1022'/0'/0'/0'/0'/1'")
do { 
	// will throw
	try childPublicKey.xprv()
} catch let error as SerializationError {
	// As expected we reach this scope, since private key is not present.
	assert(error == .privateKeyNotPresent)
} catch { fatalError("Wrong error type") }

assert(try childPublicKey.xpub() == "xpub6HJnDxL4npVUAFLjb6gxZQqCqVJbYKn5E22fQADcT2LvYHZzFAiFW4hTuQjaRsUrF28EQGsCynUz1pP7sqQ23MWdph3XxHNGuWue5BqCgmx")

let childPrivateKey = try extendedKey.derivePrivateKey(path: .harden(1))
assert(childPublicKey.derivationPath == childPrivateKey.derivationPath)
assert(try childPublicKey.xpub() == try childPrivateKey.xpub())

assert(try childPrivateKey.xprv() == "xprvA4KRpSoAxSwAwmGGV59xCGtUHTU78s4Dro74bmoztgowfVEqhdPzxGNz4DHhLfZTjvEvsqSSJofA42gHTcPfQhzhxDnbg1fLa7Q6exF9dNh")
```

## About SLIP-10
SLIP-10 (or SLIP-0010 or SLIP10) is to date (2022-05-14) the most adopted mechanism by which we get HD derivation for Ed25519. There is an **incompatible** and **competing** mechanism often called `Ed25519-BIP32` (described in this paper). [Andrew explains in Satoshi Lab](https://github.com/satoshilabs/slips/issues/703#issuecomment-515213584) some differences and why SLIP-10 is to prefer.

### BIP32 Implementations
**No alternatives exist for SLIP-0010 in Swift**, but here are some BIP32 alternatives.
[KevinVitale/WalletKit](https://github.com/KevinVitale/WalletKit) 
[Sjors/libwally-swift](https://github.com/Sjors/libwally-swift) (requires git submodules and `automake` `libtool`)
[goldennetwork/GoldenKeystore](https://github.com/goldennetwork/GoldenKeystore) (💀 4 years)
[skywinder/web3swift](https://github.com/skywinder/web3swift/tree/develop/Sources/web3swift/KeystoreManager) (Complete Ethereum toolkit, no seperate BIP32 packages)
[anquii/BIP32](https://github.com/anquii/BIP32) (Copycat of `KevinVitale/WalletKit` ?)

