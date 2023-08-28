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
		try .init(value: self.toString(withPrecision: Self.EngineKitDecimalPrecision))
	}
}
