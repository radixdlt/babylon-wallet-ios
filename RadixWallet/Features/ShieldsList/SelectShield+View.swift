import SwiftUI

// MARK: - SelectShield.View
extension SelectShield {
	struct View: SwiftUI.View {
		let store: StoreOf<SelectShield>
		@Environment(\.dismiss) var dismiss

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView
						.padding(.horizontal, .medium3)
				}
				.footer {
					WithControlRequirements(
						store.selected,
						forAction: { store.send(.view(.confirmButtonTapped($0))) }
					) { action in
						Button(L10n.Common.confirm, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.background(.secondaryBackground)
				.task {
					store.send(.view(.task))
				}
				.withNavigationBar {
					dismiss()
				}
				.destinations(with: store)
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			VStack(spacing: .large2) {
				Text("Select Security Shield")
					.textStyle(.sheetTitle)
					.padding(.horizontal, .medium3)

				VStack(spacing: .medium3) {
					ForEachStatic(store.shields) { shield in
						card(shield)
					}
				}

				Button("Create new Security Shield") {
					store.send(.view(.addShieldButtonTapped))
				}
				.buttonStyle(.secondaryRectangular)

				Spacer()
			}
			.foregroundStyle(.primaryText)
			.multilineTextAlignment(.center)
		}

		private func card(_ shield: SecurityStructureOfFactorSources) -> some SwiftUI.View {
			WithPerceptionTracking {
				ShieldCard(
					shield: shield,
					mode: .selection(isSelected: store.selected == shield)
				)
				.onTapGesture {
					store.send(.view(.selected(shield)))
				}
			}
		}
	}
}

private extension StoreOf<SelectShield> {
	var destination: PresentationStoreOf<SelectShield.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<SelectShield>) -> some View {
		let destinationStore = store.destination
		return securityShieldsSetup(with: destinationStore)
	}

	private func securityShieldsSetup(with destinationStore: PresentationStoreOf<SelectShield.Destination>) -> some View {
		fullScreenCover(store: destinationStore.scope(state: \.securityShieldsSetup, action: \.securityShieldsSetup)) {
			ShieldSetupCoordinator.View(store: $0)
		}
	}
}
