import Asset
import Dependencies

// MARK: - FungibleTokenListSorter
public struct FungibleTokenListSorter: DependencyKey {
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

public extension DependencyValues {
	var fungibleTokenListSorter: FungibleTokenListSorter {
		get { self[FungibleTokenListSorter.self] }
		set { self[FungibleTokenListSorter.self] = newValue }
	}
}
