import ComposableArchitecture
import SwiftUI

extension LSUDetails.State {
	var viewState: LSUDetails.ViewState {
		.init(
			containerWithHeader: .init(
				title: .success(stakeUnitResource.resource.metadata.title),
				amount: stakeUnitResource.amount.nominalAmount.formatted(),
				currencyWorth: nil,
				symbol: .success(stakeUnitResource.resource.metadata.symbol)
			),
			thumbnailURL: stakeUnitResource.resource.metadata.iconURL,
			validatorNameViewState: .init(with: validator),
			redeemableTokenAmount: .xrd(balance: xrdRedemptionValue, network: validator.address.networkID),
			resourceDetails: .init(
				description: .success(stakeUnitResource.resource.metadata.description),
				infoUrl: .success(stakeUnitResource.resource.metadata.infoURL),
				resourceAddress: stakeUnitResource.resource.resourceAddress,
				isXRD: false,
				validatorAddress: validator.address,
				resourceName: .success(stakeUnitResource.resource.metadata.title),
				currentSupply: .success(validator.xrdVaultBalance.formatted()),
				divisibility: .success(stakeUnitResource.resource.divisibility),
				arbitraryDataFields: .success(stakeUnitResource.resource.metadata.arbitraryItems.asDataFields),
				behaviors: .success(stakeUnitResource.resource.behaviors),
				tags: .success(stakeUnitResource.resource.metadata.tags)
			)
		)
	}
}

extension LSUDetails {
	struct ViewState: Equatable {
		let containerWithHeader: DetailsContainerWithHeaderViewState
		let thumbnailURL: URL?

		let validatorNameViewState: ValidatorHeaderView.ViewState
		let redeemableTokenAmount: ResourceBalance.ViewState.Fungible
		let resourceDetails: AssetResourceDetailsSection.ViewState
	}

	struct View: SwiftUI.View {
		private let store: StoreOf<LSUDetails>

		init(store: StoreOf<LSUDetails>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: LSUDetails.Action.view
			) { viewStore in
				DetailsContainerWithHeaderView(viewState: viewStore.containerWithHeader) {
					viewStore.send(.closeButtonTapped)
				} thumbnailView: {
					Thumbnail(.nft, url: viewStore.thumbnailURL, size: .veryLarge)
				} detailsView: {
					VStack(spacing: .medium1) {
						AssetDetailsSeparator()

						Text(L10n.Account.PoolUnits.Details.currentRedeemableValue)
							.textStyle(.secondaryHeader)
							.foregroundColor(.app.gray1)

						ValidatorHeaderView(viewState: viewStore.validatorNameViewState)
							.padding(.horizontal, .large2)

						ResourceBalanceView(.fungible(viewStore.redeemableTokenAmount), appearance: .compact(border: true))
							.padding(.horizontal, .large2)

						AssetResourceDetailsSection(viewState: viewStore.resourceDetails)
					}
					.padding(.bottom, .medium1)
				}
			}
		}
	}
}

extension ValidatorHeaderView.ViewState {
	init(
		with validator: OnLedgerEntity.Validator
	) {
		self.init(
			imageURL: validator.metadata.iconURL,
			name: validator.metadata.name,
			stakedAmount: nil
		)
	}
}
