import SwiftUI

// MARK: - AddHardwareFactor.View
extension PrepareFactors.AddHardwareFactor {
	struct View: SwiftUI.View {
		let store: StoreOf<PrepareFactors.AddHardwareFactor>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack {
					Text("Add a Hadware Device")
					Spacer()
				}
				.footer {
					Button("Add Hardware Device") {
						store.send(.view(.addButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}
