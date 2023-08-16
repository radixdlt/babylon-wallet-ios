import EngineKit
import FeaturePrelude

extension LSUDetails.State {
	var viewState: LSUDetails.ViewState {
		.init(
			containerWithHeader: stakeUnitResource.detailsContainerWithHeaderViewState,
			thumbnailURL: stakeUnitResource.iconURL,
			validatorNameViewState: .init(with: validator),
			redeemableTokenAmount: .init(.init(xrdAmount: xrdRedemptionValue.format())),
			resourceDetails: .init(
				description: stakeUnitResource.description,
				resourceAddress: stakeUnitResource.resourceAddress,
				validatorAddress: validator.address,
				resourceName: stakeUnitResource.name, // TODO: Is this correct?
				currentSupply: validator.xrdVaultBalance.format(),
				behaviors: stakeUnitResource.behaviors,
				tags: stakeUnitResource.tags
			)
		)
	}
}

extension LSUDetails {
	public struct ViewState: Equatable {
		let containerWithHeader: DetailsContainerWithHeaderViewState
		let thumbnailURL: URL?

		let validatorNameViewState: ValidatorNameView.ViewState

		let redeemableTokenAmount: NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>>

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
					NFTThumbnail(viewStore.thumbnailURL, size: .veryLarge)
				} detailsView: {
					VStack(spacing: .medium1) {
						Text(L10n.Account.PoolUnits.Details.currentRedeemableValue)
							.textStyle(.secondaryHeader)
							.foregroundColor(.app.gray1)

						ValidatorNameView(viewState: viewStore.validatorNameViewState)

						PoolUnitResourcesView(resources: viewStore.redeemableTokenAmount)

						AssetResourceDetailsSection(viewState: viewStore.resourceDetails)
					}
				} closeButtonAction: {
					viewStore.send(.closeButtonTapped)
				}
			}
		}
	}
}

extension ValidatorNameView.ViewState {
	init(
		with validator: AccountPortfolio.PoolUnitResources.RadixNetworkStake.Validator
	) {
		self.init(
			imageURL: validator.iconURL,
			name: validator.name ?? L10n.Account.PoolUnits.unknownValidatorName
		)
	}
}
