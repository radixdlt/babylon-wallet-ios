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

extension ResourceBalance {
	init(transfer: TransactionReview.Transfer) {
		switch transfer.details {
		case let .fungible(details):
			self = .fungible(.init(resource: transfer.resource, details: details))
		case let .nonFungible(details):
			self = .nonFungible(.init(resource: transfer.resource, details: details))
		case let .poolUnit(details):
			fatalError()
		case let .liquidStakeUnit(details):
			fatalError()
		case let .stakeClaimNFT(details):
			fatalError()
		}
	}
}

extension ResourceBalance.Fungible {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.Fungible) {
		self.init(
			address: resource.resourceAddress,
			tokenIcon: details.isXRD ? .xrd : .other(resource.metadata.iconURL),
			title: resource.metadata.title,
			amount: .init(details.amount, guaranteed: details.guarantee?.amount)
		)
	}
}

extension ResourceBalance.NonFungible {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.NonFungible) {
		self.init(
			id: details.id,
			resourceImage: resource.metadata.iconURL,
			resourceName: resource.metadata.name,
			nonFungibleName: details.data?.name
		)
	}
}

// MARK: - TransactionReviewResourceView
struct TransactionReviewResourceView: View {
	let transfer: TransactionReview.Transfer
	let onTap: (OnLedgerEntity.NonFungibleToken?) -> Void

	var body: some View {
		switch transfer.details {
		case .fungible, .nonFungible:
			ResourceBalanceButton(resource: .init(transfer: transfer)) {
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
struct TransactionReviewAmountView: View { // FIXME: REMOVE
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
			worth: details.worth,
			validatorName: details.validator.metadata.name
		)
	}
}

extension PoolUnitView.ViewState {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.PoolUnit) {
		self.init(
			poolName: resource.fungibleResourceName,
			amount: details.details.poolUnitResource.amount,
			guaranteedAmount: details.guarantee?.amount,
			dAppName: .success(details.details.dAppName),
			poolIcon: resource.metadata.iconURL,
			resources: .success(.init(resources: details.details)),
			isSelected: nil
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
			address: resource.resource.resourceAddress,
			tokenIcon: isXRD ? .xrd : .other(resource.resource.metadata.iconURL),
			title: isXRD ? Constants.xrdTokenName : resource.resource.metadata.title,
			amount: resource.redemptionValue.map { .init($0) },
			fallback: L10n.Account.PoolUnits.noTotalSupply
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
