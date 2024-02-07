

extension EngineToolkit.SignatureWithPublicKey {
	public var signature: EngineToolkit.Signature {
		switch self {
		case let .secp256k1(signature):
			.secp256k1(value: signature)
		case let .ed25519(signature, _):
			.ed25519(value: signature)
		}
	}

	public var publicKey: EngineToolkit.PublicKey? {
		switch self {
		case .secp256k1:
			nil
		case let .ed25519(_, key):
			.ed25519(value: key)
		}
	}
}

extension EngineToolkit.Signature {
	public var bytes: Data {
		switch self {
		case let .secp256k1(value):
			value
		case let .ed25519(value):
			value
		}
	}
}

extension EngineToolkit.PublicKey {
	public var bytes: Data {
		switch self {
		case let .secp256k1(value):
			value
		case let .ed25519(value):
			value
		}
	}
}
