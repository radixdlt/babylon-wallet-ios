// MARK: - RETDecimal
public struct RETDecimal: DummySargon {
	public init(value: String) throws {
		sargon()
	}
}

extension RETDecimal {
	// Used for development purposes
	public static let temporaryStandardFee: RETDecimal = 25

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

	public static var zero: RETDecimal {
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
extension RETDecimal {
	public func sub(other: RETDecimal) throws -> RETDecimal {
		sargon()
	}

	public func add(other: RETDecimal) throws -> RETDecimal {
		sargon()
	}

	public func mul(other: RETDecimal) throws -> RETDecimal {
		sargon()
	}

	public func div(other: RETDecimal) throws -> RETDecimal {
		sargon()
	}

	public func lessThan(other: RETDecimal) -> Bool {
		sargon()
	}

	public func lessThanOrEqual(other: RETDecimal) -> Bool {
		sargon()
	}

	public func greaterThan(other: RETDecimal) -> Bool {
		sargon()
	}

	public func greaterThanOrEqual(other: RETDecimal) -> Bool {
		sargon()
	}
}

// MARK: Clamping

extension RETDecimal {
	public var clamped: RETDecimal {
		isNegative() ? .zero : self
	}
}

// MARK: Truncation and rounding

extension RETDecimal {
	/// Rounds to `decimalPlaces` decimals, in the direction of 0
	public func floor(decimalPlaces: UInt) -> RETDecimal {
		sargon()
	}

	/// Rounds to `decimalPlaces` decimals, in the direction away from zero
	public func ceil(decimalPlaces: UInt) -> RETDecimal {
		sargon()
	}

	/// Rounds to `decimalPlaces` decimals
	public func rounded(decimalPlaces: UInt = 0) -> RETDecimal {
		sargon()
	}
}

// MARK: Parsing and formatting for human readable strings

extension UInt {
	public static let defaultMaxPlacesFormatted: UInt = 8
	public static let maxPlacesEngineeringNotation: UInt = 4
}

extension RETDecimal {
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

	/// The digits of the number, without separators or sign. The scale is fixed at 18, meaning the last 18 digits correspond to the decimal part.
	public func digits() -> String {
		sargon()
	}
}

// MARK: - RETDecimal.Multiplier
extension RETDecimal {
	public enum Multiplier: UInt, CaseIterable {
		case million = 6, billion = 9, trillion = 12

		var value: RETDecimal {
			.init(exponent: rawValue)
		}
	}
}

extension RETDecimal.Multiplier {
	var suffix: String {
		switch self {
		case .million: "M"
		case .billion: "B"
		case .trillion: "T"
		}
	}
}
