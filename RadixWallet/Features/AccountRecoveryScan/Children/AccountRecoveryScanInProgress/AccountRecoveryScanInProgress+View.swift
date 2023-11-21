extension AccountRecoveryScanInProgress.State {
	var viewState: AccountRecoveryScanInProgress.ViewState {
		.init()
	}
}

// MARK: - AccountRecoveryScanInProgress.View

public extension AccountRecoveryScanInProgress {
	struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AccountRecoveryScanInProgress>

		public init(store: StoreOf<AccountRecoveryScanInProgress>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				VStack {
					Spacer(minLength: 0)
					Text("Account Recovery Scan START")
					Spacer(minLength: 0)

					Button("Continue") {
						store.send(.view(.continueTapped))
					}.buttonStyle(.secondaryRectangular)

					Spacer(minLength: 0)
				}
				.padding()
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - AccountRecoveryScanStart_Preview

struct AccountRecoveryScanStart_Preview: PreviewProvider {
	static var previews: some View {
		AccountRecoveryScanInProgress.View(
			store: .init(
				initialState: .previewValue,
				reducer: AccountRecoveryScanInProgress.init
			)
		)
	}
}

public extension AccountRecoveryScanInProgress.State {
	static let previewValue = Self()
}
#endif
