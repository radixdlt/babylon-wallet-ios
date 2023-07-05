import FeaturePrelude

extension FungibleTokenDetails.State {
	var viewState: FungibleTokenDetails.ViewState {
		.init(
			displayName: resource.name ?? "",
			resourceAddress: resource.resourceAddress,
			thumbnail: isXRD ? .xrd : .known(resource.iconURL),
			amount: resource.amount.format(),
			symbol: resource.symbol,
			description: resource.description
		)
	}
}

// MARK: - FungibleTokenDetails.View
extension FungibleTokenDetails {
	public struct ViewState: Equatable {
		let displayName: String
		let resourceAddress: ResourceAddress
		let thumbnail: TokenThumbnail.Content
		let amount: String
		let symbol: String?
		let description: String?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleTokenDetails>

		public init(store: StoreOf<FungibleTokenDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationStack {
					ScrollView {
						header(with: viewStore)
						details(with: viewStore)
					}
					#if os(iOS)
					.navigationBarTitle(viewStore.displayName)
					.navigationBarTitleColor(.app.gray1)
					.navigationBarTitleDisplayMode(.inline)
					.navigationBarInlineTitleFont(.app.secondaryHeader)
					.toolbar {
						ToolbarItem(placement: .primaryAction) {
							CloseButton {
								viewStore.send(.closeButtonTapped)
							}
						}
					}
					#endif
				}
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
			}
		}

		@ViewBuilder
		private func header(with viewStore: ViewStoreOf<FungibleTokenDetails>) -> some SwiftUI.View {
			VStack(spacing: .medium3) {
				TokenThumbnail(viewStore.thumbnail, size: .veryLarge)
				if let symbol = viewStore.symbol {
					Text(viewStore.amount).font(.app.sheetTitle).kerning(-0.5) +
						Text(" " + symbol).font(.app.sectionHeader)
				}
			}
			.padding(.top, .small2)
		}

		@ViewBuilder
		private func details(with viewStore: ViewStoreOf<FungibleTokenDetails>) -> some SwiftUI.View {
			VStack(spacing: .medium1) {
				let divider = Color.app.gray4.frame(height: 1).padding(.horizontal, .medium1)
				if let description = viewStore.description {
					divider

					Text(description)
						.textStyle(.body1Regular)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.horizontal, .large2)
				}

				divider

				VStack(spacing: .medium3) {
					HStack {
						Text(L10n.AssetDetails.resourceAddress)
							.textStyle(.body1Regular)
							.foregroundColor(.app.gray2)

						Spacer(minLength: .zero)

						AddressView(.address(.resource(viewStore.resourceAddress)))
							.textStyle(.body1HighImportance)
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.horizontal, .large2)
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
