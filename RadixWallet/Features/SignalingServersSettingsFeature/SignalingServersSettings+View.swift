import ComposableArchitecture
import SwiftUI

// MARK: - SignalingServersSettings.View
extension SignalingServersSettings {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SignalingServersSettings>

		init(store: StoreOf<SignalingServersSettings>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView()
						.padding(.bottom, .medium1)
						.radixToolbar(title: "Signaling Servers")
				}
				.background(Color.secondaryBackground)
				.onAppear { store.send(.view(.task)) }
				.destinations(with: store)
			}
		}

		private func coreView() -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .zero) {
				Text("Choose and manage signaling server profiles used for WalletConnect P2P.")
					.foregroundColor(.secondaryText)
					.textStyle(.body1HighImportance)
					.padding(.top, .medium3)
					.padding(.horizontal, .medium3)
					.padding(.bottom, .large2)

				if let current = store.current {
					sectionHeader("Current")
					row(for: current)
						.padding(.bottom, .medium3)
				}

				if !store.others.isEmpty {
					sectionHeader("Others")
					VStack(spacing: .zero) {
						ForEach(store.others, id: \.signalingServer) { profile in
							WithPerceptionTracking {
								row(for: profile)
								if profile.signalingServer != store.others.last?.signalingServer {
									Separator()
										.padding(.leading, .medium3)
								}
							}
						}
					}
				}

				Button("Add New Signaling Server") {
					store.send(.view(.addProfileButtonTapped))
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true))
				.padding(.horizontal, .medium3)
				.padding(.top, .large1)
			}
		}

		private func sectionHeader(_ title: String) -> some SwiftUI.View {
			Text(title)
				.textStyle(.body1Link)
				.foregroundColor(.secondaryText)
				.padding(.horizontal, .medium3)
				.padding(.bottom, .small3)
		}

		private func row(for profile: P2PTransportProfile) -> some SwiftUI.View {
			Button {
				store.send(.view(.rowTapped(profile.signalingServer)))
			} label: {
				HStack(alignment: .center, spacing: .medium3) {
					VStack(alignment: .leading, spacing: .small3) {
						Text(profile.name)
							.textStyle(.body1Header)
							.foregroundColor(.primaryText)
							.frame(maxWidth: .infinity, alignment: .leading)

						Text(profile.signalingServer)
							.textStyle(.body2Regular)
							.foregroundColor(.secondaryText)
							.lineLimit(2)
							.multilineTextAlignment(.leading)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					Image(systemName: "chevron.right")
						.foregroundStyle(Color.primaryText)
				}
				.padding(.medium3)
				.background(Color.primaryBackground)
			}
			.buttonStyle(.tappableRowStyle)
		}
	}
}

private extension StoreOf<SignalingServersSettings> {
	var destination: PresentationStoreOf<SignalingServersSettings.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<SignalingServersSettings>) -> some View {
		let destinationStore = store.destination
		return navigationDestination(store: destinationStore.scope(state: \.details, action: \.details)) {
			SignalingServerDetails.View(store: $0)
		}
	}
}
