import ComposableArchitecture
import SwiftUI

// MARK: - OverlayReducer.View
extension OverlayReducer {
	struct View: SwiftUI.View {
		private let store: StoreOf<OverlayReducer>

		init(store: StoreOf<OverlayReducer>) {
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
			.sheet(with: destinationStore)
			.fullScreenCover(with: destinationStore)
	}

	private func alert(with destinationStore: PresentationStoreOf<OverlayReducer.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.alert, action: \.alert))
	}

	private func sheet(with destinationStore: PresentationStoreOf<OverlayReducer.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.sheet, action: \.sheet)) {
			SheetOverlayCoordinator.View(store: $0)
				.presentationDetents([.fraction(0.75), .large])
				.presentationBackground(.blur)
		}
	}

	private func fullScreenCover(with destinationStore: PresentationStoreOf<OverlayReducer.Destination>) -> some View {
		fullScreenCover(store: destinationStore.scope(state: \.fullScreen, action: \.fullScreen)) {
			FullScreenOverlayCoordinator.View(store: $0)
		}
	}
}
