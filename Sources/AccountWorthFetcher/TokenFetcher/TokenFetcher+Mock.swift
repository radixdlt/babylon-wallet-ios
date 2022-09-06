import Foundation

public extension TokenFetcher {
	static let mock = Self(
		fetchTokens: { _ in
			[]
		}
	)
}
