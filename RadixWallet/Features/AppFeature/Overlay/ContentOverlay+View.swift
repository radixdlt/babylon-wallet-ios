import ComposableArchitecture
import SwiftUI

// MARK: - ContentOverlay.View
extension ContentOverlay {
	struct View: SwiftUI.View {
		private let store: StoreOf<ContentOverlay>

		init(store: StoreOf<ContentOverlay>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			Color.clear
				.destinations(with: store)
				.task { store.send(.view(.task)) }
		}
	}
}

private extension StoreOf<ContentOverlay> {
	var destination: PresentationStoreOf<ContentOverlay.Destination> {
		func scopeState(state: State) -> PresentationState<ContentOverlay.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ContentOverlay>) -> some View {
		let destinationStore = store.destination
		return sheet(with: destinationStore)
			.fullScreenCover(with: destinationStore)
	}

	private func sheet(with destinationStore: PresentationStoreOf<ContentOverlay.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.sheet, action: \.sheet)) {
			SheetOverlayCoordinator.View(store: $0)
				.presentationDetents([.fraction(0.75), .large])
				.presentationBackground(.blur)
		}
	}

	private func fullScreenCover(with destinationStore: PresentationStoreOf<ContentOverlay.Destination>) -> some View {
		fullScreenCover(store: destinationStore.scope(state: \.fullScreen, action: \.fullScreen)) {
			FullScreenOverlayCoordinator.View(store: $0)
		}
	}
}
