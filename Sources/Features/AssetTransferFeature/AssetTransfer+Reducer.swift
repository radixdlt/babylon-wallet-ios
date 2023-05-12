import FeaturePrelude

public struct AssetTransfer: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public typealias Account = Profile.Network.Account

		public let fromAccount: Profile.Network.Account

		public var message: AssetTransferMessage.State?
		public var toAccounts: IdentifiedArrayOf<AccountTransferContainer>

		public struct AccountTransferContainer: Sendable, Hashable, Identifiable {
			public typealias ID = UUID
			public let id = ID()

			// Either user owned account, or foreign account Address
			public let account: Either<Account, AccountAddress>?
			public let assets: [String] // Just string for now as a placeholder

			public init(account: Either<AssetTransfer.State.Account, AccountAddress>?, assets: [String]) {
				self.account = account
				self.assets = assets
			}

			public static var empty: Self {
				.init(account: nil, assets: [])
			}
		}

		public init() {
			self.fromAccount = .previewValue0
			self.message = nil
			self.toAccounts = .init(uniqueElements: [.empty])
		}
	}

	public init() {}

	public enum ViewAction: Equatable, Sendable {
		case addMessageTapped
		case addAccountTapped
		case removeAccountTapped(State.AccountTransferContainer.ID)
	}

	public enum ChildAction: Equatable, Sendable {
		case message(AssetTransferMessage.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.message, action: /Action.child .. ChildAction.message) {
				AssetTransferMessage()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .addMessageTapped:
			state.message = .empty
			return .none

		case .addAccountTapped:
			state.toAccounts.append(.empty)
			return .none

		case let .removeAccountTapped(id):
			// Do not allow removing if here is only one toAccount container
			guard state.toAccounts.count > 1 else {
				return .none
			}
			state.toAccounts.remove(id: id)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .message(.delegate(.removed)):
			state.message = nil
			return .none
		default:
			return .none
		}
	}
}
