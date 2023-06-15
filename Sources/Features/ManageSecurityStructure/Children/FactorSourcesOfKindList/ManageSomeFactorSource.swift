import FeaturePrelude

// MARK: - ManageSomeFactorSource
public struct ManageSomeFactorSource<FactorSourceOfKind: FactorSourceProtocol, Extra: Sendable & Hashable>: Sendable, FeatureReducer {
	public typealias Factor = SavedOrDraftFactorSource<FactorSourceOfKind, Extra>

	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(TaskResult<Factor>)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
