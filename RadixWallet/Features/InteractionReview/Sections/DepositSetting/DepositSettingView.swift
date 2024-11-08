import ComposableArchitecture
import SwiftUI

typealias AccountDefaultDepositRule = DepositRule

// MARK: - TransactionReview.View.DepositSettingView
extension InteractionReview {
	typealias DepositSettingState = DepositSettingView.ViewState
	typealias DepositSettingChange = DepositSettingState.Change

	struct DepositSettingView: View {
		let viewState: ViewState

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
			let change: ViewState.Change

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

// MARK: - InteractionReview.DepositSettingView.ViewState
extension InteractionReview.DepositSettingView {
	struct ViewState: Sendable, Hashable {
		let changes: IdentifiedArrayOf<Change>

		struct Change: Sendable, Identifiable, Hashable {
			var id: AccountAddress.ID { account.address.id }
			let account: Account
			let ruleChange: AccountDefaultDepositRule
		}
	}
}

extension AccountDefaultDepositRule {
	var string: String {
		switch self {
		case .acceptAll:
			L10n.InteractionReview.DepositSettings.acceptAllRule
		case .denyAll:
			L10n.InteractionReview.DepositSettings.denyAllRule
		case .acceptKnown:
			L10n.InteractionReview.DepositSettings.acceptKnownRule
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
