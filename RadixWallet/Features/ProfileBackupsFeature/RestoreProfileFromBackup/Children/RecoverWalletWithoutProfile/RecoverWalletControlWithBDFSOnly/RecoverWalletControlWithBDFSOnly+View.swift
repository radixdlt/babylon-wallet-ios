extension RecoverWalletControlWithBDFSOnly.State {
	var viewState: RecoverWalletControlWithBDFSOnly.ViewState {
		.init()
	}
}

// MARK: - RecoverWalletControlWithBDFSOnly.View

public extension RecoverWalletControlWithBDFSOnly {
	struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<RecoverWalletControlWithBDFSOnly>

		public init(store: StoreOf<RecoverWalletControlWithBDFSOnly>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: RecoverWalletControlWithBDFSOnly")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - RecoverWalletControlWithBDFSOnly_Preview

struct RecoverWalletControlWithBDFSOnly_Preview: PreviewProvider {
	static var previews: some View {
		RecoverWalletControlWithBDFSOnly.View(
			store: .init(
				initialState: .previewValue,
				reducer: RecoverWalletControlWithBDFSOnly.init
			)
		)
	}
}

public extension RecoverWalletControlWithBDFSOnly.State {
	static let previewValue = Self()
}
#endif
