import FeaturePrelude

// MARK: - SelectGenesisFactorSource.State
public extension SelectGenesisFactorSource {
	struct State: Sendable, Equatable {
		public let specifiedNameForNewEntityToCreate: String
		public let factorSources: NonEmpty<IdentifiedArrayOf<FactorSource>>
		public init(specifiedNameForNewEntityToCreate: String, factorSources: NonEmpty<IdentifiedArrayOf<FactorSource>>) {
			self.specifiedNameForNewEntityToCreate = specifiedNameForNewEntityToCreate
			self.factorSources = factorSources
		}
	}
}

#if DEBUG
public extension SelectGenesisFactorSource.State {
	static let previewValue: Self = .init(
		specifiedNameForNewEntityToCreate: "preview",
		factorSources: .previewValue
	)
}
#endif
