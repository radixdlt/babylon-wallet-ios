import SwiftUI

// MARK: - EntityShieldDetails.View
extension EntityShieldDetails {
	struct View: SwiftUI.View {
		let store: StoreOf<EntityShieldDetails>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					if let structure = store.structure {
						Card {
							SecurityStructureOfFactorSourcesView(
								structure: structure,
								onFactorSourceTapped: { store.send(.view(.onFactorSourceTapped($0))) }
							)
						}
						.padding([.horizontal, .bottom], .medium3)
					}
				}
				.background(.primaryBackground)
				.footer {
					Button("Edit Factors") {
						store.send(.view(.editFactorsTapped))
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
				}
				.destinations(with: store)
			}
			.task {
				store.send(.view(.task))
			}
		}
	}
}

private extension StoreOf<EntityShieldDetails> {
	var destination: PresentationStoreOf<EntityShieldDetails.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<EntityShieldDetails>) -> some View {
		let destinationStore = store.destination
		return editFactors(with: destinationStore)
			.factorSourceDetail(with: destinationStore)
			.applyShield(with: destinationStore)
	}

	private func editFactors(with destinationStore: PresentationStoreOf<EntityShieldDetails.Destination>) -> some View {
		fullScreenCover(store: destinationStore.scope(state: \.editShieldFactors, action: \.editShieldFactors)) {
			EditSecurityShieldCoordinator.View(store: $0)
		}
	}

	private func factorSourceDetail(with destinationStore: PresentationStoreOf<EntityShieldDetails.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.factorSourceDetails, action: \.factorSourceDetails)) {
			FactorSourceDetail.View(store: $0)
		}
	}

	private func applyShield(with destinationStore: PresentationStoreOf<EntityShieldDetails.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.applyShield, action: \.applyShield)) { store in
			ApplyShield.Coordinator.View(store: store)
		}
	}
}
