import FeaturePrelude

extension FungibleTokenDetails.State {
	var viewState: FungibleTokenDetails.ViewState {
		.init(
			displayName: name ?? "",
			iconURL: nil,
			placeholderAsset: .placeholderImage(isXRD: false),
			amount: amount.format(),
			symbol: symbol,
			description: tokenDescription,
			address: .init(address: resourceAddress.address, format: .default)
		)
	}
}

// MARK: - FungibleTokenDetails.View
extension FungibleTokenDetails {
	public struct ViewState: Equatable {
		let displayName: String
		let iconURL: URL?
		let placeholderAsset: ImageAsset
		let amount: String
		let symbol: String?
		let description: String?
		let address: AddressView.ViewState
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
						ToolbarItem(placement: .navigationBarLeading) {
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
				LazyImage(url: viewStore.iconURL) { _ in
					Image(asset: viewStore.placeholderAsset)
						.resizable()
				}
				.frame(width: 104, height: 104)
				.clipShape(Circle())
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
						Text(L10n.FungibleTokenList.Detail.resourceAddress)
							.textStyle(.body1Regular)
							.foregroundColor(.app.gray2)
						AddressView(
							viewStore.address,
							textStyle: .body1Regular,
							copyAddressAction: {
								viewStore.send(.copyAddressButtonTapped)
							}
						)
						.frame(maxWidth: .infinity, alignment: .trailing)
						.multilineTextAlignment(.trailing)
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

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
// struct FungibleTokenDetails_Preview: PreviewProvider {
//	static var previews: some View {
//		FungibleTokenDetails.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: FungibleTokenDetails()
//			)
//		)
//	}
// }
//
// extension FungibleTokenDetails.State {
//        public static let previewValue = AccountPortfolio.FungibleToken(
//		owner: try! .init(address: "owner_address"),
//		asset: .xrd,
//		amount: 30.0,
//		worth: 500
//	)
// }
// #endif
