import BigDecimal

extension BigDecimal {
	public func format(maxPlaces: Int = 8) -> String {
		let separator = "."
		let stringRepresentation = String(describing: self)

		guard
			case let components = stringRepresentation.split(separator: separator),
			components.count == 2
		else {
			return stringRepresentation
		}

		let integerPart = String(components[0])
		let decimalPart = components[1]
		let numberOfDecimalDigits = max(maxPlaces - integerPart.count, 1)

		let truncatedDecimalPart = String(decimalPart.prefix(numberOfDecimalDigits))
		return [
			integerPart,
			truncatedDecimalPart,
		].joined(separator: separator)
	}
}
