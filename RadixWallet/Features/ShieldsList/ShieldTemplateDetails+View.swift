import SwiftUI

// MARK: - ShieldTemplateDetails.View
extension ShieldTemplateDetails {
	struct View: SwiftUI.View {
		let store: StoreOf<ShieldTemplateDetails>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(alignment: .leading, spacing: .medium3) {
						VStack(alignment: .leading, spacing: .small3) {
							Text(store.structure.metadata.displayName.rawValue)
								.textStyle(.sheetTitle)
								.foregroundStyle(.primaryText)

							Button("Rename") {
								store.send(.view(.renameButtonTapped))
							}
							.buttonStyle(.blueText)
						}

						Card {
							SecurityStructureOfFactorSourcesView(structure: store.structure)
						}
					}
					.padding([.horizontal, .bottom], .medium3)
					.background(.white)
				}
				.background(.white)
				.footer {
					Button("Edit Factors") {
						store.send(.view(.editFactorsTapped))
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))

					Button("Apply") {
						store.send(.view(.applyButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
				.destinations(with: store)
			}
		}
	}
}

private extension StoreOf<ShieldTemplateDetails> {
	var destination: PresentationStoreOf<ShieldTemplateDetails.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ShieldTemplateDetails>) -> some View {
		let destinationStore = store.destination
		return editFactors(with: destinationStore)
			.applyShield(with: destinationStore)
	}

	private func editFactors(with destinationStore: PresentationStoreOf<ShieldTemplateDetails.Destination>) -> some View {
		fullScreenCover(store: destinationStore.scope(state: \.editShieldFactors, action: \.editShieldFactors)) {
			EditSecurityShieldCoordinator.View(store: $0)
		}
	}

	private func applyShield(with destinationStore: PresentationStoreOf<ShieldTemplateDetails.Destination>) -> some View {
		fullScreenCover(store: destinationStore.scope(state: \.applyShield, action: \.applyShield)) {
			ApplyShield.Coordinator.View(store: $0)
		}
	}
}
