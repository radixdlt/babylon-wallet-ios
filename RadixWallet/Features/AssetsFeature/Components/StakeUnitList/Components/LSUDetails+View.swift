import ComposableArchitecture
import SwiftUI

extension LSUDetails.State {
	var viewState: LSUDetails.ViewState {
		.init(
			containerWithHeader: .init(
				title: .success(stakeUnitResource.resource.metadata.title),
				amount: stakeUnitResource.amount.formatted(),
				symbol: .success(stakeUnitResource.resource.metadata.symbol)
			),
			thumbnailURL: stakeUnitResource.resource.metadata.iconURL,
			validatorNameViewState: .init(with: validator),
			redeemableTokenAmount: .xrd(balance: xrdRedemptionValue),
			resourceDetails: .init(
				description: .success(stakeUnitResource.resource.metadata.description),
				resourceAddress: stakeUnitResource.resource.resourceAddress,
				isXRD: false,
				validatorAddress: validator.address,
				resourceName: .success(stakeUnitResource.resource.metadata.title),
				currentSupply: .success(validator.xrdVaultBalance.formatted()),
				behaviors: .success(stakeUnitResource.resource.behaviors),
				tags: .success(stakeUnitResource.resource.metadata.tags)
			)
		)
	}
}

extension LSUDetails {
	public struct ViewState: Equatable {
		let containerWithHeader: DetailsContainerWithHeaderViewState
		let thumbnailURL: URL?

		let validatorNameViewState: ValidatorHeaderView.ViewState
		let redeemableTokenAmount: ResourceBalanceViewState.Fungible
		let resourceDetails: AssetResourceDetailsSection.ViewState
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<LSUDetails>

		public init(store: StoreOf<LSUDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
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

						ResourceBalanceView(resource: .fungible(viewStore.redeemableTokenAmount), appearance: .compact(border: true))
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
