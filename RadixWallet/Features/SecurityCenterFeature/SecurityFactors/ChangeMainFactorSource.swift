// MARK: - ChangeMainFactorSource
@Reducer
struct ChangeMainFactorSource: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let kind: FactorSourceKind
		var factorSources: [FactorSource] = []
		var selected: FactorSource?
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
		case selected(FactorSource)
		case continueButtonTapped(FactorSource)
	}

	enum InternalAction: Sendable, Equatable {
		case setFactorSources([FactorSource])
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { [kind = state.kind] send in
				let factorSources = try await factorSourcesClient.getFactorSources(matching: { $0.kind == kind })
				await send(.internal(.setFactorSources(factorSources.elements)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .selected(factorSource):
			state.selected = factorSource
			return .none

		case let .continueButtonTapped(factorSource):
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setFactorSources(factorSources):
			state.factorSources = factorSources
			return .none
		}
	}
}
