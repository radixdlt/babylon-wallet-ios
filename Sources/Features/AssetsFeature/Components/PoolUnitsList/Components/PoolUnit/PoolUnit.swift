import FeaturePrelude

// MARK: - PoolUnit
public struct PoolUnit: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		// Int temp
		public let id: Int
	}

	public init() {}
}
