import ComposableArchitecture
import SwiftUI

extension PoolUnitDetails.State {
	var containerWithHeader: DetailsContainerWithHeaderViewState {
		.init(resourcesDetails.poolUnitResource)
	}

	var thumbnailURL: URL? {
		resourcesDetails.poolUnitResource.resource.metadata.iconURL
	}

	var resources: [ResourceBalance.ViewState.Fungible] {
		.init(resources: resourcesDetails)
	}

	var resourceDetails: AssetResourceDetailsSection.ViewState {
		let resource = resourcesDetails.poolUnitResource.resource
		return .init(
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
	}
}

// MARK: - PoolUnitDetails.View
extension PoolUnitDetails {
	struct View: SwiftUI.View {
		let store: StoreOf<PoolUnitDetails>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				DetailsContainerWithHeaderView(viewState: store.containerWithHeader) {
					store.send(.view(.closeButtonTapped))
				} thumbnailView: {
					Thumbnail(.poolUnit, url: store.thumbnailURL, size: .veryLarge)
				} detailsView: {
					VStack(spacing: .medium1) {
						AssetDetailsSeparator()

						Text(L10n.Account.PoolUnits.Details.currentRedeemableValue)
							.textStyle(.secondaryHeader)
							.foregroundColor(.app.gray1)

						ResourceBalancesView(fungibles: store.resources)
							.padding(.horizontal, .large2)

						AssetResourceDetailsSection(viewState: store.resourceDetails)

						HideResource.View(store: store.hideResource)
					}
					.padding(.bottom, .medium1)
				}
			}
		}
	}
}

private extension StoreOf<PoolUnitDetails> {
	var hideResource: StoreOf<HideResource> {
		scope(state: \.hideResource, action: \.child.hideResource)
	}
}
