import FeaturePrelude

extension Signing.State {
	var viewState: Signing.ViewState {
		.init()
	}
}

// MARK: - Signing.View
extension Signing {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Signing>

		public init(store: StoreOf<Signing>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: Signing")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - Signing_Preview
// struct Signing_Preview: PreviewProvider {
//	static var previews: some View {
//		Signing.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: Signing()
//			)
//		)
//	}
// }
//
// extension Signing.State {
//	public static let previewValue = Self()
// }
// #endif
