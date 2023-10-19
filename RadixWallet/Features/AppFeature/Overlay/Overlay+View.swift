import ComposableArchitecture
import SwiftUI

// MARK: - OverlayReducer.View
extension OverlayReducer {
	struct View: SwiftUI.View {
		private let store: StoreOf<OverlayReducer>

		public init(store: StoreOf<OverlayReducer>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				IfLetStore(
					store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /OverlayReducer.Destinations.State.hud,
					action: OverlayReducer.Destinations.Action.hud,
					then: { HUD.View(store: $0) }
				)
				.alert(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /OverlayReducer.Destinations.State.alert,
					action: OverlayReducer.Destinations.Action.alert
				)
				.task { viewStore.send(.task) }
			}
		}
	}
}
