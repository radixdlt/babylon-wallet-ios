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
		func fetchPoolAndStakeUnitsDetails(_ account: OnLedgerEntity.Account, cachingStrategy: OnLedgerEntitiesClient.CachingStrategy) async {
			async let poolDetailsFetch = Task {
				do {
					let poolUnitDetails = try await onLedgerEntitiesClient.getOwnedPoolUnitsDetails(account, cachingStrategy: cachingStrategy)
					await state.set(poolDetails: .success(poolUnitDetails), forAccount: account.address)
				} catch {
					await state.set(poolDetails: .failure(error), forAccount: account.address)
				}
			}.result
			async let stakeUnitDetails = Task {
				do {
					let stakeUnitDetails = try await onLedgerEntitiesClient.getOwnedStakesDetails(account: account, cachingStrategy: cachingStrategy)
					await state.set(stakeUnitDetails: .success(stakeUnitDetails.asIdentified()), forAccount: account.address)
				} catch {
					await state.set(stakeUnitDetails: .failure(error), forAccount: account.address)
				}
			}.result

			_ = await (poolDetailsFetch, stakeUnitDetails)
		}

		@Sendable
		func applyTokenPrices(_ resources: [ResourceAddress], forceRefresh: Bool) async {
			if !resources.isEmpty {
				let prices = try? await tokenPricesClient.getTokenPrices(
					.init(
						tokens: Array(resources.uniqued()),
						currency: state.selectedCurrency
					),
					forceRefresh
				)

				if let prices {
					await state.setTokenPrices(prices)
				}
			}
		}

		@Sendable
		func fetchAccountPortfolios(
			_ accountAddresses: [AccountAddress],
			_ forceRefresh: Bool
		) async throws -> [AccountPortfolio] {
			let gateway = await gatewaysClient.getCurrentGateway()
			await state.setRadixGateway(gateway)
			if forceRefresh {
				for accountAddress in accountAddresses {
					cacheClient.removeFolder(.init(address: accountAddress))
				}
			}

			/// Explicetely load and set the currency target and visibility to make sure
			/// it is available for usage before resources are loaded
			let preferences = await appPreferencesClient.getPreferences().display
			await state.setSelectedCurrency(preferences.fiatCurrencyPriceTarget)
			await state.setIsCurrencyAmountVisble(preferences.isCurrencyAmountVisible)

			let accounts = try await onLedgerEntitiesClient.getAccounts(accountAddresses)

			let portfolios = accounts.map { AccountPortfolio(account: $0) }
			await state.handlePortfoliosUpdate(portfolios)

			/// Put together all resources from already fetched and new accounts
			let currentAccounts = state.portfoliosSubject.value.wrappedValue.map { $0.values.map(\.account) } ?? []
			let allResources: [ResourceAddress] = {
				if gateway == .mainnet {
					/// Only Mainnet resources have prices
					return (currentAccounts + accounts).flatMap(\.resourcesWithPrices) + [.mainnetXRD]
				} else {
					#if DEBUG
					/// Helpful for testing on stokenet
					return [
						.mainnetXRD,
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

			await applyTokenPrices(Array(allResources), forceRefresh: forceRefresh)

			// Load additional details
			_ = await accounts.map(\.nonEmptyVaults).parallelMap {
				await fetchPoolAndStakeUnitsDetails($0, cachingStrategy: forceRefresh ? .forceUpdate : .useCache)
			}

			return Array(state.portfoliosSubject.value.wrappedValue!.values)
		}

		@Sendable
		func fetchAccountPortfolio(
			_ accountAddress: AccountAddress,
			_ forceRefresh: Bool
		) async throws -> AccountPortfolio {
			if forceRefresh {
				cacheClient.removeFolder(.init(address: accountAddress))
			}

			let account = try await onLedgerEntitiesClient.getAccount(accountAddress)
			let portfolio = AccountPortfolio(account: account)

			let currentResources = await state.tokenPrices.keys
			await applyTokenPrices(
				currentResources + account.resourcesWithPrices,
				forceRefresh: forceRefresh
			)

			await state.handlePortfolioUpdate(portfolio)
			await fetchPoolAndStakeUnitsDetails(account.nonEmptyVaults, cachingStrategy: forceRefresh ? .forceUpdate : .useCache)

			return portfolio
		}

		return AccountPortfoliosClient(
			fetchAccountPortfolios: { accountAddresses, forceRefresh in
				try await Task.detached {
					try await fetchAccountPortfolios(accountAddresses, forceRefresh)
				}.value
			},
			fetchAccountPortfolio: { accountAddress, forceRefresh in
				try await Task.detached {
					try await fetchAccountPortfolio(accountAddress, forceRefresh)
				}.value
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

extension OnLedgerEntity.Account {
	/// The resources which can have prices
	fileprivate var resourcesWithPrices: [ResourceAddress] {
		allFungibleResourceAddresses + poolUnitResources.poolUnits.flatMap(\.poolResources)
	}
}
