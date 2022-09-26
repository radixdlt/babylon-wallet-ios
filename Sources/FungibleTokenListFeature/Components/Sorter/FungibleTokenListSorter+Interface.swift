import Asset

// MARK: - FungibleTokenListSorter
public struct FungibleTokenListSorter {
	public var sortTokens: SortTokens

	public init(
		sortTokens: @escaping SortTokens
	) {
		self.sortTokens = sortTokens
	}
}

// MARK: FungibleTokenListSorter.SortTokens
public extension FungibleTokenListSorter {
	typealias SortTokens = @Sendable ([FungibleTokenContainer]) -> [FungibleTokenCategory]
}
