import FeaturePrelude

extension FungibleTokenDetails.State {
	var viewState: FungibleTokenDetails.ViewState {
		.init(
			displayName: asset.name ?? "",
			iconURL: asset.iconURL,
			placeholderAsset: .placeholderImage(isXRD: asset.isXRD),
			amount: amount.format(),
			symbol: asset.symbol,
			description: asset.tokenDescription,
			address: .init(address: asset.componentAddress.address, format: .default),
			currentSupply: asset.totalMinted
		)
	}
}

// MARK: - FungibleTokenDetails.View
extension FungibleTokenDetails {
	struct ViewState: Equatable {
		let displayName: String
		let iconURL: URL?
		let placeholderAsset: ImageAsset
		let amount: String
		let symbol: String?
		let description: String?
		let address: AddressView.ViewState
		let currentSupply: BigDecimal?
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
						VStack(spacing: .medium3) {
							LazyImage(url: viewStore.iconURL) { _ in
								Image(asset: viewStore.placeholderAsset)
									.resizable()
							}
							.frame(width: 104, height: 104)
							.clipShape(Circle())
							if let amount = viewStore.amount, let symbol = viewStore.symbol {
								Text(amount).font(.app.sheetTitle).kerning(-0.5) +
									Text(" " + symbol).font(.app.sectionHeader)
							}
						}
						.padding(.top, .small2)
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
								if let currentSupply = viewStore.currentSupply {
									HStack {
										Text(L10n.FungibleTokenList.Detail.currentSupply)
											.textStyle(.body1Regular)
											.foregroundColor(.app.gray2)
										Text(currentSupply.description)
											.frame(maxWidth: .infinity, alignment: .trailing)
											.multilineTextAlignment(.trailing)
									}
								}
							}
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.horizontal, .large2)
							.textStyle(.body1Regular)
							.lineLimit(1)
						}
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
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct FungibleTokenDetails_Preview: PreviewProvider {
	static var previews: some View {
		FungibleTokenDetails.View(
			store: .init(
				initialState: .previewValue,
				reducer: FungibleTokenDetails()
			)
		)
	}
}

extension FungibleTokenDetails.State {
	public static let previewValue = FungibleTokenContainer(
		owner: try! .init(address: "owner_address"),
		asset: .xrd,
		amount: 30.0,
		worth: 500
	)
}
#endif
