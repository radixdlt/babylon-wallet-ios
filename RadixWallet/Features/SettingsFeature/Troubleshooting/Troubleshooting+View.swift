extension Troubleshooting.State {
	var viewState: Troubleshooting.ViewState {
		.init()
	}
}

// MARK: - Troubleshooting.View

public extension Troubleshooting {
	struct ViewState: Equatable {}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Troubleshooting>

		public init(store: StoreOf<Troubleshooting>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: Troubleshooting")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}
