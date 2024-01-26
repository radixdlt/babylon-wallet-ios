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
							store.scope(
								state: \.accounts,
								action: { .child(.account(id: $0, action: $1)) }
							),
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
		let transfers: [TransactionReview.Transfer]
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

					VStack(spacing: 1) {
						ForEach(viewStore.transfers) { transfer in
							TransactionReviewResourceView(transfer: transfer) { token in
								viewStore.send(.transferTapped(transfer, token))
							}
						}
						.background(.app.gray5)
					}
					.background(.app.gray4)
				}
			}
		}
	}
}

// MARK: - TransactionReviewResourceView
struct TransactionReviewResourceView: View {
	let transfer: TransactionReview.Transfer
	let onTap: (OnLedgerEntity.NonFungibleToken?) -> Void

	var body: some View {
		switch transfer.details {
		case let .fungible(details):
			let viewState = TransactionReviewTokenView.ViewState(resource: transfer.resource, details: details)
			TransactionReviewTokenView(viewState: viewState, onTap: {
				onTap(nil)
			})
		case let .nonFungible(details):
			TransferNFTView(viewState: .init(resource: transfer.resource, details: details), onTap: {
				onTap(nil)
			})
		case let .poolUnit(details):
			PoolUnitView(
				viewState: .init(
					details: details.details
				),
				backgroundColor: .app.gray5,
				onTap: {
					onTap(nil)
				}
			)
		case let .stakeClaimNFT(details):
			StakeClaimNFTSView(
				viewState: details,
				onTap: { stakeClaim in
					onTap(stakeClaim.token)
				},
				onClaimAllTapped: {}
			).padding()
		}
	}
}

extension TransactionReviewTokenView.ViewState {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.Fungible) {
		self.init(
			name: resource.metadata.symbol ?? resource.metadata.name ?? L10n.TransactionReview.unknown,
			thumbnail: details.isXRD ? .xrd : .known(resource.metadata.iconURL),
			amount: details.amount,
			guaranteedAmount: details.guarantee?.amount,
			fiatAmount: nil
		)
	}
}

extension TransferNFTView.ViewState {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.NonFungible) {
		self.init(
			tokenID: details.id.localId().toUserFacingString(),
			tokenName: details.data?.name,
			thumbnail: resource.metadata.iconURL
		)
	}
}

extension PoolUnitView.ViewState {
	init(details: OnLedgerEntitiesClient.OwnedResourcePoolDetails) {
		self.init(
			poolName: details.poolUnitResource.resource.fungibleResourceName,
			dAppName: .success(details.dAppName),
			poolIcon: details.poolUnitResource.resource.metadata.iconURL,
			resources: {
				let xrdResource = details.xrdResource.map {
					PoolUnitResourceView.ViewState(resourceWithRedemptionValue: $0, isXRD: true)
				}
				.asArray(\.self)

				let nonXrdResources = details.nonXrdResources.map {
					PoolUnitResourceView.ViewState(resourceWithRedemptionValue: $0, isXRD: false)
				}

				return .success(xrdResource + nonXrdResources)
			}(),
			isSelected: nil
		)
	}
}

extension PoolUnitResourceView.ViewState {
	init(resourceWithRedemptionValue: OnLedgerEntitiesClient.OwnedResourcePoolDetails.ResourceWithRedemptionValue, isXRD: Bool) {
		self.init(
			id: resourceWithRedemptionValue.resource.id,
			symbol: resourceWithRedemptionValue.resource.metadata.symbol,
			icon: isXRD ? .xrd : .known(resourceWithRedemptionValue.resource.metadata.iconURL),
			amount: resourceWithRedemptionValue.redemptionValue
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
