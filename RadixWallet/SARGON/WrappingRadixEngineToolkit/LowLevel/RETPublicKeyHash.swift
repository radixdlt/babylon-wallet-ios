import Foundation

// MARK: - RETPublicKeyHash
public struct RETPublicKeyHash: DummySargon {
	public static func secp256k1(value: Any) -> Self {
		sargon()
	}

	public static func ed25519(value: Any) -> Self {
		sargon()
	}

	public init(hashing: Any) throws {
		sargon()
	}
}
