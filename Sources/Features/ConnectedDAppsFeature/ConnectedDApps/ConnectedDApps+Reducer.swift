import FeaturePrelude

// MARK: - Reducer

public struct ConnectedDApps: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>
	public init() {}
	
	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.selectedDApp, action: /Action.child .. ChildAction.selectedDApp) {
				ConnectedDApp()
			}
	}

    public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
        switch viewAction {
        case .appeared:
            return .none
		case .didSelectDApp(let name):
			// TODO: • This proxying is only necessary because of our strict view/child separation
			return .send(.child(.selectedDApp(.present(.init(name: name)))))
        }
    }
}

// MARK: - State

public extension ConnectedDApps {
	struct State: Sendable, Hashable {
		public var selectedDApp: PresentationStateOf<ConnectedDApp>
		
		public init(selectedDApp: PresentationStateOf<ConnectedDApp> = .dismissed) {
			self.selectedDApp = selectedDApp
		}
	}
}

// MARK: - Action

public extension ConnectedDApps {
	enum ViewAction: Sendable, Equatable {
		case appeared
		case didSelectDApp(String)
	}
	
	enum DelegateAction: Sendable, Equatable {
	}
	
	enum ChildAction: Sendable, Equatable {
		case selectedDApp(PresentationActionOf<ConnectedDApp>)
	}
}
