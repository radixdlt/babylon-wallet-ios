import FeaturePrelude

// MARK: - ChooseAccountsRow
struct ChooseAccountsRow: Sendable, FeatureReducer {
	struct State: Sendable, Equatable, Hashable, Identifiable {
		enum Mode {
			case checkmark
			case radioButton
		}

		typealias ID = AccountAddress

		var address: AccountAddress { account.address }
		var id: ID { address }

		let account: Profile.Network.Account
		let mode: Mode
		var isSelected: Bool = false

		init(
			account: Profile.Network.Account,
			mode: Mode
		) {
			self.account = account
			self.mode = mode
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
