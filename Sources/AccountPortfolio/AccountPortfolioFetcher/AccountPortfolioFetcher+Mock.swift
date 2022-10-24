import Asset
import Foundation

public extension AccountPortfolioFetcher {
	static let mock = Self(
		fetchPortfolio: { _ in
			[:]
		}
	)
}

#if DEBUG
import XCTestDynamicOverlay

public extension AccountPortfolioFetcher {
	static let unimplemented = Self(
		fetchPortfolio: XCTUnimplemented("\(Self.self).fetchPortfolio")
	)
}
#endif
