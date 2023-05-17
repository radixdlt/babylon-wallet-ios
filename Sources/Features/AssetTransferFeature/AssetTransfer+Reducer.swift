import FeaturePrelude

public struct AssetTransfer: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var accounts: TransferAccountList.State
		public var message: AssetTransferMessage.State?

		public var canSendTransferRequest: Bool

		public init(from account: Profile.Network.Account) {
			self.accounts = .init(fromAccount: account)
			self.message = nil
			self.canSendTransferRequest = false
		}
	}

	public init() {}

	public enum ViewAction: Equatable, Sendable {
		case closeButtonTapped
		case addMessageTapped
		case sendTransferTapped
	}

	public enum ChildAction: Equatable, Sendable {
		case message(AssetTransferMessage.Action)
		case accounts(TransferAccountList.Action)
	}

	public enum DelegateAction: Equatable, Sendable {
		case dismissed
	}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.accounts,
		      action: /Action.child .. ChildAction.accounts,
		      child: { TransferAccountList() })

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

		case .sendTransferTapped:
			return .none

		case .closeButtonTapped:
			return .send(.delegate(.dismissed))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .message(.delegate(.removed)):
			state.message = nil
			return .none
		case let .accounts(.delegate(.canSendTransferRequest(enabled))):
			state.canSendTransferRequest = enabled
			return .none
		default:
			return .none
		}
	}
}
