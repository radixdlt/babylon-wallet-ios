import FeaturePrelude

// MARK: - LoginRequest.View
public extension LoginRequest {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<LoginRequest>

		public init(store: StoreOf<LoginRequest>) {
			self.store = store
		}
	}
}

public extension LoginRequest.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			// TODO: implement
			Text("Implement: LoginRequest")
				.background(Color.yellow)
				.foregroundColor(.red)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - LoginRequest.View.ViewState
extension LoginRequest.View {
	struct ViewState: Equatable {
		init(state: LoginRequest.State) {
			// TODO: implement
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - LoginRequest_Preview
struct LoginRequest_Preview: PreviewProvider {
	static var previews: some View {
		LoginRequest.View(
			store: .init(
				initialState: .previewValue,
				reducer: LoginRequest()
			)
		)
	}
}
#endif
