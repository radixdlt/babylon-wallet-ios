import FeaturePrelude

extension DerivePublicKey.State {
	var viewState: DerivePublicKey.ViewState {
		.init()
	}
}

// MARK: - DerivePublicKey.View
extension DerivePublicKey {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DerivePublicKey>

		public init(store: StoreOf<DerivePublicKey>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				// TODO: implement
				Text("Implement: DerivePublicKey")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onFirstTask { @MainActor in
						ViewStore(store.stateless).send(.view(.onFirstTask))
					}
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - DerivePublicKey_Preview
// struct DerivePublicKey_Preview: PreviewProvider {
//	static var previews: some View {
//		DerivePublicKey.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: DerivePublicKey()
//			)
//		)
//	}
// }
//
// extension DerivePublicKey.State {
//	public static let previewValue = Self()
// }
// #endif
