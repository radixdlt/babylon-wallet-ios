struct ChooseAccountsForShield: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var chooseAccounts: ChooseAccounts.State
		var footerControlState: ControlState = .enabled
	}

	enum ViewAction: Sendable, Equatable {
		case continueButtonTapped([ChooseAccountsRow.State])
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case chooseAccounts(ChooseAccounts.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case finished([AccountAddress])
	}

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.chooseAccounts, action: \.child.chooseAccounts) {
			ChooseAccounts()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .continueButtonTapped(selectedAccounts):
			let addresses = selectedAccounts.map(\.account.address)
			return .send(.delegate(.finished(addresses)))
		}
	}
}
