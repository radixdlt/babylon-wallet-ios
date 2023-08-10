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

	@MainActor
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
				displayName: "YOYO",
				amount: "100",
				symbol: "XRD"
			),
			thumbnailURL: .init(string: "https://i.ibb.co/KG06168/Screenshot-2023-08-02-at-16-19-29.png")!,
			tokenAmount: "23113",
			description: "poolUnitResource.description",
			resourceAddress: .init(address: "yoyo", decodedKind: .globalIdentity),
			currentSupply: "1000"
		)
	}
}
