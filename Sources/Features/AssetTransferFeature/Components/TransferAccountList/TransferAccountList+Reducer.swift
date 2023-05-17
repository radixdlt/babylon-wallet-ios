import FeaturePrelude

public struct TransferAccountList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let fromAccount: Profile.Network.Account
		public var receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State>

		public init(fromAccount: Profile.Network.Account, receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State>) {
			self.fromAccount = fromAccount
			self.receivingAccounts = receivingAccounts
		}

		public init(fromAccount: Profile.Network.Account) {
			self.init(fromAccount: fromAccount, receivingAccounts: .init(uniqueElements: [.empty(canBeRemovedWhenEmpty: false)]))
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case addAccountTapped
	}

	public enum ChildAction: Equatable, Sendable {
		case receivingAccount(id: ReceivingAccount.State.ID, action: ReceivingAccount.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.receivingAccounts, action: /Action.child .. ChildAction.receivingAccount) {
				ReceivingAccount()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .addAccountTapped:
			if state.receivingAccounts.count == 1 {
				// Allow the first container to be removed
				state.receivingAccounts[0].canBeRemovedWhenEmpty = true
			}
			state.receivingAccounts.append(.empty(canBeRemovedWhenEmpty: true))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .receivingAccount(id: id, action: .delegate(.removed)):
			state.receivingAccounts.remove(id: id)

			if state.receivingAccounts.count == 1 {
				// Disable removal of the last container
				state.receivingAccounts[0].canBeRemovedWhenEmpty = false
			}

			if state.receivingAccounts.isEmpty {
				state.receivingAccounts.append(.empty(canBeRemovedWhenEmpty: false))
			}
			return .none
                // Calculate max for account/resource
                case let .receivingAccount(_, action: .child(.row(resourceAddress, child: .delegate(.amountChanged)))):
                        let totalSum = state.receivingAccounts
                                .flatMap(\.assets)
                                .filter { $0.resourceAddress == resourceAddress && !$0.amount.isEmpty }
                                .map {
                                        try! BigDecimal(fromString: $0.amount)
                                }
                                .reduce(0, +)
                        for account in state.receivingAccounts {
                                state.receivingAccounts[id: account.id]?.assets[id: resourceAddress]?.totalSum = totalSum
                        }
                        return .none
		default:
			return .none
		}
	}
}
