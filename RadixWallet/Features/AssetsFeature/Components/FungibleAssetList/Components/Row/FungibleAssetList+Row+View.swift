import ComposableArchitecture
import SwiftUI

extension FungibleAssetList.Section.Row.State {
	var viewState: FungibleAssetList.Section.Row.ViewState {
		.init(
			thumbnail: isXRD ? .xrd : .other(token.metadata.iconURL),
			symbol: token.metadata.symbol ?? token.metadata.name ?? "",
			tokenAmount: token.amount.formatted(),
			fiatWorth: token.fiatWorth?.currencyFormatted(applyCustomFont: false),
			isSelected: isSelected
		)
	}
}

// MARK: - FungibleTokenList.Row.View
extension FungibleAssetList.Section.Row {
	public struct ViewState: Equatable {
		let thumbnail: Thumbnail.TokenContent
		let symbol: String
		let tokenAmount: String
		let fiatWorth: AttributedString?
		let isSelected: Bool?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleAssetList.Section.Row>

		public init(store: StoreOf<FungibleAssetList.Section.Row>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: FeatureAction.view) { viewStore in
				HStack(alignment: .center) {
					HStack(spacing: .small1) {
						Thumbnail(token: viewStore.thumbnail, size: .small)

						Text(viewStore.symbol)
							.foregroundColor(.app.gray1)
							.textStyle(.body2HighImportance)
					}

					Spacer()

					VStack(alignment: .trailing, spacing: .small3) {
						Text(viewStore.tokenAmount)
							.foregroundColor(.app.gray1)
							.textStyle(.secondaryHeader)

						if let fiatWorth = viewStore.fiatWorth {
							Text(fiatWorth)
								.foregroundColor(.app.gray2)
								.textStyle(.body2HighImportance)
						}
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
