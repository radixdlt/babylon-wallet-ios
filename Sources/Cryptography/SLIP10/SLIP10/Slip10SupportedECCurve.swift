import CryptoKit
import Prelude

// MARK: - Slip10SupportedECCurve
public protocol Slip10SupportedECCurve where PrivateKey.PublicKey == Self.PublicKey {
	associatedtype PrivateKey: ECPrivateKey

	/// Conforming to `ECPublicKey`
	associatedtype PublicKey

	static var slip10Curve: Slip10CurveType { get }
}

public extension Slip10SupportedECCurve {
	var slip10Curve: Slip10CurveType { Self.slip10Curve }
}
