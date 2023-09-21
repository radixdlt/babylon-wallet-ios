import BigDecimal
import Foundation

// MARK: Formatting and parsing of human readable strings

extension BigDecimal {
//	public init?(
//		formattedString: String,
//		locale: Locale = .autoupdatingCurrent
//	) {
//
//
//		self.init(fromString: formattedString)
//	}

	/// A human readable, locale respecting but unrounded string
	public func formattedUnrounded(
		locale: Locale = .autoupdatingCurrent
	) -> String {
		formatted(roundedTo: UInt(Int.max), locale: locale)
	}

	/// A human readable, locale respecting string, rounded to the provided number of digits (including both the integral and decimal parts)
	public func formatted(
		roundedTo maxPlaces: UInt = BigDecimal.defaultMaxPlacesFormattted,
		locale: Locale = .autoupdatingCurrent
	) -> String {
		// If the number is too big to be formatted to maxPlaces, we use trillions and show all digits
		Formatter(decimal: self, maxPlaces: Int(maxPlaces), fallback: .trillion)
			.formattedString(decimalSeparator: locale.decimalSeparator ?? ".")
	}

	// A helper type for formatting BigDecimal
	private struct Formatter {
		private var sign: BigInt.Sign
		private var digits: String
		private var integers: Int
		private var multiplier: Multiplier = .one

		init(decimal: BigDecimal, maxPlaces: Int, fallback: Multiplier) {
			self.init(decimal: decimal)
			normalizeInteger()
			round(toPlaces: maxPlaces)
			digits.trimTrailingZeros()

			guard let newMultiplier = suitableMultiplier(maxPlaces: maxPlaces) else {
				self = Formatter(decimal: decimal)
				// We only get here if there are more integers than the biggest multiplier can handle
				round(toPlaces: integers - fallback.rawValue)
				applyMultiplier(fallback)
				return
			}

			applyMultiplier(newMultiplier)
		}

		/// Returns a formatted string, with the given separator
		func formattedString(decimalSeparator: String) -> String {
			guard digits.count > 0 else { return "0" }

			let signPart = sign == .minus ? "-" : ""
			// Check if we have any decimals
			guard integers < digits.count else {
				return signPart + digits + .zeros(length: integers - digits.count) + multiplierSuffix
			}

			let (integerPart, decimalPart) = digits.split(after: integers)
			return signPart + integerPart + decimalSeparator + decimalPart + multiplierSuffix
		}

		private init(decimal: BigDecimal) {
			self.sign = decimal.sign
			self.digits = decimal.integerValue.magnitude.description
			self.integers = digits.count - decimal.scale
		}

		/// Normalise digits so that they start with at least one zero before the decimal separator, for numbers < 1
		private mutating func normalizeInteger() {
			if integers < 1 {
				digits.padWithLeadingZeros(count: 1 - integers)
				integers = 1
			}
		}

		/// Rounds the number douwn to the given number of places (meaning total digits)
		private mutating func round(toPlaces maxPlaces: Int) {
			// Check if we even need to do any rounding
			let superfluousDigits = digits.count - maxPlaces
			guard superfluousDigits > 0 else { return }

			// We remove the superfluous digits, except one - it helps us decide to round or not
			digits.removeLast(superfluousDigits - 1)

			// Remove and examine the "following" digit (it's an optional, but is only nil for non-digits)
			let following = Int(String(digits.removeLast()))

			// If it's not 5 or higher, we don't need to do any rounding
			guard let following, following > 4 else { return }

			func roundUp() {
				// Remove the least significant digit
				guard let leastSignificant = Int(String(digits.removeLast())) else { return } // Can't fail

				if leastSignificant == 9 {
					// The last digit is "9", we might need to recurse
					guard !digits.isEmpty else {
						// We ran out of digits so we add a leading "1" and finish.
						digits = "1"
						integers += 1
						return
					}

					// We need to recurse. Note that we are not replacing the removed digit, because it is "0"
					roundUp()
				} else {
					// We simply increase the last digit and finish
					digits.append(contentsOf: String(leastSignificant + 1))
				}
			}

			roundUp()
		}

		private func suitableMultiplier(maxPlaces: Int) -> Multiplier? {
			/// The first multiplier that makes all the integers fit
			Multiplier.allCases.first { integers - $0.rawValue <= maxPlaces }
		}

		private mutating func applyMultiplier(_ newMultiplier: Multiplier) {
			integers -= newMultiplier.rawValue - multiplier.rawValue
			multiplier = newMultiplier
		}

		public enum Multiplier: Int, CaseIterable {
			case one = 0, million = 6, billion = 9, trillion = 12
		}

		private var multiplierSuffix: String {
			switch multiplier {
			case .one: return ""
			case .million: return " M"
			case .billion: return " B"
			case .trillion: return " T"
			}
		}

		struct NumberTooLong: Error {}
	}
}

private extension String {
	func split(after lengthOfFirstPart: Int) -> (String, String) {
		let lengthOfSecondPart = count - lengthOfFirstPart
		assert(lengthOfSecondPart >= 0)
		return (String(dropLast(lengthOfSecondPart)), String(suffix(lengthOfSecondPart)))
	}

	mutating func padWithLeadingZeros(count: Int) {
		insert(contentsOf: String.zeros(length: count), at: startIndex)
	}

	mutating func trimTrailingZeros() {
		while hasSuffix("0") {
			removeLast()
		}
	}

	static func zeros(length: Int) -> String {
		String(repeating: "0", count: length)
	}
}
