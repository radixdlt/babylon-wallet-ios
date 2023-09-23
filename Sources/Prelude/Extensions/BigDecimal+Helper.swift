import BigDecimal
import Foundation

// MARK: - BigDecimal.Helper
extension BigDecimal {
	// A helper type for formatting BigDecimal
	struct Helper {
		static let maxPlacesForEngineeringNotation = 4

		private var sign: BigInt.Sign
		/// All the digits in the number, without separators
		private var digits: String
		/// The exponent of the BigDecimal, if it were to be written in Scientific notation with normalised mantissa, i.e. m ∈ [1, 10)
		/// Add 1 to the exponent to get the number of integers in a number represented by `digits`
		private var exponent: Int

		private var multiplier: Multiplier = .one

		static func format(decimal: BigDecimal, maxPlaces: Int, decimalSeparator: String, groupingSeparator: String?) -> String {
			var helper = Helper(decimal: decimal)
			helper.normalizeInteger()
			let digitsToRemove = helper.digits.count - maxPlaces
			helper.round(byRemoving: digitsToRemove)
			helper.digits.trimTrailingZeros()

			if let newMultiplier = helper.suitableMultiplier(maxPlaces: maxPlaces) {
				helper.applyMultiplier(newMultiplier)
				return helper.formattedString(decimalSeparator: decimalSeparator, groupingSeparator: groupingSeparator)
			} else {
				// It may have happened that we removed too many digits, so we reset the helper
				helper = .init(decimal: decimal)
				helper.round(byRemoving: helper.digits.count - maxPlacesForEngineeringNotation)
				let shownExponent = helper.exponent
				// Normalise the mantissa
				helper.exponent = 0
				return helper.formattedString(decimalSeparator: decimalSeparator) + "e\(shownExponent)"
			}
		}

		static func reduceDecimals(_ decimal: inout BigDecimal, maxDecimals: Int, byRounding: Bool) throws {
			let decimalCount = max(0, decimal.scale)
			let decimalsToRemove = max(0, decimalCount - maxDecimals)
			guard decimalsToRemove > 0 else { return }

			var helper = Helper(decimal: decimal)
			if byRounding {
				helper.round(byRemoving: decimalsToRemove)
			} else {
				helper.digits.removeLast(decimalsToRemove)
			}
			helper.digits.trimTrailingZeros()

			let string = helper.machineReadableString()
			decimal = try BigDecimal(fromString: string)
		}

		private init(decimal: BigDecimal) {
			self.sign = decimal.sign
			self.digits = decimal.integerValue.magnitude.description
			self.exponent = digits.count - decimal.scale - 1
		}

		// Helper instance methods

		/// Returns a machine readable formatted string
		private func machineReadableString() -> String {
			formattedString(decimalSeparator: BigDecimal.machineReadableDecimalPartsSeparator)
		}

		/// Returns a formatted string, with the given separator
		private func formattedString(decimalSeparator: String, groupingSeparator: String? = nil) -> String {
			guard digits.count > 0 else { return "0" }

			let signPart = sign == .minus ? "-" : ""
			let integerCount = exponent + 1
			// Check if we have any decimals
			guard integerCount < digits.count else {
				// No decimals, the digits all represent the integer part
				var integerPart = digits
				integerPart.insertGroupingSeparatorInInteger(groupingSeparator)
				return signPart + integerPart + .zeros(length: integerCount - digits.count) + multiplierSuffix
			}

			var (integerPart, decimalPart) = digits.split(after: integerCount)
			integerPart.insertGroupingSeparatorInInteger(groupingSeparator)
			return signPart + integerPart + decimalSeparator + decimalPart + multiplierSuffix
		}

		/// Normalise digits so that they start with at least one zero before the decimal separator, for numbers < 1
		private mutating func normalizeInteger() {
			if exponent < 0 {
				digits.padWithLeadingZeros(count: -exponent)
				exponent = 0
			}
		}

		private mutating func round(byRemoving placesToRemove: Int) {
			// Check if we even need to do any rounding
			let superfluousDigits = placesToRemove
			guard superfluousDigits > 0 else { return }

			// We remove the superfluous digits, except one - it helps us decide to round or not
			digits.removeLast(superfluousDigits - 1)

			// Remove and examine the digit after the last kept digit (it's an optional, but is only nil for non-digits)
			let roundingDigit = Int(String(digits.removeLast()))

			// If it's not 5 or higher, we don't need to do any rounding
			guard let roundingDigit, roundingDigit > 4 else { return }

			func roundUp() {
				// Remove the least significant digit
				guard let leastSignificant = Int(String(digits.removeLast())) else { return } // Can't fail

				if leastSignificant == 9 {
					// The last digit is "9", we might need to recurse
					guard !digits.isEmpty else {
						// We ran out of digits so we add a leading "1" and finish.
						digits = "1"
						exponent += 1
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
			let integerCount = exponent + 1
			let allowedRange = integerCount - maxPlaces ..< integerCount
			return .allCases.last { allowedRange.contains($0.rawValue) }
		}

		private mutating func applyMultiplier(_ newMultiplier: Multiplier) {
			exponent -= newMultiplier.rawValue - multiplier.rawValue
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

	mutating func insertGroupingSeparatorInInteger(_ separator: String?) {
		let digits = count
		let separatorCount = (digits - 1) / 3
		guard let separator, separatorCount > 0 else { return }
		for i in 1 ... separatorCount {
			let location = index(startIndex, offsetBy: digits - 3 * i)
			insert(contentsOf: separator, at: location)
		}
	}

	static func zeros(length: Int) -> String {
		String(repeating: "0", count: length)
	}
}
