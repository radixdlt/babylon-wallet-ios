import FeaturePrelude

public struct LSUComponent: FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: String {
			stake.validator.address.address
		}

		let stake: AccountPortfolio.PoolUnitResources.RadixNetworkStake
	}
}
