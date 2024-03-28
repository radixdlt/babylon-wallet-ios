import Foundation
import Sargon
import SargonUniFFI
public typealias TXID = IntentHash

extension SLIP10.PublicKey {
	public func intoSargon() -> Sargon.PublicKey {
		try! Sargon.PublicKey(bytes: self.compressedData)
	}
}

extension SLIP10.Signature {
	public func intoSargon() -> Sargon.Signature {
		try! Sargon.Signature(bytes: self.serialize())
	}
}

extension K1.PublicKey {
	public func intoSargon() -> Sargon.Secp256k1PublicKey {
		try! Sargon.Secp256k1PublicKey(bytes: self.compressedRepresentation)
	}
}

extension SignatureWithPublicKey {
	public func intoSargon() -> Sargon.SignatureWithPublicKey {
		switch self {
		case let .ecdsaSecp256k1(signature, publicKey):
			Sargon.SignatureWithPublicKey.secp256k1(
				publicKey: publicKey.intoSargon(),
				signature: signature.intoSargon()
			)
		case let .eddsaEd25519(signature, publicKey):
			Sargon.SignatureWithPublicKey.ed25519(
				publicKey: publicKey.intoSargon(),
				signature: Sargon.Ed25519Signature(
					wallet: signature
				)
			)
		}
	}
}

extension K1.ECDSAWithKeyRecovery.Signature {
	func intoSargon() -> Sargon.Secp256k1Signature {
		try! Sargon.Secp256k1Signature(bytes: self.data)
	}
}

extension Curve25519.Signing.PublicKey {
	func intoSargon() -> Sargon.Ed25519PublicKey {
		try! Sargon.Ed25519PublicKey(bytes: self.compressedRepresentation)
	}
}

extension Sargon.Ed25519Signature {
	init(wallet: EdDSASignature) {
		try! self.init(bytes: wallet)
	}
}
