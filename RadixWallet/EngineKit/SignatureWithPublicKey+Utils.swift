import EngineToolkitimport EngineToolkit
extension SignatureWithPublicKey {
	public var signature: Signature {
		switch self {
		case let .secp256k1(signature):
			.secp256k1(value: signature)
		case let .ed25519(signature, _):
			.ed25519(value: signature)
		}
	}

	public var publicKey: PublicKey? {
		switch self {
		case .secp256k1:
			nil
		case let .ed25519(_, key):
			.ed25519(value: key)
		}
	}
}

extension Signature {
	public var bytes: [UInt8] {
		switch self {
		case let .secp256k1(value):
			value
		case let .ed25519(value):
			value
		}
	}
}

extension PublicKey {
	public var bytes: [UInt8] {
		switch self {
		case let .secp256k1(value):
			value
		case let .ed25519(value):
			value
		}
	}
}
