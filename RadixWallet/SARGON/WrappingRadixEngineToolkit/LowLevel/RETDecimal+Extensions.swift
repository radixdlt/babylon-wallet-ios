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
//		try! round(decimalPlaces: Int32(decimalPlaces), roundingMode: .toZero)
		panic()
	}

	/// Rounds to `decimalPlaces` decimals, in the direction away from zero
	public func ceil(decimalPlaces: UInt) -> RETDecimal {
		panic()
//		try! round(decimalPlaces: Int32(decimalPlaces), roundingMode: .awayFromZero)
	}

	/// Rounds to `decimalPlaces` decimals
	public func rounded(decimalPlaces: UInt = 0) -> RETDecimal {
		panic()
//		try! round(decimalPlaces: Int32(decimalPlaces), roundingMode: .toNearestMidpointAwayFromZero)
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
	public init(
		formattedString: String,
		locale: Locale = .autoupdatingCurrent
	) throws {
		// Pad with a leading zero, to make numbers with leading decimal separator parsable
		var string = "0" + formattedString
		// If the locale recognizes a grouping separator, we strip that from the string
		if let groupingSeparator = locale.groupingSeparator {
			string.replace(groupingSeparator, with: "")
		}
		// If the locale recognizes a decimal separator that is different from the machine readable one, we replace it with that
		if let decimalSeparator = locale.decimalSeparator, decimalSeparator != RETDecimal.machineReadableDecimalSeparator {
			string.replace(decimalSeparator, with: RETDecimal.machineReadableDecimalSeparator)
		}

//		try self.init(value: string)
		panic()
	}

	/// A human readable, locale respecting string, rounded to `totalPlaces` places, counting all digits
	public func formatted(
		locale: Locale = .autoupdatingCurrent,
		totalPlaces: UInt = .defaultMaxPlacesFormatted,
		useGroupingSeparator: Bool = true
	) -> String {
		func format(_ number: RETDecimal) -> String {
			number.formattedPlain(locale: locale, useGroupingSeparator: useGroupingSeparator)
		}

		let roundedToTotalPlaces = rounded(totalPlaces: totalPlaces)

		if let multiplier = roundedToTotalPlaces.multiplier() {
			let scaled = roundedToTotalPlaces / multiplier.value
			let integerCount = scaled.digits().count - RETDecimal.scale
			guard integerCount <= totalPlaces else {
				return formattedEngineeringNotation(locale: locale, totalPlaces: .maxPlacesEngineeringNotation)
			}
			return format(scaled) + " " + multiplier.suffix
		} else {
			return format(roundedToTotalPlaces)
		}
	}

	public func formattedEngineeringNotation(
		locale: Locale = .autoupdatingCurrent,
		totalPlaces: UInt = .maxPlacesEngineeringNotation
	) -> String {
		let rounded = rounded(totalPlaces: totalPlaces)
		let integerCount = rounded.digits().count - RETDecimal.scale
		let exponent = UInt(integerCount - 1)
		let scaled = rounded / .init(exponent: exponent)

		return scaled.formattedPlain(locale: locale, useGroupingSeparator: false) + "e\(exponent)"
	}

	/// A human readable, locale respecting string. Does not perform any rounding or truncation.
	public func formattedPlain(
		locale: Locale = .autoupdatingCurrent,
		useGroupingSeparator: Bool = true
	) -> String {
		guard !isZero() else { return "0" }

		let sign = isNegative() ? "-" : ""
		let decimalSeparator = locale.decimalSeparator ?? "."

		let digits = digits()
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

	/// The digits of the number, without separators or sign. The scale is fixed at 18, meaning the last 18 digits correspond to the decimal part.
	public func digits() -> String {
//		do {
//			return try abs().mantissa()
//		} catch {
//			assertionFailure("RETDecimal: Failed to get digits from \(asStr())")
//			return mantissa().replacingOccurrences(of: "-", with: "")
//		}
		panic()
	}

	/// Rounds to `totalPlaces` digits, counting both the integer and decimal parts, as well as any leading zeros
	private func rounded(totalPlaces: UInt) -> RETDecimal {
		let digits = digits()
		// If we only have decimals, we will still count the 0 before the separator as an integer
		let integerCount = UInt(Swift.max(digits.count - RETDecimal.scale, 1))
		if integerCount > totalPlaces {
			let scale = RETDecimal(exponent: integerCount - totalPlaces)
			return (self / scale).rounded(decimalPlaces: 0) * scale
		} else {
			// The remaining digits are decimals and we keep up to totalPlaces of them
			let decimalsToKeep = totalPlaces - integerCount
			return rounded(decimalPlaces: decimalsToKeep)
		}
	}

	private func multiplier() -> Multiplier? {
//		guard let abs = try? abs() else { return nil }
//		return Multiplier.allCases.last(where: { $0.value <= abs })
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
