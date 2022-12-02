import Foundation

// MARK: - NewConnection.State
public extension NewConnection {
	struct State: Equatable {
		public init() {}
	}
}

#if DEBUG
public extension NewConnection.State {
	static let previewValue: Self = .init()
}
#endif
