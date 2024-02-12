// RATIONALE: UniFFI does not support ExpressibleByIntegerLiteral / ExpressibleByFloatLiteral

// MARK: - RETDecimal + ExpressibleByIntegerLiteral
extension RETDecimal: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: Int) {
		panic()
	}
}

// MARK: - RETDecimal + ExpressibleByFloatLiteral
extension RETDecimal: ExpressibleByFloatLiteral {
	public init(floatLiteral value: Double) {
		panic()
	}
}
