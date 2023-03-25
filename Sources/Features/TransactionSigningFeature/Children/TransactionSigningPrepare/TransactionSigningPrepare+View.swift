import FeaturePrelude

extension TransactionSigningPrepare.State {
	var viewState: TransactionSigningPrepare.ViewState {
		.init()
	}
}

// MARK: - TransactionSigningPrepare.View
extension TransactionSigningPrepare {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionSigningPrepare>

		public init(store: StoreOf<TransactionSigningPrepare>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				Color.clear
					.presentsLoadingViewOverlay()
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - TransactionSigningPrepare_Preview
struct TransactionSigningPrepare_Preview: PreviewProvider {
	static var previews: some View {
		TransactionSigningPrepare.View(
			store: .init(
				initialState: .previewValue,
				reducer: TransactionSigningPrepare()
			)
		)
	}
}

extension TransactionSigningPrepare.State {
	public static let previewValue = Self(messageFromDapp: "Hello", rawTransactionManifest: .previewValue)
}
#endif
