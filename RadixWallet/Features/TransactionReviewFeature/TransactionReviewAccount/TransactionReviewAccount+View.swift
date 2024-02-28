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
	let transfer: TransactionReview.Transfer
	let onTap: (OnLedgerEntity.NonFungibleToken?) -> Void

	var body: some View {
		switch transfer.details {
		case let .fungible(details):
			TransactionReviewFungibleView(viewState: .init(resource: transfer.resource, details: details), background: .app.gray5) {
				onTap(nil)
			}
		case let .nonFungible(details):
			TransferNFTView(viewState: .init(resource: transfer.resource, details: details), background: .app.gray5) {
				onTap(nil)
			}
		case let .liquidStakeUnit(details):
			LiquidStakeUnitView(viewState: .init(resource: transfer.resource, details: details), background: .app.gray5) {
				onTap(nil)
			}
		case let .poolUnit(details):
			PoolUnitView(viewState: .init(resource: transfer.resource, details: details), background: .app.gray5) {
				onTap(nil)
			}
		case let .stakeClaimNFT(details):
			StakeClaimResourceView(viewState: details, background: .app.gray5) { stakeClaim in
				onTap(stakeClaim.token)
			}
		}
	}
}

// MARK: - TransactionReviewAmountView
struct TransactionReviewAmountView: View {
	let amount: RETDecimal
	let guaranteedAmount: RETDecimal?

	var body: some View {
		VStack(alignment: .trailing, spacing: 0) {
			if guaranteedAmount != nil {
				Text(L10n.TransactionReview.estimated)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray1)
			}
			Text(amount.formatted())
				.textStyle(.body1Header)
				.foregroundColor(.app.gray1)

			if let guaranteedAmount {
				Text(L10n.TransactionReview.guaranteed)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)
					.padding(.top, .small3)

				Text(guaranteedAmount.formatted())
					.textStyle(.body1Header)
					.foregroundColor(.app.gray2)
			}
		}
		.minimumScaleFactor(0.8)
	}
}

extension LiquidStakeUnitView.ViewState {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.LiquidStakeUnit) {
		self.init(
			resource: resource,
			amount: details.amount,
			guaranteedAmount: details.guarantee?.amount,
			worth: .init(nominalAmount: details.worth),
			validatorName: details.validator.metadata.name
		)
	}
}

extension TransactionReviewFungibleView.ViewState {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.Fungible) {
		self.init(
			name: resource.metadata.symbol ?? resource.metadata.name ?? L10n.TransactionReview.unknown,
			thumbnail: .token(details.isXRD ? .xrd : .other(resource.metadata.iconURL)),
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
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.PoolUnit) {
		self.init(
			poolName: resource.fungibleResourceName,
			amount: details.details.poolUnitResource.amount.nominalAmount,
			guaranteedAmount: details.guarantee?.amount,
			dAppName: .success(details.details.dAppName),
			poolIcon: resource.metadata.iconURL,
			resources: .success(.init(resources: details.details)),
			isSelected: nil
		)
	}
}

extension [PoolUnitResourceView.ViewState] {
	init(resources: OnLedgerEntitiesClient.OwnedResourcePoolDetails) {
		let xrdResource = resources.xrdResource.map {
			PoolUnitResourceView.ViewState(resourceWithRedemptionValue: $0, isXRD: true)
		}
		let nonXrdResources = resources.nonXrdResources.map {
			PoolUnitResourceView.ViewState(resourceWithRedemptionValue: $0, isXRD: false)
		}

		self = (xrdResource.map { [$0] } ?? []) + nonXrdResources
	}
}

extension PoolUnitResourceView.ViewState {
	init(resourceWithRedemptionValue resource: OnLedgerEntitiesClient.OwnedResourcePoolDetails.ResourceWithRedemptionValue, isXRD: Bool) {
		self.init(
			id: resource.resource.id,
			symbol: isXRD ? Constants.xrdTokenName : resource.resource.title ?? L10n.TransactionReview.unknown,
			icon: .token(isXRD ? .xrd : .other(resource.resource.metadata.iconURL)),
			amount: resource.redemptionValue,
			fiatWorth: resource.fiatWorth
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
