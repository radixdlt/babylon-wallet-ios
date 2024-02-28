// MARK: - AccountPortfoliosClient + DependencyKey
extension AccountPortfoliosClient: DependencyKey {
	public static let liveValue: AccountPortfoliosClient = {
		let state = State()

		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.tokenPriceClient) var tokenPriceClient
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		/// Update currency amount visibility based on the profile state
		Task {
			for try await isCurrencyAmountVisible in await appPreferencesClient.appPreferenceUpdates().map(\.display.isCurrencyAmountVisible) {
				guard !Task.isCancelled else { return }
				await state.setIsCurrencyAmountVisble(isCurrencyAmountVisible)
			}
		}

		/// Update used currency based on the profile state
		Task {
			for try await fiatCurrency in await appPreferencesClient.appPreferenceUpdates().map(\.display.fiatCurrencyPriceTarget) {
				guard !Task.isCancelled else { return }
				await state.setSelectedCurrency(fiatCurrency)
			}
		}

		/// Fetches the pool and stake units details for a given account; Will update the portfolio accordingly
		@Sendable
		func fetchPoolAndStakeUnitsDetails(_ account: OnLedgerEntity.Account) async {
			async let pooldetailsFetch = Task {
				do {
					let poolUnitDetails = try await onLedgerEntitiesClient.getOwnedPoolUnitsDetails(account)
					await state.set(poolDetails: .success(poolUnitDetails), forAccount: account.address)
				} catch {
					await state.set(poolDetails: .failure(error), forAccount: account.address)
				}
			}.result
			async let poolUnitsFetch = Task {
				do {
					try await Task.sleep(for: .seconds(Double.random(in: 3 ..< 5)))
					let stakeUnitDetails = try await onLedgerEntitiesClient.getOwnedStakesDetails(account: account)
					await state.set(stakeUnitDetails: .success(stakeUnitDetails.asIdentifiable()), forAccount: account.address)
				} catch {
					await state.set(stakeUnitDetails: .failure(error), forAccount: account.address)
				}
			}.result

			_ = await (pooldetailsFetch, pooldetailsFetch)
		}

		return AccountPortfoliosClient(
			fetchAccountPortfolios: { accountAddresses, forceRefresh in
				if forceRefresh {
					for accountAddress in accountAddresses {
						cacheClient.removeFolder(.onLedgerEntity(.account(accountAddress.asGeneral)))
					}
				}

				/// Explicetely load and set the currency target and visibility to make sure
				/// it is available for usage before resources are loaded
				let preferences = await appPreferencesClient.getPreferences().display
				await state.setSelectedCurrency(preferences.fiatCurrencyPriceTarget)
				await state.setIsCurrencyAmountVisble(preferences.isCurrencyAmountVisible)

				let accounts = try await onLedgerEntitiesClient.getAccounts(accountAddresses).map(\.nonEmptyVaults)
				let portfolios = accounts.map { AccountPortfolio(account: $0) }

				let allResources = accounts.flatMap {
					$0.allFungibleResourceAddresses + $0.poolUnitResources.poolUnits.flatMap(\.poolResources)
				}

				// Temporary for testing purposes
				let allTokens: [ResourceAddress] = try! [
					.init(validatingAddress: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"),
					.init(validatingAddress: "resource_rdx1t4zrksrzh7ucny7r57ss99nsrxscqwh8crjn6k22m8e9qyxh8c05pl"),
					.init(validatingAddress: "resource_rdx1t4nxvalrqpqaxv9cvmghk5yyl5u47mgj33npthwfupszvm8ezgy5x0"),
					.init(validatingAddress: "resource_rdx1t5n6agexw646tgu3lkr8n0nvt69z00384mhrlfuxz75wprtg9wwllq"),
					.init(validatingAddress: "resource_rdx1thsg68perylkawv6w9vuf9ctrjl6pjhh2vrhp5v4q0vxul7a5ws8wz"),
				]

				let prices = try await tokenPriceClient.getTokenPrices(.init(
					tokens: allTokens,
					currency: preferences.fiatCurrencyPriceTarget
				))
				await state.setTokenPrices(prices)

				await state.handlePortfoliosUpdated(portfolios)

				// Load additional details
				_ = await accounts.parallelMap(fetchPoolAndStakeUnitsDetails)

				return Array(state.portfoliosSubject.value.wrappedValue!.values)
			},
			fetchAccountPortfolio: { accountAddress, forceRefresh in
				if forceRefresh {
					cacheClient.removeFolder(.onLedgerEntity(.account(accountAddress.asGeneral)))
				}

				let account = try await onLedgerEntitiesClient.getAccount(accountAddress)
				var portfolio = AccountPortfolio(account: account)

				await state.applyCurrencyVisibility(&portfolio)
				await state.applyTokenPrices(to: &portfolio)
				await state.setOrUpdateAccountPortfolio(portfolio)

				await fetchPoolAndStakeUnitsDetails(account)

				return portfolio
			},
			portfolioForAccount: { address in
				await state.portfolioForAccount(address)
			},
			portfoliosUpdates: {
				state.portfoliosSubject.compactMap { $0.wrappedValue.map { Array($0.values) } }.eraseToAnyAsyncSequence()
			},
			portfolios: { state.portfoliosSubject.value.wrappedValue.map { Array($0.values) } ?? [] },
			totalFiatWorth: {
				state.portfoliosSubject
					.eraseToAnyAsyncSequence()
					.map {
						let isCurrencyAmountVisible = await state.isCurrencyAmountVisible
						let selectedCurrency = await state.selectedCurrency

						return $0.values.flatMap { values in
							let zero = FiatWorth(
								isVisible: isCurrencyAmountVisible,
								worth: .zero,
								currency: selectedCurrency
							)

							let result: Loadable<FiatWorth> = values
								.map(\.totalFiatWorth)
								.reduce(.success(zero)) {
									$0.reduce($1, join: +)
								}

							return result
						}
					}
					.removeDuplicates()
					.eraseToAnyAsyncSequence()
			}
		)
	}()
}

extension NumberFormatter {
	static let currencyFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency

		return formatter
	}()
}

// MARK: - TokenAmountWithFiatWorth
public struct TokenAmountWithFiatWorth: Hashable, Sendable {
	public let amount: RETDecimal
	public let fiatWorth: FiatWorth?

	public static let zero = TokenAmountWithFiatWorth(amount: 0, fiatWorth: nil)

	public static func + (lhs: TokenAmountWithFiatWorth, rhs: TokenAmountWithFiatWorth) -> TokenAmountWithFiatWorth {
		.init(
			amount: lhs.amount + rhs.amount,
			fiatWorth: {
				switch (lhs.fiatWorth, rhs.fiatWorth) {
				case let (lhsFiatWorth?, nil):
					lhsFiatWorth
				case let (nil, rhsFiatWorth?):
					rhsFiatWorth
				case let (lhsFiatWorth?, rhsFiatWorth?):
					lhsFiatWorth + rhsFiatWorth
				case (nil, nil):
					nil
				}
			}()
		)
	}
}
