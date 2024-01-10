import ComposableArchitecture
import SwiftUI

/*
 1. DetailedManifestClass.poolContribution(poolAddresses: [Address], poolContributions: [TrackedPoolContribution])
 2. ExecutionSummary.PoolContribution

 */

extension TransactionReview {
	public struct ContributingToPoolsState: Sendable, Hashable {
		public var pools: IdentifiedArrayOf<Pool>

		public struct Pool: Sendable, Identifiable, Hashable {
			public var id: AccountAddress.ID { account.address.id }
			public let account: Profile.Network.Account
		}
	}
}

/*
 public struct TrackedPoolContribution {
 	public var poolAddress: Address
 	public var contributedResources: [String: Decimal]
 	public var poolUnitsResourceAddress: Address
 	public var poolUnitsAmount: Decimal
 }
 */
