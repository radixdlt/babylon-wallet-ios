import ComposableArchitecture

// MARK: - SecurityProblem
public enum SecurityProblem: Hashable, Sendable, Identifiable {
	case problem5
	case problem6
	case problem7

	public var id: Int { number }

	public var number: Int {
		switch self {
		case .problem5: 5
		case .problem6: 6
		case .problem7: 7
		}
	}
}

// MARK: - SecurityCenter
public struct SecurityCenter: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var problems: [SecurityProblem] = Bool.random() ? [.problem5] : []
		public var actionsRequired: [Item] = []

		@PresentationState
		public var destination: Destination.State? = nil
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
		case problemTapped(SecurityProblem.ID)
		case itemTapped(Item)
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .problemTapped(id):
			return .none

		case let .itemTapped(item):
			switch item {
			case .securityFactors:
				state.destination = .securityFactors(.init())
				return .none

			case .configurationBackup:
				state.destination = .configurationBackup(.init(problems: state.problems))
				return .none
			}
		}
	}
}
