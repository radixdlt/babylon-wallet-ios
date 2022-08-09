import Foundation

// MARK: - Home
/// Namespace for HeaderFeature
public extension Home {
	enum Header {}
}

public extension Home.Header {
	// MARK: State
	struct State: Equatable {
		public var hasNotification: Bool

		public init(
			hasNotification: Bool = false
		) {
			self.hasNotification = hasNotification
		}
	}
}
