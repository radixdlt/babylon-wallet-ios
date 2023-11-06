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
			IfLetStore(
				store.destination,
				state: /OverlayReducer.Destinations.State.hud,
				action: OverlayReducer.Destinations.Action.hud,
				then: { HUD.View(store: $0) }
			)
			.alert(
				store: store.destination,
				state: /OverlayReducer.Destinations.State.alert,
				action: OverlayReducer.Destinations.Action.alert
			)
			.task { store.send(.view(.task)) }
		}
	}
}

private extension StoreOf<OverlayReducer> {
	var destination: PresentationStoreOf<OverlayReducer.Destinations> {
		scope(state: \.$destination) { .child(.destination($0)) }
	}
}
