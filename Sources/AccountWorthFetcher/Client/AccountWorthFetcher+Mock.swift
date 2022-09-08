import Foundation

public extension AccountWorthFetcher {
	static let mock = Self(
		fetchWorth: { _ in
			[:]
		}
	)
}
