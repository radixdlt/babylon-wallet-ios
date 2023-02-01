import FeaturePrelude

// MARK: - SelectGenesisFactorSource.State
public extension SelectGenesisFactorSource {
	struct State: Sendable, Equatable {
		public init() {}
	}
}

#if DEBUG
public extension SelectGenesisFactorSource.State {
	static let previewValue: Self = .init()
}
#endif
