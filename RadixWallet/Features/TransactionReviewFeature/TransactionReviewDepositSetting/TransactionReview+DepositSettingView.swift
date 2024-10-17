import ComposableArchitecture
import SwiftUI

typealias AccountDefaultDepositRule = DepositRule

extension TransactionReview {
	struct DepositSettingState: Sendable, Hashable {
		var changes: IdentifiedArrayOf<DepositSettingChange>
	}

	struct DepositSettingChange: Sendable, Identifiable, Hashable {
		var id: AccountAddress.ID { account.address.id }
		let account: Account
		let ruleChange: AccountDefaultDepositRule
	}
}

// MARK: - TransactionReview.View.DepositSettingView
extension TransactionReview.View {
	struct DepositSettingView: View {
		var viewState: TransactionReview.DepositSettingState

		var body: some View {
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
					AccountCard(kind: .innerCompact, account: change.account)

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
		case .acceptAll:
			L10n.TransactionReview.AccountDepositSettings.acceptAllRule
		case .denyAll:
			L10n.TransactionReview.AccountDepositSettings.denyAllRule
		case .acceptKnown:
			L10n.TransactionReview.AccountDepositSettings.acceptKnownRule
		}
	}

	var image: ImageAsset {
		switch self {
		case .acceptAll:
			AssetResource.iconAcceptAirdrop
		case .denyAll:
			AssetResource.iconDeclineAirdrop
		case .acceptKnown:
			AssetResource.iconAcceptKnownAirdrop
		}
	}
}
