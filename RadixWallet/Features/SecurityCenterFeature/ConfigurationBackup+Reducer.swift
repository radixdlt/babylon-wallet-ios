import ComposableArchitecture

public struct ConfigurationBackup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var automatedBackupsEnabled: Bool = false
		public var backedUpDate: Date = .init(timeIntervalSinceNow: -.random(in: 100 ..< 1000))
	}

	public enum Item: Sendable, Hashable, CaseIterable {
		case accounts
		case personas
		case securityFactors
		case walletSettings
	}

	public enum ViewAction: Sendable, Equatable {
		case toggleAutomatedBackups(Bool)
		case disconnectTapped
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .toggleAutomatedBackups(isEnabled):
			state.automatedBackupsEnabled = isEnabled
			return .none

		case .disconnectTapped:
			return .none
		}
	}
}
