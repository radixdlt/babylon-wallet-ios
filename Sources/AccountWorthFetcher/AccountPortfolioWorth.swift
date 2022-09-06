import Foundation

// MARK: - AccountPortfolioWorth
public struct AccountPortfolioWorth: Equatable {
	public let tokenContainers: [TokenWorthContainer]
}

// MARK: - Computed Properties
public extension AccountPortfolioWorth {
	var worth: Float? {
		tokenContainers.compactMap(\.valueInCurrency).reduce(0, +)
	}
}
