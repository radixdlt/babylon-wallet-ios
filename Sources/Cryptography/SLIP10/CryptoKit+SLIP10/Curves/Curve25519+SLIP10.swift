import CryptoKit
import Prelude

public extension Slip10CurveType {
	/// Curve25519 or Ed25519
	static let curve25519 = Self(
		slip10CurveID: "ed25519 seed",
		curveOrder: BigUInt(2).power(252) + BigUInt("27742317777372353535851937790883648493", radix: 16)!
	)
}

public extension Slip10CurveType {
	var isCurve25519: Bool {
		self == Self.curve25519
	}
}

internal extension Slip10SupportedECCurve {
	static var isCurve25519: Bool {
		slip10Curve.isCurve25519
	}
}

// MARK: - Curve25519 + Slip10SupportedECCurve
extension Curve25519: Slip10SupportedECCurve {
	public typealias PrivateKey = Curve25519.Signing.PrivateKey
	public typealias PublicKey = Curve25519.Signing.PublicKey
	public static let slip10Curve = Slip10CurveType.curve25519
}

// MARK: - Curve25519.Signing.PrivateKey + ECPrivateKey
extension Curve25519.Signing.PrivateKey: ECPrivateKey {}

// MARK: - Curve25519.Signing.PublicKey + ECPublicKey
extension Curve25519.Signing.PublicKey: ECPublicKey {
	public init<Bytes>(compressedRepresentation: Bytes) throws where Bytes: ContiguousBytes {
		// Curve25519 public keys ARE always compressed.
		try self.init(uncompressedRepresentation: compressedRepresentation)
	}

	public init<D>(uncompressedRepresentation: D) throws where D: ContiguousBytes {
		try self.init(rawRepresentation: uncompressedRepresentation)
	}

	public var compressedRepresentation: Data {
		// Curve25519 public keys ARE always compressed.
		rawRepresentation
	}
}
