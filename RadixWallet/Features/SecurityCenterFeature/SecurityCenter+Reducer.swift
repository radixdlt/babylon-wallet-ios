import ComposableArchitecture

public struct SecurityCenter: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var status: Status = .good
	}

	// MARK: - Status
	public enum Status: Hashable, Sendable {
		case good
		case bad(RecoverabilityIssue, [Problem], actionsRequired: [Item])

		public enum RecoverabilityIssue: Hashable, Sendable {
			case walletNotRecoverable
			case entitiesNotRecoverable(accounts: Int, personas: Int)
			case recoveryRequired
		}

		public enum Problem: Hashable, Sendable {
			case problem3
			case problem5
			case problem6
			case problem7
			case problem9
		}
	}

	public enum Item: Hashable, Sendable {
		case securityFactors
		case configurationBackup
	}

	public enum ViewAction: Sendable, Equatable {
		case statusTapped
	}
}
