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
				state: /OverlayReducer.Destination.State.hud,
				action: OverlayReducer.Destination.Action.hud,
				then: { HUD.View(store: $0) }
			)
			.destinations(with: store)
			.task { store.send(.view(.task)) }
		}
	}
}

private extension StoreOf<OverlayReducer> {
	var destination: PresentationStoreOf<OverlayReducer.Destination> {
		scope(state: \.$destination) { .child(.destination($0)) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<OverlayReducer>) -> some View {
		let destinationStore = store.destination
		return alert(
			store: destinationStore,
			state: /OverlayReducer.Destination.State.alert,
			action: OverlayReducer.Destination.Action.alert
		)
	}
}
