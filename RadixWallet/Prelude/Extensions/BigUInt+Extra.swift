// MARK: - BigUInt + Sendable
extension BigUInt: @unchecked Sendable {}

// MARK: - BigUInt.Error
extension BigUInt {
	enum Error: Swift.Error {
		case initFromDecimalStringFailed
	}
}

extension BigUInt {
	init(decimalString: String) throws {
		guard let value = Self(decimalString, radix: 10) else {
			throw Error.initFromDecimalStringFailed
		}
		self = value
	}
}

extension BigUInt {
	var inAttos: Self {
		self * BigUInt(2).power(18)
	}
}
