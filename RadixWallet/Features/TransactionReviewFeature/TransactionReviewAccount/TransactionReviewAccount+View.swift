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

extension ResourceBalance.ViewState { // FIXME: GK use full?
	init(transfer: TransactionReview.Transfer) {
		switch transfer.details {
		case let .fungible(details):
			self = .fungible(.init(resource: transfer.resource, details: details))
		case let .nonFungible(details):
			self = .nonFungible(.init(resource: transfer.resource, details: details))
		case let .liquidStakeUnit(details):
			self = .lsu(.init(resource: transfer.resource, details: details))
		case let .poolUnit(details):
			self = .poolUnit(.init(resource: transfer.resource, details: details))
		case let .stakeClaimNFT(details):
			fatalError()
		}
	}
}

private extension ResourceBalance.ViewState.Fungible {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.Fungible) {
		self.init(
			address: resource.resourceAddress,
			icon: .token(details.isXRD ? .xrd : .other(resource.metadata.iconURL)),
			title: resource.metadata.title,
			amount: .init(details.amount, guaranteed: details.guarantee?.amount)
		)
	}
}

private extension ResourceBalance.ViewState.NonFungible {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.NonFungible) {
		self.init(
			id: details.id,
			resourceImage: resource.metadata.iconURL,
			resourceName: resource.metadata.name,
			nonFungibleName: details.data?.name
		)
	}
}

private extension ResourceBalance.ViewState.LSU {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.LiquidStakeUnit) {
		self.init(
			address: resource.resourceAddress,
			icon: resource.metadata.iconURL,
			title: resource.metadata.title,
			amount: .init(details.amount, guaranteed: details.guarantee?.amount),
			worth: .init(nominalAmount: details.worth),
			validatorName: details.validator.metadata.name
		)
	}
}

private extension ResourceBalance.ViewState.PoolUnit {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.PoolUnit) {
		self.init(
			resourcePoolAddress: details.details.address,
			poolUnitAddress: resource.resourceAddress,
			poolIcon: resource.metadata.iconURL,
			poolName: resource.fungibleResourceName,
			amount: .init(details.details.poolUnitResource.amount.nominalAmount, guaranteed: details.guarantee?.amount),
			dAppName: .success(details.details.dAppName),
			resources: .success(.init(resources: details.details))
		)
	}
}

// MARK: - TransactionReviewResourceView
struct TransactionReviewResourceView: View {
	let transfer: TransactionReview.Transfer
	let onTap: (OnLedgerEntity.NonFungibleToken?) -> Void

	var body: some View {
		switch transfer.details {
		case .fungible, .nonFungible, .liquidStakeUnit, .poolUnit:
			ResourceBalanceButton(.init(transfer: transfer), appearance: .transactionReview) {
				onTap(nil)
			}
		case let .stakeClaimNFT(details):
			StakeClaimResourceView(viewState: details, background: .app.gray5) { stakeClaim in
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
