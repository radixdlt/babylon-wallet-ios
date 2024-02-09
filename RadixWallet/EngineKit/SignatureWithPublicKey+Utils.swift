import EngineToolkit

// MARK: - EngineToolkitSignature
public enum EngineToolkitSignature {
	case secp256k1(value: Data)
	case ed25519(value: Data)
}

// MARK: - EngineToolkitSecp256k1Signature
public struct EngineToolkitSecp256k1Signature {}

// MARK: - EngineToolkitSecp256k1PublicKey
public struct EngineToolkitSecp256k1PublicKey {}

// MARK: - EngineToolkitEd25519PublicKey
public struct EngineToolkitEd25519PublicKey {}

// MARK: - EngineToolkitPublicKey
public enum EngineToolkitPublicKey {
	case secp256k1(value: Data)
	case ed25519(value: Data)
}

// MARK: - EngineToolkitSignatureWithPublicKey
public enum EngineToolkitSignatureWithPublicKey {
	case secp256k1(Data)
	case ed25519(Data, Data)
}

extension EngineToolkitSignatureWithPublicKey {
	public var signature: EngineToolkitSignature {
		switch self {
		case let .secp256k1(signature):
			.secp256k1(value: signature)
		case let .ed25519(signature, _):
			.ed25519(value: signature)
		}
	}

	public var publicKey: EngineToolkitPublicKey? {
		switch self {
		case .secp256k1:
			nil
		case let .ed25519(_, key):
			.ed25519(value: key)
		}
	}
}

extension EngineToolkitSignature {
	public var bytes: Data {
		switch self {
		case let .secp256k1(value):
			value
		case let .ed25519(value):
			value
		}
	}
}

extension EngineToolkitPublicKey {
	public var bytes: Data {
		switch self {
		case let .secp256k1(value):
			value
		case let .ed25519(value):
			value
		}
	}
}
