import Foundation

extension AccountPortfoliosClient {
	public struct AccountPortfolio: Sendable, Hashable {
		public var account: OnLedgerEntity.Account
		public var poolUnitDetails: Loadable<[OnLedgerEntitiesClient.OwnedResourcePoolDetails]> = .idle
		public var stakeUnitDetails: Loadable<IdentifiedArrayOf<OnLedgerEntitiesClient.OwnedStakeDetails>> = .idle

		var isCurrencyAmountVisible: Bool = true
		var fiatCurrency: FiatCurrency = .usd
	}

	/// Internal state that holds all loaded portfolios.
	actor State {
		typealias TokenPrices = [ResourceAddress: Double]
		let portfoliosSubject: AsyncCurrentValueSubject<Loadable<[AccountAddress: AccountPortfolio]>> = .init(.loading)
		var tokenPrices: TokenPrices = [:]

		var selectedCurrency: FiatCurrency = .usd
		var isCurrencyAmountVisible: Bool = true
	}
}

extension AccountPortfoliosClient.State {
	func setTokenPrices(_ tokenPrices: TokenPrices) {
		self.tokenPrices = tokenPrices
	}

	func setSelectedCurrency(_ currency: FiatCurrency) {
		self.selectedCurrency = currency
	}

	func setIsCurrencyAmountVisble(_ isVisible: Bool) {
		self.isCurrencyAmountVisible = isVisible
		if let existingPortfolios = portfoliosSubject.value.values.wrappedValue {
			self.setOrUpdateAccountPortfolios(applyCurrencyVisibility(to: Array(existingPortfolios)))
		}
	}

	func setOrUpdateAccountPortfolio(_ portfolio: AccountPortfoliosClient.AccountPortfolio) {
		portfoliosSubject.value.mutateValue {
			$0.updateValue(portfolio, forKey: portfolio.account.address)
		}
	}

	func applyCurrencyVisibility(_ portfolio: inout AccountPortfoliosClient.AccountPortfolio) {
		portfolio.isCurrencyAmountVisible = isCurrencyAmountVisible
		portfolio.account.fungibleResources.xrdResource?.amount.fiatWorth?.isVisible = isCurrencyAmountVisible
		portfolio.account.fungibleResources.nonXrdResources.mutateAll {
			$0.amount.fiatWorth?.isVisible = isCurrencyAmountVisible
		}

		portfolio.stakeUnitDetails.mutateValue {
			$0.mutateAll { details in
				details.stakeUnitResource?.amount.fiatWorth?.isVisible = isCurrencyAmountVisible
				details.stakeClaimTokens?.stakeClaims.mutateAll { token in
					token.claimAmount.fiatWorth?.isVisible = isCurrencyAmountVisible
				}
			}
		}

		portfolio.poolUnitDetails.mutateValue {
			$0.mutateAll { details in
				details.xrdResource?.fiatWorth?.isVisible = isCurrencyAmountVisible
				details.nonXrdResources.mutateAll { resource in
					resource.fiatWorth?.isVisible = isCurrencyAmountVisible
				}
			}
		}
	}

	func applyCurrencyVisibility(to portfolios: [AccountPortfoliosClient.AccountPortfolio]) -> [AccountPortfoliosClient.AccountPortfolio] {
		var portfolios = portfolios
		portfolios.mutateAll(applyCurrencyVisibility)

		return portfolios
	}

	func applyTokenPrices(to portfolios: [AccountPortfoliosClient.AccountPortfolio]) -> [AccountPortfoliosClient.AccountPortfolio] {
		var portfolios = portfolios
		portfolios.mutateAll(applyTokenPrices)

		return portfolios
	}

	func applyTokenPrices(to portfolio: inout AccountPortfoliosClient.AccountPortfolio) {
		portfolio.fiatCurrency = selectedCurrency
		let sortedByPrice = portfolio.account.fungibleResources.nonXrdResources.map { resource in
			let price = tokenPrices.values.randomElement()
			var resource = resource
			resource.amount.fiatWorth = price.map {
				.init(
					isVisible: isCurrencyAmountVisible,
					worth: $0 * (try! resource.amount.nominalAmount.asDouble()),
					currency: selectedCurrency
				)
			}
			return resource
		}.sorted(by: <)
		let xrdPrice = tokenPrices[.init(address: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd", decodedKind: .globalFungibleResourceManager)]

		let xrdResource = portfolio.account.fungibleResources.xrdResource.map {
			var res = $0
			res.amount.fiatWorth = xrdPrice.map {
				.init(
					isVisible: isCurrencyAmountVisible,
					worth: $0 * (try! res.amount.nominalAmount.asDouble()),
					currency: selectedCurrency
				)
			}
			return res
		}
		portfolio.account.fungibleResources = .init(xrdResource: xrdResource, nonXrdResources: sortedByPrice)
	}

	func handlePortfoliosUpdated(_ portfolios: [AccountPortfoliosClient.AccountPortfolio]) {
		setOrUpdateAccountPortfolios(applyTokenPrices(to: applyCurrencyVisibility(to: portfolios)))
	}

	func setOrUpdateAccountPortfolios(_ portfolios: [AccountPortfoliosClient.AccountPortfolio]) {
		var newValue = portfoliosSubject.value.wrappedValue ?? [:]
		for portfolio in portfolios {
			newValue[portfolio.account.address] = portfolio
		}
		portfoliosSubject.value = .success(newValue)
	}

	func portfolioForAccount(_ address: AccountAddress) -> AnyAsyncSequence<AccountPortfoliosClient.AccountPortfolio> {
		portfoliosSubject.compactMap { $0[address].unwrap()?.wrappedValue }.eraseToAnyAsyncSequence()
	}

	func set(poolDetails: Loadable<[OnLedgerEntitiesClient.OwnedResourcePoolDetails]>, forAccount address: AccountAddress) {
		guard var portfolio = portfoliosSubject.value.wrappedValue?[address] else {
			return
		}
		let xrdPrice = tokenPrices[.init(address: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd", decodedKind: .globalFungibleResourceManager)]

		portfolio.poolUnitDetails = poolDetails.map { details in
			var details = details
			details.mutateAll { pool in
				let xrdResource = pool.xrdResource.map {
					var res = $0
					res.fiatWorth = xrdPrice.map {
						.init(
							isVisible: isCurrencyAmountVisible,
							worth: $0 * (try! res.redemptionValue!.asDouble()),
							currency: selectedCurrency
						)
					}
					return res
				}

				let nonXrdResources = pool.nonXrdResources.map { resource in
					let price = tokenPrices.values.randomElement()
					var resource = resource
					resource.fiatWorth = price.map {
						.init(
							isVisible: isCurrencyAmountVisible,
							worth: $0 * (try! resource.redemptionValue!.asDouble()),
							currency: selectedCurrency
						)
					}
					return resource
				}
				pool.xrdResource = xrdResource
				pool.nonXrdResources = nonXrdResources
			}

			return details
		}
		setOrUpdateAccountPortfolio(portfolio)
	}

	func set(stakeUnitDetails: Loadable<IdentifiedArrayOf<OnLedgerEntitiesClient.OwnedStakeDetails>>, forAccount address: AccountAddress) {
		guard var portfolio = portfoliosSubject.value.wrappedValue?[address] else {
			return
		}
		let xrdPrice = tokenPrices[.init(address: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd", decodedKind: .globalFungibleResourceManager)]

		portfolio.stakeUnitDetails = stakeUnitDetails.map { details in
			var details = details
			details.mutateAll { details in
				let stakeUnitAmount = details.xrdRedemptionValue
				details.stakeUnitResource?.amount.fiatWorth = .init(
					isVisible: isCurrencyAmountVisible,
					worth: xrdPrice! * (try! stakeUnitAmount.asDouble()),
					currency: selectedCurrency
				)

				details.stakeClaimTokens?.stakeClaims.mutateAll { token in
					let xrdAmount = token.claimAmount
					token.claimAmount.fiatWorth = .init(
						isVisible: isCurrencyAmountVisible,
						worth: xrdPrice! * (try! xrdAmount.nominalAmount.asDouble()),
						currency: selectedCurrency
					)
				}
			}
			return details
		}
		setOrUpdateAccountPortfolio(portfolio)
	}
}

extension AccountPortfoliosClient.AccountPortfolio {
	var totalFiatWorth: Loadable<FiatWorth> {
		poolUnitDetails.concat(stakeUnitDetails).map { poolUnitDetails, stakeUnitDetails in
			let xrdFiatWorth = account.fungibleResources.xrdResource?.amount.fiatWorth?.worth ?? .zero
			let nonXrdFiatWorth = account.fungibleResources.nonXrdResources.compactMap(\.amount.fiatWorth?.worth).reduce(0, +)
			let fungibleTokensFiatWorth = xrdFiatWorth + nonXrdFiatWorth

			let stakeUnitsFiatWorth: Double = stakeUnitDetails.reduce(0) { partialResult, next in
				let stakeUnitFiatWorth = next.stakeUnitResource?.amount.fiatWorth?.worth ?? .zero
				let stakeClaimsFiatWorth = next.stakeClaimTokens?.stakeClaims.compactMap(\.claimAmount.fiatWorth?.worth).reduce(0, +) ?? .zero
				return partialResult + stakeUnitFiatWorth + stakeClaimsFiatWorth
			}

			let poolUnitsFiatWorth: Double = poolUnitDetails.reduce(0) { partialResult, next in
				let xrdFiatWorth = next.xrdResource?.fiatWorth?.worth ?? .zero
				let nonXrdFiatWorth = account.fungibleResources.nonXrdResources.compactMap(\.amount.fiatWorth?.worth).reduce(0, +)
				return partialResult + xrdFiatWorth + nonXrdFiatWorth
			}

			let totalFiatWorth = fungibleTokensFiatWorth + poolUnitsFiatWorth + stakeUnitsFiatWorth

			return .init(isVisible: isCurrencyAmountVisible, worth: totalFiatWorth, currency: fiatCurrency)
		}
	}
}
