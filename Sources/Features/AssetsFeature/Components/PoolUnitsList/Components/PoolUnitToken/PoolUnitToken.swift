import FeaturePrelude

// MARK: - PoolUnitToken
public struct PoolUnitToken: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public let id: Int
	}

	public init() {}
}
