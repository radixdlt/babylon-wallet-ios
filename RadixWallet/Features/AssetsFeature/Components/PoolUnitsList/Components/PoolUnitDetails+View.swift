import ComposableArchitecture
import SwiftUI

extension PoolUnitDetails.State {
	var viewState: PoolUnitDetails.ViewState {
		let resource = resourcesDetails.poolUnitResource.resource
		return .init(
			containerWithHeader: .init(resourcesDetails.poolUnitResource),
			thumbnailURL: resource.metadata.iconURL,
			resources: .init(resources: resourcesDetails),
			resourceDetails: .init(
				description: .success(resource.metadata.description),
				infoUrl: .success(resource.metadata.infoURL),
				resourceAddress: resource.resourceAddress,
				isXRD: false,
				validatorAddress: nil,
				resourceName: .success(resource.metadata.name),
				currentSupply: .success(resource.totalSupply?.formatted() ?? L10n.AssetDetails.supplyUnkown),
				divisibility: .success(resource.divisibility),
				arbitraryDataFields: .success(resource.metadata.arbitraryItems.asDataFields),
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
		let resources: [ResourceBalance.ViewState.Fungible]

		let resourceDetails: AssetResourceDetailsSection.ViewState
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitDetails>

		public init(store: StoreOf<PoolUnitDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
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

						ResourceBalancesView(fungibles: viewStore.resources)
							.padding(.horizontal, .large2)

						AssetResourceDetailsSection(viewState: viewStore.resourceDetails)
					}
					.padding(.bottom, .medium1)
				}
			}
		}
	}
}
