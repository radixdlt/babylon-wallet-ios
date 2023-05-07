import FeaturePrelude

extension FungibleTokenList.Row.State {
	var viewState: FungibleTokenList.Row.ViewState {
		.init(
			thumbnail: isXRD ? .xrd : .known(token.iconURL),
			symbol: token.symbol ?? token.name ?? "",
			tokenAmount: token.amount.format()
		)
	}
}

// MARK: - FungibleTokenList.Row.View
extension FungibleTokenList.Row {
	public struct ViewState: Equatable {
		let thumbnail: TokenThumbnail.Content
		let symbol: String
		let tokenAmount: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleTokenList.Row>

		public init(store: StoreOf<FungibleTokenList.Row>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ZStack {
					HStack(alignment: .center) {
						HStack(spacing: .small1) {
							TokenThumbnail(viewStore.thumbnail, size: .small)

							Text(viewStore.symbol)
								.foregroundColor(.app.gray1)
								.textStyle(.body2HighImportance)
						}

						Spacer()

						VStack(alignment: .trailing, spacing: .small3) {
							Text(viewStore.tokenAmount)
								.foregroundColor(.app.gray1)
								.textStyle(.secondaryHeader)
						}
					}

					VStack {
						Spacer()
						Separator()
					}
				}
				.frame(height: .large1 * 2)
				.padding(.horizontal, .medium1)
				.contentShape(Rectangle())
				.onTapGesture { viewStore.send(.tapped) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct Row_Preview: PreviewProvider {
	static var previews: some View {
		FungibleTokenList.Row.View(
			store: .init(
				initialState: .init(xrdToken: .init(resourceAddress: .init(address: "resource_tdx_c_1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq40v2wv"), amount: .zero)),
				reducer: FungibleTokenList.Row()
			)
		)
	}
}
#endif
