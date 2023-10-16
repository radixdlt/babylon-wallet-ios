import CryptoKit

// MARK: - Curve25519 + SLIP10CurveProtocol
extension Curve25519: SLIP10CurveProtocol {
	public typealias PrivateKey = Curve25519.Signing.PrivateKey
	public typealias PublicKey = Curve25519.Signing.PublicKey
	public static let curve = SLIP10.Curve.curve25519
}

// MARK: - Curve25519.Signing.PrivateKey + ECPrivateKey
extension Curve25519.Signing.PrivateKey: ECPrivateKey {}

// MARK: - Curve25519.Signing.PublicKey + ECPublicKey
extension Curve25519.Signing.PublicKey: ECPublicKey {
	public init(compressedRepresentation: some ContiguousBytes) throws {
		// Curve25519 public keys ARE always compressed.
		try self.init(rawRepresentation: compressedRepresentation)
	}

	public var compressedRepresentation: Data {
		// Curve25519 public keys ARE always compressed.
		rawRepresentation
	}
}
