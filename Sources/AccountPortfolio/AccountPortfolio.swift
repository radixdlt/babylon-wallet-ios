import Asset

// MARK: - AccountPortfolio
public struct AccountPortfolio: Equatable {
	public let fungibleTokenContainers: [FungibleTokenContainer]
	public let nonFungibleTokenContainers: [NonFungibleTokenContainer]
	public let poolShareContainers: [PoolShareContainer]
	public let badgeContainers: [BadgeContainer]

	public init(
		fungibleTokenContainers: [FungibleTokenContainer],
		nonFungibleTokenContainers: [NonFungibleTokenContainer],
		poolShareContainers: [PoolShareContainer],
		badgeContainers: [BadgeContainer]
	) {
		self.fungibleTokenContainers = fungibleTokenContainers
		self.nonFungibleTokenContainers = nonFungibleTokenContainers
		self.poolShareContainers = poolShareContainers
		self.badgeContainers = badgeContainers
	}
}

// MARK: - Computed Properties
public extension AccountPortfolio {
	var worth: Float? {
		fungibleTokenContainers.compactMap(\.worth).reduce(0, +)
	}
}

public extension AccountPortfolio {
	static let empty: AccountPortfolio = Self(
		fungibleTokenContainers: [],
		nonFungibleTokenContainers: [],
		poolShareContainers: [],
		badgeContainers: []
	)
}
