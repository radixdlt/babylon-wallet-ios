// MARK: - ShieldsList.View
extension ShieldsList {
	struct View: SwiftUI.View {
		let store: StoreOf<ShieldsList>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView
						.padding(.horizontal, .medium3)
						.padding(.vertical, .large2)
				}
				.background(.secondaryBackground)
				.radixToolbar(title: L10n.SecurityShields.title)
				.task {
					store.send(.view(.task))
				}
				.destinations(with: store)
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			VStack(spacing: .medium3) {
				section(text: nil, rows: store.shields)

				Button(L10n.SecurityShields.createShieldButton) {
					store.send(.view(.createShieldButtonTapped))
				}
				.buttonStyle(.secondaryRectangular)
				.padding(.vertical, .medium2)

				InfoButton(.securityshields, label: L10n.InfoLink.Title.securityshields)
			}
			.frame(maxWidth: .infinity)
		}

		private func header(_ text: String) -> some SwiftUI.View {
			Text(text)
				.textStyle(.secondaryHeader)
				.foregroundStyle(.secondaryText)
				.flushedLeft
		}

		private func section(text: String?, rows: [SecurityStructureOfFactorSources], showChangeMain: Bool = false) -> some SwiftUI.View {
			VStack(spacing: .medium3) {
				ForEachStatic(rows) { row in
					Button {
						store.send(.view(.shieldTapped(row.metadata.id)))
					} label: {
						ShieldCard(shield: row, mode: .display)
					}
				}
			}
		}
	}
}

private extension StoreOf<ShieldsList> {
	var destination: PresentationStoreOf<ShieldsList.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ShieldsList>) -> some View {
		let destinationStore = store.destination
		return securityShieldsSetup(with: destinationStore)
			.applyShield(with: destinationStore)
			.shieldTemplateDetails(with: destinationStore)
	}

	private func securityShieldsSetup(with destinationStore: PresentationStoreOf<ShieldsList.Destination>) -> some View {
		fullScreenCover(store: destinationStore.scope(state: \.securityShieldsSetup, action: \.securityShieldsSetup)) {
			ShieldSetupCoordinator.View(store: $0)
		}
	}

	private func shieldTemplateDetails(with destinationStore: PresentationStoreOf<ShieldsList.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.shieldTemplateDetails, action: \.shieldTemplateDetails)) {
			ShieldTemplateDetails.View(store: $0)
		}
	}

	private func applyShield(with destinationStore: PresentationStoreOf<ShieldsList.Destination>) -> some View {
		fullScreenCover(store: destinationStore.scope(state: \.applyShield, action: \.applyShield)) {
			ApplyShield.Coordinator.View(store: $0)
		}
	}
}
