import FeaturePrelude

// MARK: - SelectGenesisFactorSource.State
public extension SelectGenesisFactorSource {
	struct State: Sendable, Equatable {
		public let specifiedNameForNewEntityToCreate: String
		public init(specifiedNameForNewEntityToCreate: String) {
			self.specifiedNameForNewEntityToCreate = specifiedNameForNewEntityToCreate
		}
	}
}

#if DEBUG
public extension SelectGenesisFactorSource.State {
	static let previewValue: Self = .init(specifiedNameForNewEntityToCreate: "preview")
}
#endif
