import SwiftUI

// MARK: - AddHardwareFactor.View
extension PrepareFactors.AddHardwareFactor {
	struct View: SwiftUI.View {
		let store: StoreOf<PrepareFactors.AddHardwareFactor>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				Text("Add HW Factor")
			}
		}
	}
}
