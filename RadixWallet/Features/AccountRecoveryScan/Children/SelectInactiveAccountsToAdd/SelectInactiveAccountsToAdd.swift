// MARK: - SelectInactiveAccountsToAdd

public struct SelectInactiveAccountsToAdd: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let active: IdentifiedArrayOf<Profile.Network.Account>
		public let inactive: IdentifiedArrayOf<Profile.Network.Account>
		public var selectedInactive: IdentifiedArrayOf<Profile.Network.Account> = []

		public init(
			active: IdentifiedArrayOf<Profile.Network.Account>,
			inactive: IdentifiedArrayOf<Profile.Network.Account>
		) {
			self.active = active
			self.inactive = inactive
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case doneTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case finished(
			selectedInactive: IdentifiedArrayOf<Profile.Network.Account>,
			active: IdentifiedArrayOf<Profile.Network.Account>
		)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .doneTapped:
			.send(
				.delegate(
					.finished(
						selectedInactive: state.selectedInactive,
						active: state.active
					)
				)
			)
		}
	}
}
