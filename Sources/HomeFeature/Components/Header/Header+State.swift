import Foundation

// MARK: - Home.Header
/// Namespace for HeaderFeature
public extension Home {
	enum Header {}
}

// MARK: - Home.Header.State
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
