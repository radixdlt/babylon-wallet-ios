import EngineToolkit
import Foundation

extension SignatureWithPublicKey {
	public var signature: Signature {
		switch self {
		case let .secp256k1(signature):
			return .secp256k1(value: signature)
		case let .ed25519(signature, _):
			return .ed25519(value: signature)
		}
	}

	public var publicKey: PublicKey? {
		switch self {
		case .secp256k1:
			return nil
		case let .ed25519(_, key):
			return .ed25519(value: key)
		}
	}
}

extension Signature {
	public var bytes: [UInt8] {
		switch self {
		case let .secp256k1(value):
			return value
		case let .ed25519(value):
			return value
		}
	}
}

extension PublicKey {
	public var bytes: [UInt8] {
		switch self {
		case let .secp256k1(value):
			return value
		case let .ed25519(value):
			return value
		}
	}
}
