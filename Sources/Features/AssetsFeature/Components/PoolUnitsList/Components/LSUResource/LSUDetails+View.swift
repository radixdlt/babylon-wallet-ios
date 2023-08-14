import EngineKit
import FeaturePrelude

extension LSUDetails {
	public struct ViewState: Equatable {
		let containerWithHeader: DetailsContainerWithHeaderViewState
		let thumbnailURL: URL?

		let validatorNameViewState: ValidatorNameViewState

		let redeemableTokenAmount: String

		let description: String?

		let resourceAddress: ResourceAddress
		let currentSupply: String
		let validatorAddress: ValidatorAddress
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

						LSUMaker.makeValidatorNameView(viewState: viewStore.validatorNameViewState)

						PoolUnitResourcesView(
							resources: .init(
								.init(
									xrdAmount: viewStore.redeemableTokenAmount,
									isSelected: nil
								)
							)
						)

						DetailsContainerWithHeaderViewMaker
							.makeSeparator()

						if let description = viewStore.description {
							DetailsContainerWithHeaderViewMaker
								.makeDescriptionView(description: description)
						}

						VStack(spacing: .medium3) {
							TokenDetailsPropertyViewMaker
								.makeResourceAddress(address: viewStore.resourceAddress)
							TokenDetailsPropertyViewMaker
								.makeValidatorAddress(address: viewStore.validatorAddress)
							TokenDetailsPropertyView(
								title: L10n.AssetDetails.currentSupply,
								propertyView: Text(viewStore.currentSupply)
							)
						}
					}
				} closeButtonAction: {
					viewStore.send(.closeButtonTapped)
				}
			}
		}
	}
}

extension LSUDetails.State {
	var viewState: LSUDetails.ViewState {
		.init(
			containerWithHeader: stakeUnitResource.detailsContainerWithHeaderViewState,
			thumbnailURL: stakeUnitResource.iconURL,
			validatorNameViewState: .init(with: validator),
			redeemableTokenAmount: xrdRedemptionValue.format(),
			description: stakeUnitResource.description,
			resourceAddress: stakeUnitResource.resourceAddress,
			currentSupply: validator.xrdVaultBalance.format(),
			validatorAddress: validator.address
		)
	}
}

extension ValidatorNameViewState {
	init(
		with validator: AccountPortfolio.PoolUnitResources.RadixNetworkStake.Validator
	) {
		self.init(
			imageURL: validator.iconURL,
			name: validator.name ?? L10n.Account.PoolUnits.unknownValidatorName
		)
	}
}
