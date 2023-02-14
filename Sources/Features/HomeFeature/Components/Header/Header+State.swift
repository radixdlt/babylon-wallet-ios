import FeaturePrelude

// MARK: - Home.Header.State
extension Home.Header {
	// MARK: State
	public struct State: Sendable, Equatable {
		public var hasNotification: Bool

		public init(
			hasNotification: Bool = false
		) {
			self.hasNotification = hasNotification
		}
	}
}
