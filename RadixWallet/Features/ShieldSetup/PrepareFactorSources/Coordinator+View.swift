import SwiftUI

// MARK: - PrepareFactorSources
enum PrepareFactorSources {}

// MARK: - PrepareFactorSources.Coordinator.View
extension PrepareFactorSources.Coordinator {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<PrepareFactorSources.Coordinator>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				Group {
					switch store.path.case {
					case .intro:
						PrepareFactorSources.IntroView {
							store.send(.view(.introButtonTapped))
						}
					case let .addFactor(store):
						PrepareFactorSources.AddFactorSource.View(store: store)
					case .completion:
						PrepareFactorSources.CompletionView {
							store.send(.view(.completionButtonTapped))
						}
					}
				}
				.destinations(with: store)
			}
		}
	}
}

private extension StoreOf<PrepareFactorSources.Coordinator> {
	var path: StoreOf<PrepareFactorSources.Coordinator.Path> {
		scope(state: \.path, action: \.child.path)
	}

	var destination: PresentationStoreOf<PrepareFactorSources.Coordinator.Destination> {
		func scopeState(state: State) -> PresentationState<PrepareFactorSources.Coordinator.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PrepareFactorSources.Coordinator>) -> some View {
		let destinationStore = store.destination
		return addLedger(with: destinationStore)
			.todo(with: destinationStore)
	}

	private func addLedger(with destinationStore: PresentationStoreOf<PrepareFactorSources.Coordinator.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addLedger, action: \.addLedger)) {
			AddLedgerFactorSource.View(store: $0)
		}
	}

	private func todo(with destinationStore: PresentationStoreOf<PrepareFactorSources.Coordinator.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.todo, action: \.todo)) { _ in
			TodoView(feature: "Add factor")
		}
	}
}
