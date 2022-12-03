import ComposableArchitecture
import SwiftUI

// MARK: - ConnectUsingSecrets.View
public extension ConnectUsingSecrets {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ConnectUsingSecrets>

		public init(store: StoreOf<ConnectUsingSecrets>) {
			self.store = store
		}
	}
}

public extension ConnectUsingSecrets.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			// TODO: implement
			Text("Implement: ConnectUsingSecrets")
				.background(Color.yellow)
				.foregroundColor(.red)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - ConnectUsingSecrets.View.ViewState
extension ConnectUsingSecrets.View {
	struct ViewState: Equatable {
		init(state: ConnectUsingSecrets.State) {
			// TODO: implement
		}
	}
}

#if DEBUG

// MARK: - ConnectUsingPassword_Preview
struct ConnectUsingPassword_Preview: PreviewProvider {
	static var previews: some View {
		ConnectUsingSecrets.View(
			store: .init(
				initialState: .previewValue,
				reducer: ConnectUsingSecrets()
			)
		)
	}
}
#endif
