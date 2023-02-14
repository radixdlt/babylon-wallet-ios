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

	public enum FormattingPlacement: Sendable, Hashable {
		/// used by `USD`, `GDP`, `EUR`
		case leading

		/// used by `SEK`
		case traling
	}

	public var formattingPlacement: FormattingPlacement {
		switch self {
		case .eur, .usd, .gbp: return .leading
		case .sek: return .traling
		}
	}

	public var symbol: String {
		rawValue.uppercased()
	}
}
