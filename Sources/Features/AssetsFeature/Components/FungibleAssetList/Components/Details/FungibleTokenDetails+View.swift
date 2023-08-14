import EngineKit
import FeaturePrelude

extension FungibleTokenDetails.State {
	var viewState: FungibleTokenDetails.ViewState {
		.init(
			detailsContainerWithHeader: resource.detailsContainerWithHeaderViewState,
			thumbnail: isXRD ? .xrd : .known(resource.iconURL),
			description: resource.description,
			resourceAddress: resource.resourceAddress
		)
	}
}

// MARK: - FungibleTokenDetails.View
extension FungibleTokenDetails {
	public struct ViewState: Equatable {
		let detailsContainerWithHeader: DetailsContainerWithHeaderViewState
		let thumbnail: TokenThumbnail.Content
		let description: String?
		let resourceAddress: ResourceAddress
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleTokenDetails>

		public init(store: StoreOf<FungibleTokenDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				DetailsContainerWithHeaderView(viewState: viewStore.detailsContainerWithHeader) {
					TokenThumbnail(viewStore.thumbnail, size: .veryLarge)
				} detailsView: {
					if let description = viewStore.description {
						DetailsContainerWithHeaderViewMaker
							.makeDescriptionView(description: description)
					}

					TokenDetailsPropertyViewMaker.makeResourceAddress(
						address: viewStore.resourceAddress
					)
				} closeButtonAction: {
					viewStore.send(.closeButtonTapped)
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct FungibleTokenDetails_Preview: PreviewProvider {
	static var previews: some View {
		FungibleTokenDetails.View(
			store: .init(
				initialState: try! .init(resource: .init(resourceAddress: .init(validatingAddress: "resource_tdx_c_1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq40v2wv"), amount: .zero), isXRD: true),
				reducer: FungibleTokenDetails()
			)
		)
	}
}
#endif
