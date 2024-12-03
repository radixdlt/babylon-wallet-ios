import SwiftUI

// MARK: - AddAnotherFactor.View
extension PrepareFactors.AddAnotherFactor {
	struct View: SwiftUI.View {
		let store: StoreOf<PrepareFactors.AddAnotherFactor>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				Text("Add Another Factor")
			}
		}
	}
}
