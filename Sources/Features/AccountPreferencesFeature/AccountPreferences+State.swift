import FeaturePrelude

// MARK: AccountPreferences.State
public extension AccountPreferences {
	// MARK: State
	struct State: Equatable {
		public let address: AccountAddress
		public var faucetButtonState: ControlState

		public init(
			address: AccountAddress,
			faucetButtonState: ControlState = .enabled
		) {
			self.address = address
			self.faucetButtonState = faucetButtonState
		}
	}
}
