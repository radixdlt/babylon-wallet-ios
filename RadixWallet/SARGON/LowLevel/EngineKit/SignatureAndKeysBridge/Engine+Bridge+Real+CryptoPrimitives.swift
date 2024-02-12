

extension SLIP10.Signature {
	public init(engine engineSignature: RETSignature) throws {
		switch engineSignature {
		case let .ed25519(signature):
			// TODO: validate
			self = .eddsaEd25519(Data(signature.bytes))
		case let .secp256k1(signature):
			self = try .ecdsaSecp256k1(.init(compact: .init(rawRepresentation: Data(signature.bytes), format: .vrs)))
		}
	}
}

extension SignatureWithPublicKey {
	public func intoEngine() throws -> RETSignatureWithPublicKey {
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
