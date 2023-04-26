import FeaturePrelude

extension FungibleTokenList.Row.State {
	var viewState: FungibleTokenList.Row.ViewState {
		.init(
			isXRD: isXRD,
			iconURL: token.iconURL,
			symbol: token.symbol ?? token.name ?? "",
			tokenAmount: token.amount.format()
		)
	}
}

// MARK: - FungibleTokenList.Row.View
extension FungibleTokenList.Row {
	public struct ViewState: Equatable {
		let isXRD: Bool
		let iconURL: URL?
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
							LazyImage(url: viewStore.iconURL) { _ in
								Image(asset: .placeholderImage(isXRD: viewStore.isXRD))
									.resizable()
									.frame(.small)
							}

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
				initialState: .init(xrdToken: .init(resourceAddress: .init(address: "some"), amount: .zero)),
				reducer: FungibleTokenList.Row()
			)
		)
	}
}
#endif
