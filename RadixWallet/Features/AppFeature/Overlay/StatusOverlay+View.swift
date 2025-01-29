import ComposableArchitecture
import SwiftUI

// MARK: - StatusOverlay.View
extension StatusOverlay {
	struct View: SwiftUI.View {
		private let store: StoreOf<StatusOverlay>

		init(store: StoreOf<StatusOverlay>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			IfLetStore(store.destination.scope(state: \.hud, action: \.hud)) {
				HUD.View(store: $0)
			}
			.destinations(with: store)
			.task { store.send(.view(.task)) }
		}
	}
}

private extension StoreOf<StatusOverlay> {
	var destination: PresentationStoreOf<StatusOverlay.Destination> {
		func scopeState(state: State) -> PresentationState<StatusOverlay.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<StatusOverlay>) -> some View {
		let destinationStore = store.destination
		return alert(with: destinationStore)
	}

	private func alert(with destinationStore: PresentationStoreOf<StatusOverlay.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.alert, action: \.alert))
	}
}
