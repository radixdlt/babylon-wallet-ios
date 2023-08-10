import EngineKit
import FeaturePrelude

extension PoolUnitDetails.State {
	var viewState: PoolUnitDetails.ViewState {
		let poolUnitResource = poolUnit.poolUnitResource
		return .init(
			containerWithHeader: .init(
				displayName: poolUnitResource.name ?? L10n.Account.PoolUnits.unknownPoolUnitName,
				amount: poolUnitResource.amount.format(),
				symbol: poolUnitResource.symbol
			),
			thumbnailURL: poolUnitResource.iconURL,
			resources: poolUnit.resourceViewStates,
			description: poolUnitResource.description,
			resourceAddress: poolUnitResource.resourceAddress,
			currentSupply: poolUnitResource.totalSupply?.format() ?? L10n.AssetDetails.supplyUnkown
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
