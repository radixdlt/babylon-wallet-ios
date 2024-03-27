import ComposableArchitecture
import SwiftUI

extension TransactionReview {
	public struct DepositSettingState: Sendable, Hashable {
		public var changes: IdentifiedArrayOf<DepositSettingChange>
	}

	public struct DepositSettingChange: Sendable, Identifiable, Hashable {
		public var id: AccountAddress.ID { sargon() }
		public let account: Profile.Network.Account
		public let ruleChange: AccountDefaultDepositRule
	}
}

// MARK: - TransactionReview.View.DepositSettingView
extension TransactionReview.View {
	public struct DepositSettingView: View {
		public var viewState: TransactionReview.DepositSettingState

		public var body: some View {
			Card {
				VStack(spacing: .small1) {
					ForEach(viewState.changes) { change in
						AccountView(change: change)
					}
				}
				.padding(.small1)
			}
		}

		struct AccountView: View {
			let change: TransactionReview.DepositSettingChange

			var body: some SwiftUI.View {
				InnerCard {
					SmallAccountCard(account: change.account)

					HStack(spacing: .medium3) {
						Image(asset: change.ruleChange.image)
							.frame(.smallest)

						Text(LocalizedStringKey(change.ruleChange.string))
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					.padding(.medium3)
					.background(.app.gray5)
				}
			}
		}
	}
}

extension AccountDefaultDepositRule {
	var string: String {
		switch self {
		case .accept:
			L10n.TransactionReview.AccountDepositSettings.acceptAllRule
		case .reject:
			L10n.TransactionReview.AccountDepositSettings.denyAllRule
		case .allowExisting:
			L10n.TransactionReview.AccountDepositSettings.acceptKnownRule
		}
	}

	var image: ImageAsset {
		switch self {
		case .accept:
			AssetResource.iconAcceptAirdrop
		case .reject:
			AssetResource.iconDeclineAirdrop
		case .allowExisting:
			AssetResource.iconAcceptKnownAirdrop
		}
	}
}
