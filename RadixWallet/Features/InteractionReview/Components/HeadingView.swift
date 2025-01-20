import SwiftUI

extension InteractionReview {
	struct HeadingView: View {
		let heading: String
		let icon: ImageAsset

		init(_ heading: String, icon: ImageAsset) {
			self.heading = heading
			self.icon = icon
		}

		var body: some View {
			HStack(spacing: .small2) {
				Image(asset: icon)
					.frame(.smallest)
					.padding(.small3)
					.overlay {
						Circle()
							.stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
							.foregroundColor(.app.gray3)
					}
				Text(heading)
					.minimumScaleFactor(0.7)
					.multilineTextAlignment(.leading)
					.lineSpacing(0)
					.sectionHeading
					.textCase(.uppercase)
			}
		}

		static let message = HeadingView(
			L10n.InteractionReview.messageHeading,
			icon: AssetResource.transactionReviewMessage
		)

		static let withdrawing = HeadingView(
			L10n.InteractionReview.withdrawalsHeading,
			icon: AssetResource.transactionReviewWithdrawing
		)

		static let deletingAccount = HeadingView(
			L10n.TransactionReview.DeletingAccount.title,
			icon: AssetResource.transactionReviewDeletingAccount
		)

		static let depositing = HeadingView(
			L10n.InteractionReview.depositsHeading,
			icon: AssetResource.transactionReviewDepositing
		)

		static let usingDapps = HeadingView(
			L10n.InteractionReview.usingDappsHeading,
			icon: AssetResource.transactionReviewDapps
		)

		static let contributingToPools = HeadingView(
			L10n.InteractionReview.poolContributionHeading,
			icon: AssetResource.transactionReviewPools
		)

		static let redeemingFromPools = HeadingView(
			L10n.InteractionReview.poolRedemptionHeading,
			icon: AssetResource.transactionReviewPools
		)

		static let stakingToValidators = HeadingView(
			L10n.InteractionReview.stakingToValidatorsHeading,
			icon: AssetResource.iconValidator
		)

		static let unstakingFromValidators = HeadingView(
			L10n.InteractionReview.unstakingFromValidatorsHeading,
			icon: AssetResource.iconValidator
		)

		static let claimingFromValidators = HeadingView(
			L10n.InteractionReview.claimFromValidatorsHeading,
			icon: AssetResource.iconValidator
		)

		static let depositSetting = HeadingView(
			L10n.InteractionReview.thirdPartyDepositSettingHeading,
			icon: AssetResource.transactionReviewDepositSetting
		)

		static let depositExceptions = HeadingView(
			L10n.InteractionReview.thirdPartyDepositExceptionsHeading,
			icon: AssetResource.transactionReviewDepositSetting
		)
	}
}
