import Sargon

public typealias Instances = [FactorSourceIDFromHash: [[HierarchicalDeterministicFactorInstance]]]

// MARK: - DebugFactorInstancesCacheContents
@Reducer
struct DebugFactorInstancesCacheContents: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
        var factorInstances: Loadable<Instances> = .idle
		init() {}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
	}
    
    enum InternalAction: Sendable, Equatable {
        case loadedInstances(Instances)
    }

	var body: some ReducerOf<Self> {
		Reduce(core)
	}
    
    func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
        switch internalAction {
        case let .loadedInstances(instances):
            state.factorInstances = .success(instances)
            return .none
        }
    }

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
            state.factorInstances = .loading
                return .run { send in
                    
                    let instances = await SargonOS.shared.factorInstancesInCache()
                    await send(.internal(.loadedInstances(instances)))
                }
		}
	}
}
