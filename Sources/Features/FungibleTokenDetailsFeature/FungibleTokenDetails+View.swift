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
			// TODO: implement
			Text("Implement: AssetDetails")
				.background(Color.yellow)
				.foregroundColor(.red)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - FungibleTokenDetails.View.ViewState
extension FungibleTokenDetails.View {
	struct ViewState: Equatable {
		init(state: FungibleTokenDetails.State) {
			// TODO: implement
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
