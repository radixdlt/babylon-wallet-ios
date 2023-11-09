#if DEBUG

extension DebugKeychainContents.State {
	var viewState: DebugKeychainContents.ViewState {
		.init()
	}
}

// MARK: - DebugKeychainContents.View
extension DebugKeychainContents {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DebugKeychainContents>

		public init(store: StoreOf<DebugKeychainContents>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: DebugKeychainContents")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#endif // DEBUG
