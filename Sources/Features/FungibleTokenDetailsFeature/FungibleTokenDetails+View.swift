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
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack {
				if let name = viewStore.name {
					Text(name)
						.textStyle(.body1Header)
				}
				AsyncImage(url: viewStore.iconURL)
					.frame(width: 104, height: 104)
					.clipShape(Circle())
				if let amount = viewStore.amount, let symbol = viewStore.symbol {
					Text(amount).font(.app.sheetTitle).kerning(-0.5) +
						Text(" " + symbol).font(.app.sectionHeader)
				}
//				Text()
			}
			.onAppear { viewStore.send(.appeared) }
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
		var worth: BigUInt?

		init(state: FungibleTokenDetails.State) {
			name = state.ownedToken.asset.name
			iconURL = state.ownedToken.asset.iconURL
			amount = state.ownedToken.amount
			symbol = state.ownedToken.asset.symbol
			worth = state.ownedToken.worth
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
