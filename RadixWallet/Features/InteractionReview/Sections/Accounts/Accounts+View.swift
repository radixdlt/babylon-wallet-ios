import ComposableArchitecture
import SwiftUI

// MARK: - InteractionReview.Accounts.View
extension InteractionReview.Accounts {
	struct View: SwiftUI.View {
		let store: StoreOf<InteractionReview.Accounts>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				Card {
					VStack(spacing: .small1) {
						ForEachStore(
							store.scope(state: \.accounts, action: \.child.account),
							content: { InteractionReview.Account.View(store: $0) }
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

// MARK: - InteractionReview.Account.View
extension InteractionReview.Account {
	struct View: SwiftUI.View {
		let store: StoreOf<InteractionReview.Account>

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
		switch transfer {
		case let .known(known):
			switch known.details {
			case .fungible, .nonFungible, .liquidStakeUnit, .poolUnit:
				ResourceBalanceButton(transfer.viewState, appearance: .transactionReview, warning: warning) {
					onTap(nil)
				}
			case let .stakeClaimNFT(details):
				ResourceBalanceView.StakeClaimNFT(viewState: details, appearance: .transactionReview, compact: false) { stakeClaim in
					onTap(stakeClaim.token)
				}
			}
		case .unknown:
			fatalError("Implement")
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
			amount: resource.redemptionValue.map { .init(exactAmount: $0) }
		)
	}
}

extension [KnownResourceBalance.Fungible] {
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

extension KnownResourceBalance.Fungible {
	init(resourceWithRedemptionValue resource: OnLedgerEntitiesClient.OwnedResourcePoolDetails.ResourceWithRedemptionValue, isXRD: Bool) {
		let amount: ResourceAmount = if let redemptionValue = resource.redemptionValue {
			.exact(redemptionValue)
		} else {
			.unknown
		}
		self.init(
			isXRD: isXRD,
			amount: amount,
			guarantee: nil
		)
	}
}
