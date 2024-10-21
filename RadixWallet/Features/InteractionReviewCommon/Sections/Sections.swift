import Foundation

extension InteractionReviewCommon {
	struct Sections: Sendable, Hashable {
		var withdrawals: Accounts.State? = nil
		var dAppsUsed: TransactionReviewDappsUsed.State? = nil
		var deposits: Accounts.State? = nil

		var contributingToPools: TransactionReviewPools.State? = nil
		var redeemingFromPools: TransactionReviewPools.State? = nil

		var stakingToValidators: TransactionReview.ValidatorsState? = nil
		var unstakingFromValidators: TransactionReview.ValidatorsState? = nil
		var claimingFromValidators: TransactionReview.ValidatorsState? = nil

		var accountDepositSetting: TransactionReview.DepositSettingState? = nil
		var accountDepositExceptions: TransactionReview.DepositExceptionsState? = nil

		var proofs: Proofs.State? = nil
	}
}
