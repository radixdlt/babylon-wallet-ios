import FeaturePrelude

// MARK: AccountPreferences.State
extension AccountPreferences {
	// MARK: State
	public struct State: Sendable, Hashable {
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
