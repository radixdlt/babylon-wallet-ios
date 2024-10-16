import ComposableArchitecture
import SwiftUI

extension TransactionReviewAccounts.State {
	var viewState: TransactionReviewAccounts.ViewState {
		.init(showCustomizeGuaranteesButton: enableCustomizeGuarantees)
	}
}

extension TransactionReviewAccounts {
	struct ViewState: Equatable {
		let showCustomizeGuaranteesButton: Bool
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReviewAccounts>

		init(store: StoreOf<TransactionReviewAccounts>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				Card {
					VStack(spacing: .small1) {
						ForEachStore(
							store.scope(state: \.accounts, action: \.child.account),
							content: { TransactionReviewAccount.View(store: $0) }
						)

						if viewStore.showCustomizeGuaranteesButton {
							Button(L10n.TransactionReview.customizeGuaranteesButtonTitle) {
								viewStore.send(.customizeGuaranteesTapped)
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

extension TransactionReviewAccount.State {
	var viewState: TransactionReviewAccount.ViewState {
		.init(account: account, transfers: transfers.elements, showApprovedMark: account.isApproved, isDeposit: isDeposit)
	}
}

// MARK: - TransactionReviewAccount.View
extension TransactionReviewAccount {
	struct ViewState: Equatable {
		let account: TransactionReview.ReviewAccount
		let transfers: [TransactionReview.Transfer] // FIXME: GK use viewstate?
		let showApprovedMark: Bool
		let isDeposit: Bool
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReviewAccount>

		init(store: StoreOf<TransactionReviewAccount>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				InnerCard {
					AccountCard(account: viewStore.account)

					VStack(spacing: .zero) {
						ForEach(viewStore.transfers) { transfer in
							TransactionReviewResourceView(transfer: transfer.value, isDeposit: viewStore.isDeposit) { token in
								viewStore.send(.transferTapped(transfer.value, token))
							}

							if transfer.id != viewStore.transfers.last?.id {
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
