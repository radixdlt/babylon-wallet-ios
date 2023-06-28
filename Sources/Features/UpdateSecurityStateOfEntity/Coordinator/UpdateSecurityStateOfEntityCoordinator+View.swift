import FeaturePrelude

extension UpdateSecurityStateOfEntityCoordinator.State {
	var viewState: UpdateSecurityStateOfEntityCoordinator.ViewState {
		.init()
	}
}

extension UpdateSecurityStateOfEntityCoordinator {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<UpdateSecurityStateOfEntityCoordinator>

		public init(store: StoreOf<UpdateSecurityStateOfEntityCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: UpdateSecurityStateOfEntityCoordinator \(Entity.entityKind.rawValue)")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}
