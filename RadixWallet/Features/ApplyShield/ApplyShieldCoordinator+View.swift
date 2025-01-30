import SwiftUI

// MARK: - ApplyShield
enum ApplyShield {}

// MARK: - ApplyShield.Coordinator.View
extension ApplyShield.Coordinator {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<ApplyShield.Coordinator>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack(path: $store.scope(state: \.path, action: \.child.path)) {
					path(for: store.scope(state: \.root, action: \.child.root))
				} destination: { destination in
					path(for: destination)
				}
			}
		}

		@ViewBuilder
		private func path(for store: StoreOf<ApplyShield.Coordinator.Path>) -> some SwiftUI.View {
			switch store.state {
			case .intro:
				if let store = store.scope(state: \.intro, action: \.intro) {
					ApplyShield.Intro.View(store: store)
				}
			}
		}
	}
}
