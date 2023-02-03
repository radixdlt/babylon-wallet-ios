import FeaturePrelude

// MARK: - CreationOfEntity.View
public extension CreationOfEntity {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<CreationOfEntity>

		public init(store: StoreOf<CreationOfEntity>) {
			self.store = store
		}
	}
}

public extension CreationOfEntity.View {
	var body: some View {
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
