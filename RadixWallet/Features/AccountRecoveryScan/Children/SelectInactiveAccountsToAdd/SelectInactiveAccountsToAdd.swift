// MARK: - SelectInactiveAccountsToAdd

public struct SelectInactiveAccountsToAdd: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let active: IdentifiedArrayOf<Account>
		public let inactive: IdentifiedArrayOf<Account>
		public var selectedInactive: IdentifiedArrayOf<Account> = []

		public init(
			active: IdentifiedArrayOf<Account>,
			inactive: IdentifiedArrayOf<Account>
		) {
			self.active = active
			self.inactive = inactive
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case backButtonTapped
		case doneTapped
		case selectedAccountsChanged([ChooseAccountsRow.State]?)
	}

	public enum DelegateAction: Sendable, Equatable {
		case goBack
		case finished(
			selectedInactive: IdentifiedArrayOf<Account>,
			active: IdentifiedArrayOf<Account>
		)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .backButtonTapped:
			return .send(.delegate(.goBack))
		case let .selectedAccountsChanged(rows):
			if let rows {
				state.selectedInactive = rows.map(\.account).asIdentified()
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
