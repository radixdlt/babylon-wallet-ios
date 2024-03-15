import ComposableArchitecture
import SwiftUI

extension TransactionReviewAccounts.State {
	var viewState: TransactionReviewAccounts.ViewState {
		.init(showCustomizeGuaranteesButton: enableCustomizeGuarantees)
	}
}

extension TransactionReviewAccounts {
	public struct ViewState: Equatable {
		let showCustomizeGuaranteesButton: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReviewAccounts>

		public init(store: StoreOf<TransactionReviewAccounts>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
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
		.init(account: account, transfers: transfers.elements, showApprovedMark: account.isApproved)
	}
}

// MARK: - TransactionReviewAccount.View
extension TransactionReviewAccount {
	public struct ViewState: Equatable {
		let account: TransactionReview.Account
		let transfers: [ResourceBalance] // FIXME: GK use viewstate?
		let showApprovedMark: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReviewAccount>

		public init(store: StoreOf<TransactionReviewAccount>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				InnerCard {
					SmallAccountCard(account: viewStore.account)

					VStack(spacing: .zero) {
						ForEach(viewStore.transfers) { transfer in
							TransactionReviewResourceView(transfer: transfer) { token in
								viewStore.send(.transferTapped(transfer, token))
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
	let onTap: (OnLedgerEntity.NonFungibleToken?) -> Void

	var body: some View {
		switch transfer.details {
		case .fungible, .nonFungible, .liquidStakeUnit, .poolUnit:
			ResourceBalanceButton(transfer.viewState, appearance: .transactionReview) {
				onTap(nil)
			}
		case let .stakeClaimNFT(details):
			ResourceBalanceView.StakeClaimNFT(viewState: details, background: .app.gray5, compact: false) { stakeClaim in
				onTap(stakeClaim.token)
			}
		}
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
			amount: resource.redemptionValue ?? 0, // FIXME: GK - best way to handle nil amount?
			guarantee: nil
		)
	}
}

extension SmallAccountCard where Accessory == EmptyView {
	public init(account: TransactionReview.Account) {
		switch account {
		case let .user(account):
			self.init(
				account: account
			)

		case let .external(accountAddress, _):
			self.init(
				L10n.TransactionReview.externalAccountName,
				identifiable: .address(.account(accountAddress)),
				gradient: .init(colors: [.app.gray2]),
				verticalPadding: .small1
			)
		}
	}
}
