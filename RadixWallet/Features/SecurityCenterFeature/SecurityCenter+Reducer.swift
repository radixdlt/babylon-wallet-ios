import ComposableArchitecture

public struct SecurityCenter: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var status: SecurityCenterStatus = .recoverable
		public var securityFactorsStatus: SecurityFactorsStatus = .active
		public var configurationBackupStatus: ConfigurationBackupStatus = .backedUp
	}

	public enum ViewAction: Sendable, Equatable {}
}
