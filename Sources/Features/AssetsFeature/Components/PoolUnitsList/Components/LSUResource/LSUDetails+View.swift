import EngineKit
import FeaturePrelude

extension LSUDetails.State {
	var viewState: LSUDetails.ViewState {
		.init(
			containerWithHeader: .init(resource: stakeUnitResource),
			thumbnailURL: stakeUnitResource.iconURL,
			validatorNameViewState: .init(with: validator),
			redeemableTokenAmount: .init(.init(xrdAmount: xrdRedemptionValue.format())),
			resourceDetails: .init(
				description: stakeUnitResource.description,
				resourceAddress: stakeUnitResource.resourceAddress,
				isXRD: false,
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
					viewStore.send(.closeButtonTapped)
				} thumbnailView: {
					NFTThumbnail(viewStore.thumbnailURL, size: .veryLarge)
				} detailsView: {
					VStack(spacing: .medium1) {
						AssetDetailsSeparator()

						Text(L10n.Account.PoolUnits.Details.currentRedeemableValue)
							.textStyle(.secondaryHeader)
							.foregroundColor(.app.gray1)

						ValidatorNameView(viewState: viewStore.validatorNameViewState)
							.padding(.horizontal, .large2)

						PoolUnitResourcesView(resources: viewStore.redeemableTokenAmount)
							.padding(.horizontal, .large2)

						AssetResourceDetailsSection(viewState: viewStore.resourceDetails)
					}
					.padding(.bottom, .medium1)
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
