import ComposableArchitecture

public struct CloudBackup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {}

	public enum ViewAction: Sendable, Equatable {}
}
