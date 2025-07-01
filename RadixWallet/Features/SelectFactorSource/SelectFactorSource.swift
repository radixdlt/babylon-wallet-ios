// MARK: - SelectFactorSource
@Reducer
struct SelectFactorSource: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var factorSourcesCandidates: [FactorSource] = []
		var selectedFactorSource: FactorSource?
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case appeared
		case selectedFactorSourceChanged(FactorSource?)
		case continueButtonTapped(FactorSource)
	}

	enum InternalAction: Equatable, Sendable {
		case setFactorSources([FactorSource])
	}

	enum DelegateAction: Equatable, Sendable {
		case selectedFactorSource(FactorSource)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				let factorSources = try await factorSourcesClient.getFactorSources().elements
				await send(.internal(.setFactorSources(factorSources)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .selectedFactorSourceChanged(factorSource):
			state.selectedFactorSource = factorSource
			return .none

		case let .continueButtonTapped(factorSource):
			return .send(.delegate(.selectedFactorSource(factorSource)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setFactorSources(factorSources):
			state.factorSourcesCandidates = factorSources
			return .none
		}
	}
}
