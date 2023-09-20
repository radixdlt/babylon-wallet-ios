import EngineToolkit
import Prelude

extension EngineToolkit.Decimal {
	public static let integerAndDecimalPartsSeparator = "."
	public static let maxDivisibility = 18
}

extension EngineToolkit.Decimal {
	public func asBigDecimal() throws -> BigDecimal {
		try .init(fromString: asStr())
	}
}

extension BigDecimal {
	public func asDecimal(withDivisibility divisibility: Int? = nil) throws -> EngineToolkit.Decimal {
		return try .init(value: self.toString())
		let (integerPart, decimalPart) = integerAndDecimalPart(
			withDivisibility: divisibility ?? EngineToolkit.Decimal.maxDivisibility
		)

		return try .init(
			value: [
				integerPart,
				decimalPart,
			]
			.compactMap(identity)
			.joined(separator: EngineToolkit.Decimal.integerAndDecimalPartsSeparator)
		)
	}
}
