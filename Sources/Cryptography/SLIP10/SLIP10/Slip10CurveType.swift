import Prelude

// MARK: - Slip10CurveType
public struct Slip10CurveType: Equatable {
	public let slip10CurveID: String
	public let curveOrder: BigUInt
	public init(
		slip10CurveID: String,
		curveOrder: BigUInt
	) {
		self.slip10CurveID = slip10CurveID
		self.curveOrder = curveOrder
	}
}

// MARK: - Slip10Curve
public enum Slip10Curve: String, Sendable, Hashable, Codable, CustomStringConvertible {
	case curve25519
	case secp256k1
}

extension Slip10Curve {
	public var description: String {
		rawValue
	}
}
