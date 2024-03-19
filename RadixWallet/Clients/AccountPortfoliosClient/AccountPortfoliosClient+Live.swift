// MARK: - AccountPortfoliosClient + DependencyKey
extension AccountPortfoliosClient: DependencyKey {
	public static let liveValue: AccountPortfoliosClient = {
		let state = State()

		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.tokenPricesClient) var tokenPricesClient
		@Dependency(\.appPreferencesClient) var appPreferencesClient
		@Dependency(\.gatewaysClient) var gatewaysClient

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
				let gateway = await gatewaysClient.getCurrentGateway()
				await state.setRadixGateway(gateway)
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
				let allResources: [ResourceAddress] = {
					if gateway == .mainnet {
						/// Only Mainnet resources have prices
						return (currentAccounts + accounts)
							.flatMap {
								$0.allFungibleResourceAddresses +
									$0.poolUnitResources.poolUnits.flatMap(\.poolResources) +
									[.mainnetXRDAddress]
							}
					} else {
						#if DEBUG
						/// Helpful for testing on stokenet
						return [
							.mainnetXRDAddress,
							try! .init(validatingAddress:
								"resource_rdx1t4tjx4g3qzd98nayqxm7qdpj0a0u8ns6a0jrchq49dyfevgh6u0gj3"
							),
							try! .init(validatingAddress:
								"resource_rdx1t45js47zxtau85v0tlyayerzrgfpmguftlfwfr5fxzu42qtu72tnt0"
							),
							try! .init(validatingAddress:
								"resource_rdx1tk7g72c0uv2g83g3dqtkg6jyjwkre6qnusgjhrtz0cj9u54djgnk3c"
							),
							try! .init(validatingAddress:
								"resource_rdx1tkk83magp3gjyxrpskfsqwkg4g949rmcjee4tu2xmw93ltw2cz94sq"
							),
						]
						#else
						/// No price for resources on testnets
						return []
						#endif
					}
				}()

				if !allResources.isEmpty {
					let prices = try? await tokenPricesClient.getTokenPrices(
						.init(
							tokens: Array(allResources),
							currency: preferences.fiatCurrencyPriceTarget
						),
						forceRefresh
					)

					if let prices {
						await state.setTokenPrices(prices)
					}
				}

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
			portfolioUpdates: {
				state.portfoliosSubject
					.map { $0.map { Array($0.values) } }
					.eraseToAnyAsyncSequence()
			},
			portfolioForAccount: { address in
				await state.portfolioForAccount(address)
			},
			portfolios: { state.portfoliosSubject.value.wrappedValue.map { Array($0.values) } ?? [] }
		)
	}()
}
