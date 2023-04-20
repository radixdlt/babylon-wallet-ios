import Prelude

// MARK: - SLIP10.Curve
extension SLIP10 {
	public enum Curve: String, Sendable, Hashable, Codable, CustomStringConvertible {
		/// Curve25519 or Ed25519
		case curve25519

		/// The bitcoin curve
		case secp256k1
	}
}

extension SLIP10.Curve {
	public var description: String {
		rawValue
	}

	public var curveSeed: String {
		switch self {
		case .curve25519:
			return "ed25519 seed"
		case .secp256k1:
			return "Bitcoin seed"
		}
	}

	public var curveOrder: BigUInt {
		switch self {
		case .curve25519:
			return BigUInt(2).power(252) + BigUInt("27742317777372353535851937790883648493", radix: 16)!
		case .secp256k1:
			return BigUInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!
		}
	}
}

// MARK: - SLIP10CurveProtocol
public protocol SLIP10CurveProtocol where PrivateKey.PublicKey == Self.PublicKey {
	associatedtype PrivateKey: ECPrivateKey

	/// Conforming to `ECPublicKey`
	associatedtype PublicKey

	static var curve: SLIP10.Curve { get }

	/// Defaults to use `Self.curve.curveSeed` (but present so we can add more curves in unit tests)
	static var curveSeed: String { get }

	/// Defaults to use `Self.curve.curveOrder` (but present so we can add more curves in unit tests)
	static var curveOrder: BigUInt { get }
}

extension SLIP10CurveProtocol {
	public static var isCurve25519: Bool {
		curve == .curve25519
	}

	public var isCurve25519: Bool {
		Self.isCurve25519
	}

	public static var curveSeed: String { Self.curve.curveSeed }
	public static var curveOrder: BigUInt { Self.curve.curveOrder }
	public var curve: SLIP10.Curve { Self.curve }
}
