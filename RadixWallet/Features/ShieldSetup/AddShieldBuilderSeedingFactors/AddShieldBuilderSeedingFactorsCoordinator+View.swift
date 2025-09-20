import SwiftUI

// MARK: - AddShieldBuilderSeedingFactors
enum AddShieldBuilderSeedingFactors {}

// MARK: - AddShieldBuilderSeedingFactors.Coordinator.View
extension AddShieldBuilderSeedingFactors.Coordinator {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<AddShieldBuilderSeedingFactors.Coordinator>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				Group {
					switch store.path.case {
					case .intro:
						AddShieldBuilderSeedingFactors.IntroView {
							store.send(.view(.introButtonTapped))
						}
					case let .addFactor(store):
						AddShieldBuilderSeedingFactors.SelectFactorSourceToAdd.View(store: store)
					case .completion:
						AddShieldBuilderSeedingFactors.CompletionView {
							store.send(.view(.completionButtonTapped))
						}
					}
				}
				.destinations(with: store)
			}
		}
	}
}

private extension StoreOf<AddShieldBuilderSeedingFactors.Coordinator> {
	var path: StoreOf<AddShieldBuilderSeedingFactors.Coordinator.Path> {
		scope(state: \.path, action: \.child.path)
	}

	var destination: PresentationStoreOf<AddShieldBuilderSeedingFactors.Coordinator.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<AddShieldBuilderSeedingFactors.Coordinator>) -> some View {
		let destinationStore = store.destination
		return addFactorSource(with: destinationStore)
			.todo(with: destinationStore)
	}

	private func addFactorSource(with destinationStore: PresentationStoreOf<AddShieldBuilderSeedingFactors.Coordinator.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addFactorSource, action: \.addFactorSource)) {
			AddFactorSource.Coordinator.View(store: $0)
		}
	}

	private func todo(with destinationStore: PresentationStoreOf<AddShieldBuilderSeedingFactors.Coordinator.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.todo, action: \.todo)) { _ in
			TodoView(feature: "Add factor")
		}
	}
}
