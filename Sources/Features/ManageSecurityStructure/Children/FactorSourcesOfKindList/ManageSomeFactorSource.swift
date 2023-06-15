import FeaturePrelude

// MARK: - ManageSomeFactorSource
public struct ManageSomeFactorSource<FactorSourceOfKind: FactorSourceProtocol>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(TaskResult<SavedOrDraftFactorSource<FactorSourceOfKind>>)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
