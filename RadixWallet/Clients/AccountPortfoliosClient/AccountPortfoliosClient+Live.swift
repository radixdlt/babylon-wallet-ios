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
			async let poolDetailsFetch = Task {
				do {
					let poolUnitDetails = try await onLedgerEntitiesClient.getOwnedPoolUnitsDetails(account)
					await state.set(poolDetails: .success(poolUnitDetails), forAccount: account.address)
				} catch {
					await state.set(poolDetails: .failure(error), forAccount: account.address)
				}
			}.result
			async let stakeUnitDetails = Task {
				do {
					let stakeUnitDetails = try await onLedgerEntitiesClient.getOwnedStakesDetails(account: account)
					await state.set(stakeUnitDetails: .success(stakeUnitDetails.asIdentifiable()), forAccount: account.address)
				} catch {
					await state.set(stakeUnitDetails: .failure(error), forAccount: account.address)
				}
			}.result

			_ = await (poolDetailsFetch, stakeUnitDetails)
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

				/// Put together all resources from already fetched and new accounts
				let currentAccounts = state.portfoliosSubject.value.wrappedValue.map { $0.values.map(\.account) } ?? []
				let allResources = (currentAccounts + accounts).flatMap {
					$0.allFungibleResourceAddresses + $0.poolUnitResources.poolUnits.flatMap(\.poolResources)
				}.uniqued()

				let prices = try await tokenPriceClient.getTokenPrices(.init(
					tokens: Array(allResources),
					currency: preferences.fiatCurrencyPriceTarget
				))
				await state.setTokenPrices(prices)

				let portfolios = accounts.map { AccountPortfolio(account: $0) }
				await state.handlePortfoliosUpdate(portfolios)

				// Load additional details
				_ = await accounts.parallelMap(fetchPoolAndStakeUnitsDetails)

				return Array(state.portfoliosSubject.value.wrappedValue!.values)
			},
			fetchAccountPortfolio: { accountAddress, forceRefresh in
				if forceRefresh {
					cacheClient.removeFolder(.onLedgerEntity(.account(accountAddress.asGeneral)))
				}

				let account = try await onLedgerEntitiesClient.getAccount(accountAddress)
				let portfolio = AccountPortfolio(account: account)

				await state.handlePortfolioUpdate(portfolio)
				await fetchPoolAndStakeUnitsDetails(account)

				return portfolio
			},
			portfolioForAccount: { address in
				await state.portfolioForAccount(address)
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
