import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewDepositSetting
public struct TransactionReviewDepositSetting: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var changes: IdentifiedArrayOf<AccountChange>
	}

	public init() {}
}

// MARK: TransactionReviewDepositSetting.AccountChange
extension TransactionReviewDepositSetting {
	public struct AccountChange: Sendable, Identifiable, Hashable {
		public var id: AccountAddress.ID { account.address.id }
		public let account: Profile.Network.Account
		public let ruleChange: AccountDefaultDepositRule
	}
}
