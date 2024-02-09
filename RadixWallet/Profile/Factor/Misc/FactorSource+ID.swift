

extension FactorSource {
	public static func id(
		publicKey: SLIP10.PublicKey,
		factorSourceKind: FactorSourceKind
	) throws -> FactorSourceID.FromHash {
		let hash = try blake2b(data: publicKey.compressedRepresentation)
		return try .init(
			kind: factorSourceKind,
			body: .init(data: hash)
		)
	}

	public static func id(
		fromRoot hdRoot: HD.Root,
		factorSourceKind: FactorSourceKind
	) throws -> FactorSourceID.FromHash {
		try id(
			publicKey: hdRoot.publicKeyForFactorSourceID(),
			factorSourceKind: factorSourceKind
		)
	}

	public static func id(
		fromMnemonicWithPassphrase mnemonicWithPassphrase: MnemonicWithPassphrase,
		factorSourceKind: FactorSourceKind
	) throws -> FactorSourceID.FromHash {
		try id(
			fromRoot: mnemonicWithPassphrase.hdRoot(),
			factorSourceKind: factorSourceKind
		)
	}

	public static func id(
		fromPrivateHDFactorSource privateHDFactorSource: PrivateHDFactorSource,
		factorSourceKind: FactorSourceKind
	) throws -> FactorSourceID.FromHash {
		try id(
			fromMnemonicWithPassphrase: privateHDFactorSource.mnemonicWithPassphrase,
			factorSourceKind: factorSourceKind
		)
	}
}
