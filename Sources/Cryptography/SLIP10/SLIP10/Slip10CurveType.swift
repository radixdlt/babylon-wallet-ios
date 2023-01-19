import Prelude

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
