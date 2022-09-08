import AppSettings
import Profile

public extension AccountWorthFetcher {
	static func live(
		tokenFetcher: TokenFetcher = .live,
		tokenWorthFetcher: TokenWorthFetcher = .live,
		appSettingsClient: AppSettingsClient = .live()
	) -> Self {
		Self(
			fetchWorth: { addresses in
				let portfolioDictionary = try await withThrowingTaskGroup(
					of: (address: Profile.Account.Address, tokens: [Token]).self,
					returning: [Profile.Account.Address: [Token]].self,
					body: { taskGroup in
						for address in addresses {
							taskGroup.addTask {
								let tokens = try await tokenFetcher.fetchTokens(address)
								return (address, tokens)
							}
						}

						var portfolioDictionary = [Profile.Account.Address: [Token]]()
						for try await result in taskGroup {
							portfolioDictionary[result.address] = result.tokens
						}

						return portfolioDictionary
					}
				)

				let currency = try await appSettingsClient.loadSettings().currency

				let totalWorth = try await withThrowingTaskGroup(
					of: (address: Profile.Account.Address, tokenContainers: [TokenWorthContainer]).self,
					returning: AccountsWorth.self,
					body: { taskGroup in
						for element in portfolioDictionary {
							taskGroup.addTask {
								let address = element.key
								let tokens = element.value
								let tokenContainers = try await tokenWorthFetcher.fetchWorth(tokens, currency)
								return (address, tokenContainers)
							}
						}

						var totalWorth = AccountsWorth()
						for try await result in taskGroup {
							totalWorth[result.address] = .init(tokenContainers: result.tokenContainers)
						}

						return totalWorth
					}
				)

				return totalWorth
			}
		)
	}
}
