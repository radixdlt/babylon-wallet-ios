import ComposableArchitecture

// MARK: - SecurityCenter
public struct SecurityCenter: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var problems: [SecurityProblem] = []
		public var actionsRequired: [Item] = []

		@PresentationState
		public var destination: Destination.State? = nil

		public init() {}
	}

	public enum Item: Hashable, Sendable, CaseIterable {
		case securityFactors
		case configurationBackup
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case configurationBackup(ConfigurationBackup.State)
			case securityFactors(SecurityFactors.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case configurationBackup(ConfigurationBackup.Action)
			case securityFactors(SecurityFactors.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.configurationBackup, action: \.configurationBackup) {
				ConfigurationBackup()
			}
			Scope(state: \.securityFactors, action: \.securityFactors) {
				SecurityFactors()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case didAppear
		case problemTapped(SecurityProblem.ID)
		case itemTapped(Item)
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
			return problemsSubscriptionEffect()

		case let .problemTapped(id):
			return .none

		case let .itemTapped(item):
			switch item {
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

	private func problemsSubscriptionEffect() -> Effect<Action> {
		print("•• SC subscribe"); return
			.run { send in
				let profileID = await ProfileStore.shared.profile.id
				for try await problems in await securityCenterClient.problems(profileID) {
					print("•• SC emit")
					guard !Task.isCancelled else { print("•• SC cancelled"); return }
					await send(.internal(.setProblems(problems)))
				}
			}
	}
}
