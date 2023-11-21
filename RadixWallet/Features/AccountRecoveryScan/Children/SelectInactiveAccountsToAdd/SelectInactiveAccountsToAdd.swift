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
		case selectedAccountsChanged([ChooseAccountsRow.State]?)
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
		case let .selectedAccountsChanged(rows):
			if let rows {
				state.selectedInactive = rows.map(\.account).asIdentifiable()
			} else {
				state.selectedInactive = []
			}
			return .none
		case .doneTapped:
			return .send(
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
