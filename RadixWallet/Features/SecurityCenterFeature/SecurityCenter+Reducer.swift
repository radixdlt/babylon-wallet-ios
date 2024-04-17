import ComposableArchitecture

public struct SecurityCenter: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var problems: [Problem] = []
		public var actionsRequired: [Item] = []

		@PresentationState
		public var destination: Destination.State? = nil
	}

	public enum Problem: Hashable, Sendable, Identifiable {
		case problem3(accounts: Int, personas: Int)
		case problem5
		case problem6
		case problem7
		case problem9

		public var id: Int { number }

		public var number: Int {
			switch self {
			case .problem3: 3
			case .problem5: 5
			case .problem6: 6
			case .problem7: 7
			case .problem9: 9
			}
		}
	}

	public enum Item: Hashable, Sendable, CaseIterable {
		case securityFactors
		case configurationBackup
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case configurationBackup(ConfigurationBackup.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case configurationBackup(ConfigurationBackup.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.configurationBackup, action: \.configurationBackup) {
				ConfigurationBackup()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case problemTapped(Problem.ID)
		case itemTapped(Item)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .problemTapped(iD):
			return .none

		case let .itemTapped(item):
			switch item {
			case .securityFactors:
				return .none
			case .configurationBackup:
				state.destination = .configurationBackup(.init())
				return .none
			}
		}
	}
}
