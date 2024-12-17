// MARK: - SecurityFactors

struct SecurityFactors: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var securityProblems: [SecurityProblem] = []

		@PresentationState
		var destination: Destination.State?

		init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case factorSourceRowTapped(FactorSourceKind)
	}

	enum InternalAction: Sendable, Equatable {
		case setSecurityProblems([SecurityProblem])
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case factorSourcesList(FactorSourcesList.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case factorSourcesList(FactorSourcesList.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.factorSourcesList, action: \.factorSourcesList) {
				FactorSourcesList()
			}
		}
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.securityCenterClient) var securityCenterClient

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return securityProblemsEffect()

		case let .factorSourceRowTapped(kind):
			state.destination = .factorSourcesList(.init(kind: kind))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setSecurityProblems(problems):
			state.securityProblems = problems
			return .none
		}
	}

	private func securityProblemsEffect() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems(.securityFactors) {
				guard !Task.isCancelled else { return }
				await send(.internal(.setSecurityProblems(problems)))
			}
		}
	}
}
