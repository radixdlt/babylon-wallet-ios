import FeaturePrelude

// MARK: - CreationOfEntity.View
extension CreationOfEntity {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreationOfEntity>

		public init(store: StoreOf<CreationOfEntity>) {
			self.store = store
		}
	}
}

extension CreationOfEntity.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			SwiftUI.Color.white
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - CreationOfEntity.View.ViewState
extension CreationOfEntity.View {
	struct ViewState: Equatable {
		init(state: CreationOfEntity.State) {
			// TODO: implement
		}
	}
}
