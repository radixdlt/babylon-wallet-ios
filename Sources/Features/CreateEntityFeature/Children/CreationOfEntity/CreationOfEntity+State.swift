import Cryptography
import FeaturePrelude
import ProfileClient
import ProfileModels

// MARK: - CreationOfEntity.State
extension CreationOfEntity {
	public struct State: Sendable, Hashable {
		public let curve: Slip10Curve
		public let networkID: NetworkID?
		public let name: NonEmpty<String>
		public let genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy

		public init(
			curve: Slip10Curve,
			networkID: NetworkID?,
			name: NonEmpty<String>,
			genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy
		) {
			self.curve = curve
			self.networkID = networkID
			self.name = name
			self.genesisFactorInstanceDerivationStrategy = genesisFactorInstanceDerivationStrategy
		}
	}
}
