import AppSettings
import Foundation
import Profile

public extension AccountWorthFetcher {
	static func live(
		tokenFetcher: TokenFetcher = .live,
		tokenWorthFetcher: TokenWorthFetcher = .live,
		appSettingsClient: AppSettingsClient = .live()
	) -> Self {
		Self(
			fetchWorth: { addresses in
				var totalWorth = [Profile.Account.Address: AccountPortfolioWorth]()

				var portfolioDictionary = [Profile.Account.Address: [Token]]()
				try await addresses.asyncForEach {
					portfolioDictionary[$0] = try await tokenFetcher.fetchTokens($0)
				}

				let currency = try await appSettingsClient.loadCurrency()

				try await portfolioDictionary.asyncForEach {
					let address = $0.key
					let tokens = $0.value
					let tokenContainers = try await tokenWorthFetcher.fetchWorth(tokens, currency)
					let worth = tokenContainers.compactMap(\.valueInCurrency).reduce(0, +)
					totalWorth[address] = .init(worth: worth, tokenContainers: tokenContainers)
				}

				return totalWorth
			}
		)
	}
}
