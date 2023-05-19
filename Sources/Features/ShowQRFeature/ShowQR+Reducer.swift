import FeaturePrelude

// MARK: - ShowQR
public struct ShowQR: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: - State

	public struct State: Sendable, Hashable {
		public let accountAddress: AccountAddress

		init(accountAddress: AccountAddress) {
			self.accountAddress = accountAddress
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	// MARK: - Reducer

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		}
	}
}
