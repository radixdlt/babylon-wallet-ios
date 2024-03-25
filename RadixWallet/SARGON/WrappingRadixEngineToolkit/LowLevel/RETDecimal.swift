// MARK: - Decimal192
public struct Decimal192: DummySargon {
	public init(value: String) throws {
		sargon()
	}
}

extension Decimal192 {
	// Used for development purposes
	public static let temporaryStandardFee: Decimal192 = 25

	public static let maxDivisibility: UInt = 18

	public func isNegative() -> Bool {
		sargon()
	}

	public func isPositive() -> Bool {
		sargon()
	}

	public func isZero() -> Bool {
		sargon()
	}

	public static var zero: Decimal192 {
		sargon()
	}

	public init(integer: Int) {
		sargon()
	}

	/// Creates the Decimal `10^exponent`
	public init(exponent: UInt) {
		sargon()
	}
}

// MARK: Arithmetic operators
extension Decimal192 {
	public func sub(other: Decimal192) throws -> Decimal192 {
		sargon()
	}

	public func add(other: Decimal192) throws -> Decimal192 {
		sargon()
	}

	public func mul(other: Decimal192) throws -> Decimal192 {
		sargon()
	}

	public func div(other: Decimal192) throws -> Decimal192 {
		sargon()
	}

	public func lessThan(other: Decimal192) -> Bool {
		sargon()
	}

	public func lessThanOrEqual(other: Decimal192) -> Bool {
		sargon()
	}

	public func greaterThan(other: Decimal192) -> Bool {
		sargon()
	}

	public func greaterThanOrEqual(other: Decimal192) -> Bool {
		sargon()
	}
}

// MARK: Clamping

extension Decimal192 {
	public var clamped: Decimal192 {
		isNegative() ? .zero : self
	}
}

// MARK: Truncation and rounding

extension Decimal192 {
	/// Rounds to `decimalPlaces` decimals, in the direction of 0
	public func floor(decimalPlaces: UInt) -> Decimal192 {
		sargon()
	}

	/// Rounds to `decimalPlaces` decimals, in the direction away from zero
	public func ceil(decimalPlaces: UInt) -> Decimal192 {
		sargon()
	}

	/// Rounds to `decimalPlaces` decimals
	public func rounded(decimalPlaces: UInt = 0) -> Decimal192 {
		sargon()
	}
}

// MARK: Parsing and formatting for human readable strings

extension UInt {
	public static let defaultMaxPlacesFormatted: UInt = 8
	public static let maxPlacesEngineeringNotation: UInt = 4
}

extension Decimal192 {
	/// Parse a local respecting string
	public init(
		formattedString: String,
		locale: Locale = .autoupdatingCurrent
	) throws {
		sargon()
	}

	/// A human readable, locale respecting string, rounded to `totalPlaces` places, counting all digits
	public func formatted(
		locale: Locale = .autoupdatingCurrent,
		totalPlaces: UInt = .defaultMaxPlacesFormatted,
		useGroupingSeparator: Bool = true
	) -> String {
		sargon()
	}

	public func formattedEngineeringNotation(
		locale: Locale = .autoupdatingCurrent,
		totalPlaces: UInt = .maxPlacesEngineeringNotation
	) -> String {
		sargon()
	}

	/// A human readable, locale respecting string. Does not perform any rounding or truncation.
	public func formattedPlain(
		locale: Locale = .autoupdatingCurrent,
		useGroupingSeparator: Bool = true
	) -> String {
		sargon()
	}
}
