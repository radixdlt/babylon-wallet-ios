import EngineKit
import FeaturePrelude

extension PoolUnitDetails.State {
	var viewState: PoolUnitDetails.ViewState {
		let resource = poolUnit.poolUnitResource
		return .init(
			containerWithHeader: .init(resource: resource),
			thumbnailURL: resource.iconURL,
			resources: poolUnit.resourceViewStates,
			resourceDetails: .init(
				description: resource.description,
				resourceAddress: resource.resourceAddress,
				isXRD: false,
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
