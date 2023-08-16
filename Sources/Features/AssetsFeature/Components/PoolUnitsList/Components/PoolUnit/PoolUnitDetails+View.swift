import EngineKit
import FeaturePrelude

extension PoolUnitDetails.State {
	var viewState: PoolUnitDetails.ViewState {
		let resource = poolUnit.poolUnitResource
		return .init(
			containerWithHeader: resource.detailsContainerWithHeaderViewState,
			thumbnailURL: resource.iconURL,
			resources: poolUnit.resourceViewStates,
			resourceDetails: .init(
				description: resource.description,
				resourceAddress: resource.resourceAddress,
				validatorAddress: nil,
				resourceName: resource.name, // FIXME: Is this correct?
				currentSupply: resource.totalSupply?.format() ?? L10n.AssetDetails.supplyUnkown,
				behaviors: resource.behaviors,
				tags: resource.tags
			)
		)
	}
}

// MARK: - PoolUnitDetails.View
extension PoolUnitDetails {
	public struct ViewState: Equatable {
		let containerWithHeader: DetailsContainerWithHeaderViewState
		let thumbnailURL: URL?
		let resources: NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>>
		let resourceDetails: AssetResourceDetailsSection.ViewState
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

						PoolUnitResourcesView(resources: viewStore.resources)

						AssetResourceDetailsSection(viewState: viewStore.resourceDetails)
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
