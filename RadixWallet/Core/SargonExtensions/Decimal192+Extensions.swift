extension Decimal192 {
	func asDouble() throws -> Double {
		guard let double = Double(self.description) else {
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
