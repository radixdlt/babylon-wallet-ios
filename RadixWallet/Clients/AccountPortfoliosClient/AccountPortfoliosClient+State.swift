import Foundation

// MARK: - Definition
extension AccountPortfoliosClient {
	struct AccountPortfolio: Sendable, Hashable, CustomDebugStringConvertible {
		/// The visible account to consumers of this portfolio. It has already removed any reference to hidden resources.
		var account: OnLedgerEntity.OnLedgerAccount

		/// The original account, without any modifications made. Necessary for whenever we need to update the hidden resources.
		private let originalAccount: OnLedgerEntity.OnLedgerAccount

		private(set) var hiddenResources: [ResourceIdentifier]

		var poolUnitDetails: Loadable<[OnLedgerEntitiesClient.OwnedResourcePoolDetails]> = .idle
		var stakeUnitDetails: Loadable<IdentifiedArrayOf<OnLedgerEntitiesClient.OwnedStakeDetails>> = .idle

		var isCurrencyAmountVisible: Bool = true
		var fiatCurrency: FiatCurrency = .usd
		var debugDescription: String {
			account.debugDescription
		}

		init(account: OnLedgerEntity.OnLedgerAccount, hiddenResources: [ResourceIdentifier]) {
			self.originalAccount = account
			self.hiddenResources = hiddenResources
			self.account = Self.removeHiddenResourcesFromAccount(account: account, hiddenResources: hiddenResources)
		}

		mutating func updateHiddenResources(hiddenResources: [ResourceIdentifier]) {
			self.hiddenResources = hiddenResources
			self.account = Self.removeHiddenResourcesFromAccount(account: originalAccount, hiddenResources: hiddenResources)
		}

		private static func removeHiddenResourcesFromAccount(account: OnLedgerEntity.OnLedgerAccount, hiddenResources: [ResourceIdentifier]) -> OnLedgerEntity.OnLedgerAccount {
			var modified = account

			// Remove every hidden fungible resource
			modified.fungibleResources.nonXrdResources.removeAll(where: { resource in
				hiddenResources.contains(.fungible(resource.resourceAddress))
			})

			// Remove every hidden non fungible resource
			modified.nonFungibleResources.removeAll(where: { resource in
				hiddenResources.contains(.nonFungible(resource.resourceAddress))
			})

			// Remove every hidden pool unit
			modified.poolUnitResources.poolUnits.removeAll(where: { poolUnit in
				hiddenResources.contains(.poolUnit(poolUnit.resourcePoolAddress))
			})

			return modified
		}
	}

	/// Internal state that holds all loaded portfolios.
	actor State {
		typealias TokenPrices = [ResourceAddress: Decimal192]
		let portfoliosSubject: AsyncCurrentValueSubject<Loadable<[AccountAddress: AccountPortfolio]>> = .init(.loading)
		var tokenPrices: Result<TokenPrices, Error> = .success([:])

		var selectedCurrency: FiatCurrency = .usd
		var isCurrencyAmountVisible: Bool = true

		// Useful for DEBUG mode, when we want to display proper resources fiat worth on mainnet
		// but use random prices on testnets; as one resources from mainnet have prices.
		var gateway: Gateway = .mainnet
	}
}

// MARK: - Portfolio Setters/Getters
extension AccountPortfoliosClient.State {
	func setRadixGateway(_ gateway: Gateway) {
		self.gateway = gateway
	}

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

	func updatePortfoliosHiddenResources(hiddenResources: [ResourceIdentifier]) {
		if var existingPortfolios = portfoliosSubject.value.values.wrappedValue.map({ Array($0) }) {
			existingPortfolios.mutateAll { portfolio in
				portfolio.updateHiddenResources(hiddenResources: hiddenResources)
			}
			applyTokenPrices(to: &existingPortfolios)
			setOrUpdateAccountPortfolios(existingPortfolios)
		}
	}

	func portfolioForAccount(_ address: AccountAddress) -> AnyAsyncSequence<AccountPortfoliosClient.AccountPortfolio> {
		portfoliosSubject.compactMap { $0[address].unwrap()?.wrappedValue }.removeDuplicates().eraseToAnyAsyncSequence()
	}

	private func setOrUpdateAccountPortfolio(_ portfolio: AccountPortfoliosClient.AccountPortfolio) {
		portfoliosSubject.value.mutateValue {
			$0.updateValue(portfolio, forKey: portfolio.account.address)
		}
	}

	private func setOrUpdateAccountPortfolios(_ portfolios: [AccountPortfoliosClient.AccountPortfolio]) {
		var newValue: [AccountAddress: AccountPortfoliosClient.AccountPortfolio] = portfoliosSubject.value.wrappedValue ?? [:]
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
		applyCurrencyVisibility(to: &portfolio)
		applyFiatCurrency(to: &portfolio)
	}

	func setTokenPrices(_ tokenPrices: Result<TokenPrices, Error>) {
		self.tokenPrices = tokenPrices
		if var existingPortfolios = portfoliosSubject.value.values.wrappedValue.map({ Array($0) }) {
			applyTokenPrices(to: &existingPortfolios)
			setOrUpdateAccountPortfolios(existingPortfolios)
		}
	}

	func setIsCurrencyAmountVisble(_ isVisible: Bool) {
		self.isCurrencyAmountVisible = isVisible
		if var existingPortfolios = portfoliosSubject.value.values.wrappedValue.map({ Array($0) }) {
			applyCurrencyVisibility(to: &existingPortfolios)
			setOrUpdateAccountPortfolios(existingPortfolios)
		}
	}

	func setSelectedCurrency(_ currency: FiatCurrency) {
		self.selectedCurrency = currency
		if var existingPortfolios = portfoliosSubject.value.values.wrappedValue.map({ Array($0) }) {
			applyFiatCurrency(to: &existingPortfolios)
			setOrUpdateAccountPortfolios(existingPortfolios)
		}
	}

	func applyTokenPrices(to portfolios: inout [AccountPortfoliosClient.AccountPortfolio]) {
		portfolios.mutateAll(applyTokenPrices)
	}

	func applyTokenPrices(to portfolio: inout AccountPortfoliosClient.AccountPortfolio) {
		portfolio.updateFiatWorth(calculateWorth(gateway))
	}

	func applyCurrencyVisibility(to portfolio: inout AccountPortfoliosClient.AccountPortfolio) {
		portfolio.isCurrencyAmountVisible = isCurrencyAmountVisible
		portfolio.updateFiatWorth(value: isCurrencyAmountVisible, to: \.isVisible)
	}

	func applyCurrencyVisibility(to portfolios: inout [AccountPortfoliosClient.AccountPortfolio]) {
		portfolios.mutateAll(applyCurrencyVisibility)
	}

	func applyFiatCurrency(to portfolio: inout AccountPortfoliosClient.AccountPortfolio) {
		portfolio.fiatCurrency = self.selectedCurrency
		portfolio.updateFiatWorth(value: selectedCurrency, to: \.currency)
	}

	func applyFiatCurrency(to portfolios: inout [AccountPortfoliosClient.AccountPortfolio]) {
		portfolios.mutateAll(applyFiatCurrency)
	}
}

// MARK: - Stake and Pool details handling
extension AccountPortfoliosClient.State {
	func calculateWorth(_ gateway: Gateway) -> (ResourceAddress, ExactResourceAmount) -> FiatWorth? {
		{ resourceAddress, amount in
			let worth: FiatWorth.Worth? = {
				guard case let .success(tokenPrices) = self.tokenPrices else {
					return .unknown
				}

				let price = {
					#if DEBUG
					if gateway != .mainnet {
						if resourceAddress == .mainnetXRD {
							return tokenPrices[resourceAddress]
						} else {
							return tokenPrices.values.randomElement()
						}
					} else {
						return tokenPrices[resourceAddress]
					}
					#else
					return tokenPrices[resourceAddress]
					#endif
				}()
				return price.map { .known($0 * amount.nominalAmount) }
			}()

			return worth.map {
				.init(
					isVisible: self.isCurrencyAmountVisible,
					worth: $0,
					currency: self.selectedCurrency
				)
			}
		}
	}

	func set(poolDetails: Loadable<[OnLedgerEntitiesClient.OwnedResourcePoolDetails]>, forAccount address: AccountAddress) {
		guard var portfolio = portfoliosSubject.value.wrappedValue?[address] else {
			return
		}

		portfolio.poolUnitDetails = poolDetails.map { details in
			var details = details
			details.updateFiatWorth(calculateWorth(gateway))
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
			details.updateFiatWorth(calculateWorth(gateway))
			return details
		}
		setOrUpdateAccountPortfolio(portfolio)
	}
}

// MARK: Fiat Worth changes
private extension AccountPortfoliosClient.AccountPortfolio {
	mutating func updateFiatWorth<T>(value: T, to keyPath: WritableKeyPath<FiatWorth, T>) {
		updateFiatWorth { _, worth in
			var worth = worth.fiatWorth
			worth?[keyPath: keyPath] = value
			return worth
		}
	}

	mutating func updateFiatWorth(_ change: (ResourceAddress, ExactResourceAmount) -> FiatWorth?) {
		account.fungibleResources.updateFiatWorth(change)
		stakeUnitDetails.mutateValue { $0.updateFiatWorth(change) }
		poolUnitDetails.mutateValue { $0.updateFiatWorth(change) }
	}
}

extension ResourceAmount {
	mutating func updateFiatWorth(resourceAddress: ResourceAddress, change: (ResourceAddress, ExactResourceAmount) -> FiatWorth?) {
		switch self {
		case let .exact(exactAmount):
			var updatedAmount = exactAmount
			updatedAmount.fiatWorth = change(resourceAddress, exactAmount)
			self = .exact(updatedAmount)
		case let .atLeast(exactAmount):
			var updatedAmount = exactAmount
			updatedAmount.fiatWorth = change(resourceAddress, exactAmount)
			self = .atLeast(updatedAmount)
		case let .atMost(exactAmount):
			var updatedAmount = exactAmount
			updatedAmount.fiatWorth = change(resourceAddress, exactAmount)
			self = .atMost(updatedAmount)
		case let .between(minExactAmount, maxExactAmount):
			var updatedMinAmount = minExactAmount
			updatedMinAmount.fiatWorth = change(resourceAddress, minExactAmount)
			var updatedMaxAmount = maxExactAmount
			updatedMaxAmount.fiatWorth = change(resourceAddress, maxExactAmount)
			self = .between(minimum: updatedMinAmount, maximum: updatedMaxAmount)
		case .unknown:
			return
		}
	}
}

private extension OnLedgerEntity.OwnedFungibleResources {
	mutating func updateFiatWorth(_ change: (ResourceAddress, ExactResourceAmount) -> FiatWorth?) {
		xrdResource.mutate { resource in
			resource.amount.updateFiatWorth(resourceAddress: .mainnetXRD, change: change)
		}

		nonXrdResources.mutateAll { resource in
			resource.amount.updateFiatWorth(resourceAddress: resource.resourceAddress, change: change)
		}

		nonXrdResources.sort(by: <)
	}
}

private extension MutableCollection where Element == OnLedgerEntitiesClient.OwnedResourcePoolDetails {
	mutating func updateFiatWorth(_ change: (ResourceAddress, ExactResourceAmount) -> FiatWorth?) {
		mutateAll { detail in
			detail.xrdResource?.redemptionValue.mutate { amount in
				amount.updateFiatWorth(resourceAddress: .mainnetXRD, change: change)
			}

			detail.nonXrdResources.mutateAll { resource in
				let address = resource.resource.resourceAddress
				resource.redemptionValue.mutate { amount in
					amount.updateFiatWorth(resourceAddress: address, change: change)
				}
			}
		}
	}
}

private extension MutableCollection where Element == OnLedgerEntitiesClient.OwnedStakeDetails {
	mutating func updateFiatWorth(_ change: (ResourceAddress, ExactResourceAmount) -> FiatWorth?) {
		mutateAll { detail in
			var xrdRedemptionValue = detail.xrdRedemptionValue
			var stakeUnitResource = detail.stakeUnitResource
			stakeUnitResource.mutate {
				$0.amount.updateFiatWorth(resourceAddress: .mainnetXRD, change: {
					change(
						.mainnetXRD,
						detail.xrdRedemptionValue(exactAmount: $1)
					)
				})
			}
			detail.stakeClaimTokens.mutate {
				$0.stakeClaims.mutateAll { token in
					token.claimAmount.fiatWorth = change(.mainnetXRD, token.claimAmount)
				}
			}
			detail.stakeUnitResource = stakeUnitResource
		}
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

private extension OnLedgerEntity.OwnedFungibleResources {
	var fiatWorth: FiatWorth.Worth {
		let xrdFiatWorth = xrdResource?.amount.exactAmount?.fiatWorth?.worth ?? .zero
		let nonXrdFiatWorth = nonXrdResources.compactMap(\.amount.exactAmount?.fiatWorth?.worth).reduce(.zero, +)
		return xrdFiatWorth + nonXrdFiatWorth
	}
}

private extension Collection<OnLedgerEntitiesClient.OwnedStakeDetails> {
	var fiatWorth: FiatWorth.Worth {
		reduce(.zero) { partialResult, stakeUnitDetail in
			let stakeUnitFiatWorth = stakeUnitDetail.stakeUnitResource?.amount.exactAmount?.fiatWorth?.worth ?? .zero
			let stakeClaimsFiatWorth = stakeUnitDetail
				.stakeClaimTokens?
				.stakeClaims
				.compactMap(\.claimAmount.fiatWorth?.worth)
				.reduce(.zero, +) ?? .zero
			return partialResult + stakeUnitFiatWorth + stakeClaimsFiatWorth
		}
	}
}

private extension Collection<OnLedgerEntitiesClient.OwnedResourcePoolDetails> {
	var fiatWorth: FiatWorth.Worth {
		reduce(.zero) { partialResult, poolUnitDetail in
			let xrdFiatWorth = poolUnitDetail.xrdResource?.redemptionValue?.exactAmount?.fiatWorth?.worth ?? .zero
			let nonXrdFiatWorth = poolUnitDetail.nonXrdResources.compactMap(\.redemptionValue?.exactAmount?.fiatWorth?.worth).reduce(.zero, +)
			return partialResult + xrdFiatWorth + nonXrdFiatWorth
		}
	}
}
