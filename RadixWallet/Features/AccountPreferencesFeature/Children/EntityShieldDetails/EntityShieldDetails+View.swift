import SwiftUI

// MARK: - EntityShieldDetails.View
extension EntityShieldDetails {
	struct View: SwiftUI.View {
		let store: StoreOf<EntityShieldDetails>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .medium3) {
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
				}
				.background(.primaryBackground)
				.footer {
					VStack(spacing: .medium2) {
						Button("Edit Factors") {
							store.send(.view(.editFactorsTapped))
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))
						.disabled(store.hasTimedRecovery)
						.opacity(store.hasTimedRecovery ? 0.5 : 1.0)

						// Timed Recovery Button
						if let acDetails = store.accessControllerStateDetails,
						   let bannerState = store.timedRecoveryBannerState
						{
							Button {
								store.send(.view(.timedRecoveryBannerTapped))
							} label: {
								timedRecoveryButtonLabel(state: bannerState)
							}
							.buttonStyle(.secondaryRectangular(shouldExpand: true))
						}
					}
				}
				.destinations(with: store)
			}
			.task {
				store.send(.view(.task))
			}
		}

		@ViewBuilder
		private func timedRecoveryButtonLabel(state: AccountBannerView.TimedRecoveryBannerState) -> some SwiftUI.View {
			HStack(spacing: .small2) {
				switch state {
				case .inProgress:
					Image(systemName: "hourglass")
				case .unknown:
					Image(.error)
				}

				VStack(alignment: .leading, spacing: .small3) {
					switch state {
					case let .inProgress(countdown):
						if let countdown {
							Text(L10n.HandleAccessControllerTimedRecovery.Banner.recoveryInProgress(countdown))
								.textStyle(.body1HighImportance)
						} else {
							Text(L10n.HandleAccessControllerTimedRecovery.Banner.readyToConfirm)
								.textStyle(.body1HighImportance)
						}
					case .unknown:
						Text(L10n.HandleAccessControllerTimedRecovery.Banner.unknownRecovery)
							.textStyle(.body1HighImportance)
					}
				}
			}
			.foregroundColor(.button)
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
			.handleTimedRecovery(with: destinationStore)
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

	private func handleTimedRecovery(with destinationStore: PresentationStoreOf<EntityShieldDetails.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.handleTimedRecovery, action: \.handleTimedRecovery)) { store in
			HandleAccessControllerTimedRecovery.View(store: store)
		}
	}
}
