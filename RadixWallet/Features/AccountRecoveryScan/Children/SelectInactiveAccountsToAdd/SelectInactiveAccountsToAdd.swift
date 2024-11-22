// MARK: - SelectInactiveAccountsToAdd

struct SelectInactiveAccountsToAdd: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let active: IdentifiedArrayOf<Account>
		let deleted: IdentifiedArrayOf<Account>
		let inactive: IdentifiedArrayOf<Account>
		var selectedInactive: IdentifiedArrayOf<Account> = []
	}

	enum ViewAction: Sendable, Equatable {
		case backButtonTapped
		case doneTapped
		case selectedAccountsChanged([ChooseAccountsRow.State]?)
	}

	enum DelegateAction: Sendable, Equatable {
		case goBack
		case finished(
			selectedInactive: IdentifiedArrayOf<Account>,
			active: IdentifiedArrayOf<Account>,
			deleted: IdentifiedArrayOf<Account>
		)
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
						active: state.active,
						deleted: state.deleted
					)
				)
			)
		}
	}
}
