import FeaturePrelude

// MARK: - CreationOfEntity.State
public extension CreationOfEntity {
	struct State: Sendable, Equatable {
		public let name: String
		public let genesisFactorSource: FactorSource

		public init(
			name: String,
			genesisFactorSource: FactorSource
		) {
			self.name = name
			self.genesisFactorSource = genesisFactorSource
		}
	}
}

// #if DEBUG
// public extension CreationOfEntity.State {
//	static let previewValue: Self = .init()
// }
// #endif
