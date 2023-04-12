import Foundation
import ClientPrelude

public actor AccountPortfoliosClient {
        public var fetchAccountPortfolios: FetchAccountPortfolios
        public var fetchAccountPortfolio: FetchAccountPortfolio
        public var fetchMoreFungibleTokens: FetchMoreFungibleTokens
        public var fetchMoreNonFungibleTokens: FetchMoreNonFungibleTokens
        public var portfolioForAccount: PortfolioForAccount

        public let portfolios: AsyncCurrentValueSubject<Set<AccountPortfolio>>

        internal init(fetchAccountPortfolios: @escaping FetchAccountPortfolios,
                      fetchAccountPortfolio: @escaping FetchAccountPortfolio,
                      fetchMoreFungibleTokens: @escaping FetchMoreFungibleTokens,
                      fetchMoreNonFungibleTokens: @escaping FetchMoreNonFungibleTokens,
                      portfolioForAccount: @escaping PortfolioForAccount,
                      portfolios: AsyncCurrentValueSubject<Set<AccountPortfolio>>) {
                self.fetchAccountPortfolios = fetchAccountPortfolios
                self.fetchAccountPortfolio = fetchAccountPortfolio
                self.fetchMoreFungibleTokens = fetchMoreFungibleTokens
                self.fetchMoreNonFungibleTokens = fetchMoreNonFungibleTokens
                self.portfolioForAccount = portfolioForAccount
                self.portfolios = portfolios
        }
}

extension DependencyValues {
        public var accountPortfoliosClient: AccountPortfoliosClient {
                get { self[AccountPortfoliosClient.self] }
                set { self[AccountPortfoliosClient.self] = newValue }
        }
}

extension AccountPortfoliosClient {
        public typealias FetchAccountPortfolios = @Sendable (_ addresses: [AccountAddress]) async throws -> [AccountPortfolio]
        public typealias FetchAccountPortfolio = @Sendable (_ address: AccountAddress) async throws -> AccountPortfolio

        public typealias FetchMoreFungibleTokens = @Sendable (_ address: AccountAddress) async throws -> AccountPortfolio
        public typealias FetchMoreNonFungibleTokens = @Sendable (_ address: AccountAddress) async throws -> AccountPortfolio
        public typealias PortfolioForAccount = @Sendable (_ address: AccountAddress) -> AnyAsyncSequence<AccountPortfolio>
}

public struct AccountPortfolio: Sendable, Hashable {
        public let owner: AccountAddress
        public var fungibleResources: PaginatedResourceContainer<[FungibleToken]>
        public var nonFungibleResources: PaginatedResourceContainer<[NonFungibleToken]>
}

extension AccountPortfolio {
        public struct FungibleToken: Sendable, Hashable {
                public let resourceAddress: ResourceAddress
                public let amount: BigDecimal
                public let divisibility: Int?
                public let name: String?
                public let symbol: String?
                public let tokenDescription: String?
        }
        
        public struct NonFungibleToken: Sendable, Hashable {
                public let resourceAddress: ResourceAddress
                public let name: String?
                public let description: String?
                // The number of tokens owned by the Account
                public let amount: Int

                // TODO: Should not be just string
                public let ids: PaginatedResourceContainer<[String]>
        }
}
