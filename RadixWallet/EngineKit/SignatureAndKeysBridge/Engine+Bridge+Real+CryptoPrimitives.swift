

extension SLIP10.PublicKey {
	public init(engine enginePublicKey: EngineToolkit.PublicKey) throws {
		switch enginePublicKey {
		case let .ed25519(key):
			self = try .eddsaEd25519(Curve25519.Signing.PublicKey(rawRepresentation: key.bytes))
		case let .secp256k1(key):
			self = try .ecdsaSecp256k1(.init(compressedRepresentation: key.bytes))
		}
	}
}

extension SLIP10.PublicKey {
	public func intoEngine() -> EngineToolkit.PublicKey {
		switch self {
		case let .ecdsaSecp256k1(key):
			.secp256k1(value: key.compressedRepresentation)
		case let .eddsaEd25519(key):
			.ed25519(value: key.rawRepresentation)
		}
	}
}

extension SLIP10.Signature {
	public init(engine engineSignature: EngineToolkit.Signature) throws {
		switch engineSignature {
		case let .ed25519(signature):
			// TODO: validate
			self = .eddsaEd25519(Data(signature.bytes))
		case let .secp256k1(signature):
			self = try .ecdsaSecp256k1(.init(compact: .init(rawRepresentation: Data(signature.bytes), format: .vrs)))
		}
	}
}

extension K1.PublicKey {
	public func intoEngine() -> EngineToolkit.PublicKey {
		.secp256k1(value: compressedRepresentation)
	}
}

extension SignatureWithPublicKey {
	public func intoEngine() throws -> EngineToolkit.SignatureWithPublicKey {
		switch self {
		case let .ecdsaSecp256k1(signature, _):
			try .secp256k1(signature: signature.radixSerialize())
		case let .eddsaEd25519(signature, publicKey):
			.ed25519(
				signature: signature,
				publicKey: publicKey.rawRepresentation
			)
		}
	}
}
