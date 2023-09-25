import Foundation

public typealias RETDecimal = EngineToolkit.Decimal

// MARK: Arithmetic operators

extension RETDecimal {
	public static func + (lhs: RETDecimal, rhs: RETDecimal) throws -> RETDecimal {
		try lhs.add(other: rhs)
	}

	public static func - (lhs: RETDecimal, rhs: RETDecimal) throws -> RETDecimal {
		try lhs.sub(other: rhs)
	}

	public static func * (lhs: RETDecimal, rhs: RETDecimal) throws -> RETDecimal {
		try lhs.mul(other: rhs)
	}

	public static func / (lhs: RETDecimal, rhs: RETDecimal) throws -> RETDecimal {
		try lhs.div(other: rhs)
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
}

// MARK: Truncation and rounding

extension RETDecimal {
	/// Truncates to `decimalPlaces` decimals
	public func truncated(decimalPlaces: UInt) throws -> RETDecimal {
		try round(decimalPlaces: Int32(decimalPlaces), roundingMode: .toZero)
	}

	/// Rounds to `decimalPlaces` decimals
	public func rounded(decimalPlaces: UInt) throws -> RETDecimal {
		try round(decimalPlaces: Int32(decimalPlaces), roundingMode: .toNearestMidpointAwayFromZero)
	}
}

// MARK: Parsing and formatting for human readable strings

extension UInt {
	public static let defaultMaxPlacesFormatted: UInt = 8
	public static let maxPlacesEngineeringNotation: UInt = 4
}

extension RETDecimal {
	public static let machineReadableDecimalSeparator = "."
	public static let scale: Int = 18

	/// Parse a local respecting string
	public convenience init(
		formattedString: String,
		locale: Locale = .autoupdatingCurrent
	) throws {
		var string = formattedString
		// If the locale recognizes a grouping separator, we strip that from the string
		if let groupingSeparator = locale.groupingSeparator {
			string.replace(groupingSeparator, with: "")
		}
		// If the locale recognizes a decimal separator that is different from the machine readable one, we replace it with that
		if let decimalSeparator = locale.decimalSeparator, decimalSeparator != RETDecimal.machineReadableDecimalSeparator {
			string.replace(decimalSeparator, with: RETDecimal.machineReadableDecimalSeparator)
		}

		try self.init(value: string)
	}

	/// A human readable, locale respecting string, rounded to `totalPlaces` places, counting all digits
	public func formatted(
		locale: Locale = .autoupdatingCurrent,
		totalPlaces: UInt = .defaultMaxPlacesFormatted,
		useGroupingSeparator: Bool = true
	) throws -> String {
		func format(_ number: RETDecimal) throws -> String {
			try number.formattedPlain(locale: locale, useGroupingSeparator: useGroupingSeparator)
		}

		let roundedToTotalPlaces = try rounded(totalPlaces: totalPlaces)

		if let multiplier = try roundedToTotalPlaces.multiplier() {
			let scaled = try roundedToTotalPlaces / multiplier.value
			let integerCount = try scaled.abs().mantissa().count - RETDecimal.scale
			guard integerCount <= totalPlaces else {
				return try formattedEngineeringNotation(locale: locale, totalPlaces: .maxPlacesEngineeringNotation)
			}
			return try format(scaled) + " " + multiplier.suffix
		} else {
			return try format(roundedToTotalPlaces)
		}
	}

	public func formattedEngineeringNotation(
		locale: Locale = .autoupdatingCurrent,
		totalPlaces: UInt = .maxPlacesEngineeringNotation
	) throws -> String {
		let rounded = try rounded(totalPlaces: totalPlaces)
		let integerCount = try rounded.abs().mantissa().count - RETDecimal.scale
		let exponent = UInt(integerCount - 1)
		let scaled = try rounded / .init(exponent: exponent)

		return try scaled.formattedPlain(locale: locale, useGroupingSeparator: false) + "e\(exponent)"
	}

	/// A human readable, locale respecting string. Does not perform any rounding or truncation.
	public func formattedPlain(
		locale: Locale = .autoupdatingCurrent,
		useGroupingSeparator: Bool = true
	) throws -> String {
		guard !isZero() else { return "0" }

		let sign = isNegative() ? "-" : ""
		let decimalSeparator = locale.decimalSeparator ?? "."

		let digits = try abs().mantissa()
		let integerCount = digits.count - RETDecimal.scale
		let trailingZeroCount = digits.trailingZeroCount

		var (integerPart, decimalPart) = digits.split(after: integerCount)

		if integerCount <= 0 {
			// If we don't have any integers, we just use "0"
			integerPart = "0"
		} else if useGroupingSeparator, let groupingSeparator = locale.groupingSeparator {
			integerPart.insertGroupingSeparatorInInteger(groupingSeparator)
		}

		if trailingZeroCount >= RETDecimal.scale {
			// No non-zero decimals, we only have an integerpart
			return sign + integerPart
		} else {
			let zerosToPad = Swift.max(-integerCount, 0)
			return sign + integerPart + decimalSeparator + .zeros(length: zerosToPad) + decimalPart.dropLast(trailingZeroCount)
		}
	}

	/// Rounds to `totalPlaces` digits, counting both the integer and decimal parts, as well as any leading zeros
	private func rounded(totalPlaces: UInt) throws -> RETDecimal {
		let digits = try abs().mantissa()
		// If we only have decimals, we will still count the 0 before the separator as an integer
		let integerCount = UInt(Swift.max(digits.count - 18, 1))
		if integerCount > totalPlaces {
			let scale = RETDecimal(exponent: integerCount - totalPlaces)
			return try (self / scale).rounded(decimalPlaces: 0) * scale
		} else {
			// The remaining digits are decimals and we keep up to totalPlaces of them
			let decimalsToKeep = totalPlaces - integerCount
			return try rounded(decimalPlaces: decimalsToKeep)
		}
	}

	private func multiplier() throws -> Multiplier? {
		let abs = try abs()
		return Multiplier.allCases.last(where: { $0.value <= abs })
	}
}

extension RETDecimal {
	/// Creares the Decimal `10^exponent`
	public convenience init(exponent: UInt) {
		try! self.init(value: "1" + .zeros(length: Int(exponent)))
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
		case .million: return "M"
		case .billion: return "B"
		case .trillion: return "T"
		}
	}
}

private extension String {
	func split(after lengthOfFirstPart: Int) -> (String, String) {
		let lengthOfSecondPart = count - lengthOfFirstPart
		assert(lengthOfSecondPart >= 0)
		return (String(dropLast(lengthOfSecondPart)), String(suffix(lengthOfSecondPart)))
	}

	mutating func insertGroupingSeparatorInInteger(_ separator: String) {
		let digits = count
		let separatorCount = (digits - 1) / 3
		guard separatorCount > 0 else { return }
		for i in 1 ... separatorCount {
			let location = index(startIndex, offsetBy: digits - 3 * i)
			insert(contentsOf: separator, at: location)
		}
	}

	static func zeros(length: Int) -> String {
		String(repeating: "0", count: length)
	}

	var trailingZeroCount: Int {
		reversed().enumerated().first { $0.element != "0" }?.offset ?? count
	}
}
