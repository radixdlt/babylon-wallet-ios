import Foundation
import Profile

#if DEBUG
public extension Wallet {
	static let noop = Self(
		loadAccounts: { [] }
	)

	static let placeholder = Self(
		loadAccounts: { [] }
	)
}
#endif
