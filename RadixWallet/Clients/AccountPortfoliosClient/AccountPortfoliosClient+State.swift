import Foundation

// MARK: - Definition
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
		typealias TokenPrices = [ResourceAddress: RETDecimal]
		let portfoliosSubject: AsyncCurrentValueSubject<Loadable<[AccountAddress: AccountPortfolio]>> = .init(.loading)
		var tokenPrices: TokenPrices = [:]

		var selectedCurrency: FiatCurrency = .usd
		var isCurrencyAmountVisible: Bool = true
	}
}

// MARK: - Portfolio Setters/Getters
extension AccountPortfoliosClient.State {
	func handlePortfolioUpdate(_ portfolio: AccountPortfoliosClient.AccountPortfolio) {
		var portfolio = portfolio
		applyFiatWorth(&portfolio)
		setOrUpdateAccountPortfolio(portfolio)
	}

	func handlePortfoliosUpdate(_ portfolios: [AccountPortfoliosClient.AccountPortfolio]) {
		var portfolios = portfolios
		portfolios.mutateAll(applyFiatWorth)
		setOrUpdateAccountPortfolios(portfolios)
	}

	func portfolioForAccount(_ address: AccountAddress) -> AnyAsyncSequence<AccountPortfoliosClient.AccountPortfolio> {
		portfoliosSubject.compactMap { $0[address].unwrap()?.wrappedValue }.eraseToAnyAsyncSequence()
	}

	private func setOrUpdateAccountPortfolio(_ portfolio: AccountPortfoliosClient.AccountPortfolio) {
		portfoliosSubject.value.mutateValue {
			$0.updateValue(portfolio, forKey: portfolio.account.address)
		}
	}

	private func setOrUpdateAccountPortfolios(_ portfolios: [AccountPortfoliosClient.AccountPortfolio]) {
		var newValue = portfoliosSubject.value.wrappedValue ?? [:]
		for portfolio in portfolios {
			newValue[portfolio.account.address] = portfolio
		}
		portfoliosSubject.value = .success(newValue)
	}
}

// MARK: - Fiat worth setters
extension AccountPortfoliosClient.State {
	func applyFiatWorth(_ portfolio: inout AccountPortfoliosClient.AccountPortfolio) {
		applyTokenPrices(to: &portfolio)
		applyCurrencyVisibility(&portfolio)
		applyFiatCurrency(to: &portfolio)
	}

	func setTokenPrices(_ tokenPrices: TokenPrices) {
		self.tokenPrices = tokenPrices
		if var existingPortfolios = portfoliosSubject.value.values.wrappedValue.map(Array.init) {
			applyTokenPrices(to: &existingPortfolios)
			self.setOrUpdateAccountPortfolios(existingPortfolios)
		}
	}

	func setIsCurrencyAmountVisble(_ isVisible: Bool) {
		self.isCurrencyAmountVisible = isVisible
		if var existingPortfolios = portfoliosSubject.value.values.wrappedValue.map(Array.init) {
			applyCurrencyVisibility(to: &existingPortfolios)
			setOrUpdateAccountPortfolios(existingPortfolios)
		}
	}

	func setSelectedCurrency(_ currency: FiatCurrency) {
		self.selectedCurrency = currency
		if var existingPortfolios = portfoliosSubject.value.values.wrappedValue.map(Array.init) {
			applyFiatCurrency(to: &existingPortfolios)
			self.setOrUpdateAccountPortfolios(existingPortfolios)
		}
	}

	func applyTokenPrices(to portfolios: inout [AccountPortfoliosClient.AccountPortfolio]) {
		portfolios.mutateAll(applyTokenPrices)
	}

	func applyTokenPrices(to portfolio: inout AccountPortfoliosClient.AccountPortfolio) {
		portfolio.updateFiatWorth(calculateWorth)
	}

	func applyCurrencyVisibility(_ portfolio: inout AccountPortfoliosClient.AccountPortfolio) {
		portfolio.isCurrencyAmountVisible = isCurrencyAmountVisible
		portfolio.updateFiatWorth(value: isCurrencyAmountVisible, to: \.isVisible)
	}

	func applyFiatCurrency(to portfolio: inout AccountPortfoliosClient.AccountPortfolio) {
		portfolio.fiatCurrency = self.selectedCurrency
		portfolio.updateFiatWorth(value: selectedCurrency, to: \.currency)
	}

	func applyFiatCurrency(to portfolios: inout [AccountPortfoliosClient.AccountPortfolio]) {
		portfolios.mutateAll(applyFiatCurrency)
	}

	func applyCurrencyVisibility(to portfolios: inout [AccountPortfoliosClient.AccountPortfolio]) {
		portfolios.mutateAll(applyCurrencyVisibility)
	}
}

// MARK: - Stake and Pool details handling
extension AccountPortfoliosClient.State {
	func calculateWorth(for resourceAddress: ResourceAddress, amount: ResourceAmount) -> FiatWorth? {
		let price = tokenPrices[resourceAddress]
		return price.map {
			.init(
				isVisible: isCurrencyAmountVisible,
				worth: .known($0 * amount.nominalAmount),
				currency: selectedCurrency
			)
		}
	}

	func set(poolDetails: Loadable<[OnLedgerEntitiesClient.OwnedResourcePoolDetails]>, forAccount address: AccountAddress) {
		guard var portfolio = portfoliosSubject.value.wrappedValue?[address] else {
			return
		}

		portfolio.poolUnitDetails = poolDetails.map { details in
			var details = details
			details.updateFiatWorth(calculateWorth)
			return details
		}
		setOrUpdateAccountPortfolio(portfolio)
	}

	func set(stakeUnitDetails: Loadable<IdentifiedArrayOf<OnLedgerEntitiesClient.OwnedStakeDetails>>, forAccount address: AccountAddress) {
		guard var portfolio = portfoliosSubject.value.wrappedValue?[address] else {
			return
		}
		portfolio.stakeUnitDetails = stakeUnitDetails.map { details in
			var details = details
			details.updateFiatWorth(calculateWorth)
			return details
		}
		setOrUpdateAccountPortfolio(portfolio)
	}
}

private let xrdAddress = ResourceAddress(address: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd", decodedKind: .globalFungibleResourceManager)

// MARK: Fiat Worth changes
extension AccountPortfoliosClient.AccountPortfolio {
	mutating func updateFiatWorth<T>(value: T, to keyPath: WritableKeyPath<FiatWorth, T>) {
		updateFiatWorth { _, worth in
			var worth = worth.fiatWorth
			worth?[keyPath: keyPath] = value
			return worth
		}
	}

	mutating func updateFiatWorth(_ change: (ResourceAddress, ResourceAmount) -> FiatWorth?) {
		account.fungibleResources.updateFiatWorth(change)
		stakeUnitDetails.mutateValue { $0.updateFiatWorth(change) }
		poolUnitDetails.mutateValue { $0.updateFiatWorth(change) }
	}
}

extension OnLedgerEntity.OwnedFungibleResources {
	mutating func updateFiatWorth(_ change: (ResourceAddress, ResourceAmount) -> FiatWorth?) {
		xrdResource.mutate { resource in
			resource.amount.fiatWorth = change(resource.resourceAddress, resource.amount)
		}

		nonXrdResources.mutateAll { resource in
			resource.amount.fiatWorth = change(resource.resourceAddress, resource.amount)
		}
	}
}

extension MutableCollection where Element == OnLedgerEntitiesClient.OwnedResourcePoolDetails {
	mutating func updateFiatWorth(_ change: (ResourceAddress, ResourceAmount) -> FiatWorth?) {
		mutateAll { detail in
			detail.xrdResource?.redemptionValue.mutate { amount in
				amount.fiatWorth = change(xrdAddress, amount)
			}

			detail.nonXrdResources.mutateAll { resource in
				let address = resource.resource.resourceAddress
				resource.redemptionValue.mutate { amount in
					amount.fiatWorth = change(address, amount)
				}
			}
		}
	}
}

extension MutableCollection where Element == OnLedgerEntitiesClient.OwnedStakeDetails {
	mutating func updateFiatWorth(_ change: (ResourceAddress, ResourceAmount) -> FiatWorth?) {
		mutateAll { detail in
			detail.stakeUnitResource.mutate {
				$0.amount.fiatWorth = change(xrdAddress, $0.amount)
			}
			detail.stakeClaimTokens.mutate {
				$0.stakeClaims.mutateAll { token in
					token.claimAmount.fiatWorth = change(xrdAddress, token.claimAmount)
				}
			}
		}
	}
}

extension Optional {
	mutating func mutate(_ mutate: (inout Wrapped) -> Void) {
		guard case var .some(wrapped) = self else {
			return
		}
		mutate(&wrapped)
		self = .some(wrapped)
	}
}

// MARK: - Account portfolio fiat worth
extension AccountPortfoliosClient.AccountPortfolio {
	var totalFiatWorth: Loadable<FiatWorth> {
		poolUnitDetails.concat(stakeUnitDetails).map { poolUnitDetails, stakeUnitDetails in
			let totalFiatWorth = account.fungibleResources.fiatWorth + stakeUnitDetails.fiatWorth + poolUnitDetails.fiatWorth
			return .init(isVisible: isCurrencyAmountVisible, worth: totalFiatWorth, currency: fiatCurrency)
		}
		.errorFallback(.unknownWorth(isVisible: isCurrencyAmountVisible, currency: fiatCurrency))
	}
}

extension OnLedgerEntity.OwnedFungibleResources {
	var fiatWorth: FiatWorth.Worth {
		let xrdFiatWorth = xrdResource?.amount.fiatWorth?.worth ?? .zero
		let nonXrdFiatWorth = nonXrdResources.compactMap(\.amount.fiatWorth?.worth).reduce(.zero, +)
		return xrdFiatWorth + nonXrdFiatWorth
	}
}

extension Collection<OnLedgerEntitiesClient.OwnedStakeDetails> {
	var fiatWorth: FiatWorth.Worth {
		reduce(.zero) { partialResult, stakeUnitDetail in
			let stakeUnitFiatWorth = stakeUnitDetail.stakeUnitResource?.amount.fiatWorth?.worth ?? .zero
			let stakeClaimsFiatWorth = stakeUnitDetail
				.stakeClaimTokens?
				.stakeClaims
				.compactMap(\.claimAmount.fiatWorth?.worth)
				.reduce(.zero, +) ?? .zero
			return partialResult + stakeUnitFiatWorth + stakeClaimsFiatWorth
		}
	}
}

extension Collection<OnLedgerEntitiesClient.OwnedResourcePoolDetails> {
	var fiatWorth: FiatWorth.Worth {
		reduce(.zero) { partialResult, poolUnitDetail in
			let xrdFiatWorth = poolUnitDetail.xrdResource?.redemptionValue?.fiatWorth?.worth ?? .zero
			let nonXrdFiatWorth = poolUnitDetail.nonXrdResources.compactMap(\.redemptionValue?.fiatWorth?.worth).reduce(.zero, +)
			return partialResult + xrdFiatWorth + nonXrdFiatWorth
		}
	}
}
