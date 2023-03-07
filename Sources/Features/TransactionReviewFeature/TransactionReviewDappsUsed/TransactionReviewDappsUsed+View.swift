import FeaturePrelude

// extension TransactionReviewDappsUsed.State {
//	var viewState: TransactionReviewDappsUsed.ViewState {
//		.init()
//	}
// }

// MARK: - TransactionReviewDappsUsed.View
extension TransactionReviewDappsUsed {
//	struct ViewState: Equatable {
//		// TODO: declare some properties
//	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewDappsUsed>

		public init(store: StoreOf<TransactionReviewDappsUsed>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: TransactionReviewDappsUsed")
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
//// MARK: - TransactionReviewDappsUsed_Preview
// struct TransactionReviewDappsUsed_Preview: PreviewProvider {
//	static var previews: some View {
//		TransactionReviewDappsUsed.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: TransactionReviewDappsUsed()
//			)
//		)
//	}
// }
//
// extension TransactionReviewDappsUsed.State {
//	public static let previewValue = Self()
// }
// #endif
