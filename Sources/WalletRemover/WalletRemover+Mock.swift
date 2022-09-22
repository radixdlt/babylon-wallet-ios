import Foundation

public extension WalletRemover {
	static let mock = Self(
		removeWallet: {}
	)
}

#if DEBUG
import XCTestDynamicOverlay

public extension WalletRemover {
	static let noop = Self(
		removeWallet: {}
	)

	static let unimplemented = Self(
		removeWallet: XCTUnimplemented("\(Self.self).removeWallet")
	)
}
#endif
