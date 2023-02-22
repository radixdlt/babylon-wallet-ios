import FeaturePrelude

// MARK: - FungibleTokenDetails.View
extension FungibleTokenDetails {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleTokenDetails>

		public init(store: StoreOf<FungibleTokenDetails>) {
			self.store = store
		}
	}
}

extension FungibleTokenDetails.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
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
				.navigationBarTitle(viewStore.displayName)
				#if os(iOS)
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
					.foregroundColor(.app.gray1)
			}
		}
	}
}

// MARK: - FungibleTokenDetails.View.ViewState
extension FungibleTokenDetails.View {
	struct ViewState: Equatable {
		let displayName: String
		let iconURL: URL?
		let placeholderAsset: ImageAsset
		let amount: String
		let symbol: String?
		let description: String?
		let address: AddressView.ViewState
		let currentSupply: BigDecimal?

		init(state: FungibleTokenDetails.State) {
			self.displayName = state.asset.name ?? ""
			self.iconURL = state.asset.iconURL
			self.placeholderAsset = .placeholderImage(isXRD: state.asset.isXRD)
			self.amount = state.amount.format()
			self.symbol = state.asset.symbol
			self.description = state.asset.tokenDescription
			self.address = .init(address: state.asset.componentAddress.address, format: .default)
			self.currentSupply = state.asset.totalMinted
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
#endif
