import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewDepositExceptions
public struct TransactionReviewDepositExceptions: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let changes: IdentifiedArrayOf<AccountChange>
	}

	public init() {}
}

// MARK: TransactionReviewDepositExceptions.AccountChange
extension TransactionReviewDepositExceptions {
	public struct AccountChange: Sendable, Identifiable, Hashable {
		public var id: AccountAddress.ID { account.address.id }
		public let account: Profile.Network.Account
		public let resourcePreferenceChanges: IdentifiedArrayOf<ResourcePreferenceChange>
		public let allowedDepositorChanges: IdentifiedArrayOf<AllowedDepositorChange>

		public struct ResourcePreferenceChange: Sendable, Identifiable, Hashable {
			public var id: OnLedgerEntity.Resource.ID { resource.id }
			public let resource: OnLedgerEntity.Resource
			public let change: ResourcePreferenceUpdate
		}

		public struct AllowedDepositorChange: Sendable, Identifiable, Hashable {
			public var id: OnLedgerEntity.Resource.ID { resource.id }
			public let resource: OnLedgerEntity.Resource
			public let change: Change

			public enum Change: Sendable, Hashable {
				case added
				case removed
			}
		}
	}
}
