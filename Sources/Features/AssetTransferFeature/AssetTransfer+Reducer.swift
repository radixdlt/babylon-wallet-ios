import FeaturePrelude

public struct AssetTransfer: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public typealias Account = Profile.Network.Account

		public let fromAccount: Profile.Network.Account

		public var message: AssetTransferMessage.State?
		public var toAccounts: IdentifiedArrayOf<ToAccountTransfer.State>

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
		case sendTransferTapped
	}

	public enum ChildAction: Equatable, Sendable {
		case message(AssetTransferMessage.Action)
		case toAccountTransfer(id: ToAccountTransfer.State.ID, action: ToAccountTransfer.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.message, action: /Action.child .. ChildAction.message) {
				AssetTransferMessage()
			}
			.forEach(\.toAccounts, action: /Action.child .. ChildAction.toAccountTransfer) {
				ToAccountTransfer()
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

		case .sendTransferTapped:
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .message(.delegate(.removed)):
			state.message = nil
			return .none
		case let .toAccountTransfer(id: id, action: .delegate(.removed)):
			// Do not allow removing if here is only one toAccount container
			guard state.toAccounts.count > 1 else {
				return .none
			}
			state.toAccounts.remove(id: id)
			return .none
		default:
			return .none
		}
	}
}
