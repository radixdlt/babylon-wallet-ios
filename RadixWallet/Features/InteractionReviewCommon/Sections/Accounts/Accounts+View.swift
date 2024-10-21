import ComposableArchitecture
import SwiftUI

// MARK: - InteractionReviewCommon.Accounts.View
extension InteractionReviewCommon.Accounts {
	struct View: SwiftUI.View {
		let store: StoreOf<InteractionReviewCommon.Accounts>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				Card {
					VStack(spacing: .small1) {
						ForEachStore(
							store.scope(state: \.accounts, action: \.child.account),
							content: { InteractionReviewCommon.Account.View(store: $0) }
						)

						if store.enableCustomizeGuarantees {
							Button(L10n.TransactionReview.customizeGuaranteesButtonTitle) {
								store.send(.view(.customizeGuaranteesTapped))
							}
							.textStyle(.body1Header)
							.foregroundColor(.app.blue2)
							.padding(.vertical, .small3)
						}
					}
					.padding(.small1)
				}
			}
		}
	}
}

// MARK: - InteractionReviewCommon.Account.View
extension InteractionReviewCommon.Account {
	struct View: SwiftUI.View {
		let store: StoreOf<InteractionReviewCommon.Account>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				InnerCard {
					AccountCard(account: store.account)

					VStack(spacing: .zero) {
						ForEach(store.transfers) { transfer in
							TransactionReviewResourceView(transfer: transfer.value, isDeposit: store.isDeposit) { token in
								store.send(.view(.transferTapped(transfer.value, token)))
							}

							WithPerceptionTracking {
								if transfer.id != store.transfers.last?.id {
									Rectangle()
										.fill(.app.gray4)
										.frame(height: 1)
								}
							}
						}
					}
				}
			}
		}
	}
}

// MARK: - TransactionReviewResourceView
struct TransactionReviewResourceView: View {
	let transfer: ResourceBalance // FIXME: GK use viewstate
	let isDeposit: Bool
	let onTap: (OnLedgerEntity.NonFungibleToken?) -> Void

	var body: some View {
		switch transfer.details {
		case .fungible, .nonFungible, .liquidStakeUnit, .poolUnit:
			ResourceBalanceButton(transfer.viewState, appearance: .transactionReview, warning: warning) {
				onTap(nil)
			}
		case let .stakeClaimNFT(details):
			ResourceBalanceView.StakeClaimNFT(viewState: details, appearance: .transactionReview, compact: false) { stakeClaim in
				onTap(stakeClaim.token)
			}
		}
	}

	private var warning: String? {
		guard let isHidden = transfer.isHidden, isHidden else {
			return nil
		}
		return isDeposit ? L10n.TransactionReview.HiddenAsset.deposit : L10n.TransactionReview.HiddenAsset.withdraw
	}
}

extension [ResourceBalance.ViewState.Fungible] { // FIXME: GK use full
	init(resources: OnLedgerEntitiesClient.OwnedResourcePoolDetails) {
		let xrdResource = resources.xrdResource.map {
			Element(resourceWithRedemptionValue: $0, isXRD: true)
		}
		let nonXrdResources = resources.nonXrdResources.map {
			Element(resourceWithRedemptionValue: $0, isXRD: false)
		}
		self = (xrdResource.map { [$0] } ?? []) + nonXrdResources
	}
}

extension ResourceBalance.ViewState.Fungible { // FIXME: GK use full
	init(resourceWithRedemptionValue resource: OnLedgerEntitiesClient.OwnedResourcePoolDetails.ResourceWithRedemptionValue, isXRD: Bool) {
		self.init(
			address: resource.resource.resourceAddress,
			icon: .token(isXRD ? .xrd : .other(resource.resource.metadata.iconURL)),
			title: isXRD ? Constants.xrdTokenName : resource.resource.metadata.title,
			amount: resource.redemptionValue.map { .init($0) }
		)
	}
}

extension [ResourceBalance.Fungible] {
	init(resources: OnLedgerEntitiesClient.OwnedResourcePoolDetails) {
		let xrdResource = resources.xrdResource.map {
			Element(resourceWithRedemptionValue: $0, isXRD: true)
		}
		let nonXrdResources = resources.nonXrdResources.map {
			Element(resourceWithRedemptionValue: $0, isXRD: false)
		}
		self = (xrdResource.map { [$0] } ?? []) + nonXrdResources
	}
}

extension ResourceBalance.Fungible {
	init(resourceWithRedemptionValue resource: OnLedgerEntitiesClient.OwnedResourcePoolDetails.ResourceWithRedemptionValue, isXRD: Bool) {
		self.init(
			isXRD: isXRD,
			amount: resource.redemptionValue ?? .zero, // FIXME: GK - best way to handle nil amount?
			guarantee: nil
		)
	}
}
