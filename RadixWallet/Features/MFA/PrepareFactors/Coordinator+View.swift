import SwiftUI

// MARK: - PrepareFactors
enum PrepareFactors {}

// MARK: - PrepareFactors.Coordinator.View
extension PrepareFactors.Coordinator {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<PrepareFactors.Coordinator>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack(path: $store.scope(state: \.path, action: \.child.path)) {
					PrepareFactors.Intro.View(store: store.scope(state: \.root, action: \.child.root))
				} destination: { store in
					switch store.case {
					case let .addHardwareFactor(store):
						PrepareFactors.AddHardwareFactor.View(store: store)
					case let .addAnotherFactor(store):
						PrepareFactors.AddAnotherFactor.View(store: store)
					}
				}
			}
		}
	}
}
