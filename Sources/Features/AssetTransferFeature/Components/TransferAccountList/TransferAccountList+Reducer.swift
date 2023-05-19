import FeaturePrelude

public struct TransferAccountList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let fromAccount: Profile.Network.Account
		public var receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State> {
			didSet {
				if receivingAccounts.count > 1, receivingAccounts[0].canBeRemoved == false {
					receivingAccounts[0].canBeRemoved = true
				}

				if receivingAccounts.count == 1, receivingAccounts[0].canBeRemoved == true {
					receivingAccounts[0].canBeRemoved = false
				}

				if receivingAccounts.isEmpty {
					receivingAccounts.append(.empty(canBeRemovedWhenEmpty: false))
				}
			}
		}

		public init(fromAccount: Profile.Network.Account, receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State>) {
			self.fromAccount = fromAccount
			self.receivingAccounts = receivingAccounts
		}

		public init(fromAccount: Profile.Network.Account) {
			self.init(
				fromAccount: fromAccount,
				receivingAccounts: .init(uniqueElements: [.empty(canBeRemovedWhenEmpty: false)])
			)
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case addAccountTapped
	}

	public enum ChildAction: Equatable, Sendable {
		case receivingAccount(id: ReceivingAccount.State.ID, action: ReceivingAccount.Action)
	}

	public enum DelegateAction: Equatable, Sendable {
		case canSendTransferRequest(Bool)
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
			state.receivingAccounts.append(.empty(canBeRemovedWhenEmpty: true))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .receivingAccount(id: id, action: .delegate(.remove)):
			state.receivingAccounts.remove(id: id)
			return validateState(&state)
		case .receivingAccount(_, action: .delegate(.validate)):
			return validateState(&state)

		case let .receivingAccount(_, action: .child(.row(resourceAddress, child: .delegate(.fungibleAsset(.amountChanged))))):
			updateTotalSum(&state, resourceAddress: resourceAddress)
			return validateState(&state)
		default:
			return .none
		}
	}

	private func updateTotalSum(_ state: inout State, resourceAddress: ResourceAddress) {
		let totalSum = state.receivingAccounts
			.flatMap(\.assets)
			.compactMap(/ResourceAsset.State.fungibleAsset)
			.filter { $0.resource.resourceAddress == resourceAddress }
			.compactMap(\.transferAmount)
			.reduce(0, +)

		for account in state.receivingAccounts {
			guard case var .fungibleAsset(asset) = state.receivingAccounts[id: account.id]?.assets[id: resourceAddress] else {
				continue
			}

			asset.totalTransferSum = totalSum
			state.receivingAccounts[id: account.id]?.assets[id: resourceAddress] = .fungibleAsset(asset)
		}
	}

	private func validateState(_ state: inout State) -> EffectTask<Action> {
		let receivingAccounts = state.receivingAccounts.filter {
			$0.account != nil || !$0.assets.isEmpty
		}

		guard !receivingAccounts.isEmpty else {
			return .send(.delegate(.canSendTransferRequest(false)))
		}

		let isValid = receivingAccounts.allSatisfy {
			$0.account != nil &&
				!$0.assets.isEmpty &&
				$0.assets
				.compactMap(/ResourceAsset.State.fungibleAsset)
				.allSatisfy { $0.transferAmount != nil && $0.totalTransferSum <= $0.balance }
		}

		return .send(.delegate(.canSendTransferRequest(isValid)))
	}
}
