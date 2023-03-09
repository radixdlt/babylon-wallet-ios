import Cryptography
import Prelude

public extension FactorSource {
	static func id(
		fromRoot hdRoot: HD.Root
	) throws -> FactorSourceID {
		try Self.id(
			publicKey: hdRoot.publicKeyForFactorSourceID()
		)
	}

	static func id(
		publicKey: SLIP10.PublicKey
	) throws -> FactorSourceID {
		let hash = Data(SHA256.twice(data: publicKey.compressedRepresentation))
		return try FactorSourceID(data: hash)
	}
}
