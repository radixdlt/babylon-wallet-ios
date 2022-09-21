import Foundation

// MARK: - AccountPortfolioWorth
public struct AccountPortfolioWorth: Equatable {
	public let tokenContainers: [TokenWorthContainer]

	public init(
		tokenContainers: [TokenWorthContainer]
	) {
		self.tokenContainers = tokenContainers
	}
}

// MARK: - Computed Properties
public extension AccountPortfolioWorth {
	var worth: Float? {
		tokenContainers.compactMap(\.valueInCurrency).reduce(0, +)
	}
}
