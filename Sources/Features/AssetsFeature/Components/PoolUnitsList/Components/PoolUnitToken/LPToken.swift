import FeaturePrelude

// MARK: - LPToken
public struct LPToken: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		// Int temp
		public let id: Int
	}

	public init() {}
}
