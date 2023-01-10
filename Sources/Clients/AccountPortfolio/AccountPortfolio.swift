import Asset
import IdentifiedCollections
import RadixFoundation

// MARK: - AccountPortfolio
public struct AccountPortfolio: Sendable, Equatable {
	public var fungibleTokenContainers: IdentifiedArrayOf<FungibleTokenContainer>
	public var nonFungibleTokenContainers: IdentifiedArrayOf<NonFungibleTokenContainer>
	public var poolShareContainers: IdentifiedArrayOf<PoolShareContainer>
	public var badgeContainers: IdentifiedArrayOf<BadgeContainer>

	public init(
		fungibleTokenContainers: IdentifiedArrayOf<FungibleTokenContainer>,
		nonFungibleTokenContainers: IdentifiedArrayOf<NonFungibleTokenContainer>,
		poolShareContainers: IdentifiedArrayOf<PoolShareContainer>,
		badgeContainers: IdentifiedArrayOf<BadgeContainer>
	) {
		self.fungibleTokenContainers = fungibleTokenContainers
		self.nonFungibleTokenContainers = nonFungibleTokenContainers
		self.poolShareContainers = poolShareContainers
		self.badgeContainers = badgeContainers
	}
}

// MARK: - Computed Properties
public extension AccountPortfolio {
	var worth: BigUInt? {
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
