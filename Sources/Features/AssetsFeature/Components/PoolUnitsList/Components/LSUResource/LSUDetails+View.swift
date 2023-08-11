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
				displayName: stake.validator.name ?? "Unknown",
				amount: (stake.xrdRedemptionValue ?? 0).format(),
				symbol: "XRD"
			),
			thumbnailURL: stake.validator.iconURL,
			tokenAmount: (stake.stakeUnitResource?.amount ?? 0).format(),
			description: stake.validator.description,
			resourceAddress: stake.stakeUnitResource!.resourceAddress,
			currentSupply: stake.validator.xrdVaultBalance.format()
		)
	}
}
