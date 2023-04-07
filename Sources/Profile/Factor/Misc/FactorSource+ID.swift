import Cryptography
import EngineToolkit
import Prelude

extension FactorSource {
	public static func id(
		fromPrivateHDFactorSource privateHDFactorSource: PrivateHDFactorSource
	) throws -> FactorSourceID {
		try Self.id(fromMnemonicWithPassphrase: privateHDFactorSource.mnemonicWithPassphrase)
	}

	public static func id(
		fromMnemonicWithPassphrase mnemonicWithPassphrase: MnemonicWithPassphrase
	) throws -> FactorSourceID {
		try Self.id(fromRoot: mnemonicWithPassphrase.hdRoot())
	}

	public static func id(
		fromRoot hdRoot: HD.Root
	) throws -> FactorSourceID {
		try Self.id(
			publicKey: hdRoot.publicKeyForFactorSourceID()
		)
	}

	public static func id(
		publicKey: SLIP10.PublicKey
	) throws -> FactorSourceID {
		let hash = try blake2b(data: publicKey.compressedRepresentation)
		return try FactorSourceID(data: hash)
	}
}
