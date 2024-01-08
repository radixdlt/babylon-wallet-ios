import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewDepositExceptions.View
extension TransactionReviewDepositExceptions {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReviewDepositExceptions>

		public init(store: StoreOf<TransactionReviewDepositExceptions>) {
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
		let accountChange: TransactionReviewDepositExceptions.AccountChange

		var body: some SwiftUI.View {
			InnerCard {
				SmallAccountCard(account: accountChange.account)

				VStack(spacing: 1) {
					ForEach(accountChange.resourcePreferenceChanges) { change in
						ResourceChangeView(resource: change.resource, image: change.change.image, text: change.change.text)
					}
					ForEach(accountChange.allowedDepositorChanges) { change in
						ResourceChangeView(resource: change.resource, image: change.change.image, text: change.change.text)
					}
				}
				.background(.app.gray4)
			}
		}

		struct ResourceChangeView: SwiftUI.View {
			let resource: OnLedgerEntity.Resource
			let image: ImageAsset
			let text: String

			var body: some SwiftUI.View {
				HStack(spacing: 0) {
					ResourceIconNameView(resource: resource)

					Spacer(minLength: .zero)

					VStack(spacing: .small3) {
						Image(asset: image)
							.frame(.smallest)

						Text(text)
							.multilineTextAlignment(.center)
							.lineLimit(2)
							.lineSpacing(-3)
							.textStyle(.body2HighImportance)
							.foregroundColor(.app.gray1)
					}
					.frame(width: .huge1)
				}
				.padding(.medium3)
				.frame(maxWidth: .infinity)
				.background(.app.gray5)
			}
		}
	}
}

extension ResourcePreferenceUpdate {
	var image: ImageAsset {
		switch self {
		case .set(.allowed):
			AssetResource.iconAcceptAirdrop
		case .set(.disallowed):
			AssetResource.iconDeclineAirdrop
		case .remove:
			// FIXME: Is this the correct icon?
			AssetResource.iconAcceptKnownAirdrop
		}
	}

	var text: String {
		switch self {
		case .set(.allowed):
			L10n.TransactionReview.AccountDepositSettings.assetChangeAllow
		case .set(.disallowed):
			L10n.TransactionReview.AccountDepositSettings.assetChangeDisallow
		case .remove:
			L10n.TransactionReview.AccountDepositSettings.assetChangeClear
		}
	}
}

extension TransactionReviewDepositExceptions.AccountChange.AllowedDepositorChange.Change {
	var image: ImageAsset {
		switch self {
		case .added:
			AssetResource.iconPlusCircle
		case .removed:
			AssetResource.iconMinusCircle
		}
	}

	var text: String {
		switch self {
		case .added:
			L10n.TransactionReview.AccountDepositSettings.depositorChangeAdd
		case .removed:
			L10n.TransactionReview.AccountDepositSettings.depositorChangeRemove
		}
	}
}

// MARK: - ResourceIconNameView
struct ResourceIconNameView: View {
	let resource: OnLedgerEntity.Resource

	var body: some View {
		HStack(spacing: .small1) {
			if case .globalNonFungibleResourceManager = resource.resourceAddress.decodedKind {
				NFTThumbnail(resource.metadata.iconURL)
			} else {
				TokenThumbnail(.known(resource.metadata.iconURL))
			}
			Text(resource.metadata.name ?? "")
				.foregroundColor(.app.gray1)
				.textStyle(.body1HighImportance)
		}
	}
}
