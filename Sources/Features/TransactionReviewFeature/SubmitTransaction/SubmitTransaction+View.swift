import FeaturePrelude

extension SubmitTransaction.State {
	var viewState: SubmitTransaction.ViewState {
		.init()
	}
}

// MARK: - SubmitTransaction.View
extension SubmitTransaction {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SubmitTransaction>

		public init(store: StoreOf<SubmitTransaction>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				Text("Submitting transaction")
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - SubmitTransaction_Preview
// struct SubmitTransaction_Preview: PreviewProvider {
//	static var previews: some View {
//		SubmitTransaction.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: SubmitTransaction()
//			)
//		)
//	}
// }
//
// extension SubmitTransaction.State {
//	public static let previewValue = Self()
// }
// #endif
