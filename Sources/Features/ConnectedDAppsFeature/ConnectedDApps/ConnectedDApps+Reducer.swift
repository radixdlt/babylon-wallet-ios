import FeaturePrelude

// MARK: - Reducer

public struct ConnectedDApps: Sendable, FeatureReducer {
	public typealias Store = ComposableArchitecture.Store<State, Action>

	public init() {}
	
	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			._printChanges()
			.ifLet(\.destination, action: /Action.child .. ChildAction.destination) {
				ConnectedDApp()
			}
	}

    public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
        switch viewAction {
        case .appeared:
            return .none
		case .didTapDApp(let name):
			state.destination = .init(name: name)
			return .none
		case .dismissButtonTapped:
			return .send(.delegate(.dismiss))
        }
    }
	
	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destination(.delegate(.dismiss)):
			state.destination = nil
			return .none
		case .destination:
			return .none
		}
	}
}

// MARK: - State

public extension ConnectedDApps {
	struct State: Sendable, Equatable {
		public var destination: ConnectedDApp.State?
		
		public init(destination: ConnectedDApp.State?) {
			self.destination = destination
		}
	}
}

// MARK: - Action

public extension ConnectedDApps {
	enum ViewAction: Sendable, Equatable {
		case appeared
		case didTapDApp(String)
		case dismissButtonTapped
	}
	
	enum DelegateAction: Sendable, Equatable {
		case dismiss
	}
	
	enum ChildAction: Sendable, Equatable {
		case destination(ConnectedDApp.Action)
	}
}

// MARK: - Child Stores

extension ConnectedDApps.Store {
	var destination: Store<ConnectedDApp.State?, ConnectedDApp.Action> {
		scope(state: \.destination) { destinationAction in
			.child(.destination(destinationAction))
		}
	}
}
