import Foundation
import Profile

public extension Wallet {
	static let noop = Self(
		loadAccounts: { [] }
	)
}

#if DEBUG
public extension Wallet {
	static let placeholder = Self(
		loadAccounts: {
			[.checking, .savings, .deposit]
		}
	)
}
#endif
