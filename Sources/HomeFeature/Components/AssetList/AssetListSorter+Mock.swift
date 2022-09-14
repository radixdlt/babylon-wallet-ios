import Foundation

public extension AssetListSorter {
	static let mock = Self(
		sortTokens: { _ in
			[[]]
		}
	)
}
