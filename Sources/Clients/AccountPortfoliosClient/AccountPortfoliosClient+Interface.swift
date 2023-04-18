import ClientPrelude
import Foundation
import SharedModels

// MARK: - AccountPortfoliosClient
public actor AccountPortfoliosClient {
	public var fetchAccountPortfolios: FetchAccountPortfolios
	public var fetchAccountPortfolio: FetchAccountPortfolio
        public var fetchAccountNonFungibleResourceIds: FetchAccountNonFungibleResourceIds
//	public var fetchMoreFungibleTokens: FetchMoreFungibleTokens
//	public var fetchMoreNonFungibleTokens: FetchMoreNonFungibleTokens
	public var portfolioForAccount: PortfolioForAccount

	public let portfolios: AsyncCurrentValueSubject<Set<AccountPortfolio>>

	internal init(fetchAccountPortfolios: @escaping FetchAccountPortfolios,
	              fetchAccountPortfolio: @escaping FetchAccountPortfolio,
                      fetchAccountNonFungibleResourceIds: @escaping FetchAccountNonFungibleResourceIds,
//	              fetchMoreFungibleTokens: @escaping FetchMoreFungibleTokens,
//	              fetchMoreNonFungibleTokens: @escaping FetchMoreNonFungibleTokens,
	              portfolioForAccount: @escaping PortfolioForAccount,
	              portfolios: AsyncCurrentValueSubject<Set<AccountPortfolio>>)
	{
		self.fetchAccountPortfolios = fetchAccountPortfolios
		self.fetchAccountPortfolio = fetchAccountPortfolio
                self.fetchAccountNonFungibleResourceIds = fetchAccountNonFungibleResourceIds
//		self.fetchMoreFungibleTokens = fetchMoreFungibleTokens
//		self.fetchMoreNonFungibleTokens = fetchMoreNonFungibleTokens
		self.portfolioForAccount = portfolioForAccount
		self.portfolios = portfolios
	}
}

extension AccountPortfoliosClient {
	public typealias FetchAccountPortfolios = @Sendable (_ addresses: [AccountAddress]) async throws -> [AccountPortfolio]
	public typealias FetchAccountPortfolio = @Sendable (_ address: AccountAddress, _ refresh: Bool) async throws -> AccountPortfolio
        public typealias FetchAccountNonFungibleResourceIds = @Sendable (_ address: AccountAddress, _ resourceAddress: ResourceAddress) async throws -> [String]

	public typealias FetchMoreFungibleTokens = @Sendable (_ address: AccountAddress) async throws -> AccountPortfolio
	public typealias FetchMoreNonFungibleTokens = @Sendable (_ address: AccountAddress) async throws -> AccountPortfolio
	public typealias PortfolioForAccount = @Sendable (_ address: AccountAddress) -> AnyAsyncSequence<AccountPortfolio>
}

extension DependencyValues {
	public var accountPortfoliosClient: AccountPortfoliosClient {
		get { self[AccountPortfoliosClient.self] }
		set { self[AccountPortfoliosClient.self] = newValue }
	}
}
