import FeaturePrelude

extension TransactionReview.State {
	var viewState: TransactionReview.ViewState {
		.init()
	}
}

// MARK: - TransactionReview.View
extension TransactionReview {
	struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReview>

		public init(store: StoreOf<TransactionReview>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: TransactionReview")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - TransactionReview_Preview
struct TransactionReview_Preview: PreviewProvider {
	static var previews: some View {
		TransactionReview.View(
			store: .init(
				initialState: .previewValue,
				reducer: TransactionReview()
			)
		)
	}
}

extension TransactionReview.State {
	public static let previewValue = Self()
}
#endif
