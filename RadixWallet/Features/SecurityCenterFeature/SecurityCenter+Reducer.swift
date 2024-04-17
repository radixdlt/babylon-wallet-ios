import ComposableArchitecture

public struct SecurityCenter: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var status: Status = .good
	}

	public enum Item: Hashable {
		case securityFactors
		case configurationBackup
	}

	// MARK: - Status
	public enum Status: Hashable {
		case good
		case bad(RecoverabilityIssue, Problem, actionsRequired: [Item])

		public enum RecoverabilityIssue: Hashable {
			case walletNotRecoverable
			case entitiesNotRecoverable(accounts: Int, personas: Int)
			case recoveryRequired
		}

		public enum Problem: Hashable {
			case problem3
			case problem5
			case problem6
			case problem7
			case problem9
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case statusTapped
	}
}
