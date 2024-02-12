// MARK: - RETSignatureWithPublicKey
public enum RETSignatureWithPublicKey: DummySargon {
	case secp256k1(signature: Data)
	case ed25519(signature: Data, publicKey: Data)
}

extension RETSignatureWithPublicKey {
	public var signature: SLIP10.Signature {
		panic()
	}

	public var publicKey: SLIP10.PublicKey? {
		panic()
	}
}

extension SLIP10.Signature {
	public var bytes: Data {
		switch self {
		case let .ecdsaSecp256k1(value):
			try! value.radixSerialize()
		case let .eddsaEd25519(value):
			value
		}
	}
}

extension SLIP10.PublicKey {
	public var bytes: Data {
		switch self {
		case let .ecdsaSecp256k1(key):
			key.compressedRepresentation
		case let .eddsaEd25519(key):
			key.rawRepresentation
		}
	}
}
