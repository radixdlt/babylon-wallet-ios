import EngineToolkit
import Prelude

extension EngineToolkit.Decimal {
	public func asBigDecimal() throws -> BigDecimal {
		try .init(fromString: asStr())
	}
}

extension BigDecimal {
	static let EngineKitDecimalPrecision = 18
	public func intoEngine() throws -> EngineToolkit.Decimal {
		let value = withPrecision(Self.EngineKitDecimalPrecision).droppingTrailingZeros.toString()
		return try .init(value: value)
	}
}
