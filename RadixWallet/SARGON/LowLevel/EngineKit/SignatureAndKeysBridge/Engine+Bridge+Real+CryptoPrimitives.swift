

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
