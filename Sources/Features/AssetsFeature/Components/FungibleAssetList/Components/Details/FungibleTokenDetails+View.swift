import EngineKit
import FeaturePrelude

extension FungibleTokenDetails.State {
	var viewState: FungibleTokenDetails.ViewState {
		.init(
			resourceAddress: resource.resourceAddress,
			description: resource.description,
			xViewState: .init(
				displayName: resource.name ?? "",
				thumbnail: isXRD ? .xrd : .known(resource.iconURL),
				amount: resource.amount.format(),
				symbol: resource.symbol
			)
		)
	}
}

// MARK: - FungibleTokenDetails.View
extension FungibleTokenDetails {
	public struct ViewState: Equatable {
		let resourceAddress: ResourceAddress
		let description: String?
		let xViewState: DetailsContainerWithHeaderViewState
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleTokenDetails>

		public init(store: StoreOf<FungibleTokenDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				DetailsContainerWithHeaderView(viewState: viewStore.xViewState) {
					details(with: viewStore)
				} closeButtonAction: {
					viewStore.send(.closeButtonTapped)
				}
			}
		}

		@ViewBuilder
		private func details(with viewStore: ViewStoreOf<FungibleTokenDetails>) -> some SwiftUI.View {
			VStack(spacing: .medium1) {
				if let description = viewStore.description {
					Text(description)
						.textStyle(.body1Regular)
						.frame(maxWidth: .infinity, alignment: .leading)

					DetailsContainerWithHeaderViewMaker.makeSeparator()
				}

				TokenDetailsPropertyViewMaker.makeAddress(
					resourceAddress: viewStore.resourceAddress
				)
				.frame(maxWidth: .infinity, alignment: .leading)
				.textStyle(.body1Regular)
				.lineLimit(1)
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
