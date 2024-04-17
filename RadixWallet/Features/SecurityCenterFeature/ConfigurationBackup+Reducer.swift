import ComposableArchitecture

public struct ConfigurationBackup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {}

	public enum ViewAction: Sendable, Equatable {}
}
