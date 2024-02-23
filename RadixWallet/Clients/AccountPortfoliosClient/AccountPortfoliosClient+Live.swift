// MARK: - AccountPortfoliosClient + DependencyKey
extension AccountPortfoliosClient: DependencyKey {
	public struct AccountPortfolio: Sendable, Hashable {
		public var account: OnLedgerEntity.Account
		public var poolUnitDetails: [OnLedgerEntitiesClient.OwnedResourcePoolDetails]
		public var stakeUnitDetails: [OnLedgerEntitiesClient.OwnedStakeDetails]

		var isCurrencyAmountVisible: Bool = true
		var fiatCurrency: FiatCurrency = .usd

		var totalFiatWorth: OnLedgerEntity.FiatWorth {
			let xrdFiatWorth = account.fungibleResources.xrdResource?.fiatWorth?.worth ?? .zero
			let nonXrdFiatWorth = account.fungibleResources.nonXrdResources.compactMap(\.fiatWorth?.worth).reduce(0, +)
			let fungibleTokensFiatWorth = xrdFiatWorth + nonXrdFiatWorth

			let stakeUnitsFiatWorth: Double = stakeUnitDetails.map {
				let stakeUnitFiatWorth = $0.stakeUnitResource?.amounFiatWorth?.worth ?? .zero
				let stakeClaimsFiatWorth = $0.stakeClaimTokens?.stakeClaims.compactMap(\.claimFiatWorth?.worth).reduce(0, +) ?? .zero
				return stakeUnitFiatWorth + stakeClaimsFiatWorth
			}.reduce(0, +)

			let totalFiatWorth = fungibleTokensFiatWorth + stakeUnitsFiatWorth

			return .init(isVisible: isCurrencyAmountVisible, worth: totalFiatWorth, currency: fiatCurrency)
		}
	}

	/// Internal state that holds all loaded portfolios.
	actor State {
		let portfoliosSubject: AsyncCurrentValueSubject<[AccountAddress: AccountPortfolio]> = .init([:])

		func setOrUpdateAccountPortfolio(_ portfolio: AccountPortfolio) {
			portfoliosSubject.value.updateValue(portfolio, forKey: portfolio.account.address)
		}

		func setOrUpdateAccountPortfolios(_ portfolios: [AccountPortfolio]) {
			var newValue = portfoliosSubject.value
			for portfolio in portfolios {
				newValue[portfolio.account.address] = portfolio
			}
			portfoliosSubject.value = newValue
		}

		func portfolioForAccount(_ address: AccountAddress) -> AnyAsyncSequence<AccountPortfolio> {
			portfoliosSubject.compactMap { $0[address] }.eraseToAnyAsyncSequence()
		}
	}

	public static let liveValue: AccountPortfoliosClient = {
		let state = State()

		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.tokenPriceClient) var tokenPriceClient
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		Task {
			for try await isCurrencyAmountVisible in await appPreferencesClient.appPreferenceUpdates().map(\.display.isCurrencyAmountVisible) {
				guard !Task.isCancelled else { return }
				let updated = await updateWithCurrencyVisibility(isCurrencyAmountVisible, Array(state.portfoliosSubject.value.values))
				await state.setOrUpdateAccountPortfolios(updated)
			}
		}

		@Sendable
		func updateWithCurrencyVisibility(
			_ isCurrencyAmountVisible: Bool,
			_ portfolios: [AccountPortfolio]
		) async -> [AccountPortfolio] {
			var portfolios = portfolios
			if !isCurrencyAmountVisible {
				portfolios.mutateAll { portfolio in
					portfolio.isCurrencyAmountVisible = false
					portfolio.account.fungibleResources.nonXrdResources.mutateAll { resource in
						resource.fiatWorth?.isVisible = false
					}
					portfolio.account.fungibleResources.xrdResource?.fiatWorth?.isVisible = false
					portfolio.account.poolUnitResources.radixNetworkStakes.mutateAll { stake in
						stake.stakeUnitResource?.fiatWorth?.isVisible = false
					}
					portfolio.account.fungibleResources.nonXrdResources.sort(by: <)
				}

				return portfolios
			} else {
				// all resources and lsus
				let allTokens: [ResourceAddress] = try! [
					.init(validatingAddress: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"),
					.init(validatingAddress: "resource_rdx1t4zrksrzh7ucny7r57ss99nsrxscqwh8crjn6k22m8e9qyxh8c05pl"),
					.init(validatingAddress: "resource_rdx1t4nxvalrqpqaxv9cvmghk5yyl5u47mgj33npthwfupszvm8ezgy5x0"),
					.init(validatingAddress: "resource_rdx1t5n6agexw646tgu3lkr8n0nvt69z00384mhrlfuxz75wprtg9wwllq"),
					.init(validatingAddress: "resource_rdx1thsg68perylkawv6w9vuf9ctrjl6pjhh2vrhp5v4q0vxul7a5ws8wz"),
				]

				// accounts.flatMap { $0.fungibleResources.nonXrdResources.map { $0.resourceAddress } }
				let allLsus: [ResourceAddress] = try! [
					.init(validatingAddress: "resource_rdx1tkfxrsffdlh82fjxjwpgrgrgcmc7cfe0sy99c7vm6gsnujelupglnj"),
					.init(validatingAddress: "resource_rdx1t5x9fx6vjyk5x77vtqtzchxdlk5p9hgp8vpz8v3s0dzdu0dmps58pu"),
					.init(validatingAddress: "resource_rdx1thnr43ane3jrxlj6m230n6mf2n5fmmpj029maw9u60jhmjs6p4tfun"),
					.init(validatingAddress: "resource_rdx1th3adk93ale3n8nzrypghtkasczmpt42qamq7x5dy8lsu3uwycvh4n"),
					.init(validatingAddress: "resource_rdx1t493qnkufdgy57p034e2rny6gn7lf8a4zh8v68fpecs7vl7lv5qajv"),
				]
				//                accounts.flatMap { $0.poolUnitResources.radixNetworkStakes.compactMap(\.stakeClaimResource?.resourceAddress)
				//                }

				let tokenPrices = try? await tokenPriceClient.getTokenPrices(.init(tokens: Array(allTokens.prefix(5)), lsus: Array(allLsus)))
				let xrdPrice = tokenPrices!.tokens[id: .init(address: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd", decodedKind: .globalFungibleResourceManager)]!.price

				let new = portfolios.map { portfolio in
					var portfolio = portfolio
					portfolio.isCurrencyAmountVisible = true
					let sortedByPrice = portfolio.account.fungibleResources.nonXrdResources.map { resource in
						let price = tokenPrices?.tokens.randomElement()?.price
						var resource = resource
						resource.fiatWorth = price.map {
							.init(
								isVisible: true,
								worth: $0.price * (try! resource.amount.asDouble()),
								currency: $0.currency
							)
						}
						return resource
					}.sorted(by: <)
					let xrdResource = portfolio.account.fungibleResources.xrdResource.map {
						var res = $0
						let price = tokenPrices?.tokens[id: .init(address: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd", decodedKind: .globalFungibleResourceManager)]?.price
						res.fiatWorth = price.map {
							.init(
								isVisible: true,
								worth: $0.price * (try! res.amount.asDouble()),
								currency: $0.currency
							)
						}
						return res
					}
					portfolio.account.fungibleResources = .init(xrdResource: xrdResource, nonXrdResources: sortedByPrice)
					portfolio.stakeUnitDetails.mutateAll { details in
						let stakeUnitAmount = details.stakeUnitResource?.amount
						details.stakeUnitResource?.amounFiatWorth = stakeUnitAmount.map {
							.init(
								isVisible: true,
								worth: xrdPrice.price * (try! $0.asDouble()),
								currency: xrdPrice.currency
							)
						}
						details.stakeClaimTokens?.stakeClaims.mutateAll { token in
							let xrdAmount = token.claimAmount
							token.claimFiatWorth = .init(
								isVisible: true,
								worth: xrdPrice.price * (try! xrdAmount.asDouble()),
								currency: xrdPrice.currency
							)
						}
					}
					return portfolio
				}

				return new
			}
		}

		return AccountPortfoliosClient(
			fetchAccountPortfolios: { accountAddresses, forceRefresh in
				if forceRefresh {
					for accountAddress in accountAddresses {
						cacheClient.removeFolder(.onLedgerEntity(.account(accountAddress.asGeneral)))
					}
				}

				let accounts = try await onLedgerEntitiesClient.getAccounts(accountAddresses)
				let allPoolAndStakeUnitAddresses = accounts.flatMap { account in
					account.poolUnitResources.fungibleResourceAddresses + account.poolUnitResources.nonFungibleResourceAddresses
				}

				let isCurrencyAmountVisible = await appPreferencesClient.getPreferences().display.isCurrencyAmountVisible

				let portfolios = try await accounts.parallelMap {
					let detailsS = try await onLedgerEntitiesClient.getOwnedStakesDetails(account: $0)
					let detailsP = try await onLedgerEntitiesClient.getOwnedPoolUnitsDetails($0)

					return AccountPortfolio(account: $0, poolUnitDetails: detailsP, stakeUnitDetails: detailsS)
				}
				await state.setOrUpdateAccountPortfolios(updateWithCurrencyVisibility(isCurrencyAmountVisible, portfolios))

				return portfolios
			},
			fetchAccountPortfolio: { accountAddress, forceRefresh in
				if forceRefresh {
					cacheClient.removeFolder(.onLedgerEntity(.account(accountAddress.asGeneral)))
				}

				var account = try await onLedgerEntitiesClient.getAccount(accountAddress)
				let detailsS = try await onLedgerEntitiesClient.getOwnedStakesDetails(account: account)
				let detailsP = try await onLedgerEntitiesClient.getOwnedPoolUnitsDetails(account)

				let portfolio = AccountPortfolio(account: account, poolUnitDetails: detailsP, stakeUnitDetails: detailsS)

				await state.setOrUpdateAccountPortfolio(portfolio)

				return portfolio
			},
			portfolioForAccount: { address in
				await state.portfolioForAccount(address)
			},
			portfoliosUpdates: {
				state.portfoliosSubject.map { Array($0.values) }.eraseToAnyAsyncSequence()
			},
			portfolios: { state.portfoliosSubject.value.map(\.value) }
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

extension OnLedgerEntity.FiatWorth {
	func currencyFormatted(applyCustomFont: Bool) -> AttributedString? {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.currencyCode = currency.currencyCode
		if self.worth < 1 {
			formatter.maximumFractionDigits = 10
		}

		var attributedString = AttributedString(formatter.string(for: self.worth)!)

		let currencySymbol = formatter.currencySymbol ?? ""
		let symbolRange = attributedString.range(of: currencySymbol)

		guard isVisible else {
			let hiddenValue = "• • • •"
			if symbolRange!.lowerBound == attributedString.startIndex {
				return AttributedString(currencySymbol + hiddenValue)
			} else {
				return AttributedString(hiddenValue + currencySymbol)
			}
		}

		guard applyCustomFont else {
			return attributedString
		}

		// Define font sizes
		let symbolFontSize: CGFloat = 12
		let mainFontSize: CGFloat = 18

		// Apply main font size to entire string
		attributedString.font = .app.sheetTitle
		attributedString.kern = -0.5

		let decimalSeparator = formatter.decimalSeparator ?? "."

		if let symbolRange = attributedString.range(of: currencySymbol) {
			attributedString[symbolRange].font = .app.sectionHeader
			attributedString[symbolRange].kern = 0.0
		}

		if let decimalRange = attributedString.range(of: decimalSeparator) {
			attributedString[decimalRange.lowerBound...].font = .app.sectionHeader
			attributedString[decimalRange.lowerBound...].kern = 0.0
		}

		return attributedString
	}
}

extension FiatCurrency {
	var currencyCode: String {
		switch self {
		case .usd:
			"USD"
		}
	}
}
