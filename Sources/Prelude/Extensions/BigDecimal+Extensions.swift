import BigDecimal
import Foundation

extension BigDecimal {
	public func format(
		fiatCurrency: FiatCurrency,
		locale: Locale = .current
	) -> String {
		fiatCurrency.sign + format(locale: locale)
	}

	/// Formats the number for human consumtion
	public func format(
		maxPlaces maxPlacesNonNegative: UInt = 8,
		locale: Locale = .current
	) -> String {
		// N.B. We cannot use `Local.current.decimalSeperator` here because
		// `github.com/Zollerbo1/BigDecimal` package **hardcodes** usage of
		// the decimal separator ".", see this line here:
		// https://github.com/Zollerboy1/BigDecimal/blob/main/Sources/BigDecimal/BigDecimal.swift#L469
		let separatorRequiredByBigDecimalLib = "."
		let stringRepresentation = String(describing: self)

		guard
			case let components = stringRepresentation.split(separator: separatorRequiredByBigDecimalLib),
			components.count == 2
		else {
			return stringRepresentation
		}

		let integerPart = String(components[0])
		let decimalPart = String(components[1])

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

	/// The number as a Double, with the given precision
	public func toDouble(withPrecision precision: Int) throws -> Double {
		let stringValue = toString(withPrecision: precision)
		guard let doubleValue = Double(stringValue) else {
			throw BigDecimal.ConversionError.failedToCreateDouble(stringValue)
		}
		return doubleValue
	}

	/// Computer readable string representaton with full precision
	public func toString() -> String {
		description
	}

	/// Computer readable string representaton with the given precision
	public func toString(withPrecision precision: Int) -> String {
		withPrecision(precision).description
	}

	public enum ConversionError: Error, CustomStringConvertible {
		case failedToCreateDouble(String)

		public var description: String {
			switch self {
			case let .failedToCreateDouble(stringValue):
				return "Cannot create Double from \(stringValue)."
			}
		}
	}
}
