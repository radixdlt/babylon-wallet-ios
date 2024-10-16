import SwiftUI

// MARK: - PreAuthorizationReview.View
extension PreAuthorizationReview {
	struct View: SwiftUI.View {
		let store: StoreOf<PreAuthorizationReview>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				// TODO: implement
				Text("Implement: PreAuthorizationReview")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { store.send(.view(.appeared)) }
			}
		}

		private var content: some SwiftUI.View {
			ScrollView(showsIndicators: false) {
				VStack(spacing: .zero) {}
			}
		}
	}
}
