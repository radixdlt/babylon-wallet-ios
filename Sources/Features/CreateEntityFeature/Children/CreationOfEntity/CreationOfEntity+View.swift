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

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - CreationOfEntity_Preview
// struct CreationOfEntity_Preview: PreviewProvider {
//	static var previews: some View {
//		CreationOfEntity.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: CreationOfEntity()
//			)
//		)
//	}
// }
// #endif
