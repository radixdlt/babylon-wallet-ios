import EngineKit
import FeaturePrelude

extension FungibleTokenDetails.State {
	var viewState: FungibleTokenDetails.ViewState {
		.init(
			detailsHeader: detailsHeader,
			thumbnail: isXRD ? .xrd : .known(resource.iconURL),
			details: .init(
				description: resource.description,
				resourceAddress: resource.resourceAddress,
				isXRD: isXRD,
				validatorAddress: nil,
				resourceName: nil,
				currentSupply: resource.totalSupply?.formatted() ?? L10n.AssetDetails.supplyUnkown,
				behaviors: resource.behaviors,
				tags: isXRD ? resource.tags + [.officialRadix] : resource.tags
			)
		)
	}

	var detailsHeader: DetailsContainerWithHeaderViewState {
		.init(
			title: resource.name ?? L10n.Account.PoolUnits.unknownPoolUnitName,
			amount: amount?.formatted(),
			symbol: resource.symbol
		)
	}
}

// MARK: - FungibleTokenDetails.View
extension FungibleTokenDetails {
	public struct ViewState: Equatable {
		let detailsHeader: DetailsContainerWithHeaderViewState
		let thumbnail: TokenThumbnail.Content
		let details: AssetResourceDetailsSection.ViewState
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleTokenDetails>

		public init(store: StoreOf<FungibleTokenDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				DetailsContainerWithHeaderView(viewState: viewStore.detailsHeader) {
					viewStore.send(.closeButtonTapped)
				} thumbnailView: {
					TokenThumbnail(viewStore.thumbnail, size: .veryLarge)
				} detailsView: {
					AssetResourceDetailsSection(viewState: viewStore.details)
						.padding(.bottom, .medium1)
				}
			}
		}
	}
}
