import ComposableArchitecture
import SwiftUI

extension InteractionReview {
	typealias DepositExceptionsState = DepositExceptionsView.ViewState
	typealias DepositExceptionsChange = DepositExceptionsView.Change

	struct DepositExceptionsView: View {
		var viewState: ViewState

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
			let change: Change

			var body: some View {
				InnerCard {
					AccountCard(kind: .innerCompact, account: change.account)

					VStack(spacing: 1) {
						ForEach(change.resourcePreferenceChanges) { change in
							ResourceChangeView(resource: change.resource, image: change.change.image, text: change.change.text)
						}
						ForEach(change.allowedDepositorChanges) { change in
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
}

extension InteractionReview.DepositExceptionsView {
	struct ViewState: Sendable, Hashable {
		var changes: IdentifiedArrayOf<Change>
	}

	struct Change: Sendable, Identifiable, Hashable {
		var id: AccountAddress.ID { account.address.id }
		let account: Account
		let resourcePreferenceChanges: IdentifiedArrayOf<ResourcePreferenceChange>
		let allowedDepositorChanges: IdentifiedArrayOf<AllowedDepositorChange>

		struct ResourcePreferenceChange: Sendable, Identifiable, Hashable {
			var id: OnLedgerEntity.Resource.ID { resource.id }
			let resource: OnLedgerEntity.Resource
			let change: ResourcePreferenceUpdate
		}

		struct AllowedDepositorChange: Sendable, Identifiable, Hashable {
			var id: OnLedgerEntity.Resource.ID { resource.id }
			let resource: OnLedgerEntity.Resource
			let change: Change

			enum Change: Sendable, Hashable {
				case added
				case removed
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
			AssetResource.iconMinusCircle
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

extension InteractionReview.DepositExceptionsChange.AllowedDepositorChange.Change {
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
			if resource.resourceAddress.isNonFungible {
				Thumbnail(.nft, url: resource.metadata.iconURL)
			} else {
				Thumbnail(token: .other(resource.metadata.iconURL))
			}
			if let title = resource.metadata.title {
				Text(title)
					.foregroundColor(.app.gray1)
					.textStyle(.body1HighImportance)
			}
		}
	}
}
