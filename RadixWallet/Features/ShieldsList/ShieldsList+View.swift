extension ShieldsList.State {}

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
				.radixToolbar(title: "Security Shields")
				.task {
					store.send(.view(.task))
				}
				.destinations(with: store)
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			VStack(spacing: .medium3) {
				ForEach(store.shields, id: \.self) { shield in
					shieldCard(shield)
				}

				Button("Create New Security Shield") {
					store.send(.view(.createShieldButtonTapped))
				}
				.buttonStyle(.secondaryRectangular)
				.padding(.vertical, .medium2)

				InfoButton(.securityshields, label: L10n.InfoLink.Title.securityshields)
			}
			.frame(maxWidth: .infinity)
		}

		private func shieldCard(_ shield: ShieldForDisplay) -> some SwiftUI.View {
			VStack {
				Text(shield.name.rawValue)
			}
			.centered
			.padding(.medium2)
			.background(.app.white)
			.roundedCorners(radius: .small1)
			.cardShadow
		}
	}
}

private extension StoreOf<ShieldsList> {
	var destination: PresentationStoreOf<ShieldsList.Destination> {
		func scopeState(state: State) -> PresentationState<ShieldsList.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ShieldsList>) -> some View {
		let destinationStore = store.destination
		return securityShieldsSetup(with: destinationStore)
	}

	private func securityShieldsSetup(with destinationStore: PresentationStoreOf<ShieldsList.Destination>) -> some View {
		fullScreenCover(store: destinationStore.scope(state: \.securityShieldsSetup, action: \.securityShieldsSetup)) {
			ShieldSetupCoordinator.View(store: $0)
		}
	}
}
