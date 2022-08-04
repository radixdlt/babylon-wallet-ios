import Foundation

// MARK: - Home
/// Namespace for HomeFeature
public enum Home {}

public extension Home {
	// MARK: State
	struct State: Equatable {
		public var header: Home.Header.State

		public init(
			header: Home.Header.State = .init()
		) {
			self.header = header
		}
	}
}
