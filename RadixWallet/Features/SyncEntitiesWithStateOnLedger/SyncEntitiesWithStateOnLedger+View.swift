extension SyncEntitiesWithStateOnLedger.State {
	var viewState: SyncEntitiesWithStateOnLedger.ViewState {
		.init()
	}
}

// MARK: - SyncEntitiesWithStateOnLedger.View

public extension SyncEntitiesWithStateOnLedger {
	struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SyncEntitiesWithStateOnLedger>

		public init(store: StoreOf<SyncEntitiesWithStateOnLedger>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: SyncEntitiesWithStateOnLedger")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SyncEntitiesWithStateOnLedger_Preview

struct SyncEntitiesWithStateOnLedger_Preview: PreviewProvider {
	static var previews: some View {
		SyncEntitiesWithStateOnLedger.View(
			store: .init(
				initialState: .previewValue,
				reducer: SyncEntitiesWithStateOnLedger.init
			)
		)
	}
}

public extension SyncEntitiesWithStateOnLedger.State {
	static let previewValue = Self()
}
#endif
