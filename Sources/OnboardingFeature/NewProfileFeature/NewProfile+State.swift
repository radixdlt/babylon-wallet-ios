import ComposableArchitecture
import Mnemonic

// MARK: - NewProfile.State
public extension NewProfile {
	// MARK: State
	struct State: Equatable {
		@BindableState public var nameOfFirstAccount: String
		public var canProceed: Bool

		public init(
			nameOfFirstAccount: String = "",
			canProceed: Bool = false
		) {
			self.nameOfFirstAccount = nameOfFirstAccount
			self.canProceed = canProceed
		}
	}
}

#if DEBUG
public extension NewProfile.State {
	static let placeholder = Self(
		nameOfFirstAccount: "Main",
		canProceed: true
	)
}
#endif
