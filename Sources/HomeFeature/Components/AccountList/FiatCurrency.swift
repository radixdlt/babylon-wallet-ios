import Foundation

public enum FiatCurrency: String, Equatable {
	case usd

	public var sign: String {
		switch self {
		case .usd:
			return "$"
		}
	}

	public var symbol: String {
		rawValue.uppercased()
	}
}
