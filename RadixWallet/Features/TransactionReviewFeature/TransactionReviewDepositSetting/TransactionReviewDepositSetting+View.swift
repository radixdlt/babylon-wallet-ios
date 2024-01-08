import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewDepositSetting.View
extension TransactionReviewDepositSetting {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReviewDepositSetting>

		public init(store: StoreOf<TransactionReviewDepositSetting>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				Card {
					VStack(spacing: .small1) {
						ForEach(viewStore.changes) { accountChange in
							AccountView(accountChange: accountChange)
						}
					}
					.padding(.small1)
				}
			}
		}
	}

	struct AccountView: SwiftUI.View {
		let accountChange: TransactionReviewDepositSetting.AccountChange

		var body: some SwiftUI.View {
			InnerCard {
				SmallAccountCard(account: accountChange.account)

				HStack(spacing: .medium3) {
					Image(asset: accountChange.ruleChange.image)
						.frame(.smallest)

					Text(LocalizedStringKey(accountChange.ruleChange.string))
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
