import Foundation
import Sargon

extension FiatCurrency {
	var currencyCode: String {
		switch self {
		case .usd:
			"USD"
		case .sek:
			"SEK"
		}
	}
}
