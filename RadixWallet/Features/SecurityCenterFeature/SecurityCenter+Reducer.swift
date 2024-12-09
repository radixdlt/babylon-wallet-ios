import ComposableArchitecture

// MARK: - SecurityCenter
struct SecurityCenter: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var problems: [SecurityProblem] = []
		var actionsRequired: Set<SecurityProblemKind> {
			Set(problems.map(\.kind))
		}

		@PresentationState
		var destination: Destination.State? = nil

		init() {}
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case configurationBackup(ConfigurationBackup.State)
			case securityFactors(SecurityFactors.State)
			case deviceFactorSources(DeviceFactorSources.State)
			case importMnemonics(ImportMnemonicsFlowCoordinator.State)
			case securityShields(ShieldSetupCoordinator.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case configurationBackup(ConfigurationBackup.Action)
			case securityFactors(SecurityFactors.Action)
			case deviceFactorSources(DeviceFactorSources.Action)
			case importMnemonics(ImportMnemonicsFlowCoordinator.Action)
			case securityShields(ShieldSetupCoordinator.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.configurationBackup, action: \.configurationBackup) {
				ConfigurationBackup()
			}
			Scope(state: \.securityFactors, action: \.securityFactors) {
				SecurityFactors()
			}
			Scope(state: \.deviceFactorSources, action: \.deviceFactorSources) {
				DeviceFactorSources()
			}
			Scope(state: \.importMnemonics, action: \.importMnemonics) {
				ImportMnemonicsFlowCoordinator()
			}
			Scope(state: \.securityShields, action: \.securityShields) {
				ShieldSetupCoordinator()
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case problemTapped(SecurityProblem)
		case cardTapped(SecurityProblemKind)
	}

	enum InternalAction: Sendable, Equatable {
		case setProblems([SecurityProblem])
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	@Dependency(\.securityCenterClient) var securityCenterClient

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return securityProblemsEffect()

		case let .problemTapped(problem):
			switch problem {
			case .problem3:
				state.destination = .deviceFactorSources(.init())

			case .problem5, .problem6, .problem7:
				state.destination = .configurationBackup(.init())

			case .problem9:
				state.destination = .importMnemonics(.init())
			}
			return .none

		case let .cardTapped(type):
			switch type {
			case .securityShields:
				state.destination = .securityShields(.init())
				return .none

			case .securityFactors:
				state.destination = .securityFactors(.init())
				return .none

			case .configurationBackup:
				state.destination = .configurationBackup(.init())
				return .none
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setProblems(problems):
			state.problems = problems
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .importMnemonics(.delegate(.finishedEarly)), .importMnemonics(.delegate(.finishedImportingMnemonics)):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}

	private func securityProblemsEffect() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems() {
				guard !Task.isCancelled else { return }
				await send(.internal(.setProblems(problems)))
			}
		}
	}
}
