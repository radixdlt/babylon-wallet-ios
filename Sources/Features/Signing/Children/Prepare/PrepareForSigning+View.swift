import FeaturePrelude

extension PrepareForSigning.State {
	var viewState: PrepareForSigning.ViewState {
		.init()
	}
}

// MARK: - PrepareForSigning.View
extension PrepareForSigning {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PrepareForSigning>

		public init(store: StoreOf<PrepareForSigning>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Text("Preparing transaction for signing")
				}
				.padding(.medium1)
				.onAppear { viewStore.send(.appeared) }
				.navigationTitle("Preparing Transaction")
			}
		}
	}
}
