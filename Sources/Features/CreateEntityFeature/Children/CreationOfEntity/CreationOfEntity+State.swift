import FeaturePrelude
import ProfileClient
import ProfileModels

// MARK: - CreationOfEntity.State
public extension CreationOfEntity {
	struct State: Sendable, Equatable {
		public let networkID: NetworkID?
		public let name: NonEmpty<String>
		public let genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy

		public init(
			networkID: NetworkID?,
			name: NonEmpty<String>,
			genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy
		) {
			self.networkID = networkID
			self.name = name
			self.genesisFactorInstanceDerivationStrategy = genesisFactorInstanceDerivationStrategy
		}
	}
}
