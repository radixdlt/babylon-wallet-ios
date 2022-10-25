import ComposableArchitecture
import EngineToolkit
import Mnemonic

// MARK: - NewProfile.State
public extension NewProfile {
	// MARK: State
	struct State: Equatable {
		public var networkID: NetworkID
		@BindableState public var nameOfFirstAccount: String
		public var canProceed: Bool

		public init(
			networkID: NetworkID,
			nameOfFirstAccount: String = "",
			canProceed: Bool = false
		) {
			self.networkID = networkID
			self.nameOfFirstAccount = nameOfFirstAccount
			self.canProceed = canProceed
		}
	}
}

#if DEBUG
public extension NewProfile.State {
	static let placeholder = Self(
		networkID: .primary,
		nameOfFirstAccount: "Main",
		canProceed: true
	)
}
#endif
