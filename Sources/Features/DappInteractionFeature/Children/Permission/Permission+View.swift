import FeaturePrelude

// MARK: - Permission.View
public extension Permission {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Permission>

		public init(store: StoreOf<Permission>) {
			self.store = store
		}
	}
}

public extension Permission.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			// TODO: implement
			Text("Implement: Permission")
				.background(Color.yellow)
				.foregroundColor(.red)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - Permission.View.ViewState
extension Permission.View {
	struct ViewState: Equatable {
		init(state: Permission.State) {
			// TODO: implement
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Permission_Preview
struct Permission_Preview: PreviewProvider {
	static var previews: some View {
		Permission.View(
			store: .init(
				initialState: .previewValue,
				reducer: Permission()
			)
		)
	}
}
#endif
