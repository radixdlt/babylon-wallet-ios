import FeaturePrelude

extension FungibleAssetList.Row.State {
	var viewState: FungibleAssetList.Row.ViewState {
		.init(
			thumbnail: isXRD ? .xrd : .known(token.iconURL),
			symbol: token.symbol ?? token.name ?? "",
			tokenAmount: token.amount.formatted(),
			isSelected: isSelected
		)
	}
}

// MARK: - FungibleTokenList.Row.View
extension FungibleAssetList.Row {
	public struct ViewState: Equatable {
		let thumbnail: TokenThumbnail.Content
		let symbol: String
		let tokenAmount: String
		let isSelected: Bool?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleAssetList.Row>

		public init(store: StoreOf<FungibleAssetList.Row>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: FeatureAction.view) { viewStore in
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

					if let isSelected = viewStore.isSelected {
						CheckmarkView(appearance: .dark, isChecked: isSelected)
					}
				}
				.frame(height: 2 * .large1)
				.padding(.horizontal, .medium1)
				.contentShape(Rectangle())
				.onTapGesture { viewStore.send(.tapped) }
			}
		}
	}
}
