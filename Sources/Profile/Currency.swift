import Foundation

public enum Currency: String, Equatable {
	case usd

	public var symbol: String {
		switch self {
		case .usd:
			return "$"
		}
	}

	public var code: String {
		rawValue.uppercased()
	}
}
