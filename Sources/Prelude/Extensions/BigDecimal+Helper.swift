import BigDecimal
import Foundation

// MARK: - BigDecimal.Helper
extension BigDecimal {
	// A helper type for formatting BigDecimal
	struct Helper {
		static let maxPlacesForEngineeringNotation = 4

		private var sign: BigInt.Sign
		private var digits: String
		private var integers: Int
		private var multiplier: Multiplier = .one

		static func format(decimal: BigDecimal, maxPlaces: Int, decimalSeparator: String) -> String {
			var helper = Helper(decimal: decimal)
			helper.normalizeInteger()
			let digitsToRemove = helper.digits.count - maxPlaces
			helper.round(byRemoving: digitsToRemove)
			helper.digits.trimTrailingZeros()

			if let newMultiplier = helper.suitableMultiplier(maxPlaces: maxPlaces) {
				helper.applyMultiplier(newMultiplier)
			} else {
				if maxPlaces < maxPlacesForEngineeringNotation {
					// if maxPlaces is too low, we might have removed too many digits already, need to start over
					helper = .init(decimal: decimal)
				}
				// If the number is too big to be formatted to maxPlaces, we use engineering notation
				helper.round(byRemoving: helper.digits.count - maxPlacesForEngineeringNotation)
				let exponent = helper.integers - 1
				// Normalise the mantissa
				helper.integers = 1
				return helper.formattedString(decimalSeparator: decimalSeparator) + "e\(exponent)"
			}

			return helper.formattedString(decimalSeparator: decimalSeparator)
		}

		static func reduceDecimals(_ decimal: inout BigDecimal, maxDecimals: Int, byRounding: Bool) throws {
			var helper = Helper(decimal: decimal)
			let decimalCount = max(0, decimal.scale)
			let decimalsToRemove = max(0, decimalCount - maxDecimals)
			guard decimalsToRemove > 0 else { return }
			if byRounding {
				helper.round(byRemoving: decimalsToRemove)
				helper.digits.trimTrailingZeros()
			} else {
				helper.digits.removeLast(decimalsToRemove)
				helper.digits.trimTrailingZeros()
			}

			let string = helper.formattedString(decimalSeparator: BigDecimal.machineReadableDecimalPartsSeparator)
			decimal = try BigDecimal(fromString: string)
		}

		private init(decimal: BigDecimal) {
			self.sign = decimal.sign
			self.digits = decimal.integerValue.magnitude.description
			self.integers = digits.count - decimal.scale
		}

		// Helper instance methods

		/// Returns a formatted string, with the given separator
		private func formattedString(decimalSeparator: String) -> String {
			guard digits.count > 0 else { return "0" }

			let signPart = sign == .minus ? "-" : ""
			// Check if we have any decimals
			guard integers < digits.count else {
				return signPart + digits + .zeros(length: integers - digits.count) + multiplierSuffix
			}

			let (integerPart, decimalPart) = digits.split(after: integers)
			return signPart + integerPart + decimalSeparator + decimalPart + multiplierSuffix
		}

		/// Normalise digits so that they start with at least one zero before the decimal separator, for numbers < 1
		private mutating func normalizeInteger() {
			if integers < 1 {
				digits.padWithLeadingZeros(count: 1 - integers)
				integers = 1
			}
		}

		private mutating func round(byRemoving placesToRemove: Int) {
			// Check if we even need to do any rounding
			let superfluousDigits = placesToRemove
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

		// Use e.g. millions starting from 1 million
		private func suitableMultiplier(maxPlaces: Int) -> Multiplier? {
			let allowedRange = integers - maxPlaces ..< integers
			return .allCases.last { allowedRange.contains($0.rawValue) }
		}

		// Using the smallest multiplier that fits all integers - not used currently
		private func suitableMultiplierCommentStyle(maxPlaces: Int) -> Multiplier? {
			.allCases.first { integers - $0.rawValue <= maxPlaces }
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
