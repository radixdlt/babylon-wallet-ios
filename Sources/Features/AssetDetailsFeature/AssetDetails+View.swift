import ComposableArchitecture
import SwiftUI

// MARK: - AssetDetails.View
public extension AssetDetails {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AssetDetails>

		public init(store: StoreOf<AssetDetails>) {
			self.store = store
		}
	}
}

public extension AssetDetails.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { _ in
			// TODO: implement
			Text("Implement: AssetDetails")
				.background(Color.yellow)
				.foregroundColor(.red)
		}
	}
}

// MARK: - AssetDetails.View.ViewState
extension AssetDetails.View {
	struct ViewState: Equatable {
		init(state: AssetDetails.State) {
			// TODO: implement
		}
	}
}

#if DEBUG

// MARK: - AssetDetails_Preview
struct AssetDetails_Preview: PreviewProvider {
	static var previews: some View {
		AssetDetails.View(
			store: .init(
				initialState: .previewValue,
				reducer: AssetDetails()
			)
		)
	}
}
#endif
