import ComposableArchitecture
import SwiftUI

// MARK: - NewConnection.View
public extension NewConnection {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<NewConnection>

		public init(store: StoreOf<NewConnection>) {
			self.store = store
		}
	}
}

public extension NewConnection.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			// TODO: implement
			Text("Implement: NewConnection")
				.background(Color.yellow)
				.foregroundColor(.red)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - NewConnection.View.ViewState
extension NewConnection.View {
	struct ViewState: Equatable {
		init(state: NewConnection.State) {
			// TODO: implement
		}
	}
}

#if DEBUG

// MARK: - NewConnection_Preview
struct NewConnection_Preview: PreviewProvider {
	static var previews: some View {
		NewConnection.View(
			store: .init(
				initialState: .previewValue,
				reducer: NewConnection()
			)
		)
	}
}
#endif
