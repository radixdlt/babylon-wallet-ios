import FeaturePrelude

// MARK: - PoolUnitToken
public struct PoolUnitToken: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		// temp
		public let id: Int
	}

	public init() {}
}
