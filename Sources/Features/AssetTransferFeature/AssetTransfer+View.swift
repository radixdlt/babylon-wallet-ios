import ComposableArchitecture
import SharedModels
import SwiftUI

// MARK: - AssetTransfer.View
public extension AssetTransfer {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension AssetTransfer.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { _ in
			Text("Implement me")
		}
	}
}

// MARK: - AssetTransfer.View.ViewState
extension AssetTransfer.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state: AssetTransfer.State) {}
	}
}

// MARK: - AssetTransfer_Preview
#if DEBUG
struct AssetTransfer_Preview: PreviewProvider {
	static var previews: some View {
		AssetTransfer.View(
			store: .init(
				initialState: .init(
					from: .previewValue0
				),
				reducer: AssetTransfer()
			)
		)
	}
}
#endif
