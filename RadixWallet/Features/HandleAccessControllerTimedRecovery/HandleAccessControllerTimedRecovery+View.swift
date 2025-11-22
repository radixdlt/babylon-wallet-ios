import SwiftUI

// MARK: - HandleAccessControllerTimedRecovery.View
extension HandleAccessControllerTimedRecovery {
	struct View: SwiftUI.View {
		let store: StoreOf<HandleAccessControllerTimedRecovery>
		@Environment(\.dismiss) var dismiss

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack {
						Text("Your Security Shield is in a timed recovery period. This is a security feature to protect your assets.")

						Text("You will be able to confirm this change after: ")

						if let proposedSecurityStructure = store.provisionalSecurityState {
							SecurityStructureOfFactorSourcesView(structure: proposedSecurityStructure, onFactorSourceTapped: { _ in })
						} else {
							Text("The proposed timed recovery is unknown to the Wallet, and cannot be confirmed.")
						}
					}
				}
				.radixToolbar(title: "Timed Recovery", closeAction: {})
				.footer {
					HStack {
						Button("Stop") {
							store.send(.view(.stopButtonTapped))
						}
						.buttonStyle(.secondaryRectangular)

						Button("Confirm") {
							store.send(.view(.confirmButtonTapped))
						}
						.buttonStyle(.secondaryRectangular)
					}
				}
			}
		}
	}
}
