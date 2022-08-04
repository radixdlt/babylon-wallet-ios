import Foundation

public enum Currency: Equatable {
	case usd

	var symbol: String {
		switch self {
		case .usd:
			return "$"
		}
	}
}
