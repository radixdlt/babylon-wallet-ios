import ComposableArchitecture
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
						.background(Color.yellow)
						.foregroundColor(.red)
				}
			}
			.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - FungibleTokenDetails.View.ViewState
extension FungibleTokenDetails.View {
	struct ViewState: Equatable {
		var name: String?

		init(state: FungibleTokenDetails.State) {
			name = state.ownedToken.asset.name
		}
	}
}

#if DEBUG

// MARK: - AssetDetails_Preview
struct AssetDetails_Preview: PreviewProvider {
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
