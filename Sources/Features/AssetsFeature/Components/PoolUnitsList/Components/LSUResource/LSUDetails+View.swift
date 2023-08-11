import EngineKit
import FeaturePrelude

extension LSUDetails {
	public struct ViewState: Equatable {
		let containerWithHeader: DetailsContainerWithHeaderViewState
		let thumbnailURL: URL?

		let tokenAmount: String

		let description: String?

		let resourceAddress: ResourceAddress
		let currentSupply: String
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
						PoolUnitResourcesView(
							resources: .init(.init(xrdAmount: viewStore.tokenAmount))
						)

						DetailsContainerWithHeaderViewMaker
							.makeSeparator()

						DetailsContainerWithHeaderViewMaker
							.makeDescriptionView(description: viewStore.description)

						VStack(spacing: .medium3) {
							TokenDetailsPropertyViewMaker
								.makeAddress(resourceAddress: viewStore.resourceAddress)
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
			containerWithHeader: .init(
				displayName: validator.name ?? L10n.Account.PoolUnits.unknownValidatorName,
				amount: AccountPortfolio.xrdRedemptionValue(
					validator: validator,
					stakeUnitResource: stakeUnitResource
				).format(),
				symbol: "XRD"
			),
			thumbnailURL: validator.iconURL,
			tokenAmount: stakeUnitResource.amount.format(),
			description: stakeUnitResource.description,
			resourceAddress: stakeUnitResource.resourceAddress,
			currentSupply: validator.xrdVaultBalance.format()
		)
	}
}
