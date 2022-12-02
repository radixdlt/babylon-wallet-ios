import ComposableArchitecture
import DesignSystem
import SharedModels
import SwiftUI

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
			store.actionless,
			observe: ViewState.init(state:)
		) { viewStore in
			VStack(spacing: 0) {
				if let name = viewStore.name {
					Text(name).textStyle(.body1Header)
				}
				AsyncImage(url: viewStore.iconURL)
					.frame(width: 104, height: 104)
					.clipShape(Circle())
				if let amount = viewStore.amount, let symbol = viewStore.symbol {
					Text(amount).font(.app.sheetTitle).kerning(-0.5) +
						Text(" " + symbol).font(.app.sectionHeader)
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
								copyAddressAction: .none
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
			.foregroundColor(.app.gray1)
		}
	}
}

// MARK: - FungibleTokenDetails.View.ViewState
extension FungibleTokenDetails.View {
	struct ViewState: Equatable {
		var name: String?
		var iconURL: URL?
		var amount: String?
		var symbol: String?
		var description: String?
		var address: AddressView.ViewState
		var currentSupply: BigUInt?

		init(state: FungibleTokenDetails.State) {
			name = state.ownedToken.asset.name
			iconURL = state.ownedToken.asset.iconURL
			amount = state.ownedToken.amount
			symbol = state.ownedToken.asset.symbol
			description = state.ownedToken.asset.tokenDescription
			address = .init(address: state.ownedToken.asset.address.description, format: .short())
			currentSupply = state.ownedToken.asset.totalMintedAttos
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
