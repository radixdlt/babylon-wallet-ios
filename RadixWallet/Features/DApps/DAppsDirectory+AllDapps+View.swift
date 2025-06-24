import SwiftUI

// MARK: - AllDapps.View

extension DAppsDirectory.AllDapps {
	struct View: SwiftUI.View {
		let store: StoreOf<DAppsDirectory.AllDapps>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				// TODO: implement
				Text("Implement: AllDapps")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { store.send(.view(.appeared)) }
			}
		}
	}
}
