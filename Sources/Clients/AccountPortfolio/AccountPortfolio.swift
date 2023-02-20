import ClientPrelude

// MARK: - AccountPortfolio
public struct AccountPortfolio: Sendable, Hashable {
	public var fungibleTokenContainers: IdentifiedArrayOf<FungibleTokenContainer>
	public var nonFungibleTokenContainers: IdentifiedArrayOf<NonFungibleTokenContainer>
	public var poolUnitContainers: IdentifiedArrayOf<PoolUnitContainer>
	public var badgeContainers: IdentifiedArrayOf<BadgeContainer>

	public init(
		fungibleTokenContainers: IdentifiedArrayOf<FungibleTokenContainer>,
		nonFungibleTokenContainers: IdentifiedArrayOf<NonFungibleTokenContainer>,
		poolUnitContainers: IdentifiedArrayOf<PoolUnitContainer>,
		badgeContainers: IdentifiedArrayOf<BadgeContainer>
	) {
		self.fungibleTokenContainers = fungibleTokenContainers
		self.nonFungibleTokenContainers = nonFungibleTokenContainers
		self.poolUnitContainers = poolUnitContainers
		self.badgeContainers = badgeContainers
	}
}

// MARK: - Computed Properties
extension AccountPortfolio {
	public var worth: BigDecimal? {
		fungibleTokenContainers.compactMap(\.worth).reduce(0, +)
	}
}

extension AccountPortfolio {
	public static let empty: AccountPortfolio = Self(
		fungibleTokenContainers: [],
		nonFungibleTokenContainers: [],
		poolUnitContainers: [],
		badgeContainers: []
	)
}
