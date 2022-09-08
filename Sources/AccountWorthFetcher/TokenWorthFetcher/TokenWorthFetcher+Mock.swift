import Foundation

public extension TokenWorthFetcher {
	static let mock = Self(
		fetchWorth: { _, _ in
			[]
		}, fetchSingleTokenWorth: { _, _ in
			0
		}
	)
}
