import Foundation

// MARK: - BigUInt + Sendable
extension BigUInt: @unchecked Sendable {}

// MARK: - BigUInt.Error
extension BigUInt {
	public enum Error: Swift.Error {
		case initFromDecimalStringFailed
	}
}

extension BigUInt {
	public init(decimalString: String) throws {
		guard let value = Self(decimalString, radix: 10) else {
			throw Error.initFromDecimalStringFailed
		}
		self = value
	}
}

extension BigUInt {
	public var inAttos: Self {
		self * BigUInt(2).power(18)
	}
}
