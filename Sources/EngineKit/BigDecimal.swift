import EngineToolkit
import Prelude

extension EngineToolkit.Decimal {
	public static let integerAndDecimalPartsSeparator = "."
}

extension EngineToolkit.Decimal {
	public func asBigDecimal() throws -> BigDecimal {
		try .init(fromString: asStr())
	}
}

extension BigDecimal {
	public func asDecimal(withDivisibility divisibility: UInt) throws -> EngineToolkit.Decimal {
		let stringRepresentation = String(describing: self)

		guard
			case let integerAndDecimalParts = stringRepresentation.split(
				separator: BigDecimal.integerAndDecimalPartsSeparator
			),
			integerAndDecimalParts.count == 2
		else {
			return try .init(value: stringRepresentation)
		}

		let integerPart = String(integerAndDecimalParts[0])
		let decimalPart = String(integerAndDecimalParts[1].prefix(Int(divisibility)))

		return try .init(
			value: [
				integerPart,
				decimalPart,
			].joined(separator: EngineToolkit.Decimal.integerAndDecimalPartsSeparator)
		)
	}
}
