import FeaturePrelude

// MARK: - DappInteraction.State
public extension DappInteraction {
	struct State: Sendable, Equatable {
		public init() {}
	}
}

#if DEBUG
public extension DappInteraction.State {
	static let previewValue: Self = .init()
}
#endif
