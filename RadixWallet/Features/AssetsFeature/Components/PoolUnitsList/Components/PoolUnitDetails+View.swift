import ComposableArchitecture
import SwiftUI

extension PoolUnitDetails.State {
	var viewState: PoolUnitDetails.ViewState {
		let resource = resourcesDetails.poolUnitResource.resource
		return .init(
			containerWithHeader: .init(resourcesDetails.poolUnitResource),
			thumbnailURL: resource.metadata.iconURL,
			resources: PoolUnitResourceView.ViewState.viewStates(resourcesDetails: resourcesDetails),
			resourceDetails: .init(
				description: .success(resource.metadata.description),
				resourceAddress: resource.resourceAddress,
				isXRD: false,
				validatorAddress: nil,
				resourceName: .success(resource.metadata.name), // FIXME: Is this correct?
				currentSupply: .success(resource.totalSupply?.formatted() ?? L10n.AssetDetails.supplyUnkown),
				behaviors: .success(resource.behaviors),
				tags: .success(resource.metadata.tags)
			)
		)
	}
}

// MARK: - PoolUnitDetails.View
extension PoolUnitDetails {
	public struct ViewState: Equatable {
		let containerWithHeader: DetailsContainerWithHeaderViewState
		let thumbnailURL: URL?
		let resources: [PoolUnitResourceView.ViewState]
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
					Thumbnail(.poolUnit, url: viewStore.thumbnailURL, size: .veryLarge)
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
