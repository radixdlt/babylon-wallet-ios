import Cryptography
import EngineToolkit
import Prelude

extension FactorSource {
	public static func id(
		publicKey: SLIP10.PublicKey,
		factorSourceKind: FactorSourceKind
	) throws -> FactorSourceID {
		let hash = try blake2b(data: publicKey.compressedRepresentation)
		return try FactorSourceID(factorSourceKind: factorSourceKind, hash: hash)
	}

	public static func id(
		fromRoot hdRoot: HD.Root,
		factorSourceKind: FactorSourceKind
	) throws -> FactorSourceID {
		try Self.id(
			publicKey: hdRoot.publicKeyForFactorSourceID(),
			factorSourceKind: factorSourceKind
		)
	}

	public static func id(
		fromMnemonicWithPassphrase mnemonicWithPassphrase: MnemonicWithPassphrase,
		factorSourceKind: FactorSourceKind
	) throws -> FactorSourceID {
		try Self.id(
			fromRoot: mnemonicWithPassphrase.hdRoot(),
			factorSourceKind: factorSourceKind
		)
	}

	public static func id(
		fromPrivateHDFactorSource privateHDFactorSource: PrivateHDFactorSource,
		factorSourceKind: FactorSourceKind
	) throws -> FactorSourceID {
		try Self.id(
			fromMnemonicWithPassphrase: privateHDFactorSource.mnemonicWithPassphrase,
			factorSourceKind: factorSourceKind
		)
	}
}
