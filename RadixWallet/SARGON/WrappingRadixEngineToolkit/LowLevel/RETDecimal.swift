// MARK: - RETDecimal

extension RETDecimal {
	// Used for development purposes
	public static let temporaryStandardFee: RETDecimal = 25

	public static let maxDivisibility: UInt = 18

	public func isNegative() -> Bool {
		panic()
	}

	public func isPositive() -> Bool {
		panic()
	}

	public func isZero() -> Bool {
		panic()
	}

	public static var zero: RETDecimal {
		panic()
	}

	public init(integer: Int) {
		panic()
	}

	/// Creates the Decimal `10^exponent`
	public init(exponent: UInt) {
		panic()
	}
}

// MARK: Arithmetic operators
extension RETDecimal {
	public func sub(other: RETDecimal) throws -> RETDecimal {
		panic()
	}

	public func add(other: RETDecimal) throws -> RETDecimal {
		panic()
	}

	public func mul(other: RETDecimal) throws -> RETDecimal {
		panic()
	}

	public func div(other: RETDecimal) throws -> RETDecimal {
		panic()
	}

	public func lessThan(other: RETDecimal) -> Bool {
		panic()
	}

	public func lessThanOrEqual(other: RETDecimal) -> Bool {
		panic()
	}

	public func greaterThan(other: RETDecimal) -> Bool {
		panic()
	}

	public func greaterThanOrEqual(other: RETDecimal) -> Bool {
		panic()
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
		panic()
	}

	/// Rounds to `decimalPlaces` decimals, in the direction away from zero
	public func ceil(decimalPlaces: UInt) -> RETDecimal {
		panic()
	}

	/// Rounds to `decimalPlaces` decimals
	public func rounded(decimalPlaces: UInt = 0) -> RETDecimal {
		panic()
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
		panic()
	}

	/// A human readable, locale respecting string, rounded to `totalPlaces` places, counting all digits
	public func formatted(
		locale: Locale = .autoupdatingCurrent,
		totalPlaces: UInt = .defaultMaxPlacesFormatted,
		useGroupingSeparator: Bool = true
	) -> String {
		panic()
	}

	public func formattedEngineeringNotation(
		locale: Locale = .autoupdatingCurrent,
		totalPlaces: UInt = .maxPlacesEngineeringNotation
	) -> String {
		panic()
	}

	/// A human readable, locale respecting string. Does not perform any rounding or truncation.
	public func formattedPlain(
		locale: Locale = .autoupdatingCurrent,
		useGroupingSeparator: Bool = true
	) -> String {
		panic()
	}

	/// The digits of the number, without separators or sign. The scale is fixed at 18, meaning the last 18 digits correspond to the decimal part.
	public func digits() -> String {
		panic()
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
