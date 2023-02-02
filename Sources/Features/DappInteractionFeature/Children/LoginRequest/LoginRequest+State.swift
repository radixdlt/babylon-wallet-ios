import FeaturePrelude

// MARK: - LoginRequest.State
public extension LoginRequest {
	struct State: Sendable, Hashable {
		public init() {}
	}
}

#if DEBUG
public extension LoginRequest.State {
	static let previewValue: Self = .init()
}
#endif
