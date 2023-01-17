import FeaturePrelude

// MARK: - Home.Header.State
public extension Home.Header {
	// MARK: State
	struct State: Sendable, Equatable {
		public var hasNotification: Bool

		public init(
			hasNotification: Bool = false
		) {
			self.hasNotification = hasNotification
		}
	}
}
