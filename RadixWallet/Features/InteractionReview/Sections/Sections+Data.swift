import Foundation

extension InteractionReview {
	struct SectionsData: Sendable, Hashable {
		var withdrawals: Accounts.State? = nil
		var dAppsUsed: InteractionReviewDappsUsed.State? = nil
		var deposits: Accounts.State? = nil
		var accountDeletion: Accounts.State? = nil

		var contributingToPools: InteractionReviewPools.State? = nil
		var redeemingFromPools: InteractionReviewPools.State? = nil

		var stakingToValidators: InteractionReview.ValidatorsState? = nil
		var unstakingFromValidators: InteractionReview.ValidatorsState? = nil
		var claimingFromValidators: InteractionReview.ValidatorsState? = nil

		var accountDepositSetting: InteractionReview.DepositSettingState? = nil
		var accountDepositExceptions: InteractionReview.DepositExceptionsState? = nil

		var proofs: Proofs.State? = nil

		var shieldUpdate: InteractionReview.ShieldState? = nil
	}
}
