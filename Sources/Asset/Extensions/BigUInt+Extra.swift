import BigInt

// MARK: - BigUInt + Sendable
extension BigUInt: @unchecked Sendable {}

extension BigUInt {
	init?(decimalString: String) throws {
		self.init(decimalString, radix: 10)
	}
}

extension BigUInt {
	var inAttos: Self {
		self * BigUInt(2).power(18)
	}
}
