import SwiftUI

// MARK: - PrepareFactors
enum PrepareFactors {}

// MARK: - PrepareFactors.Coordinator.View
extension PrepareFactors.Coordinator {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<PrepareFactors.Coordinator>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack(path: $store.scope(state: \.path, action: \.child.path)) {
					PrepareFactors.Intro.View(store: store.scope(state: \.root, action: \.child.root))
				} destination: { store in
					switch store.case {
					case let .addFactor(store):
						PrepareFactors.AddFactor.View(store: store)
					}
				}
				.destinations(with: store)
			}
		}
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PrepareFactors.Coordinator>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: \.destination)
		return addLedger(with: destinationStore)
			.noDeviceAlert(with: destinationStore)
	}

	private func addLedger(with destinationStore: PresentationStoreOf<PrepareFactors.Coordinator.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addLedger, action: \.addLedger)) {
			AddLedgerFactorSource.View(store: $0)
		}
	}

	private func noDeviceAlert(with destinationStore: PresentationStoreOf<PrepareFactors.Coordinator.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.noDeviceAlert, action: \.noDeviceAlert))
	}
}
