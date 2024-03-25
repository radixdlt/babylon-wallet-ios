// MARK: - Decimal192 + DummySargonCodable
extension Decimal192: DummySargonCodable {}

// MARK: - Decimal192 + ExpressibleByIntegerLiteral
// RATIONALE: UniFFI does not support ExpressibleByIntegerLiteral / ExpressibleByFloatLiteral

extension Decimal192: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: Int) {
		sargon()
	}
}

// MARK: - Decimal192 + ExpressibleByFloatLiteral
extension Decimal192: ExpressibleByFloatLiteral {
	public init(floatLiteral value: Double) {
		sargon()
	}
}

extension Decimal192 {
	public static func + (lhs: Decimal192, rhs: Decimal192) -> Decimal192 {
		try! lhs.add(other: rhs)
	}

	public static func += (lhs: inout Decimal192, rhs: Decimal192) {
		lhs = lhs + rhs
	}

	public static func - (lhs: Decimal192, rhs: Decimal192) -> Decimal192 {
		try! lhs.sub(other: rhs)
	}

	public static func -= (lhs: inout Decimal192, rhs: Decimal192) {
		lhs = lhs - rhs
	}

	public static func * (lhs: Decimal192, rhs: Decimal192) -> Decimal192 {
		try! lhs.mul(other: rhs)
	}

	public static func *= (lhs: inout Decimal192, rhs: Decimal192) {
		lhs = lhs * rhs
	}

	public static func / (lhs: Decimal192, rhs: Decimal192) -> Decimal192 {
		try! lhs.div(other: rhs)
	}

	public static func < (lhs: Decimal192, rhs: Decimal192) -> Bool {
		lhs.lessThan(other: rhs)
	}

	public static func <= (lhs: Decimal192, rhs: Decimal192) -> Bool {
		lhs.lessThanOrEqual(other: rhs)
	}

	public static func > (lhs: Decimal192, rhs: Decimal192) -> Bool {
		lhs.greaterThan(other: rhs)
	}

	public static func >= (lhs: Decimal192, rhs: Decimal192) -> Bool {
		lhs.greaterThanOrEqual(other: rhs)
	}

	public static prefix func - (value: Decimal192) -> Decimal192 {
		.zero - value
	}
}
