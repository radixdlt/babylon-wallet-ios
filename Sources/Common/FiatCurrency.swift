import Foundation

// FIXME: replace with Currency, it can be any currency
public enum FiatCurrency: String, Equatable, Codable {
	case usd
	case gbp
	case eur

	public var sign: String {
		switch self {
		case .usd:
			return "$"
		case .gbp:
			return "£"
		case .eur:
			return "€"
		}
	}

	public var symbol: String {
		rawValue.uppercased()
	}
}
