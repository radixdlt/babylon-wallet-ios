import EngineToolkit
import Foundation

extension SignatureWithPublicKey {
	public var signature: Signature {
		switch self {
		case let .ecdsaSecp256k1(signature):
			return .ecdsaSecp256k1(value: signature)
		case let .eddsaEd25519(signature, _):
			return .eddsaEd25519(value: signature)
		}
	}

	public var publicKey: PublicKey? {
		switch self {
		case .ecdsaSecp256k1:
			return nil
		case let .eddsaEd25519(_, key):
			return .eddsaEd25519(value: key)
		}
	}
}

extension Signature {
	public var bytes: [UInt8] {
		switch self {
		case let .ecdsaSecp256k1(value):
			return value
		case let .eddsaEd25519(value):
			return value
		}
	}
}

extension PublicKey {
	public var bytes: [UInt8] {
		switch self {
		case let .ecdsaSecp256k1(value):
			return value
		case let .eddsaEd25519(value):
			return value
		}
	}
}
