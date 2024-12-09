import ComposableArchitecture

@Reducer
struct SelectFactorSources: FeatureReducer, Sendable {
	@ObservableState
	struct State: Hashable, Sendable {
		var factorSources: FactorSources = []
		var selectedFactorSources: [FactorSource]?
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable, Sendable {
		case task
		case selectedFactorSourcesChanged([FactorSource]?)
		case buildButtonTapped([FactorSource])
	}

	enum InternalAction: Equatable, Sendable {
		case factorSourcesResult(TaskResult<FactorSources>)
	}

	enum DelegateAction: Equatable, Sendable {
		case finished([FactorSource])
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				let result = await TaskResult {
					try await factorSourcesClient.getFactorSources()
				}
				await send(.internal(.factorSourcesResult(result)))
			}
		case let .selectedFactorSourcesChanged(factorSources):
			state.selectedFactorSources = factorSources
			return .none
		case let .buildButtonTapped(factorSources):
			return .send(.delegate(.finished(factorSources)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .factorSourcesResult(.success(factorSources)):
			state.factorSources = factorSources
			return .none
		case let .factorSourcesResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}
}
