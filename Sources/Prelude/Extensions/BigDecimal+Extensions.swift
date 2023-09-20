import BigDecimal
import Foundation

extension BigDecimal {
	// Used for development purposes
	public static let temporaryStandardFee: BigDecimal = 25
	public static let defaultMaxPlacesFormattted: UInt = 8

	// N.B. We cannot use `Local.current.decimalSeperator` here because
	// `github.com/Zollerbo1/BigDecimal` package **hardcodes** usage of
	// the decimal separator ".", see this line here:
	// https://github.com/Zollerboy1/BigDecimal/blob/main/Sources/BigDecimal/BigDecimal.swift#L469
	public static let integerAndDecimalPartsSeparator = "."
}

extension BigDecimal {
	public func format(
		fiatCurrency: FiatCurrency,
		locale: Locale = .autoupdatingCurrent
	) -> String {
		fiatCurrency.sign + format(locale: locale)
	}

	public func integerAndDecimalPart(withDivisibility divisibility: Int?) -> (String, String?) {
		let stringRepresentation = String(describing: self)

		guard
			case let components = stringRepresentation.split(
				separator: Self.integerAndDecimalPartsSeparator
			),
			components.count == 2
		else {
			return (stringRepresentation, nil)
		}

		let integerPart = String(components[0])
		let decimalPart = String({
			let decimalComponents = components[1]
			guard let divisibility else {
				return decimalComponents
			}

			guard divisibility > .zero else {
				return ""
			}

			return decimalComponents.prefix(divisibility)
		}())

		return (integerPart, decimalPart.isEmpty ? nil : decimalPart)
	}

	/// Formats the number for human consumtion
	public func format(
		maxPlaces maxPlacesNonNegative: UInt = BigDecimal.defaultMaxPlacesFormattted,
		divisibility: Int? = nil,
		locale: Locale = .autoupdatingCurrent
	) -> String {
		let (integerPart, decimalPart) = integerAndDecimalPart(withDivisibility: divisibility)
		guard let decimalPart else {
			return integerPart
		}

		let numberOfDecimalDigits = max(1, Int(maxPlacesNonNegative) - integerPart.count)

		let decimalSeparatorMaybeAccordingToLocal = locale.decimalSeparator ?? "."
		let decimalPartPrefixWith0AndSeparator = "0" + decimalSeparatorMaybeAccordingToLocal + decimalPart

		// N.B. that this will format => `0.99999999999999999` as "0.9999999", and not as `"1"` (which we want)
		func nonRoundedFormatting() -> String {
			let truncatedDecimalPart = String(decimalPart.prefix(numberOfDecimalDigits))

			return [
				integerPart,
				truncatedDecimalPart,
			].joined(separator: decimalSeparatorMaybeAccordingToLocal)
		}

		guard let decimal = Foundation.Decimal(string: decimalPartPrefixWith0AndSeparator, locale: locale) else {
			// for some reason failed to create `Decimal` => fallback to non rounded formatting.
			return nonRoundedFormatting()
		}

		let numberFormatter = NumberFormatter()
		numberFormatter.locale = locale
		numberFormatter.maximumFractionDigits = numberOfDecimalDigits
		guard let formattedDecimalPartWith0AndSeparator = numberFormatter.string(for: decimal) else {
			return nonRoundedFormatting()
		}

		let componentsFromDecimal = formattedDecimalPartWith0AndSeparator.split(separator: decimalSeparatorMaybeAccordingToLocal)

		guard componentsFromDecimal.count == 2 else {
			assert(componentsFromDecimal.count == 1, "What 0 or over 2 components should not be possible?")
			if let bigInt = try? BigDecimal(fromString: integerPart) {
				return bigInt.isZero ? formattedDecimalPartWith0AndSeparator : integerPart
			} else {
				return nonRoundedFormatting()
			}
		}

		return [
			integerPart,
			String(componentsFromDecimal[1]),
		].joined(separator: decimalSeparatorMaybeAccordingToLocal)
	}

	public var droppingTrailingZeros: BigDecimal {
		var result = self
		while result.integerValue.isMultiple(of: 10), result.scale > 0 {
			result = result.withScale(result.scale - 1)
		}

		return result
	}

	/// Outputs a locale respecting string, without rounding.
	public func formatWithoutRounding(locale: Locale = .autoupdatingCurrent) -> String {
		var absoluteIntegerValue = self.integerValue.magnitude.description

		let (before, after): (String, String) = {
			if self.scale >= absoluteIntegerValue.count {
				let after = String(repeating: "0", count: self.scale - absoluteIntegerValue.count) + absoluteIntegerValue
				return ("0", after)
			} else {
				let location = absoluteIntegerValue.count - self.scale
				if location > absoluteIntegerValue.count {
					let zeros = String(repeating: "0", count: location - absoluteIntegerValue.count)
					return (absoluteIntegerValue + zeros, "")
				} else {
					let afterLength = absoluteIntegerValue.count - location
					let after = absoluteIntegerValue.suffix(afterLength)
					absoluteIntegerValue.removeLast(afterLength)
					return (absoluteIntegerValue, String(after))
				}
			}
		}()

		let sign = self.sign == .minus ? "-" : ""

		let decimalSeparator = locale.decimalSeparator ?? "."

		return sign + (after.isEmpty ? before : "\(before)\(decimalSeparator)\(after)")
	}

	/// Creates a `BigDecimal` from a string, respecting the users locale w.r.t decimal separator
	@inlinable public init<S>(localizedFromString string: S, locale: Locale = .autoupdatingCurrent) throws where S: StringProtocol {
		func strippingGroupingSeparator(_ string: S) -> String {
			guard let groupingSeparator = locale.groupingSeparator else { return String(string) }
			return string.replacingOccurrences(of: groupingSeparator, with: "")
		}

		let stripped = strippingGroupingSeparator(string)

		if let decimalSeparator = locale.decimalSeparator, decimalSeparator != ".", stripped.contains(decimalSeparator) {
			guard stripped != decimalSeparator else {
				throw ConversionError.onlyDecimalSeparator
			}

			let converted = stripped.replacingOccurrences(of: decimalSeparator, with: ".")
			try self.init(fromString: converted)
			return
		}

		try self.init(fromString: stripped)
	}

	/// The number as a Double, with the given `precision`. Uses "." as decimal separator.
	public func toDouble(withPrecision precision: Int) throws -> Double {
		let stringValue = toString(withPrecision: precision)
		guard let doubleValue = Double(stringValue) else {
			throw BigDecimal.ConversionError.failedToCreateDouble(stringValue)
		}
		return doubleValue
	}

	/// Computer readable string representaton with full precision. Uses "." as decimal separator.
	public func toString() -> String {
		description
	}

	/// Computer readable string representaton with the given `precision`. Uses "." as decimal separator.
	public func toString(withPrecision precision: Int) -> String {
		withPrecision(precision).description
	}

	/// Computer readable string representaton with the given `scale`. Uses "." as decimal separator.
	public func toString(withScale scale: Int) -> String {
		withScale(scale).description
	}

	public enum ConversionError: Error, CustomStringConvertible {
		case failedToCreateDouble(String)
		case onlyDecimalSeparator

		public var description: String {
			switch self {
			case let .failedToCreateDouble(stringValue):
				return "Cannot create Double from \(stringValue)."
			case .onlyDecimalSeparator:
				return "Cannot create BigDecimal from just the decimal separator."
			}
		}
	}
}

extension BigDecimal {
	struct Digits {
		var string: String
		var integers: Int
		var count: Int { string.count }

		func withSeparator(_ separator: String, after charactersBeforeSeparator: Int) -> String {
			assert(charactersBeforeSeparator < count)
//			let padded = string + .zeroPadding(length: max(charactersBeforeSeparator - count, 0))
//
			let before = String(string.prefix(charactersBeforeSeparator))
			let after = String(string.suffix(count - charactersBeforeSeparator))
			return before + separator + after
		}
	}

	public func new_format(
		maxPlaces: UInt = BigDecimal.defaultMaxPlacesFormattted,
		locale: Locale = .autoupdatingCurrent
	) -> String {
		let signPart = sign == .minus ? "-" : ""
		var digits = digits()
		let separator = locale.decimalSeparator ?? "."

		// The Digits type tracks the number of integers, since we round without regard for decimal separator position
		round(digits: &digits, toPlaces: maxPlaces)

		if digits.integers > maxPlaces {
			if digits.integers > 12 {
				// 1,234,234,333,234.2343242342
				// 12342343
				// 1 . 2342343

				return signPart + digits.withSeparator(separator, after: digits.integers - 12) + " T"
			} else if digits.integers > 9 {
				// 34234333234.2343242342
				// 34234333
				// 34 234333
				return signPart + digits.withSeparator(separator, after: digits.integers - 9) + " B"
			} else if digits.count > 8 {}
		}
	}

	private func digits() -> Digits {
		let integerPart, decimalPart: String

		// The magnitude of the underlying integer value, as a string
		let magnitude = integerValue.magnitude.description

		if scale >= magnitude.count {
			// No integer part. Pad magnitude part with leading zeros as needed to get decimal part.
			integerPart = "0"
			decimalPart = .zeroPadding(length: scale - magnitude.count) + magnitude
		} else {
			let location = magnitude.count - scale
			if location > magnitude.count {
				// No decimal part. Pad magnitude part with trailing zeros as needed to get integer part.
				integerPart = magnitude + .zeroPadding(length: location - magnitude.count)
				decimalPart = ""
			} else {
				// General case. Take the last digits as decimals.
				let decimalCount = magnitude.count - location
				integerPart = String(magnitude.dropLast(decimalCount))
				decimalPart = String(magnitude.suffix(decimalCount))
			}
		}

		return Digits(string: integerPart + decimalPart, integers: integerPart.count)
	}

	/// Rounds the sequence of digits, ignoring trailing zeros and not taking decimal position into account.
	private func round(digits: inout Digits, toPlaces maxPlaces: UInt) {
		// Check if we even need to do any rounding
		let superfluousDigits = digits.count - Int(maxPlaces)
		guard superfluousDigits > 0 else { return }

		// We remove the superfluous digits, except the one that follows the last one we will be keeping
		digits.string.removeLast(superfluousDigits - 1)

		// Remove and examine the "following" digit (it's optional, but is only nil for non-digits)
		let following = Int(String(digits.string.removeLast()))

		// If it's not 5 or higher, we don't need to do any rounding
		guard let following, following > 4 else { return }

		func roundUp() {
			// Remove the least significant digit
			guard let leastSignificant = Int(String(digits.string.removeLast())) else { return } // Can't fail

			if leastSignificant == 9 {
				// The last digit is "9", we might need to recurse
				guard !digits.string.isEmpty else {
					// We ran out of digits so we add a leading "1" and finish.
					digits.string = "1"
					digits.integers += 1
					return
				}

				// We need to recurse. Note that we are not replacing the removed digit because it is "0"
				roundUp()
			} else {
				// We simply increase the last digit and finish
				digits.string.append(contentsOf: String(leastSignificant + 1))
			}
		}

		roundUp()

//		// We pad the result back up to maxPlaces digits
//		let missingDigits = Int(maxPlaces) - digits.count
//		digits.string.append(contentsOf: zeroPadding(length: missingDigits))
	}

	// Trim the decimal part as needed
	private func trim(decimalPart: inout String) {
		while decimalPart.hasSuffix("0") {
			decimalPart.removeLast()
		}
	}
}

private extension String {
	static func zeroPadding(length: Int) -> String {
		String(repeating: "0", count: length)
	}
}

extension BigDecimal {
	public var clamped: BigDecimal {
		max(0, self)
	}

	public func clampedDiff(_ other: BigDecimal) -> BigDecimal {
		(self - other).clamped
	}
}
