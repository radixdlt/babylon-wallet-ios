import AppSettings
import Foundation
import Profile

public extension AccountWorthFetcher {
	static let mock = Self(
		fetchWorth: { _ in
			[:]
		}
	)
}
