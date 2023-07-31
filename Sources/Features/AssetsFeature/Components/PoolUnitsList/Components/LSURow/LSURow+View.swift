import FeaturePrelude

extension PoolUnitsList.LSURow.State {
	var viewState: PoolUnitsList.LSURow.ViewState {
		.init()
	}
}

// MARK: - PoolUnitsList.LSURow.View
extension PoolUnitsList.LSURow {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitsList.LSURow>

		public init(store: StoreOf<PoolUnitsList.LSURow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: LSURow")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}
