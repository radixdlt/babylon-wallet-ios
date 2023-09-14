import EngineKit
import FeaturePrelude

extension FungibleTokenDetails.State {
	var viewState: FungibleTokenDetails.ViewState {
		.init(
			detailsHeader: resource.detailsHeader(withAmount: context == .portfolio),
			thumbnail: isXRD ? .xrd : .known(resource.iconURL),
			details: .init(
				description: resource.description,
				resourceAddress: resource.resourceAddress,
				isXRD: isXRD,
				validatorAddress: nil,
				resourceName: nil,
				currentSupply: resource.totalSupply?.format(), // FIXME: Check which format
				behaviors: resource.behaviors,
				tags: isXRD ? resource.tags + [.officialRadix] : resource.tags
			)
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
					TokenThumbnail(viewStore.thumbnail, size: .veryLarge)
				} detailsView: {
					AssetResourceDetailsSection(viewState: viewStore.details)
						.padding(.bottom, .medium1)
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
				initialState: try! .init(
					resource: .init(
						resourceAddress: .init(validatingAddress: "resource_tdx_c_1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq40v2wv"),
						amount: .zero
					),
					isXRD: true,
					context: .portfolio
				),
				reducer: FungibleTokenDetails.init
			)
		)
	}
}
#endif
