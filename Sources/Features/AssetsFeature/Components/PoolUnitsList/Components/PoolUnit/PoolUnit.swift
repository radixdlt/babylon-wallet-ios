import EngineKit
import FeaturePrelude

// MARK: - PoolUnit
public struct PoolUnit: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: ResourcePoolAddress {
			poolUnit.poolAddress
		}

		public let poolUnit: AccountPortfolio.PoolUnitResources.PoolUnit

		public init(poolUnit: AccountPortfolio.PoolUnitResources.PoolUnit) {
			self.poolUnit = poolUnit
		}
	}

	public init() {}
}
