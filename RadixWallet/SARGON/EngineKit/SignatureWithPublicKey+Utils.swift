// MARK: - RETSignature
public enum RETSignature: DummySargon {
	case secp256k1(value: Data)
	case ed25519(value: Data)
}

// MARK: - RETSecp256k1Signature
public struct RETSecp256k1Signature: DummySargon {}

// MARK: - RETSecp256k1PublicKey
public struct RETSecp256k1PublicKey: DummySargon {}

// MARK: - RETEd25519PublicKey
public struct RETEd25519PublicKey: DummySargon {}

// MARK: - RETPublicKey
public enum RETPublicKey: DummySargon {
	case secp256k1(value: Data)
	case ed25519(value: Data)
}

// MARK: - RETSignatureWithPublicKey
public enum RETSignatureWithPublicKey: DummySargon {
	case secp256k1(signature: Data)
	case ed25519(signature: Data, publicKey: Data)
}

extension RETSignatureWithPublicKey {
	public var signature: RETSignature {
		switch self {
		case let .secp256k1(signature):
			.secp256k1(value: signature)
		case let .ed25519(signature, _):
			.ed25519(value: signature)
		}
	}

	public var publicKey: RETPublicKey? {
		switch self {
		case .secp256k1:
			nil
		case let .ed25519(_, key):
			.ed25519(value: key)
		}
	}
}

extension RETSignature {
	public var bytes: Data {
		switch self {
		case let .secp256k1(value):
			value
		case let .ed25519(value):
			value
		}
	}
}

extension RETPublicKey {
	public var bytes: Data {
		switch self {
		case let .secp256k1(value):
			value
		case let .ed25519(value):
			value
		}
	}
}
