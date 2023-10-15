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
			"$"
		case .gbp:
			"£"
		case .eur:
			"€"
		case .sek:
			"kr"
		}
	}

	public var symbol: String {
		rawValue.uppercased()
	}
}
