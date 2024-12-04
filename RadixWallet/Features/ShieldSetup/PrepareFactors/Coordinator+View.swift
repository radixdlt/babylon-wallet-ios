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
					PrepareFactors.IntroView {
						store.send(.view(.introButtonTapped))
					}
				} destination: { destination in
					switch destination.case {
					case let .addFactor(store):
						PrepareFactors.AddFactor.View(store: store)
					case .completion:
						PrepareFactors.CompletionView {
							store.send(.view(.completionButtonTapped))
						}
					}
				}
				.destinations(with: store)
			}
		}
	}
}

private extension StoreOf<PrepareFactors.Coordinator> {
	var destination: PresentationStoreOf<PrepareFactors.Coordinator.Destination> {
		func scopeState(state: State) -> PresentationState<PrepareFactors.Coordinator.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PrepareFactors.Coordinator>) -> some View {
		let destinationStore = store.destination
		return addLedger(with: destinationStore)
	}

	private func addLedger(with destinationStore: PresentationStoreOf<PrepareFactors.Coordinator.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addLedger, action: \.addLedger)) {
			AddLedgerFactorSource.View(store: $0)
		}
	}
}
