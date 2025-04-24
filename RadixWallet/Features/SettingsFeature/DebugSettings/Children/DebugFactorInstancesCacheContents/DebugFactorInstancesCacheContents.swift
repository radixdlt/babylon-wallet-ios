#if DEBUG
import Sargon

public typealias Instances = [FactorSourceIDFromHash: [[FactorInstanceForDebugPurposes]]]

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
		case deleteButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case loadedInstances(Instances)
		case failedToDelete(String)
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .failedToDelete(error):
			struct Err: LocalizedError {
				let localizedDescription: String
			}
			state.factorInstances = .failure(Err(localizedDescription: error))
			return .none
		case let .loadedInstances(instances):
			state.factorInstances = .success(instances)
			return .none
		}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .deleteButtonTapped:
			return .run { send in
				try await FileSystem.shared.deleteFactorInstancesCache()
				await send(.internal(.loadedInstances([:])))
			} catch: { error, send in
				await send(.internal(.failedToDelete(error.localizedDescription)))
			}
		case .task:
			state.factorInstances = .loading
			return .run { send in
				let instances = await SargonOS.shared.debugFactorInstancesInCache()
				await send(.internal(.loadedInstances(instances)))
			}
		}
	}
}
#endif // DEBUG
