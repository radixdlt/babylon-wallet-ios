import ComposableArchitecture

// MARK: - SecurityCenter
public struct SecurityCenter: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var problems: [SecurityProblem] = []
		public var actionsRequired: Set<SecurityProblem.ProblemType> {
			Set(problems.map(\.type))
		}

		@PresentationState
		public var destination: Destination.State? = nil

		public init() {}
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case configurationBackup(ConfigurationBackup.State)
			case securityFactors(SecurityFactors.State)
			case displayMnemonics(DisplayMnemonics.State)
			case importMnemonics(ImportMnemonicsFlowCoordinator.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case configurationBackup(ConfigurationBackup.Action)
			case securityFactors(SecurityFactors.Action)
			case displayMnemonics(DisplayMnemonics.Action)
			case importMnemonics(ImportMnemonicsFlowCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.configurationBackup, action: \.configurationBackup) {
				ConfigurationBackup()
			}
			Scope(state: \.securityFactors, action: \.securityFactors) {
				SecurityFactors()
			}
			Scope(state: \.displayMnemonics, action: \.displayMnemonics) {
				DisplayMnemonics()
			}
			Scope(state: \.importMnemonics, action: \.importMnemonics) {
				ImportMnemonicsFlowCoordinator()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case didAppear
		case problemTapped(SecurityProblem)
		case cardTapped(SecurityProblem.ProblemType)
	}

	public enum InternalAction: Sendable, Equatable {
		case setProblems([SecurityProblem])
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	@Dependency(\.securityCenterClient) var securityCenterClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didAppear:
			return securityProblemsEffect()

		case let .problemTapped(problem):
			switch problem {
			case .problem3:
				state.destination = .displayMnemonics(.init())

			case .problem5, .problem6, .problem7:
				state.destination = .configurationBackup(.init())

			case .problem9:
				state.destination = .importMnemonics(.init())
			}
			return .none

		case let .cardTapped(type):
			switch type {
			case .securityFactors:
				state.destination = .securityFactors(.init())
				return .none

			case .configurationBackup:
				state.destination = .configurationBackup(.init())
				return .none
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setProblems(problems):
			state.problems = problems
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
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
