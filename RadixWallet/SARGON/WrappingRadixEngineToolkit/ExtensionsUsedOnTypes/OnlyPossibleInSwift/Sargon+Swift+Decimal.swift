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

extension RETDecimal {
	public static func + (lhs: RETDecimal, rhs: RETDecimal) -> RETDecimal {
		try! lhs.add(other: rhs)
	}

	public static func += (lhs: inout RETDecimal, rhs: RETDecimal) {
		lhs = lhs + rhs
	}

	public static func - (lhs: RETDecimal, rhs: RETDecimal) -> RETDecimal {
		try! lhs.sub(other: rhs)
	}

	public static func -= (lhs: inout RETDecimal, rhs: RETDecimal) {
		lhs = lhs - rhs
	}

	public static func * (lhs: RETDecimal, rhs: RETDecimal) -> RETDecimal {
		try! lhs.mul(other: rhs)
	}

	public static func *= (lhs: inout RETDecimal, rhs: RETDecimal) {
		lhs = lhs * rhs
	}

	public static func / (lhs: RETDecimal, rhs: RETDecimal) -> RETDecimal {
		try! lhs.div(other: rhs)
	}

	public static func < (lhs: RETDecimal, rhs: RETDecimal) -> Bool {
		lhs.lessThan(other: rhs)
	}

	public static func <= (lhs: RETDecimal, rhs: RETDecimal) -> Bool {
		lhs.lessThanOrEqual(other: rhs)
	}

	public static func > (lhs: RETDecimal, rhs: RETDecimal) -> Bool {
		lhs.greaterThan(other: rhs)
	}

	public static func >= (lhs: RETDecimal, rhs: RETDecimal) -> Bool {
		lhs.greaterThanOrEqual(other: rhs)
	}

	public static prefix func - (value: RETDecimal) -> RETDecimal {
		.zero - value
	}
}
