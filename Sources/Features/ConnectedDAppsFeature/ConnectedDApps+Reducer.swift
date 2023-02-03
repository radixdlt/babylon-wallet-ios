import FeaturePrelude

// MARK: - ConnectedDApps
public struct ConnectedDApps: Sendable, FeatureReducer {
    public init() {}

    public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
        switch viewAction {
        case .appeared:
            return .none
		case .dismissButtonTapped:
			return .task { .delegate(.dismiss) }
        }
    }
}

// STATE

public extension ConnectedDApps {
    struct State: Sendable, Equatable {
        public init() {}
    }
}

// ACTION

public extension ConnectedDApps {
    enum ViewAction: Sendable, Equatable {
        case appeared
		case dismissButtonTapped
    }
	
    enum DelegateAction: Sendable, Equatable {
		case dismiss
    }
}
