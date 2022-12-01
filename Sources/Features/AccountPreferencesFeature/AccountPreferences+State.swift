import Foundation
import Profile

// MARK: AccountPreferences.State
public extension AccountPreferences {
	// MARK: State
	struct State: Equatable {
		public let address: AccountAddress
		public var isFaucetButtonEnabled: Bool
		public var isLoading: Bool

		public init(
			address: AccountAddress,
			isFaucetButtonEnabled: Bool = false,
			isLoading: Bool = false
		) {
			self.address = address
			self.isFaucetButtonEnabled = isFaucetButtonEnabled
			self.isLoading = isLoading
		}
	}
}
