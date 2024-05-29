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
		func scopeState(state: State) -> PresentationState<OverlayReducer.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<OverlayReducer>) -> some View {
		let destinationStore = store.destination
		return alert(with: destinationStore)
			.claimWallet(with: destinationStore)
	}

	private func alert(with destinationStore: PresentationStoreOf<OverlayReducer.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /OverlayReducer.Destination.State.alert,
			action: OverlayReducer.Destination.Action.alert
		)
	}

	private func claimWallet(with destinationStore: PresentationStoreOf<OverlayReducer.Destination>) -> some View {
		fullScreenCover(
			store: destinationStore,
			state: /OverlayReducer.Destination.State.fullScreen,
			action: OverlayReducer.Destination.Action.fullScreen,
			content: { FullScreenOverlayCoordinator.View(store: $0) }
		)
	}
}
