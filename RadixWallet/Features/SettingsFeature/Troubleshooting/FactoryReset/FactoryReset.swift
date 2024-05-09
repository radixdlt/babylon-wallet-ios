// MARK: - FactoryReset

public struct FactoryReset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case resetWalletButtonTapped
	}

	public init() {}

	public func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .resetWalletButtonTapped:
			.none
		}
	}
}
