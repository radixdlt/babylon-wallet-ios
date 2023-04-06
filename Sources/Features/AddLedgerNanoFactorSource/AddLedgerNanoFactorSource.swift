import FeaturePrelude

// MARK: - AddLedgerNanoFactorSource
public struct AddLedgerNanoFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case finishedButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .finishedButtonTapped:
			return .send(.delegate(.completed))
		}
	}
}
