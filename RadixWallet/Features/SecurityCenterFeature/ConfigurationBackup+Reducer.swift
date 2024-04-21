import ComposableArchitecture

public struct ConfigurationBackup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var automatedBackupsEnabled: Bool = false
		public var actionsRequired: [Item] = [.accounts]
		public var outdatedBackupPresent: Bool = true
		public var lastBackup: Date = .init(timeIntervalSinceNow: -.random(in: 100 ..< 1000))
	}

	public enum Item: Sendable, Hashable, CaseIterable {
		case accounts
		case personas
		case securityFactors
		case walletSettings
	}

	public enum ViewAction: Sendable, Equatable {
		case toggleAutomatedBackups(Bool)
		case exportTapped
		case deleteOutdatedTapped
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .toggleAutomatedBackups(isEnabled):
			state.automatedBackupsEnabled = isEnabled
			return .none

		case .exportTapped:
			return .none

		case .deleteOutdatedTapped:
			return .none
		}
	}
}
