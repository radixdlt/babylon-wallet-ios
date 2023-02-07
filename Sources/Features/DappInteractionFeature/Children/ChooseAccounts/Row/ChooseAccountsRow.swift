import FeaturePrelude

// MARK: - ChooseAccountsRow
struct ChooseAccountsRow: Sendable, FeatureReducer {
	struct State: Sendable, Equatable, Hashable, Identifiable {
		typealias ID = AccountAddress

		var address: AccountAddress { account.address }
		var id: ID { address }

		let account: OnNetwork.Account
		var isSelected: Bool

		init(
			account: OnNetwork.Account,
			isSelected: Bool = false
		) {
			self.account = account
			self.isSelected = isSelected
		}
	}

	enum ViewAction: Sendable, Equatable {
		case didSelect
	}

	enum DelegateAction: Sendable, Equatable {
		case didSelect
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .didSelect:
			return .send(.delegate(.didSelect))
		}
	}
}
