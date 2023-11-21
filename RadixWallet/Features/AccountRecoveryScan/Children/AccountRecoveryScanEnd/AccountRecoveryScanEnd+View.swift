extension AccountRecoveryScanEnd.State {
	var viewState: AccountRecoveryScanEnd.ViewState {
		.init()
	}
}

// MARK: - AccountRecoveryScanEnd.View

public extension AccountRecoveryScanEnd {
	struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AccountRecoveryScanEnd>

		public init(store: StoreOf<AccountRecoveryScanEnd>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				VStack {
					Text("AccountRecScan END ✅")
						.background(Color.green)
						.foregroundColor(.white)

					Button("DONE") {
						store.send(.view(.doneTapped))
					}.buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - AccountRecoveryScanEnd_Preview

struct AccountRecoveryScanEnd_Preview: PreviewProvider {
	static var previews: some View {
		AccountRecoveryScanEnd.View(
			store: .init(
				initialState: .previewValue,
				reducer: AccountRecoveryScanEnd.init
			)
		)
	}
}

public extension AccountRecoveryScanEnd.State {
	static let previewValue = Self()
}
#endif
