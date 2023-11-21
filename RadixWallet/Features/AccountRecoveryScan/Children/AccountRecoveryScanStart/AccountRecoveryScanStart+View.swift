extension AccountRecoveryScanStart.State {
	var viewState: AccountRecoveryScanStart.ViewState {
		.init()
	}
}

// MARK: - AccountRecoveryScanStart.View

public extension AccountRecoveryScanStart {
	struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AccountRecoveryScanStart>

		public init(store: StoreOf<AccountRecoveryScanStart>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				VStack {
					Text("AccountRecScan START")

					Button("Continue") {
						store.send(.view(.continueTapped))
					}.buttonStyle(.secondaryRectangular)
				}
				.padding()
				.background(Color.blue)
				.foregroundColor(.white)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - AccountRecoveryScanStart_Preview

struct AccountRecoveryScanStart_Preview: PreviewProvider {
	static var previews: some View {
		AccountRecoveryScanStart.View(
			store: .init(
				initialState: .previewValue,
				reducer: AccountRecoveryScanStart.init
			)
		)
	}
}

public extension AccountRecoveryScanStart.State {
	static let previewValue = Self()
}
#endif
