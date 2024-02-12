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
