import FeaturePrelude

// MARK: - TransactionReviewDappsUsed.View
extension TransactionReviewNetworkFee {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewNetworkFee>

		public init(store: StoreOf<TransactionReviewNetworkFee>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				// TODO: implement
				Text(L10n.TransactionReview.networkFeeText)
					.background(Color.yellow)
					.foregroundColor(.red)
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
