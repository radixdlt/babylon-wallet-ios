struct ChooseAccountsForShield: FeatureReducer {
	struct State: Hashable {
		var chooseAccounts: ChooseAccounts.State
	}

	enum ViewAction: Equatable {
		case continueButtonTapped([ChooseAccountsRow.State])
		case skipButtonTapped
	}

	@CasePathable
	enum ChildAction: Equatable {
		case chooseAccounts(ChooseAccounts.Action)
	}

	enum DelegateAction: Equatable {
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
		case .skipButtonTapped:
			return .send(.delegate(.finished([])))
		}
	}
}
