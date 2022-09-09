import Foundation
import XCTestDynamicOverlay

public extension AccountWorthFetcher {
	static let mock = Self(
		fetchWorth: { _ in
			[:]
		}
	)
}

#if DEBUG
public extension AccountWorthFetcher {
	static let unimplemented = Self(
		fetchWorth: XCTUnimplemented("\(Self.self).fetchWorth")
	)
}
#endif
