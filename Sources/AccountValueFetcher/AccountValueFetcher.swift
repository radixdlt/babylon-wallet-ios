import AppSettings
import Common
import Foundation
import Profile

// MARK: - AccountValueFetcher
public struct AccountValueFetcher {
	public let tokenFetcher: TokenFetcher
	public let tokenWorthFetcher: TokenWorthFetcher
	public let appSettingsClient: AppSettingsClient

	public init(
		tokenFetcher: TokenFetcher = .init(),
		tokenWorthFetcher: TokenWorthFetcher = .init(),
		appSettingsClient: AppSettingsClient = .init()
	) {
		self.tokenFetcher = tokenFetcher
		self.tokenWorthFetcher = tokenWorthFetcher
		self.appSettingsClient = appSettingsClient
	}
}

// MARK: - Public Methods
public extension AccountValueFetcher {
	func fetchWorth(for addresses: [Profile.Account.Address]) -> [Profile.Account.Address: AccountPortfolioWorth] {
		var totalWorth = [Profile.Account.Address: AccountPortfolioWorth]()

		var portfolioDictionary = [Profile.Account.Address: [Token]]()
		addresses.forEach {
			portfolioDictionary[$0] = tokenFetcher.fetchTokens(for: $0)
		}

		let currency = appSettingsClient.loadCurrency()

		portfolioDictionary.forEach {
			let address = $0.key
			let tokens = $0.value
			let tokenContainers = tokenWorthFetcher.fetchWorth(for: tokens, in: currency)
			let worth = tokenContainers.compactMap(\.valueInCurrency).reduce(0, +)
			totalWorth[address] = .init(worth: worth, tokenContainers: tokenContainers)
		}

		return totalWorth
	}
}

// MARK: - TokenWorthContainer
public struct TokenWorthContainer: Equatable {
	public let token: Token
	public let valueInCurrency: Float?
}

// MARK: - AccountPortfolioWorth
public struct AccountPortfolioWorth: Equatable {
	public let worth: Float?
	public let tokenContainers: [TokenWorthContainer]
}
