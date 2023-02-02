import FeaturePrelude

// MARK: - LoginRequest.State
public extension LoginRequest {
	struct State: Sendable, Equatable {
		public init() {}
	}
}

#if DEBUG
public extension LoginRequest.State {
	static let previewValue: Self = .init()
}
#endif
