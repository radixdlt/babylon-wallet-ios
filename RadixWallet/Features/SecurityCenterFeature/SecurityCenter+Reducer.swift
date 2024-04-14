import ComposableArchitecture

public struct SecurityCenter: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {}

	public enum ViewAction: Sendable, Equatable {}
}
