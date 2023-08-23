import EngineToolkit
import Prelude

extension EngineToolkit.Decimal {
	public func asBigDecimal() throws -> BigDecimal {
		try .init(fromString: asStr())
	}
}

extension BigDecimal {
	public func intoEngine() throws -> EngineToolkit.Decimal {
		try .init(value: toString())
	}
}
