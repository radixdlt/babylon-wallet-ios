import ComposableArchitecture
import SwiftUI

extension PoolUnitDetails.State {
	var viewState: PoolUnitDetails.ViewState {
		let resource = poolUnit.resource
		return .init(
			containerWithHeader: .init(resource: resource),
			thumbnailURL: resource.metadata.iconURL,
			resources: PoolUnitResourceViewState.viewStates(amount: poolUnit.resource.amount, resourcesDetails: resourcesDetails),
			resourceDetails: .init(
				description: .success(resourcesDetails.poolUnitResource.resource.metadata.description),
				resourceAddress: resource.resourceAddress,
				isXRD: false,
				validatorAddress: nil,
				resourceName: .success(resourcesDetails.poolUnitResource.resource.metadata.name), // FIXME: Is this correct?
				currentSupply: .success(resourcesDetails.poolUnitResource.resource.totalSupply?.formatted() ?? L10n.AssetDetails.supplyUnkown),
				behaviors: .success(resourcesDetails.poolUnitResource.resource.behaviors),
				tags: .success(resourcesDetails.poolUnitResource.resource.metadata.tags)
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
					viewStore.send(.closeButtonTapped)
				} thumbnailView: {
					NFTThumbnail(viewStore.thumbnailURL, size: .veryLarge)
				} detailsView: {
					VStack(spacing: .medium1) {
						AssetDetailsSeparator()

						Text(L10n.Account.PoolUnits.Details.currentRedeemableValue)
							.textStyle(.secondaryHeader)
							.foregroundColor(.app.gray1)

						PoolUnitResourcesView(resources: viewStore.resources)
							.padding(.horizontal, .large2)

						AssetResourceDetailsSection(viewState: viewStore.resourceDetails)
					}
					.padding(.bottom, .medium1)
				}
			}
		}
	}
}
