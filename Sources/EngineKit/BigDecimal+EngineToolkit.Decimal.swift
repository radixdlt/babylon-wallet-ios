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
	public func asDecimal(withDivisibility divisibility: Int? = nil) throws -> EngineToolkit.Decimal {
		let (integerPart, decimalPart) = integerAndDecimalPart(withDivisibility: divisibility ?? 18)

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
