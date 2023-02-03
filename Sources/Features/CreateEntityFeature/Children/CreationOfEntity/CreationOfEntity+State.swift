import FeaturePrelude
import ProfileModels

// MARK: - CreationOfEntity.State
public extension CreationOfEntity {
	struct State: Sendable, Equatable {
		public let networkID: NetworkID?
		public let name: NonEmpty<String>
		public let genesisFactorSource: Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource

		public init(
			networkID: NetworkID?,
			name: NonEmpty<String>,
			genesisFactorSource: Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource
		) {
			self.networkID = networkID
			self.name = name
			self.genesisFactorSource = genesisFactorSource
		}
	}
}

// MARK: - FactorSourceNotHDCompatible
struct FactorSourceNotHDCompatible: Swift.Error {}

// #if DEBUG
// public extension CreationOfEntity.State {
//	static let previewValue: Self = .init()
// }
// #endif
