import AppSettings
import Common
import Foundation
import Profile

// MARK: - AccountWorthFetcher
public struct AccountWorthFetcher {
	public var fetchWorth: @Sendable ([Profile.Account.Address]) async throws -> AccountsWorth
}

// MARK: - Typealias
public extension AccountWorthFetcher {
	typealias AccountsWorth = [Profile.Account.Address: AccountPortfolioWorth]
}

// MARK: - TokenWorthContainer
public struct TokenWorthContainer: Equatable {
	public let token: Token
	public let valueInCurrency: Float?
}

// MARK: - AccountPortfolioWorth
public struct AccountPortfolioWorth: Equatable {
	public let worth: Float?
	public let tokenContainers: [TokenWorthContainer]
}
