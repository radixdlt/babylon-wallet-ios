// MARK: - FiatCurrency
public enum FiatCurrency:
	String,
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpRepresentable
{
	case usd
}
