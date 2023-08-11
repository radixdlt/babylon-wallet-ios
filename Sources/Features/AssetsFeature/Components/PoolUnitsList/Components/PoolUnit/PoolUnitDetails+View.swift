import EngineKit
import FeaturePrelude

extension PoolUnitDetails.State {
	var viewState: PoolUnitDetails.ViewState {
		let resource = poolUnit.poolUnitResource
		return .init(
			containerWithHeader: resource.detailsContainerWithHeaderViewState,
			thumbnailURL: resource.iconURL,
			resources: poolUnit.resourceViewStates,
			description: resource.description,
			resourceAddress: resource.resourceAddress,
			currentSupply: resource.totalSupply?.format() ?? L10n.AssetDetails.supplyUnkown
		)
	}
}

// MARK: - PoolUnitDetails.View
extension PoolUnitDetails {
	public struct ViewState: Equatable {
		let containerWithHeader: DetailsContainerWithHeaderViewState
		let thumbnailURL: URL?

		let resources: NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>>

		let description: String?

		let resourceAddress: ResourceAddress
		let currentSupply: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitDetails>

		public init(store: StoreOf<PoolUnitDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: PoolUnitDetails.Action.view
			) { viewStore in
				DetailsContainerWithHeaderView(viewState: viewStore.containerWithHeader) {
					NFTThumbnail(viewStore.thumbnailURL, size: .veryLarge)
				} detailsView: {
					VStack(spacing: .medium1) {
						Text(L10n.Account.PoolUnits.Details.currentRedeemableValue)
							.textStyle(.secondaryHeader)
							.foregroundColor(.app.gray1)
						PoolUnitResourcesView(
							resources: viewStore.resources
						)

						DetailsContainerWithHeaderViewMaker
							.makeSeparator()

						if let description = viewStore.description {
							DetailsContainerWithHeaderViewMaker
								.makeDescriptionView(description: description)
						}

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

extension AccountPortfolio.FungibleResource {
	var detailsContainerWithHeaderViewState: DetailsContainerWithHeaderViewState {
		.init(
			title: name ?? L10n.Account.PoolUnits.unknownPoolUnitName,
			amount: amount.format(),
			symbol: symbol
		)
	}
}
