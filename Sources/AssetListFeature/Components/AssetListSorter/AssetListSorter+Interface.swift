import AccountWorthFetcher
import Foundation

// MARK: - AssetListSorter
public struct AssetListSorter {
	public var sortTokens: SortTokens

	public init(
		sortTokens: @escaping SortTokens
	) {
		self.sortTokens = sortTokens
	}
}

// MARK: - Typealias
public extension AssetListSorter {
	typealias SortTokens = @Sendable ([TokenWorthContainer]) -> [[TokenWorthContainer]]
}
