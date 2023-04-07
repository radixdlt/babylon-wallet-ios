import ClientPrelude

// MARK: - AccountPortfolio
public struct AccountPortfolio: Sendable, Hashable, Identifiable {
        
	public typealias ID = AccountAddress
	public var id: ID { owner }

	public let owner: AccountAddress
	public var fungibleTokenContainers: PaginatedResourceContainer<IdentifiedArrayOf<FungibleTokenContainer>>
	public var nonFungibleTokenContainers: PaginatedResourceContainer<IdentifiedArrayOf<NonFungibleTokenContainer>>
	public var poolUnitContainers: IdentifiedArrayOf<PoolUnitContainer>
	public var badgeContainers: IdentifiedArrayOf<BadgeContainer>

	public init(
		owner: AccountAddress,
		fungibleTokenContainers: PaginatedResourceContainer<IdentifiedArrayOf<FungibleTokenContainer>>,
		nonFungibleTokenContainers: PaginatedResourceContainer<IdentifiedArrayOf<NonFungibleTokenContainer>>,
		poolUnitContainers: IdentifiedArrayOf<PoolUnitContainer>,
		badgeContainers: IdentifiedArrayOf<BadgeContainer>
	) {
		self.owner = owner
		self.fungibleTokenContainers = fungibleTokenContainers
		self.nonFungibleTokenContainers = nonFungibleTokenContainers
		self.poolUnitContainers = poolUnitContainers
		self.badgeContainers = badgeContainers
	}
}

// MARK: - Computed Properties

extension AccountPortfolio {
	public static func empty(
		owner: AccountAddress
	) -> AccountPortfolio {
		.init(
			owner: owner,
                        fungibleTokenContainers: .init(loaded: []),
			nonFungibleTokenContainers: .init(loaded: []),
			poolUnitContainers: [],
			badgeContainers: []
		)
	}
}
