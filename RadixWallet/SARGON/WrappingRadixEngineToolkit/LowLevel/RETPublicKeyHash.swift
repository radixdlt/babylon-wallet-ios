import Foundation

// MARK: - RETPublicKeyHash
public struct RETPublicKeyHash: DummySargon {
	public static func secp256k1(value: Any) -> Self {
		sargon()
	}

	public static func ed25519(value: Any) -> Self {
		sargon()
	}

	public struct InvalidPublicKeyHashLength: Error {
		public let got: Int
		public let expected: Int
	}

	static let hashLength = 29

	public init(hashing publicKey: SLIP10.PublicKey) throws {
		let hashBytes = try Sargon.hash(data: publicKey.compressedData).suffix(Self.hashLength)

		guard
			hashBytes.count == Self.hashLength
		else {
			throw InvalidPublicKeyHashLength(got: hashBytes.count, expected: Self.hashLength)
		}

		switch publicKey {
		case .ecdsaSecp256k1:
			self = .secp256k1(value: hashBytes)
		case .eddsaEd25519:
			self = .ed25519(value: hashBytes)
		}
	}
}
