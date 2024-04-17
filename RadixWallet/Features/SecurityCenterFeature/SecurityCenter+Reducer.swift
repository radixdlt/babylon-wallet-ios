import ComposableArchitecture

public struct SecurityCenter: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var problems: [Problem] = []
		public var actionsRequired: [Item] = []
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

	public enum ViewAction: Sendable, Equatable {
		case problemTapped(Problem.ID)
		case itemTapped(Item)
	}
}
