import FeaturePrelude

extension PoolUnitsList.State {
	var viewState: PoolUnitsList.ViewState {
		.init()
	}
}

// MARK: - PoolUnitsList.View
extension PoolUnitsList {
	public struct ViewState: Equatable {
		public init() {}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store<PoolUnitsList.ViewState, PoolUnitsList.ViewAction>

		public init(store: Store<PoolUnitsList.ViewState, PoolUnitsList.ViewAction>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: identity, send: identity) { viewStore in
				// TODO: implement
				Text("Implement: PoolUnitsList")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}
