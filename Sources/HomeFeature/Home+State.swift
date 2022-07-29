import Foundation

// MARK: - Home
/// Namespace for HomeFeature
public enum Home {}

public extension Home {
	// MARK: State
	struct State: Equatable {
		public var walletIsVisible: Bool
		public var walletFiatTotalValue: Float
		public var walletCurrency: Currency
		public var accounts: [Account]
		public var radixHubUrlString: String

		public init(
			walletIsVisible: Bool = false,
			walletFiatTotalValue: Float = 0,
			walletCurrency: Currency = .usd,
			accounts: [Account] = [],
			radixHubUrlString: String = ""
		) {
			self.walletIsVisible = walletIsVisible
			self.walletFiatTotalValue = walletFiatTotalValue
			self.walletCurrency = walletCurrency
			self.accounts = accounts
			self.radixHubUrlString = radixHubUrlString
		}
	}
}

public extension Home {
	struct Account: Equatable {
		var userGeneratedName: String
		var systemGeneratedName: String
		var accountFiatTotalValue: Float
		var accountCurrency: Currency
	}
}

public extension Home {
	enum Currency: Equatable {
		case usd

		var symbol: String {
			switch self {
			case .usd:
				return "$"
			}
		}
	}
}
