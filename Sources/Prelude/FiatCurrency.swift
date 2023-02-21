// MARK: - FiatCurrency
public enum FiatCurrency:
	String,
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpRepresentable
{
	case usd, eur, gbp, sek
}

extension FiatCurrency {
	public var sign: String {
		switch self {
		case .usd:
			return "$"
		case .gbp:
			return "£"
		case .eur:
			return "€"
		case .sek:
			return "kr"
		}
	}

	public var symbol: String {
		rawValue.uppercased()
	}
}
