import EngineKit
import FeaturePrelude

extension PoolUnitDetails.State {
	var viewState: PoolUnitDetails.ViewState {
		let resource = poolUnit.poolUnitResource
		return .init(
			containerWithHeader: .init(resource: resource),
			thumbnailURL: resource.metadata.iconURL,
			resources: poolUnit.resourceViewStates,
			resourceDetails: .init(
				description: .idle, // resource.metadata.description,
				resourceAddress: resource.resourceAddress,
				isXRD: false,
				validatorAddress: nil,
				resourceName: .idle, // resource.metadata.name, // FIXME: Is this correct?
				currentSupply: .idle, // resource.totalSupply?.format() ?? L10n.AssetDetails.supplyUnkown,
				behaviors: .idle,
				tags: .idle // resource.metadata.tags
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
						AssetDetailsSeparator()

						Text(L10n.Account.PoolUnits.Details.currentRedeemableValue)
							.textStyle(.secondaryHeader)
							.foregroundColor(.app.gray1)

						PoolUnitResourcesView(resources: viewStore.resources)
							.padding(.horizontal, .large2)

						AssetResourceDetailsSection(viewState: viewStore.resourceDetails)
					}
					.padding(.bottom, .medium1)
				} closeButtonAction: {
					viewStore.send(.closeButtonTapped)
				}
			}
		}
	}
}
