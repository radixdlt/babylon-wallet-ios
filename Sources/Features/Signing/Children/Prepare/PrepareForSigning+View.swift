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
				// TODO: implement
				Text("Implement: PrepareForSigning")
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
//// MARK: - PrepareForSigning_Preview
// struct PrepareForSigning_Preview: PreviewProvider {
//	static var previews: some View {
//		PrepareForSigning.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: PrepareForSigning()
//			)
//		)
//	}
// }
//
// extension PrepareForSigning.State {
//	public static let previewValue = Self()
// }
// #endif
