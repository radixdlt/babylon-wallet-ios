import SargonUniFFI

extension Decimal192 {
	func toRawString() -> String {
		decimalToString(decimal: self)
	}
}

extension Decimal192 {
	func asDouble() throws -> Double {
		guard let double = Double(self.toRawString()) else {
			assertionFailure("Invalid decimal? how is it possible?")
			struct InvalidDecimalValue: Error {}
			throw InvalidDecimalValue()
		}
		return double
	}

	public var isPositive: Bool {
		fatalError()
	}
}
