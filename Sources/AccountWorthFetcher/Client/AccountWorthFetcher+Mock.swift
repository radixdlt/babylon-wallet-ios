import Foundation

public extension AccountWorthFetcher {
	static let mock = Self(
		fetchWorth: { _ in
			[:]
		}
	)
}

#if DEBUG
import XCTestDynamicOverlay

public extension AccountWorthFetcher {
	static let unimplemented = Self(
		fetchWorth: XCTUnimplemented("\(Self.self).fetchWorth")
	)
}
#endif
