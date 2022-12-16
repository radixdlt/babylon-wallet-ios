import ComposableArchitecture
import DesignSystem
import Resources
import SharedModels

// MARK: - FungibleTokenDetails.View
public extension FungibleTokenDetails {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<FungibleTokenDetails>

		public init(store: StoreOf<FungibleTokenDetails>) {
			self.store = store
		}
	}
}

public extension FungibleTokenDetails.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack(spacing: .medium2) {
				NavigationBar(
					titleText: viewStore.displayName,
					leadingItem: CloseButton { viewStore.send(.closeButtonTapped) }
				)
				.padding([.horizontal, .top], .medium3)

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
								Text("Token ID")
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
									Text("Current Supply")
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
			}
			.foregroundColor(.app.gray1)
		}
	}
}

// MARK: - FungibleTokenDetails.View.ViewState
extension FungibleTokenDetails.View {
	struct ViewState: Equatable {
		var displayName: String?
		var iconURL: URL?
		var placeholderAsset: ImageAsset
		var amount: String?
		var symbol: String?
		var description: String?
		var address: AddressView.ViewState
		var currentSupply: BigUInt?

		init(state: FungibleTokenDetails.State) {
			displayName = state.asset.name
			iconURL = state.asset.iconURL
			placeholderAsset = state.asset.placeholderImage
			amount = state.amount
			symbol = state.asset.symbol
			description = state.asset.tokenDescription
			address = .init(address: state.asset.componentAddress.address, format: .short())
			currentSupply = state.asset.totalMintedAttos
		}
	}
}

#if DEBUG

// MARK: - FungibleTokenDetails_Preview
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
