import Cryptography
import Prelude

public extension HD.Root {
	func derivePrivateKey(
		path: DerivationPath,
		curve: Slip10Curve
	) throws -> SLIP10.PrivateKey {
		// FIXME: CLEAN THIS UP!
		let path = try HD.Path.Full(string: path.path)
		switch curve {
		case .curve25519:
			let key: HD.ExtendedKey<Curve25519> = try derivePrivateKey(path: path, curve: Curve25519.self)
			return .curve25519(key.privateKey!)
		case .secp256k1:
			let key: HD.ExtendedKey<SECP256K1> = try derivePrivateKey(path: path, curve: SECP256K1.self)
			return .secp256k1(key.privateKey!)
		}
	}

	func derivePublicKey(
		path: DerivationPath,
		curve: Slip10Curve
	) throws -> SLIP10.PublicKey {
		try derivePrivateKey(path: path, curve: curve).publicKey()
	}
}

extension HD.Root {
	func publicKeyForFactorSourceID() throws -> SLIP10.PublicKey {
		try derivePublicKey(path: .getID, curve: .curve25519)
	}
}
