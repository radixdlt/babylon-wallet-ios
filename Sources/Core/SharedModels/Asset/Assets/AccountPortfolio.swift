import Prelude

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
